function [ t_if ] = mixer( t_rf, t_lo, f_cutoff, ts)
% Simulates an ideal downconverting mixer.
% [ t_if ] = mixer(t_rf, t_lo, f_cutoff, ts) simulates a mixer
% mixer returns t_if, the product of t_rf and t_if, with a 5th order butterworth
% filter of order 5 and cutoff frequency f_cutoff.
% The sample time ts is required for the filter.
% mixer is used to simulate the mixing of the received and transmitted signals.

    N = 5; % butterworth filter order
    [b,a] = butter(N,f_cutoff*ts); % create butterworth filter to filter out higher frequency product
    t_if = t_rf ./ t_lo; % calculate product of signals
    t_if(abs(t_if)>5) = 0; % fudge data before first reflection to avoid overflow
    t_if(isnan(abs(t_if))) = 0;
    t_if = filter(b,a,t_if); % pass through a low pass filter to remove higher frequency product
end

