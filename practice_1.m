% знаковое кодирование

str = input('Введите битики: ', 's');
str = strtrim(str);
bits = str - '0'; 

if mod(length(str), 8) ~= 0
    error('Длина битовой строки должна быть кратна 8');
end

% fprintf('Двоичные коды: ');
% for j = 1:length(bits)
%     bin_str = dec2bin(double(bits(j)), 8);  
%     fprintf('%s ', bin_str);
% end
% fprintf('\n');
% 
% fprintf('Битовая последовательность: ');
% for j = 1:length(bits)
%     bin_str = dec2bin(double(bits(j)), 8);
%     fprintf('%s', bin_str);
% end
% fprintf('\n');
% 
% fprintf('Декодированная строка: ');
% for j = 1:length(bits)
%     bin_str = dec2bin(double(bits(j)), 8);
%     dec_val = bin2dec(bin_str);
%     fprintf('%c', char(dec_val));
% end
% fprintf('\n');
% 







num_bytes = length(str) / 8;
decoded_str = '';

fprintf('Декодированная строка: ');

for i = 1:num_bytes
    % Вырезаем 8 бит, соответствующих одному байту
    start_idx = (i - 1) * 8 + 1;
    end_idx = i * 8;
    byte_bits = str(start_idx:end_idx);
    
    % Преобразуем двоичную строку (например, '01001000') в десятичное число (72)
    dec_val = bin2dec(byte_bits);
    
    char_val = char(dec_val);
    
    fprintf('%c', char_val);
   
    decoded_str = [decoded_str, char_val];
end

fprintf('\n');
fprintf('Полная декодированная строка: %s\n', decoded_str);