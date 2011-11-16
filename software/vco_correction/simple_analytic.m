clear; clc
set(0,'defaultaxesfontsize',16);
set(0,'defaulttextfontsize',16);

%------------------------------------------------------------------------
% linear signal
T=1e-4;                                 %PRI=100us
B=30e6;                                 %bandwise 30MHz 
alpha=B/T;                                     
fc=80e6;
fs=10*max(fc,B);Ts=1/fs;     
c=3e8;            
d=1000;     
tau=2*d/c;                            %time delay 
N=T/Ts;
t=linspace(0,T,N);
noise = .04;

% Transmitted signal
St0=exp(1j*pi*(fc*t+0.5*alpha*t.^2));
f=linspace(-fs/2,fs/2,N);
subplot(6,1,1);
plot(t*1e4,real(St0)); 
xlabel('Time us'); 
title('Real part of chirp signal'); 
grid on;axis tight;
[St0_fft,f]= TwoSidedFFT( St0,fs,7500 );
subplot(6,1,2);
plot(f,abs(St0_fft));

% Recieved signal
Sr0=exp(1j*pi*(fc*(t-tau)+0.5*alpha*(t-tau).^2));
subplot(6,1,3);
plot(t*1e4,real(Sr0)); 
xlabel('Time us'); 
title('Real part of chirp signal'); 
grid on;axis tight;
[Sr0_fft,f]= TwoSidedFFT( Sr0,fs,7500 );
subplot(6,1,4);
plot(f,abs(Sr0_fft));

% Beat signal
Sb0=St0./Sr0;
subplot(6,1,5);
plot(t*1e4,real(Sb0)); 
xlabel('Time us'); 
title('Real part of beat signal'); 
grid on;axis tight;
[Sb0_fft,f]= TwoSidedFFT(Sb0,fs,7500 );
subplot(6,1,6);
plot(f,abs(Sb0_fft));

% close all figures
close all;

% Generate VCO noise
n = random('norm',0,noise,1,length(t));
cn = cumsum(n);
cn_tau = [zeros(1,round(tau*fs)), cumsum(n)];
cn_tau = cn_tau(1:length(cn));

se_t = exp(1j*2*pi*cn);

% Generate noisy beat signal
sif1 = exp(1j*(2*pi*(fc*tau+alpha*t*tau - .5*alpha*(tau.^2) + cn - cn_tau)));

% remove tx nonlinearitiy
sif2 = sif1 .* conj(se_t);

% plot sif1
[sif1fft,f]= TwoSidedFFT(sif1,fs,7500 );
subplot(2,1,1);
plot(f,abs(sif1fft));
title('spectrum of single stationary target with noisy VCO');
xlabel('frequency');
ylabel('amplitude');

% plot sif2
[sif2fft,f]= TwoSidedFFT(sif2,fs,7500 );
subplot(2,1,2);
plot(f,abs(sif2fft));
title('spectrum of single stationary, corrected for transmitter nonlinearity');
xlabel('frequency (Hz)');
ylabel('amplitude');

% Calculate and plot RVP (sif3)
frvp = (fs/2)*linspace(-1,1,length(t));
% add range dependant phase shift
sif3 = ifft(ifftshift(  fftshift(fft(sif2)) .* exp(1j*pi*(frvp.*frvp)/alpha)  ));
se_rvp = ifft(ifftshift(fftshift(fft(se_t)) .* exp(1j*pi*(frvp.*frvp)/alpha)));
%subplot(4,1,3);
[sif3fft,f]= TwoSidedFFT(sif3,fs,7500 );
%plot(f,abs(sif3fft));

% Calculted and plot corrected signal
sif4 = sif3 .* se_rvp;
[sif4fft,f]= TwoSidedFFT(sif4,fs,7500);
%subplot(4,1,4);
%plot(f,abs(sif4fft));

