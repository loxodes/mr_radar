% mr_radar vco test
f_start = 4e6;
f_stop = 20e6;
t_sweep = 1e-3;
type = 'ideal';
ts = 1e-8;
tbounce = 2e-5;
f_cutoff = 1e6;

[ t, f_rf ] = vco( f_start, f_stop, t_sweep, type, ts );
f_if = delay_line(f_rf, tbounce, ts);
[ f_lo ] = mixer( f_rf, f_if, f_cutoff, ts );
spectrogram(f_lo,256,250,256,1/ts);
