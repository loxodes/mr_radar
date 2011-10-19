function [ f_lo ] = mixer( f_rf, f_if, f_cutoff, ts)
    % ideal downconverter mixer
    % filters out higher frequency product using a butterworth filter
    N = 5;                                      % butterworth filter order
    [b,a] = butter(N,f_cutoff*ts*2);            % create bessel filter to filter out higher frequency product
    fo = f_rf .* f_if;                          % calculate product of signals
    f_lo = filter(b,a,fo);                      % pass through a low pass filter
end

