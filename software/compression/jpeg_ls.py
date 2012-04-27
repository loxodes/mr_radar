# jpeg-ls encoder/decoder
# pass in list of lists
# uses notation and algorithm from: 
# and The LOCO-I Lossless Image Compression Algorithm: Principles and Standardization into JPEG-LS
# Marcelo J. Weinberger, Gadiel Seroussi, and Guillermo Sapiro


# supports monochrome images
# currently lossless only

#  c  b  d
#  a  x  <-- current pixel

import numpy

quan_vector = [-15,-7,-3,1,0,1,3,7,15] # quantization steps for q1, q2, q3
quan_level = 5 # quantization level for q4
bias_table = {}

A_CONTEXT = 0
B_CONTEXT = 1
C_CONTEXT = 2
N_CONTEXT = 3

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
    context_table = [[max(2, numpy.floor(((alpha+32)/64))),0,0,1] for i in range(365)]
    
    # initialize irun
    irun = 0
    
    for row in range(height): 
        output.append([])
        run = 0
        for col in range(width):
            # check for run mode processing
            if(run):
                # add check for end of line
                if(run == m):
                    output += '1'
                    run = 0
                    irun += 1
                    m = updatem(irun)

                if(x == a):
                    run += 1
                    if(x == width - 1):
                        output += '1'
                        irun += 1
                        # update m run table?
                    continue
                else:
                    output += '0' + bin(run)[2:]
                    irun -= 1
                    run = 0
                    m = updatem(irun)
            
            # otherwise.. single component encoding
            # find neighboring pixels
            x = image[row][col]
            a = image[row][col-1]
            b = image[row-1][col]
            c = image[row-1][col-1]
            d = image[row-1][col+1]
            sign = 1
            
            # special cases: first and last column, first row
            if row == 0:
                b = 0
                c = 0
                d = 0
            
            if col == 0:
                a = b

            if col == width - 1:
                d = b

            # step 1, compute local gradients
            g1 = d - b
            g2 = a - c
            g3 = c - b
            
            # step 2, check for run mode processing
            if g1 == g2 == g3 == 0:
                run += 1
                continue
                # (may be zero run, or stop at end of line, 
                # read new samples until x!=a, or end of line
                # let m = 2^g be golomb code,
                # for each segment of length m, append  1 to output bit stream and increment i1
                # if ran to end of line, append 1 to bistream
                # otherwise, append 0 and use binary representation of resudial g bits, decrese irun
                # encode run interruption sample, continue
                

            else:
                # step 3, quantize the local gradients 
                C = vect_quantize([g1, g2, g3], quan_vector)
                
                # step 4, compute context
                # determine sign bit
                for i in range(len(C)):
                    if C[i] < 0:
                        C = [-q for q in C]
                        sign = -1
                        break
                    elif C[i] == 0:
                        continue
                    else:
                        break
                # compute context index, gather contexts
                context = sum([C[i] * pow(len(quan_vector),i) for i in range(len(C))])
                
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
                if x_hat > alpha - 1:
                    x_hat = alpha - 1
                
                # step 7, compute prediction residual
                r = sign * (x - x_hat)
                
                # this doesn't entirely make sense yet.. stepping by alpha feels extreme
                while r <= numpy.floor(-alpha/2):
                    r += alpha
                while r > numpy.ceil(alpha/2) + 1:
                    r -= alpha

                # step 8, compute golumn parameter k
                k = 0
                while (N << k) < A:
                    k += 1
                
                # step 9, map residual

                # step 10, golomb encode prediction residual using k
                                
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


def vect_quantize(g_vect, vector):
    return [[g > v for v in vector].index(False)-1 for g in g_vect]

def thresh_quantize(g, threshold):
    if(abs(g) < threshold):
        return 0
    if(g > threshold):
        return 1
    return 2

def gpo2_encode(m, codeword):
    quotient = unary(codeword / m)
    remainder = bin(codeword % m)[2:]
    return quotient + remainder

def unary(x):
    return x * '0' + '1'

def jpegls_decode(image):
    pass

def updatem(irun):
    return m
