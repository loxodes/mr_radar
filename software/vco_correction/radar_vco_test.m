clc; clear; clf;
%set(0,'defaultaxesfontsize',16);
%set(0,'defaulttextfontsize',16);

% mr_radar vco test 
f_start = 4e6;          % start frequency (Hz)
f_stop = 6e6;           % stop frequency (Hz)
t_sweep = 2e-3;         % sweep time (s)
type = 'pnoise';        % vco type ('ideal', 'awgnoise')
vco_snr = 1e-2;         % vco snr for awgnoise (dB)
ts = 1e-7;              % sample time
tbounce = 20e-5;        % target distance (s)
f_cutoff = 1e6;         % mixer filter cutoff frequency (Hz)
smooth = 4;             % frequency bins
bwthreshold = .5;       % 3dB bandwidth
trefdelay = 4e-6;     % reference delay

bsweep = (f_stop-f_start)/t_sweep;
% create time and frequency vectors for VCO
[ t, t_rf, perror, real_ierror] = vco( f_start, f_stop, t_sweep, type, ts, vco_snr);

% create IF frequency, delayed version of RF
[ t_if ] = delay_line(t_rf, tbounce, ts);

% calculate reference delay
[ t_ref ] = delay_line(t_rf, trefdelay, ts);

% calculate LO, product of RF and IF frequency
[ t_lo ] = mixer( t_rf, t_if, f_cutoff, ts );

% determine perror from reference delay and lo
[ t_ref_lo ] = mixer( t_ref, t_rf, f_cutoff, ts );
[ cerror ] = find_perror( t_ref_lo, ts, trefdelay, bsweep, perror, real_ierror );

% remove estimated error
[ t_lo_c ] = remove_perror(t_lo, ts, cerror, t_sweep, bsweep);

% display spectrogram of downconverted output
subplot(4,1,1);
spectrogram(t_lo_c,256,250,256,1/ts);
title('sampled signal');

% display one sided spectrum of t_lo up to mixer cutoff
subplot(4,2,3);
nfft = 2^nextpow2(length(t_lo_c));
fft_lo = fft(t_lo_c,nfft);
f_fft_lo = linspace(0,1,nfft/2+1)/(2*ts);
f_lo_lp = f_fft_lo(f_fft_lo < f_cutoff);
f_lo_lp_singlesided =  2*abs(fft_lo(1:length(f_lo_lp)));
plot(f_lo_lp,10*log10(f_lo_lp_singlesided));
grid on;

df = f_cutoff/length(f_lo_lp_singlesided);
fprintf('bandwidth with filtering: %d MHz\n', (evaluate_signal(df,f_lo_lp_singlesided, bwthreshold, smooth)/1e6))

% display one sided spectrum of t_lo without filtering
subplot(4,2,4);
nfft = 2^nextpow2(length(t_lo));
fft_lo = fft(t_lo,nfft);
f_fft_lo = linspace(0,1,nfft/2+1)/(2*ts);
f_lo_lp = f_fft_lo(f_fft_lo < f_cutoff);
f_lo_lp_singlesided =  2*abs(fft_lo(1:length(f_lo_lp)));
plot(f_lo_lp,10*log10(f_lo_lp_singlesided));
grid on;
df = f_cutoff/length(f_lo_lp_singlesided);
fprintf('bandwidth without filtering: %d MHz\n', (evaluate_signal(df,f_lo_lp_singlesided, bwthreshold, smooth)/1e6))

% display spectrogram of transmitted and received chirps
% change to time as x axis
subplot(4,1,3);

spectrogram(t_rf,256,250,256,1/ts);
view(0,90);
title('transmitted chirp');
subplot(4,1,4);
spectrogram(t_if,256,250,256,1/ts);
title('received chirp');