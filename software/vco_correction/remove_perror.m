function [ t_lo_cleaned ] = remove_perror( t_lo, ts, perror, t_sweep, f, tau)
% removes phase error from input vector perror from time domain samples of t_lo
% returns cleaned lo
    % plot(f,fftshift(abs(fft(t_lo))))
    % etau = delay_line(perror, tau, ts);
    se = conj(exp(1j*perror));
    sif2 = t_lo .* se;
 
    % find the frequency vector of the 
    N = length(sif2);
    fs = 1/ts;
    f = (fs/2)*linspace(-1,1,N);
    %f = -(fs/2-fs/N):fs/N:fs/2;
    
    sif3 = ifft(ifftshift(fftshift(fft(sif2)) .* exp(1j*pi*(f.^2)/t_sweep)));
    
    se_rvp = ifft(ifftshift(fftshift(fft(se)) .* exp(1j*pi*(f.^2)/t_sweep)));
    
    sif4 = sif3 .* se_rvp;
    
    t_lo_cleaned = sif4;
end
