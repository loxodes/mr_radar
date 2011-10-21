% mr_radar vco test
f_start = 30e6;         % start frequency (Hz)
f_stop = 35e6;          % stop frequency (Hz)
t_sweep = 1e-3;         % sweep time (s)
type = 'awgnoise';      % vco type ('ideal', 'awgnoise')
vco_snr = 5;            % vco snr for awgnoise (dB)
ts = 1e-8;              % sample time
tbounce = 20e-5;        % target distance (s)
f_cutoff = 2e6;         % mixer filter cutoff frequency (Hz)

% create time and frequency vectors for VCO
[ t, f_rf ] = vco( f_start, f_stop, t_sweep, type, ts, vco_snr);

% create IF frequency, delayed version of RF
f_if = delay_line(f_rf, tbounce, ts);

% calculate LO, product of RF and IF frequency
[ f_lo ] = mixer( f_rf, f_if, f_cutoff, ts );

% display spectrogram of downconverted output
subplot(4,1,1);
spectrogram(f_lo,256,250,256,1/ts);
title('sampled signal');

% display one sided spectrum of f_lo up to mixer cutoff
subplot(4,1,2);
nfft = 2^nextpow2(length(f_lo));
fft_lo = fft(f_lo,nfft);
f_fft_lo = linspace(0,1,nfft/2+1)/(2*ts);
f_lo_lp = f_fft_lo(f_fft_lo < f_cutoff);
plot(f_lo_lp, 2*abs(fft_lo(1:length(f_lo_lp))));
grid on;

% display spectrogram of transmitted and received chirps
subplot(4,1,3);
spectrogram(f_rf,256,250,256,1/ts);
title('transmitted chirp');
subplot(4,1,4);
spectrogram(f_if,256,250,256,1/ts);
title('received chirp');