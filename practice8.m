clear; clc; close all;

%% ГЕНЕРАЦИЯ СООБЩЕНИЯ

%bits = [01001000011001010110110001101100011011110101011101101111011100100110110001100100];
str = 'HelloWorld';
fprintf('Входная строка: %s\n', str);
bits = [];

fprintf('Входные биты:  ');
for j = 1:length(str)
    bin_str = dec2bin(double(str(j)), 8);
    fprintf('%s', bin_str);
    current_bits = bin_str - '0';
    bits = [bits, current_bits];
end
fprintf('\n');

%% СВЕРТОЧНОЕ КОДИРОВАНИЕ

trellis = poly2trellis(7, [171 133]);
coded = convenc(bits, trellis);

%% ПЕРЕМЕЖЕНИЕ

[interleaved, perm] = interleaver(coded);

%% QPSK МОДУЛЯЦИЯ 

c = [];
for i = 1:2:length(interleaved)
    sym = (1/sqrt(2))*((1-2*interleaved(i)) + 1j*(1-2*interleaved(i+1)));
    c = [c sym];
end

%% OFDM МОДУЛЯЦИЯ

RS = 9;
Nqpsk = length(c);
NRS = floor(Nqpsk/RS) + 1;

% пилоты
rs_sc = 1:RS+1:(Nqpsk+NRS);
rs_sc(rs_sc > (Nqpsk+NRS)) = [];
opor_sig = ones(1, length(rs_sc));

% размещение
N = Nqpsk + length(rs_sc);
Mux = zeros(1, N);

data_sc = setdiff(1:N, rs_sc);

Mux(data_sc(1:length(c))) = c;  % данные
Mux(rs_sc) = opor_sig;  % пилоты

C = 1/4;
Nz = round(C*N);

half = floor(N/2);

ofdm_spectrum = [zeros(1,Nz), Mux(1:half), 0, Mux(half+1:end), zeros(1,Nz)];

ofdm_symb = ifft(ofdm_spectrum);

cp_size = floor(length(ofdm_symb)/8);
Stx = [ofdm_symb(end-cp_size+1:end), ofdm_symb];

%% КАНАЛ

Nb = 8;
c_light = 3e8;
B = 7e6;
Ts = 1/B;
f0 = 1.8e9;
N0 = -90;

D = 10 + (500-10)*rand(1, Nb);
min_D = min(D);

tau = zeros(1, Nb);
G = zeros(1, Nb);

for i=1:Nb
    tau(i) = round((D(i)-min_D)/(c_light*Ts));
    G(i) = c_light/(4*pi*D(i)*f0);
end

L = length(Stx);
S = zeros(Nb, L + max(tau));

for i=1:Nb
    for k=1:(L + tau(i))
        if k > tau(i)
            S(i,k) = Stx(k - tau(i));
        end
    end
end

Smpy = sum(S .* G.',1);

% шум
%noise_power = 10^(N0/10) * 1e-3 * B;
%n = sqrt(noise_power/2)*(randn(size(Smpy)) + 1j*randn(size(Smpy)));
%Srx = Smpy + n;

%SNR_linear = 1 / 1e-17;
%SNR_dB = 10*log10(SNR_linear);
%real_SNR = 20; 
%Srx = awgn(Smpy, real_SNR, 'measured');


%N0_dBm = -140; 
%B = 7e6;          
%N0_dBW = N0_dBm - 30; 
%noise_power_dBW = N0_dBW + 10*log10(B);


%target_SNR_dB = 20; 
%sig_power_watts = mean(abs(Smpy).^2);
%sig_power_dBW = 10*log10(sig_power_watts);
%noise_power_dBW = sig_power_dBW - target_SNR_dB;

n = wgn(size(Smpy, 1), size(Smpy, 2), N0, 'complex');

Srx = Smpy + n;

Srx = Srx(1:L);

%% OFDM ДЕМОДУЛЯЦИЯ

rx_no_cp = Srx(cp_size+1:end);

out = fft(rx_no_cp);

informSpectrum = out(Nz+1:end-Nz);
informSpectrum = [informSpectrum(1:half), informSpectrum(half+2:end)];

% пилоты
rs_sc(rs_sc > length(informSpectrum)) = [];
hw = informSpectrum(rs_sc) ./ opor_sig(1:length(rs_sc));

% интерполяция канала
EQ = interp1(rs_sc, hw, 1:length(informSpectrum), 'linear', 'extrap');

% эквализация
informSpectrumEQ = informSpectrum ./ EQ;

% удаляем из списка индексов те, которые выходят за пределы массива
data_sc(data_sc > length(informSpectrumEQ)) = [];
modSymbRx = informSpectrumEQ(data_sc(1:length(c)));

%% QPSK ДЕМОДУЛЯЦИЯ

bits_rx = zeros(1, length(modSymbRx)*2);

for i = 1:length(modSymbRx)
    bits_rx(2*i-1) = real(modSymbRx(i)) < 0;
    bits_rx(2*i)   = imag(modSymbRx(i)) < 0;
end

%% ДЕПЕРЕМЕЖЕНИЕ

bits_deint = deinterleaver(bits_rx, perm);

%% ВИТЕРБИ

bits_deint = bits_deint(:).';
decoded = vitdec(bits_deint, trellis, 34, 'trunc', 'hard');

%% ВЫВОД

fprintf('Выходные биты: ');
for i = 1:length(decoded)
    fprintf('%d', decoded(i));
end

fprintf('\n');

num_bytes = length(decoded) / 8;
decoded_str = '';
fprintf('Декодированная строка: ');

for i = 1:num_bytes
    start_idx = (i - 1) * 8 + 1;
    end_idx = i * 8;
    decoded_b = decoded(start_idx:end_idx);
    
    byte_bits_str = num2str(decoded_b); 
    byte_bits_str(byte_bits_str == ' ') = '';

    % Преобразуем двоичную строку (например, '01001000') в десятичное число (72)
    dec_val = bin2dec(byte_bits_str);
    
    char_val = char(dec_val);
    
    fprintf('%c', char_val);
   
    decoded_str = [decoded_str, char_val];
end

%% BER 

min_len = min(length(bits), length(decoded));
BER = sum(bits(1:min_len) ~= decoded(1:min_len)) / min_len;

fprintf('\nBER = %.4e\n', BER);
fprintf('Errors: %d / %d\n', sum(bits(1:min_len) ~= decoded(1:min_len)), min_len);

%% ФУНКЦИИ

function [interleaved, perm] = interleaver(bits)
    perm = randperm(length(bits));
    interleaved = bits(perm);
end

function deinterleaved = deinterleaver(bits, perm)
    inv_perm(perm) = 1:length(bits);
    deinterleaved = bits(inv_perm);
end

%% ГРАФИКИ

figure;

subplot(5,1,1);
plot(abs(ofdm_spectrum));
title('Spectrum Tx');
grid on;

subplot(5,1,2);
plot(abs(informSpectrum));
title('Spectrum Rx');
grid on;

subplot(5,1,3);
plot(abs(informSpectrumEQ));
title('EQ Spectrum Rx');
grid on;

subplot(5,1,4);
plot(real(c), imag(c), 'o');
title('QAM Symbols Tx');
xlabel('I');
ylabel('Q');
grid on;
axis equal;

subplot(5,1,5);
plot(real(modSymbRx), imag(modSymbRx), 'o');
title('QAM Symbols Rx');
xlabel('I');
ylabel('Q');
grid on;
axis equal;