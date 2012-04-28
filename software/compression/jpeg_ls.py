# jpeg-ls encoder
# almost certainly not standards compliant, and entirely unoptimized
# 
# uses notation and algorithm from: 
# and The LOCO-I Lossless Image Compression Algorithm: Principles and Standardization into JPEG-LS
# Marcelo J. Weinberger, Gadiel Seroussi, and Guillermo Sapiro


# supports monochrome images
# currently lossless only

#  c  b  d
#  a  x  <-- current pixel

import numpy
import pdb
import sys

quan_vector = [-15,-7,-3,1,0,1,3,7,15] # quantization steps for q1, q2, q3

A_CONTEXT = 0
B_CONTEXT = 1
C_CONTEXT = 2
N_CONTEXT = 3
INT_CONTEXT_IDX = [365, 366]

J = [0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,5,5,6,6,7,7,8,9,10,11,12,13,14,15]

N0 = 64 # reset threshold for N, set between 32 and 256

def jpegls_encode(image, bpp):
    output = []
    height = len(image)
    width = len(image[0])

    # step 0, initialization
    # compute lmax
    bmax = max(2, bpp) 
    l_max = 2 * (bmax * max(8, bmax))
    alpha = pow(2, bpp)

    # initialize context table, [A, B, C, N]
    context_table = [[max(2, numpy.floor(((alpha+32)/64))),0,0,1] for i in range(367)]
    NN = [0, 0]

    # initialize irun
    irun = 0
    
    for row in range(height): 
        output.append([])
        run = 0
        col = 0 
        while col < width:
            print 'encoding: ' + str(row) + ',' + str(col)
            # determine context pixels, with special cases: first and last column, first row
            x = image[row][col]
            sign = 1
            
            if row == 0:
                b = 0
                c = 0
                d = 0
            else:
                b = image[row-1][col]
                c = image[row-1][col-1]
                if col == width - 1:
                    d = b
                else:
                    d = image[row-1][col+1]
                
            if col == 0:
                a = b
            else:
                a = image[row][col-1]
            
            # step 1, compute local gradients
            g1 = d - b
            g2 = b - c #a - c ???
            g3 = c - a #c - b ???
            
            # step 2, check for run mode processing
            if g1 == g2 == g3 == 0:
                print 'run mode processing'
                run = 0
                x_run = x

                while x_run == x:
                    run += 1
                    if col + run >= width - 1:
                        break
                    x = image[row][col+run]

                col += run

                while run >= (1 << J[irun]):
                    output[-1].append('1')
                    run -= (1 << J[irun])
                    if irun <= len(J):
                        irun += 1
                
                if x_run != x:
                    output[-1].append('0' + bin(run)[2:])
                    if irun > 0:
                        irun -= 1
                    
                    # encode residual using interruption context
                    a = image[row][col-1]
                    if row:
                        b = image[row-1][col]
                    
                    int_type = a - b == 0
                     
                    if int_type:
                        x_hat = a
                    else:
                        x_hat = b

                    r = x - x_hat
                     
                    if int_type and a > b:
                        x_hat = -x_hat
                        sign = -1
                    
                    r = clamp_range(r, alpha)

                    A = context_table[INT_CONTEXT_IDX[int_type]][A_CONTEXT]
                    B = context_table[INT_CONTEXT_IDX[int_type]][B_CONTEXT]
                    C = context_table[INT_CONTEXT_IDX[int_type]][C_CONTEXT]
                    N = context_table[INT_CONTEXT_IDX[int_type]][N_CONTEXT]
    
                    t = a + int_type * (N >> 1)    
                 
                    k = compute_k(N, t)
                    
                    if (k == 0) and (r < 0) and (2 * NN[int_type] < N): 
                        map = 1
                    elif (r < 0) and (2 * NN[int_type] >= N):
                        map = 1
                    elif (r < 0) and k:
                        map = 1
                    else:
                        map = 0

                    r_map = 2 * abs(r) - int_type - map
                    
                    output[-1].append(gpo2_encode(k, r_map)) # ADD LIMITING

                    if r < 0:
                        NN[int_type] += 1
                    
                    A += (r_map + int_type) >> 1
                    if N == N0:
                        N = N / 2
                        A = A / 2
                        NN[int_type] = NN[int_type] / 2
                    
                    N += 1
                    context_table[INT_CONTEXT_IDX[int_type]][A_CONTEXT] = A
                    context_table[INT_CONTEXT_IDX[int_type]][N_CONTEXT] = N

                else: # end of line
                    output[-1].append('1')

            else:
                print 'local encoding'
                # step 3, quantize the local gradients 
                Q = vect_quantize([g1, g2, g3], quan_vector)
                
                # step 4, compute context
                # determine sign bit
                for i in range(len(Q)):
                    if Q[i] < 0:
                        Q = [-q for q in Q]
                        sign = -1
                        break
                    elif Q[i] == 0:
                        continue
                    else:
                        break

                # compute context index, gather contexts
                context = 81 * Q[0] + 9 * Q[1] + Q[2]
                print Q
                print context 
                A = context_table[context][A_CONTEXT]
                B = context_table[context][B_CONTEXT]
                C = context_table[context][C_CONTEXT]
                N = context_table[context][N_CONTEXT]

                # step 5, compute fixed prediction
                if(c >= max(a,b)):
                    x_hat = min(a,b)
                elif(c <= min(a,b)):
                    x_hat = max(a,b)
                else:
                    x_hat = a + b - c
                
                # step 6, correct prediction with context table, clamp
                x_hat = x_hat + sign * C
                
                if x_hat < 0:
                    x_hat = 0
                elif x_hat > alpha - 1:
                    x_hat = alpha - 1
                
                # step 7, compute prediction residual
                r = sign * (x - x_hat)
                
                # this doesn't entirely make sense yet.. stepping by alpha feels extreme
                r = clamp_range(r, alpha)
                
                # step 8, compute golumn parameter k
                k = compute_k(N, A)

                # step 9, map residual
                if k == 0 and 2 * B <= -N:
                    if r >= 0:
                        r_map = 2 * r + 1
                    else:
                        r_map = -2 * (r + 1)
                else:
                    if r >= 0:
                        r_map = 2 * r
                    else:
                        r_map = -2 * r - 1

                # step 10, golomb encode prediction residual using k
                if r_map >> k < l_max - bpp - 1:
                    output[-1].append(gpo2_encode(k, r_map))
                else:
                    word = bin(r_map)[2:]
                    word = '0' * (bpp - len(word)) + word
                    output[-1].append('0' * (l_max - bpp - 1) + '1' + word)

                # step 11 and 12, update context counters 
                A += abs(r)
                B += r
                
                if N == N0:
                    N = numpy.floor(N/2)
                    A = numpy.floor(A/2)
                    B = numpy.floor(B/2)

                N += 1
                
                if B <= -N:
                    C -= 1
                    B += N
                    if B <= -N:
                        B = -N + 1
                elif B > 0:
                    C += 1
                    B -= N
                    if B > 0:
                        B = 0

                context_table[context][A_CONTEXT] = A
                context_table[context][B_CONTEXT] = B
                context_table[context][C_CONTEXT] = C
                context_table[context][N_CONTEXT] = N
                col += 1

    return output

def clamp_range(r, alpha):
    while r <= numpy.floor(-alpha/2):
        r += alpha
    print 'r: ' + str(r)
    while r > numpy.ceil(alpha/2) + 1:
        r -= alpha
    return r
                  
def compute_k(N, A):
    k = 0
    while (N << k) < A:
        k += 1
    return k
 
def vect_quantize(g_vect, vector):
    q = [0,0,0]
    
    for i in range(len(g_vect)):
        cmp = [g_vect[i] < v for v in vector] 
        if True in cmp:
            q[i] = cmp.index(True)-4
        else:
            q[i] = 4
    return q 

def gpo2_encode(k, codeword):
    if k:
        quotient = unary(codeword / k)
    else:
        quotient = ''
        k = pow(2,16) # FIX !!
    remainder = bin(codeword % k)[2:]
    return quotient + remainder

def unary(x):
    return x * '0' + '1'
