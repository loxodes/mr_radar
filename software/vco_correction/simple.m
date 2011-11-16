clear; clc
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
%-------------------------------------------------------------------------




%-------------------------------------------------------------------------
u=real(BSt).*real(Sb0);
f=linspace(0,fs,N);
subplot(2,1,1);
plot(t,u)
subplot(2,1,2);
plot(f,abs(fftshift(fft(u,N))))
xlabel('frequency')

%------------------------------------------------------------------------

%----------------------------------------------------------
% non linear noises 
% nl is short for non linear
t1=linspace(-T/2,-T/4,N/4) ;
nl1=zeros(1,1875);
t2=linspace(-T/4,0,N/4);
nl2=t2*10^4+0.25;
t3=linspace(0,T/4,N/4);
nl3=(-1)*t3*10^4+0.25;
t4=linspace(T/4,T/2,N/4);
nl4=zeros(1,1875);
t=[t1,t2,t3,t4];
nl=[nl1,nl2,nl3,nl4];
subplot(2,1,2)
plot(t,nl);

% non linear with tau
% nlt is short for non linear with tau delay
t1t=linspace(-T/2+tau,-T/4+tau,N/4) ;
nl1t=zeros(1,1875);
t2t=linspace(-T/4+tau,tau,N/4);
nl2t=(t2t-tau)*10^4+0.25;
t3t=linspace(tau,T/4+tau,N/4);
nl3t=(-1)*(t3t-tau)*10^4+0.25;
t4t=linspace(T/4+tau,T/2+tau,N/4);
nl4t=zeros(1,1875);
tt=[t1t,t2t,t3t,t4t];
nlt=[nl1t,nl2t,nl3t,nl4t];
subplot(2,1,2)
plot(t+tau,nlt);
%----------------------------------------------------------------
% Signals with non-linearities
Sif1=Sb0.*exp(nl).*exp(-nlt);
plot(f,abs(fftshift(fft(Sif1,length(f)))));