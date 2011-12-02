function [ t_lo ] = mixer( f_rf, f_if, f_cutoff, ts)
% Simulates an ideal downconverting mixer.
% [ f_lo ] = mixer(f_rf, f_if, f_cutoff, ts) simulates a mixer
% mixer returns f_lo, the product of f_rf and f_if, with a 5th order butterworth
% filter of order 5 and cutoff frequency f_cutoff.
% The sample time ts is required for the filter.
% mixer is used to simulate the mixing of the received and transmitted signals.
    N = 5;                                      % butterworth filter order
    [b,a] = butter(N,f_cutoff*ts*2);            % create butterworth filter to filter out higher frequency product
    t_lo = f_rf ./ f_if;                        % calculate product of signals
    t_lo(abs(t_lo)>5) = 0;                      % fudge data before first reflection to avoid overflow
    t_lo(isnan(abs(t_lo))) = 0;
    t_lo = filter(b,a,t_lo);                    % pass through a low pass filter
end

