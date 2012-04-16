# jpeg-ls encoder/decoder
# pass in list of lists
# uses notation and algorithm from LOCO-I: A Low Complexity, Context-Based, Lossless Image Compression Algorithm
# Marcelo J. Weinberger, Gadiel Seroussi, and Guillermo Sapiro, Hewlett-Packard Laboratories

# and The LOCO-I Lossless Image Compression Algorithm: Principles and Standardization into JPEG-LS
# Marcelo J. Weinberger, Gadiel Seroussi, and Guillermo Sapiro

# Evaluation of JPEG-LS, the New Lossless and
# Controlled-Lossy Still Image Compression Standard,
# for Compression of High-Resolution Elevation Data
# Shantanu D. Rane and Guillermo Sapiro, Member, IEEE


# supports monochrome images
# currently lossless only

#    c  a  d
# e  b  x  <-- current pixel

import numpy

quan_vector = [-15,-7,-3,1,0,1,3,7,15] # quantization steps for q1, q2, q3
quan_level = 5 # quantization level for q4
bias_table = {}

A_CONTEXT = 0
B_CONTEXT = 1
C_CONTEXT = 2
N_CONTEXT = 3


def jpegls_encode(image, bpp):
    output = []
    height = len(image)
    width = len(image[0])

    bmax = max(2, bpp) 
    l_max = 2 * (bmax * max(8, bmax))
    
    irun = 0
    # initialize context table
    context_table = [[max(2, numpy.floor(((pow(2,bpp)+32)/64))),0,0,1] for i in range(365)]


    for row in range(height): 
        output.append([])
        run = 0
        for col in range(width):
            x = image[row][col]
            a = image[row-1][col]
            b = image[row][col-1]
            c = image[row-1][col-1]
            d = image[row+1][col+1]
            e = image[row][col-2]
            sign = 1

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

            # for the first and last column, whenever undefined,
            # the samples at positions a and d are assumed to equal b
            # and position c is copied from the value that was assigned to a
            # for the first sample of the previous line
           
            # compute local gradients
            g1 = d - a
            g2 = a - c
            g3 = c - b
            
            if g1 == g2 == g3 == 0:
                # do run length encoding
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
                if(c >= max(a,b)):
                    x_hat = min(a,b)
                elif(c <= min(a,b)):
                    x_hat = max(a,b)
                else:
                    x_hat = a + b - c
                
                r = x - x_hat


                g4 = b - e
                # quantize gradients
                C = vect_quantize([g1, g2, g3], quan_vector)
                for i in range(len(C)):
                    if C[i] < 0:
                        C = [-q for q in C]
                        sign = -1
                        break
                    elif C[i] == 0:
                        continue
                    else:
                        break
                
                context = sum([C[i] * pow(len(quan_vector),i) for i in range(len(C))])

                context_table[context] = 
                 

                # map triplet to range [1,364] (0 is RLE), use index for context counter

                # compute fixed prediction

                # correct fixed prediction by adding C for context, clamp corrected value, obtain new prediction

                # compute residual, flip if negative
                # reduce residual modulo alphabet to range

                # compute golomb paramter

                # update contetx counters, B, C

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
