fs = 10e3;
ts = 1/fs;

t_stop = .6;     % seconds
t_start = .2;    % seconds
t_total = 2;     % second

fc = 5000;
t = 0:ts:t_total-ts;

f_maxdev = 1000;  % hertz
theta_maxdev = ((2*pi*f_maxdev) * ts)/(2*pi);
maxdev = f_maxdev * ts;

r_width = (t_stop-t_start)/2;
r = ones(1,floor(r_width/ts));
p = [zeros(1,floor(t_start/ts)),conv(r,r),zeros(1,floor((t_total-t_stop)/ts))];
p = [p, zeros(1,length(t)-length(p))];
p = (p / max(p))*theta_maxdev; % normalize amplitude

e_t = (cumsum(p));

s = exp(1i*2*pi*(fc*t+e_t));
spectrogram(s,256,250,256,1/ts);