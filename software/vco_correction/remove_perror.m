function [ t_lo_cleaned ] = remove_perror( t_lo, ts, perror, bsweep)
    fs = 1/ts;
    
    % attempt to remove nonlinearities caused by phase errors 
    % until the transmitted signal
    se_t = exp(1j*2*pi*perror);
    s2 = t_lo.*conj(se_t);
    
    % create an adaptive frequency dependent filter to attempt to remove
    % the range dependant phase error between the lo and rf signals
    [s2f, f2] = twosidedfft(s2,fs,length(s2));
    s3 = ifft(ifftshift((s2f .* (exp(1j*pi*(f2.^2)/bsweep)))));
    [se, fe] = twosidedfft(se_t,fs,length(s2));
    sef = ifft(ifftshift((se .* (exp(1j*pi*(f2.^2)/bsweep)))));
    t_lo_cleaned = s3 .* sef;
end
