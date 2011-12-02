function [ t_lo_cleaned ] = remove_perror( t_lo, ts, perror, t_sweep, tau, bsweep)
    fs = 1/ts;

    se_t = exp(1j*2*pi*perror);
    s2 = t_lo.*conj(se_t);
    
    [s2f, f2] = twosidedfft(s2,fs,length(s2));
    s3 = ifft(ifftshift((s2f .* (exp(1j*pi*(f2.^2)/bsweep)))));
    
    [se, fe] = twosidedfft(se_t,fs,length(s2));
    sef = ifft(ifftshift((se .* (exp(1j*pi*(f2.^2)/bsweep)))));

    t_lo_cleaned = s3 .* sef;
end
