# visualization of ADC samples dumped from stm32f4
# displays samples in time and and a plot of distance 
# jon klein, kleinjt@ieee.org
# mit license

import serial
from numpy.fft import *
import pdb
from pylab import *
import numpy

c = 3e8
ts = 1/(1.2e6)
nsamples = pow(2,13)
bsweep = 100e9 # hz/second
dead_zone = 5 # meters
threshold = .1e7
pulses = 1
clutter_pulses = 0
clutter = numpy.zeros(nsamples/2)
bus_pirate = 0
t = [i * ts for i in range(nsamples)]

def grab_pulse(ser):
    data = []

    while(ser.read(3) != '\x55\x55\x55'):
        print 'waiting for dump...'
        ser.write('r')

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
    
    return data

def process_distance(data):
    fdata = fft(data)
    f = fftfreq(len(data), ts)
    d = [((freq/2) / bsweep) * c for freq in f]
    d = d[:(len(d)/2)]
    fdata = [pow(pow(fi.real,2) + pow(fi.imag,2), .5) for fi in fdata]
    fdata = fdata[:len(fdata)/2]
    return d, fdata

def main():
    # setup serial for bus pirate in USART passthrough mode
    if(bus_pirate):
        ser = serial.Serial('/dev/ttyUSB0', 115200, timeout=1)
        ser.write('m\x133\x139\x131\x131\x131\x132\13(1)\x13y')
        ser.flushInput()
    # setup serial for MSP430 launchpad eval board serial
    else:
        ser = serial.Serial('/dev/ttyACM0', 9600, timeout=1)
    
    for p in range(clutter_pulses):
        data = grab_pulse(ser)
        d, fdata = process_distance(data)
        clutter += numpy.array(fdata)
    if clutter_pulses:
        clutter /= float(clutter_pulses) 

    for p in range(pulses):
        data = grab_pulse(ser)
        print 'completed capture...'

        subplot(2,1,1)
        plot([ti * (1e3) for ti in t], data)
        title('time domain samples')
        xlabel('time (ms)')
        ylabel('amplitude')

        subplot(2,1,2)
        d, fdata = process_distance(data)
       
        fd_array = numpy.array(fdata) - clutter
        d_array = numpy.array(d)

        plot(d_array, fd_array)
        title('distance of targets')
        ylabel('amplitude')
        xlabel('distance (meters)')
        
        print 'targets found:'
        print d_array[fd_array > threshold]

    ser.close()
    show()


if __name__ == "__main__":
    main()


