% script to help calculate the specifications of the ADC on the radar
% used to calculate how the sampling frequency, antialiasing filter cutoff
% frequency, chrip length, and resolution of the ADC will change the 
% maximum distance, distance resolution, and sensitivity of the radar

f_start = 3.3e9;
f_stop = 3.4e9; 
t_sweep = 4e-3;
c = 3e8;
fs = 4e6;
f_cutoff = .4e6;
adc_res = 14; % bits
minimum_signal = -90; % dBm

ts = 1/fs;
bsweep = (f_stop-f_start)/t_sweep;

f_res = (1 / (t_sweep));
d_res = ((f_res/bsweep)/4) * c;
max_range = c*((f_cutoff/2)/bsweep);
sqnr = 20*log10(2^adc_res);


fprintf('frequency resolution: %d Hz\n', f_res);
fprintf('distance resolution: %d m\n', d_res);
fprintf('max range: %d m\n', max_range);
fprintf('signal-to-quantization-noise ratio: %d dB\n', sqnr);