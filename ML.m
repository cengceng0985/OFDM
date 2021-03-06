clear all;
N_symbol=4; 
N =1024; %the number of carrier 
%N = 256; %the number of carrier 
%T=10^(-6); % Sampling time : 1us 
L=128; % the number of cp
SNR=40; % SNR of signal   
rx_pre2 = zeros(1,N+L); %buffer for symber i-1 
rx_pre1 = zeros(1,N+L); %buffer for symbol i 
rx = zeros(1,N+L); %buffer for symbol i+1 
ro = SNR/(SNR+1);  
delay=floor(rand*N); %generate delay 
cnt = 0; 
while cnt <= N_symbol+1 
    % Generate Signal 
   % input_stream = (sign(randn(1,N*2))+1)/2;
    input_stream = sign(randn(1,N*2));
    
    for k=1:N     
        ich1(:,k)=input_stream(:,2*k-1);     
        qch1(:,k)=input_stream(:,2*k); 
    end
    kmod=1./sqrt(2); % modulation to QPSK 
    ich=ich1.*kmod; 
    qch=qch1.*kmod;  
    qpsk_str = ich+qch.*sqrt(-1);
    %QPSK(input_stream); % QPSK stream : 1024 
    % inverse fft : from frequency domain to time domain
    xn=ifft(qpsk_str,N); 
    % add_prefix 
    len_xn = length(xn); % for checking : len_xn=N 
    sn=[xn(len_xn-L+1:len_xn) xn];%加循环前缀
    rx_pre2=rx_pre1; 
    rx_pre1=rx;
    %############################ AWGN Channel ############################# 
    e=0.25; 
    for k=1:length(sn)
        rx(k)=sn(k)*exp(j*2*pi*e*(k-1)/N); %相位偏移
    end
    %rx= rx+add_noise(sn,SNR);
    % add noise %rx(delay:length(rx))=rx; 
    %rx(1:delay-1)=0; 
    obs_rx=[rx_pre2(N+L-delay+1:N+L) rx_pre1 rx(1:N-delay)]; % observe 2N+L 
    obs_rx=obs_rx+awgn(obs_rx,SNR); % add noise 
    %################## Calculate gamma(m) & PI(m) ################### 
    if cnt > 1 
        i=cnt-1; 
        gamma =zeros(1,N); 
        pii =zeros(1,N); 
        for m=1:N %sampling interval
            
            for k=m:m+L-1 
                gamma(m)= gamma(m)+obs_rx(k)*conj(obs_rx(k+N)); 
                pii(m)=pii(m)+0.5*( abs(obs_rx(k))^2 + abs(obs_rx(k+N))^2 ); 
            end
            %equation 2-(5) 
            %lamda(i,theta)=abs(gamma(theta))*cos( 2*pi*e+angle(gamma(theta)) ) - ro*pii(theta);
            lamda(i,m)=abs(gamma(m))- ro*pii(m);
            gamma1(i,m)=-angle(gamma(m))/(2*pi); 
        end %end loop_theta 
    end %end if 
    cnt= cnt+1; % increase counter 
end % end while % S/P for lamda 
lamda_str=[]; 
gamma1_str=[]; 
for i=1:N_symbol 
    lamda_str=[ lamda_str lamda(i,:)]; 
    gamma1_str=[ gamma1_str gamma1(i,:)]; 
end % for display
clf; 
figure(1); 
plot(lamda_str) 
%plot(abs(xn)*100)  
grid on;
figure(2); 
plot(gamma1_str) 
grid on; 
error=gamma1_str(find(lamda_str==max(lamda_str)))-e;