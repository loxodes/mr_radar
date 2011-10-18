function [ f_lo ] = mixer( f_rf, f_if, f_cutoff, ts)
    % ideal downconverter mixer
    % filters out higher frequency product using a bessel filter
    % n'th order
    N = 5; 
    [b,a] = besself(N,f_cutoff*2*pi*ts);
    fo = f_rf .* f_if;
    f_lo = filter(b,a,fo);
end

