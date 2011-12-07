function [ x_ds_fft,freq ] = twosidedfft( x,fs,nfft )
    x_ds_fft = fftshift(fft(x,nfft));
    freq = -(fs/2-fs/nfft):fs/nfft:fs/2;
    magnitude = abs(x_ds_fft); phase = angle(x_ds_fft)*180/pi;

end


