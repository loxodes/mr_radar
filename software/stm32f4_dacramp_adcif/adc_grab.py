# visualization of ADC samples dumped from stm32f4
# displays samples in time and and a plot of distance 
# jon klein, kleinjt@ieee.org
# mit license

import serial
from numpy.fft import *
import pdb
from pylab import *

c = 3e8
ts = 1/(1.2e6)
ser = serial.Serial('/dev/ttyACM1', 9600, timeout=1)
nsamples = pow(2,14)
bsweep = 100e9
t = [i * ts for i in range(nsamples)]

while(True):
    data = []

    while(ser.read(3) != '\x55\x55\x55'):
        print 'waiting for dump...'

    s = ser.read()
    while(s == '\x55'):
        s = ser.read()

    if(s + ser.read(4) != 'start'):
        print 'I am having trouble synching..'
    else:
        print 'dump found, capturing'

    for i in range(nsamples):
        l = ser.read()
        u = ser.read()
        data += [ord(l) + (ord(u) << 8)]

    if(ser.read(4) != 'stop'):
        print 'something went wrong..'


    print 'completed capture, displaying..'

    subplot(2,1,1)
    plot([ti * (1e3) for ti in t], data)
    title('time domain samples')
    xlabel('time (ms)')
    ylabel('amplitude')

    subplot(2,1,2)
    fdata = fft(data)
    f = fftfreq(len(data), ts)
    d = [((freq/2) / bsweep) * c for freq in f]
    fdata = [pow(fi.real * fi.real + fi.imag * fi.imag, .5) for fi in fdata]
    plot(d[:(len(d)/2)], fdata[:len(fdata)/2])

    title('distance of targets')
    ylabel('amplitude')
    xlabel('distance (meters)')
    
    show()
