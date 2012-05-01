#i jpeg-ls encoder
# almost certainly not standards compliant, and entirely unoptimized
# 
# uses notation and algorithm from: 
# and The LOCO-I Lossless Image Compression Algorithm: Principles and Standardization into JPEG-LS
# Marcelo J. Weinberger, Gadiel Seroussi, and Guillermo Sapiro


# supports monochrome images
# currently lossless only

#  c  b  d
#  a  x  <-- current pixel

import math
import pdb

quan_vector = [-21,-7,-3,0,0,3,7,21] # quantization steps for q1, q2, q3

A_CONTEXT = 0
B_CONTEXT = 1
C_CONTEXT = 2
N_CONTEXT = 3
INT_CONTEXT_IDX = [365, 366]

J = [0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,5,5,6,6,7,7,8,9,10,11,12,13,14,15]

N0 = 64 # reset threshold for N, set between 32 and 256

def jpegls_encode(image, bpp, near):
    output = []
    height = len(image)
    width = len(image[0])

    # step 0, initialization
    # compute lmax
    l_max = 2 * (bpp + max(8, bpp))

    if near:
        alpha = ((pow(2, bpp) + (2 * near)) / (2 * near + 1)) + 1
    else:
        alpha = pow(2, bpp)

    # initialize context table, [A, B, C, N]
    context_table = [[max(2, ((alpha+32)/64)),0,0,1] for i in range(367)]
    NN = [0, 0]

    # initialize irun
    irun = 0
    
    for row in range(height): 
        output.append([])
        run = 0
        col = 0 
        while col < width:
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
                if row == 1 or row == 0:
                    c = 0
                else:
                    c = image[row-2][col] 
            else:
                a = image[row][col-1]
            
            # step 1, compute local gradients
            g1 = d - b
            g2 = b - c
            g3 = c - a
            
            # step 2, check for run mode processing
            if abs(g1) <= near and abs(g2) <= near and abs(g3) <= near:
                run = 0
                x_run = a
                x = image[row][col]
                
                while abs(x_run - x) <= near:
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
                
                if abs(x_run - x) > near:
                    output[-1].append('0')
                    output[-1].append(binpad(run,J[irun]))

                    if irun > 0:
                        irun -= 1

                    # encode residual using interruption context
                    if col:
                        a = image[row][col-1]
                    
                    if row:
                        b = image[row-1][col]
                    
                    int_type = abs(a - b) <= near
                     
                    if int_type:
                        x_hat = a
                    else:
                        x_hat = b

                    r = x - x_hat
                     
                    if int_type and a > b:
                        x_hat = -x_hat
                        sign = -1
                   
                    if near:
                        x_hat = error_quantize(x_hat, alpha, near)
                        r = sign * (x - x_hat) * (2 * near + 1)

                    r = clamp_range(r, alpha)

                    A = context_table[INT_CONTEXT_IDX[int_type]][A_CONTEXT]
                    B = context_table[INT_CONTEXT_IDX[int_type]][B_CONTEXT]
                    C = context_table[INT_CONTEXT_IDX[int_type]][C_CONTEXT]
                    N = context_table[INT_CONTEXT_IDX[int_type]][N_CONTEXT]
    
                    t = A + int_type * (N >> 1)    
                 
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
                    
                    output[-1].append(gpo2_encode(k, r_map, l_max - J[irun] -1, bpp))

                    if r < 0:
                        NN[int_type] += 1
                    
                    A += (r_map + 1 - int_type) >> 1 # ??? (1 + int_type)?

                    if N == N0:
                        N = N / 2
                        A = A / 2
                        NN[int_type] = NN[int_type] / 2
                    N += 1
                    
                    context_table[INT_CONTEXT_IDX[int_type]][A_CONTEXT] = A
                    context_table[INT_CONTEXT_IDX[int_type]][N_CONTEXT] = N
                    col += 1

                elif run > 0:
                    output[-1].append('1')
            else:
                # step 3, quantize the local gradients 
                Q = vect_quantize([g1, g2, g3], quan_vector, near)
                
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
                A = context_table[context][A_CONTEXT]
                B = context_table[context][B_CONTEXT]
                C = context_table[context][C_CONTEXT]
                N = context_table[context][N_CONTEXT]

                # step 5, compute fixed prediction
                if c >= max(a,b):
                    x_hat = min(a,b)
                elif c <= min(a,b):
                    x_hat = max(a,b)
                else:
                    x_hat = a + b - c
                
                # step 6, correct prediction with context table, clamp
                x_hat = x_hat + sign * C
                x_hat = error_quantize(x_hat, alpha, near)

                # step 7, compute prediction residual
                r = sign * (x - x_hat) * (2 * near + 1)
                
                # this doesn't entirely make sense yet.. stepping by alpha feels extreme
                r = clamp_range(r, alpha)
                
                # step 8, compute golumn parameter k
                k = compute_k(N, A)

                # step 9, map residual
                if k == 0 and 2 * B <= -N and (not near):
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
                output[-1].append(gpo2_encode(k, r_map, l_max - bpp - 1, bpp))

                # step 11 and 12, update context counters 
                A += abs(r)
                B += r * (2 * near + 1)
                
                if N == N0:
                    N = N/2
                    A = A/2
                    B = B/2

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


def error_quantize(x_hat, alpha, near):
    if near:
        if x_hat > 0:
            x_hat = (x_hat + near)/(2 * near + 1)
        else:
            x_hat = -(near - x_hat)/(2 * near + 1)
    if x_hat < 0:
        x_hat = 0
    elif x_hat > alpha - 1:
        x_hat = alpha - 1
    return x_hat

def clamp_range(r, alpha):
    while r <= -alpha/2:
        r += alpha
    while r > int(math.ceil(alpha/2)) + 1:
        r -= alpha
    return r
                  
def compute_k(N, A):
    k = 0
    while (N << k) < A:
        k += 1
    return k
 
def vect_quantize(g_vect, vector, near):
    q = [0,0,0]
    
    for i in range(len(g_vect)):
        if g_vect[i] <= vector[0]:
            q[i] = -4
        elif g_vect[i] <= vector[1]:
            q[i] = -3
        elif g_vect[i] <= vector[2]:
            q[i] = -2
        elif g_vect[i] < -near:
            q[i] = -1
        elif g_vect[i] <= near:
            q[i] = 0
        elif g_vect[i] < vector[5]:
            q[i] = 1 
        elif g_vect[i] < vector[6]:
            q[i] = 2
        elif g_vect[i] < vector[7]:
            q[i] = 3
        else:
            q[i] = 4
    return q 

def gpo2_encode(k, codeword, limit, bpp):
    quotient = unary(codeword >> k) 
    remainder = binpad(codeword % pow(2,k),k)
    if len(quotient) < limit:
        return quotient + remainder
    else:
        return limit * '0' + '1' + binpad(codeword - 1, bpp)

def binpad(x, l):
    if not l:
        return ''
    y = bin(x)[2:]
    return (l - len(y)) * '0' + y

def bin_encode(output, filename):
    # not a smart or efficent way of doing this..
    f = open(filename, 'w')
    for line in output:
        binline = ''.join(line)
        binline += (len(binline) % 8) * '0'
        for i in range(0,len(binline),8):
            f.write(chr(int(binline[i:i+8],2)))
        f.write('\n')
    f.close()

def unary(x):
    return x * '0' + '1'
