function [ x_ds_fft,freq ] = TwoSidedFFT( x,fs,nfft )
% [x_ds_t,freq] = TwoSidedFFT(x,fs) Generates complex two-sided Fourier 
% transform (x_ds_t) of signal x. Plots the magnitude and phase of x_ds_t
% as a function of frequency.
% x = discrete time signal
% fs = sampling frequency
% x_ds_t = complex two-sided Fourier transform
% freq = vector giving the frequency axis (Hz)
% freq vector has the same length as x.
x_ds_fft = fftshift(fft(x,nfft));
freq = -(fs/2-fs/nfft):fs/nfft:fs/2;
magnitude = abs(x_ds_fft); phase = angle(x_ds_fft)*180/pi;

end


