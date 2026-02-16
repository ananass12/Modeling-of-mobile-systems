% помехоустойчивое кодирование (сверточный кодер и декодер Витерби)

str = input('Введите битики: ', 's');
bits = str - '0'; 

p1 = [1 1 1 1 0 0 1]; % 171
p2 = [1 0 1 1 0 1 1]; % 133

reg = zeros(1,6);
coded = [];

for i = 1:length(bits)
    now = [bits(i), reg];  % 7 бит = 1 текущий + 6 предыдущих
    
    x = mod(sum(now .* p1), 2);
    y = mod(sum(now .* p2), 2);
    
    coded = [coded, x, y];

    reg = [bits(i), reg(1:end-1)];
end

fprintf('Выход сверточного кодера: ');
fprintf('%d ', coded);
fprintf('\n');

trellis = poly2trellis(7, [171 133]);  
decoded = vitdec(coded, trellis, length(bits), 'trunc', 'hard');

fprintf('Выход декодера Витерби: ');
fprintf('%d ', decoded);
fprintf('\n');