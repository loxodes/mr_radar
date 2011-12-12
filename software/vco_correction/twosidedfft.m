function [ x_ds_fft,freq ] = twosidedfft( x,fs,nfft )
    % calculates nfft point sided fft of signal x with sample rate fs
    % retruns fft and frequency vector
    x_ds_fft = fftshift(fft(x,nfft));
    freq = -(fs/2-fs/nfft):fs/nfft:fs/2;
end


