# scraps of code to test reading and poking at SRTM hgt files, calculating entropy
# incomplete
# jon klein, kleinjt@ieee.org
# mit license

from pylab import *
import pdb
import struct
import scipy.stats
import numpy as np
import matplotlib.cm as cm
import matplotlib.pyplot as plt

filename = 'N19W156_fill.hgt' # holes filled using SRTMFill
width = 1201

# calculate the entropy of an (up to) 2d array 
def entropy(im):
    ar = list(np.array(im).flatten())
    counts = {}
    for c in ar:
        if not c in counts:
            counts[c] = int(0)
        counts[c] += 1
    return scipy.stats.entropy(counts.values())
 
# return an elevation array from SRTM file 
def read_hgt(filename, width):
    fi = open(filename, "rb")
    contents = fi.read()
    fi.close()
    z_raw = list(struct.unpack(">" + str(width * width) + "H", contents))
    elev = [[z_raw[width*j + i] for i in range(width)] for j in range(width)]
    return elev


def main():
    # read in test file 
    elev = read_hgt(filename, width) 

    # plot elevation
    plt.subplot(3,1,1)
    imshow(np.log1p(elev))
    plt.title('hawaii main island')
    print 'entropy (before): ' + str(entropy(elev))

    # try simple differential model
    plt.subplot(3,1,2)
    elev_diff = [[elev[j][i] - (i>0) * elev[j][i - 1] for i in range(width)] for j in range(width)]
    
    imshow(np.log1p(elev_diff))
    plt.title('hawaii diff')
    print 'entropy (after differential model): ' + str(entropy(elev_diff))
  
    # stick compression algorithm here!
    # to be determined.. 

    # restore image 
    plt.subplot(3,1,3)
    elev_restored = np.cumsum(np.array(elev_diff),1)
    imshow(np.log1p(elev_restored))
    plt.title('hawaii restored')
    print 'entropy (after restoring): ' + str(entropy(elev_restored))
    show()

    if max(abs(np.array(elev_restored).flatten() - np.array(elev).flatten())) != 0:
        print 'the image was not restored properly :('
    else:
        print 'inflation sucessful!'

if __name__ == "__main__":
    main()

