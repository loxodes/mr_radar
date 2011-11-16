clc; clear; clf;
set(0,'defaultaxesfontsize',16);
set(0,'defaulttextfontsize',16);

% mr_radar vco test 
f_start = 30e6;         % start frequency (Hz)
f_stop = 35e6;          % stop frequency (Hz)
t_sweep = 1e-3;         % sweep time (s)
type = 'pnoise';         % vco type ('ideal', 'awgnoise')
vco_snr = 1e-3;            % vco snr for awgnoise (dB)
ts = 1e-8;              % sample time
tbounce = 20e-5;        % target distance (s)
f_cutoff = 2e6;         % mixer filter cutoff frequency (Hz)
smooth = 4;            % frequency bins
bwthreshold = .5;       % 3dB bandwidth

% create time and frequency vectors for VCO
[ t, t_rf, perror ] = vco( f_start, f_stop, t_sweep, type, ts, vco_snr);

% create IF frequency, delayed version of RF
f_if = delay_line(t_rf, tbounce, ts);

% calculate LO, product of RF and IF frequency
[ t_lo ] = mixer( t_rf, f_if, f_cutoff, ts );

% remove
[ t_lo_cleaned ] = remove_perror(t_lo, ts, perror, t_sweep, tbounce);

% display spectrogram of downconverted output
subplot(4,1,1);
spectrogram(t_lo,256,250,256,1/ts);
title('sampled signal');

% display one sided spectrum of t_lo up to mixer cutoff
subplot(4,1,2);
nfft = 2^nextpow2(length(t_lo));
fft_lo = fft(t_lo,nfft);
f_fft_lo = linspace(0,1,nfft/2+1)/(2*ts);
f_lo_lp = f_fft_lo(f_fft_lo < f_cutoff);
f_lo_lp_singlesided =  2*abs(fft_lo(1:length(f_lo_lp)));
plot(f_lo_lp,f_lo_lp_singlesided);
grid on;

df = f_cutoff/length(f_lo_lp_singlesided);
fprintf('bandwidth of %d MHz\n', (evaluate_signal(df,f_lo_lp_singlesided, bwthreshold, smooth)/1e6))
% display spectrogram of transmitted and received chirps
% change to time as x axis
subplot(4,1,3);

spectrogram(t_rf,256,250,256,1/ts);
view(0,90);
title('transmitted chirp');
subplot(4,1,4);
spectrogram(f_if,256,250,256,1/ts);
title('received chirp');