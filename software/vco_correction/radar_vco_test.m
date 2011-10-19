% mr_radar vco test
f_start = 30e6;         % start frequency (Hz)
f_stop = 35e6;          % stop frequency (Hz)
t_sweep = 1e-3;         % sweep time (s)
type = 'ideal';         % vco type ('ideal', 'gnoise')
ts = 1e-8;              % sample time
tbounce = 20e-5;        % target distance (s)
f_cutoff = 10e6;        % mixer filter cutoff frequency (Hz)

% create time and frequency vectors for VCO
[ t, f_rf ] = vco( f_start, f_stop, t_sweep, type, ts );

% create IF frequency, delayed version of RF
f_if = delay_line(f_rf, tbounce, ts);

% calculate LO, product of RF and IF frequency
[ f_lo ] = mixer( f_rf, f_if, f_cutoff, ts );

% display spectrogram of downconverted output
subplot(3,1,1);
spectrogram(f_lo,256,250,256,1/ts);
title('sampled signal');
subplot(3,1,2);
spectrogram(f_rf,256,250,256,1/ts);
title('transmitted chirp');
subplot(3,1,3);
spectrogram(f_if,256,250,256,1/ts);
title('received chirp');