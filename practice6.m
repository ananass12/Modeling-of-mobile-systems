%%  ofdm модуляция
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

RS = 9;  % шаг опорных поднесущих
Nqpsk = n;  % кол-во qpsk символов
NRS = floor(Nqpsk/RS) + 1; % кол-во опорных поднесущих
indexes = zeros(1, NRS); 
current_idx = 1;

opor_sig = ones(1, NRS);

%% расчет индексов опорных поднесущих

for i = 1:RS:(1 + (NRS-1)*RS)
    indexes(current_idx) = i;
    current_idx = current_idx + 1;
end

%% размещение опорного сигнала

signal = zeros(1, Nqpsk + NRS);
j = 1;  % счетчик для опорного сигнала
z = 1;  % счетчик для данных

for i = 1:length(signal)
     if j <= NRS && i == indexes(j)
        signal(i) = opor_sig(j);
        j = j + 1;
    else
        signal(i) = c(z);
        z = z + 1;
     end
end

%% добавление нулевого защитного интервала

C = 1/4;
Nz = C * (NRS + Nqpsk);  % кол-во нулевых поднесущих
zero = zeros(1, Nz);

signal_with_zeros = [zero, signal, zero];


%% обратное ДПФ

signal_fft = ifft(signal_with_zeros);

%% добавление циклического префикса
   
Tcp = floor(length(signal_fft) / 8);        % длина префикса

prefix = signal_fft(end-Tcp+1:end);

Stx = [prefix, signal_fft];

fprintf('\nИтоговый вектор = %d\n', length(Stx));
for i = 1:length(Stx)
    fprintf('(%g%+gi) ', real(Stx(i)), imag(Stx(i)));
end

fprintf('\n');

%% модель канала передачи

Nb = 8;  % количество лучей
L = length(Stx); % длина сигнала с выхода передатчика  
c = 3e8;
B = 7e6; % полоса сигнала
Ts = 1/B; % длительность дискретного отчета модели
f0 = 1.8e9; % несущая частота сигнала
N0 = -140;

D = 10 + (500-10)*rand(1, Nb);
min_D = min(D);

tau = zeros(1, Nb);
G = zeros(1, Nb); 

fprintf('\nЛуч | Расстояние  | Задержка  | Ослабление |\n');

for i=1:Nb
    % задержка прихода луча
    tau(i) = round((D(i) - min_D)/(c*Ts));

    % коэффициент ослабления
    G(i) = c / (4 * pi * D(i) * f0);

    fprintf('\n %2d | %11.2f | %9d | %10.6f | %6.2f\n', i, D(i), tau(i), G(i));
end

fprintf('\n');

% сигналы с задержками и ослаблениями
S = zeros(Nb, L + max(tau));

% добавление задержки
for i = 1:Nb
    for k=1:(L + tau(i))
        if k <= tau(i)
            S(i,k) = 0;
        else 
            S(i,k) = Stx(k - tau(i));
        end
    end
end

S_weak = zeros(Nb, L + max(tau));

for i = 1:Nb
    S_weak(i,:) = S(i,:) * G(i);
end

Smpy = sum(S_weak,1);

M = length(Smpy);
n = wgn(M, 1, N0, 'complex');

Srx = Smpy + n;

Srx = Srx(1:L);

fprintf('\nСигнальный вектор на выходе многолучевого канала: \n');

for i = 1:length(Srx)
    fprintf('(%g%+gi) ', real(Srx(i)), imag(Srx(i)));
end

fprintf('\n');

Tx_power = mean(abs(Stx).^2);
Rx_power = mean(abs(Srx).^2);
   
fprintf('\nМощность сигнала на входе: %.2f дБ\n', 10*log10(Tx_power));
fprintf('Мощность сигнала на выходе: %.2f дБ\n', 10*log10(Rx_power));
fprintf('Потери: %.2f дБ\n', 10*log10(Rx_power/Tx_power)); 