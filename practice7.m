%%  генерация битов
clear; clc;

bits = randi([0 1], 50);

fprintf('Комплексные символы: ');
c = [];
n = 0;

for i = 1:2:length(bits)
    complex = (1/sqrt(2))* ((1-2*bits(i)) + 1j*(1-2*bits(i+1)));
    fprintf('(%g%+gi) ', real(complex), imag(complex));
    c = [c, complex];
    n = n + 1;
end

fprintf('\nКол-во символов на выходе модулятора = %d\n', n);


%% пилоты

RS = 9;  % шаг опорных поднесущих
NRS = floor(length(c)/RS) + 1; % кол-во опорных поднесущих
opor_sig = ones(1, NRS); 
current_idx = 1;

rs_sc = 1 : RS + 1 : length(c) + NRS; % пилоты

C = 1/4;
Nz = C * (NRS + length(c));  % кол-во нулевых поднесущих

guard_band = round(Nz);
cp_size = 20;

% полный размер спектра
N = length(c) + NRS;

% индексы данных
data_sc = [];
k = 0;

% data_sc = позиции данных, rs_sc = позиции пилотов
for i = 1:N
    if sum(i == rs_sc) == 0
        k = k + 1;
        data_sc(k) = i;
    end
end

% размещение символов
Mux = zeros(1, N);

rs_sc = 1:RS+1:N;
rs_sc(rs_sc > N) = [];   

Mux(data_sc(1:min(length(data_sc), length(c)))) = c(1:min(length(data_sc), length(c)));
Mux(rs_sc) = opor_sig;

half = floor(length(Mux)/2);

ofdm_spectrum = [zeros(1,Nz), Mux(1:half), 0, Mux(half+1:end), zeros(1,Nz)];

ofdm_symb = ifft(ofdm_spectrum);

% циклический префикс
Stx = [ofdm_symb(end-cp_size+1:end), ofdm_symb];

%% модель канала передачи

Nb = 8;  % количество лучей
L_tx = length(Stx); % длина сигнала с выхода передатчика  
c_light = 3e8;
B = 7e6; % полоса сигнала
Ts = 1/B; % длительность дискретного отчета модели
f0 = 1.8e9; % несущая частота сигнала
N0 = -140;

D = 10 + (500-10)*rand(1, Nb);
min_D = min(D);

tau = zeros(1, Nb);
G = zeros(1, Nb); 

%fprintf('\nЛуч | Расстояние  | Задержка  | Ослабление |\n');

for i=1:Nb
    % задержка прихода луча
    tau(i) = round((D(i) - min_D)/(c_light*Ts));

    % коэффициент ослабления
    G(i) = c_light / (4 * pi * D(i) * f0);

    %fprintf('\n %2d | %11.2f | %9d | %10.6f | %6.2f\n', i, D(i), tau(i), G(i));
end

%fprintf('\n');

% сигналы с задержками и ослаблениями
S = zeros(Nb, L_tx + max(tau));

% добавление задержки
for i = 1:Nb
    for k=1:(L_tx + tau(i))
        if k <= tau(i)
            S(i,k) = 0;
        else 
            S(i,k) = Stx(k - tau(i));
        end
    end
end

S_weak = zeros(Nb, L_tx + max(tau));

for i = 1:Nb
    S_weak(i,:) = S(i,:) * G(i);
end

Smpy = sum(S_weak,1);

% добавление шума
M = length(Smpy);

%n = wgn(M, 1, N0, 'complex');
noise_power_linear = 10^(N0/10) * 1e-3 * B;
n = sqrt(noise_power_linear/2) * (randn(M,1) + 1j*randn(M,1));

Srx_full = Smpy(:).' + n.';
Srx = Srx_full(1:L_tx + max(tau));
Srx = Srx(1:L_tx);

Tx_power = mean(abs(Stx).^2);
Rx_power = mean(abs(Srx).^2);
fprintf('Tx Power: %.2f dB\n', 10*log10(Tx_power));
fprintf('Rx Power: %.2f dB\n', 10*log10(Rx_power));
fprintf('Channel Loss: %.2f dB\n', 10*log10(Rx_power/Tx_power));

fprintf('\nСигнальный вектор на выходе многолучевого канала: \n');

for i = 1:length(Srx)
    fprintf('(%g%+gi) ', real(Srx(i)), imag(Srx(i)));
end

fprintf('\n');
   
%% демодуляция

% удаление префикса
rx_no_cp = Srx(cp_size+1:end);

out = fft(rx_no_cp);

% Удаление guard band
informSpectrum = out(guard_band+1:end-guard_band);
informSpectrum = [informSpectrum(1:half), informSpectrum(half+2:end)];

rs_rx = informSpectrum(rs_sc);

% Оценка канала
hw = rs_rx ./ opor_sig;

% Интерполяция канала
EQ = interp1(rs_sc, hw, 1:length(informSpectrum), 'linear', 'extrap');

% Эквализация
informSpectrumEQ = informSpectrum ./ EQ;

% Извлечение данных
modSymbRx = informSpectrumEQ(data_sc(1:length(c)));

% Демодуляция QPSK
bits_rx = zeros(1, length(modSymbRx)*2);

for i = 1:length(modSymbRx)
    bits_rx(2*i-1) = real(modSymbRx(i)) < 0;
    bits_rx(2*i)   = imag(modSymbRx(i)) < 0;
end

%%

fprintf('\nИсходные биты: ');
for i = 1:length(bits)
    fprintf('%d', bits(i));
end
fprintf('\n');

fprintf('Принятые биты: ');
for i = 1:length(bits_rx)
    fprintf('%d', bits_rx(i));
end
fprintf('\n');

min_len = min(length(bits), length(bits_rx));
num_errors = sum(bits(1:min_len) ~= bits_rx(1:min_len));
BER = num_errors / min_len;

fprintf('\nBER = %.4e\n', BER);
fprintf('Errors: %d / %d\n', num_errors, min_len);