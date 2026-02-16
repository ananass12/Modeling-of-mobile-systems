% знаковое кодирование

str = input('Введите битики: ', 's');
str = strtrim(str);
bits = str - '0'; 

fprintf('Двоичные коды: ');
for j = 1:length(bits)
    bin_str = dec2bin(double(bits(j)), 8);  
    fprintf('%s ', bin_str);
end
fprintf('\n');

fprintf('Битовая последовательность: ');
for j = 1:length(bits)
    bin_str = dec2bin(double(bits(j)), 8);
    fprintf('%s', bin_str);
end
fprintf('\n');

fprintf('Декодированная строка: ');
for j = 1:length(bits)
    bin_str = dec2bin(double(bits(j)), 8);
    dec_val = bin2dec(bin_str);
    fprintf('%c', char(dec_val));
end
fprintf('\n');