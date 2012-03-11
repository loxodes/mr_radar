# visualization of ADC samples dumped from stm32f4
# displays samples in time and and a plot of distance 
# jon klein, kleinjt@ieee.org
# mit license

import serial
import matplotlib.pyplot as plt
from numpy.fft import *

c = 3e8
ts = 1/(2.4e6)
ser = serial.Serial('/dev/ttyACM1', 9600, timeout=1)
nsamples = pow(2,14)
bsweep = 100e9

t = [i * ts for i in range(nsamples)]

data = []

while(ser.read(4) != 'tart'):
    print 'waiting for dump...'

print 'dump found, capturing'

for i in range(nsamples):
    l = ser.read()
    u = ser.read()
    data += [ord(l) + (ord(u) << 8)]

if(ser.read(4) != 'stop'):
    print 'something went wrong..'

print 'completed capture, displaying..'

plt.subplot(2,1,1)
plt.plot([ti * (1e3) for ti in t], data)
plt.title('time domain samples')
plt.xlabel('time (ms)')
plt.ylabel('amplitude')

plt.subplot(2,1,2)
fdata = fft(data)
f = fftfreq(len(data), ts)
d = [((freq/2) / bsweep) * c for freq in f]
fdata = [pow(fi.real * fi.real + fi.imag * fi.imag, .5) for fi in fdata]
plt.plot(d[:(len(d)/2)], fdata[:len(fdata)/2])

plt.title('frequency domain')
plt.ylabel('amplitude')
plt.xlabel('distance (meters)')

plt.show()

