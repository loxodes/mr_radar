clc; clear; clf;
%set(0,'defaultaxesfontsize',16);
%set(0,'defaulttextfontsize',16);

% mr_radar vco test
f_start = 4e6; % start frequency (Hz)
f_stop = 8e6; % stop frequency (Hz)
t_sweep = 2e-3; % sweep time (s)
type = 'ramp'; % vco type ('ideal', 'awgnoise')
vco_snr = 3e-3; % vco snr for awgnoise (dB)
ts = 1e-7; % sample time
tbounce = 20e-5; % target distance (s)
f_cutoff = 1e6; % mixer filter cutoff frequency (Hz)
smooth = 4; % frequency bins
bwthreshold = .5; % 3dB bandwidth
trefdelay = 100e-9; % reference delay

bsweep = (f_stop-f_start)/t_sweep;
% create time and frequency vectors for VCO
[ t, t_rf, perror, real_ierror] = vco( f_start, f_stop, t_sweep, type, ts, vco_snr);

% create rx signal, delayed version of rf
[ t_rx ] = delay_line(t_rf, tbounce, ts);

% calculate reference delay
[ t_ref ] = delay_line(t_rf, trefdelay, ts);

% combine refdelay and rx signal to save on hardware
% [ t_rx_ref ] = combiner( t_ref, t_rx );

% calculate if, product of rf and rx signals
[ t_if ] = mixer( t_rf, t_rx, f_cutoff, ts );

% determine perror from reference delay signal
[ t_ref_if ] = mixer( t_ref, t_rf, f_cutoff, ts );

%[ t_if_rx_ref ] = mixer( t_rf, t_rx_ref, f_cutoff, ts );

%[ t_ref_if, t_if ] = split_ref( t_if_rx_ref, trefdelay, ts, bsweep );
[ cerror ] = find_perror( t_ref_if, ts, bsweep );

% remove estimated error
[ t_if_c ] = remove_perror(t_if, ts, cerror, t_sweep, bsweep);

% display spectrogram of downconverted output
subplot(4,1,1);
spectrogram(t_if_c,256,250,256,1/ts);
title('sampled signal');

% display one sided spectrum of t_if up to mixer cutoff
subplot(4,2,3);
nfft = 2^nextpow2(length(t_if_c));
fft_if = fft(t_if_c,nfft);
f_fft_if = linspace(0,1,nfft/2+1)/(2*ts);
f_if_lp = f_fft_if(f_fft_if < f_cutoff);
f_if_lp_singlesided = 2*abs(fft_if(1:length(f_if_lp)));
plot(f_if_lp,10*log10(f_if_lp_singlesided));
grid on;

df = f_cutoff/length(f_if_lp_singlesided);
fprintf('bandwidth with filtering: %d MHz\n', (evaluate_signal(df,f_if_lp_singlesided, bwthreshold, smooth)/1e6))

% display one sided spectrum of t_if without filtering
subplot(4,2,4);
nfft = 2^nextpow2(length(t_if));
fft_if = fft(t_if,nfft);
f_fft_if = linspace(0,1,nfft/2+1)/(2*ts);
f_if_lp = f_fft_if(f_fft_if < f_cutoff);
f_if_lp_singlesided = 2*abs(fft_if(1:length(f_if_lp)));
plot(f_if_lp,10*log10(f_if_lp_singlesided));
grid on;
df = f_cutoff/length(f_if_lp_singlesided);
fprintf('bandwidth without filtering: %d MHz\n', (evaluate_signal(df,f_if_lp_singlesided, bwthreshold, smooth)/1e6))

% display spectrogram of transmitted and received chirps
% change to time as x axis
subplot(4,1,3);

spectrogram(t_rf,256,250,256,1/ts);
view(0,90);
title('transmitted chirp');
subplot(4,1,4);
spectrogram(t_rx,256,250,256,1/ts);
title('received chirp');