% qpsk модуляция

str = input('Введите битики: ', 's');
bits = str - '0'; 

type = input(['Введите то что вам нужно: ' ...
    ' 1 - QPSK' ...
    '    2 - 16QAM' ...
    '    3 - 64QAM' ...
    '    4 - 256QAM  : '], 's');

type = str2double(type);

fprintf('Комплексные символы: ');
c = [];

switch type
    case 1 % QPSK
        for i = 1:2:length(bits)
            complex = (1/sqrt(2))* * ((1-2*bits(i)) + 1j*(1-2*bits(i+1)));
            fprintf('(%g%+gi) ', real(complex), imag(complex));
            c = [c, complex];
        end
        
    case 2 % 16QAM
        for i = 1:4:length(bits)
            re = (1-2*bits(i)) * (2*bits(i+2) + 1);   
            im = (1-2*bits(i+1)) * (2*bits(i+3) + 1);
            complex = (re + 1j*im) / sqrt(10);
            fprintf('(%g%+gi) ', real(complex), imag(complex));
            c = [c, complex];
        end
        
    case 3 % 64QAM
        for i = 1:6:length(bits)
            re = (1-2*bits(i)) * (4*bits(i+2) + 2*bits(i+4) + 1); 
            im = (1-2*bits(i+1)) * (4*bits(i+3) + 2*bits(i+5) + 1);
            complex = (re + 1j*im) / sqrt(42);
            fprintf('(%g%+gi) ', real(complex), imag(complex));
            c = [c, complex];
        end
        
    case 4 % 256QAM
        for i = 1:8:length(bits)
            re = (1-2*bits(i)) * (8*bits(i+2) + 4*bits(i+4) + 2*bits(i+6) + 1);
            im = (1-2*bits(i+1)) * (8*bits(i+3) + 4*bits(i+5) + 2*bits(i+7) + 1);
            complex = (re + 1j*im) / sqrt(170);
            fprintf('(%g%+gi) ', real(complex), imag(complex));
            c = [c, complex];
        end
end

fprintf('\n');
fprintf('Биты: ');
bits_demod = [];

switch type
    case 1 % QPSK
        for i = 1:length(c)
            r = real(c(i));
            im = imag(c(i));
            bit1 = double(r < 0);
            bit2 = double(im < 0);
            bits_demod = [bits_demod, bit1, bit2];
            fprintf('%d%d ', bit1, bit2);
        end
        
    case 2 % 16QAM
        for i = 1:length(c)
            r = real(c(i)) * sqrt(10);
            im = imag(c(i)) * sqrt(10);
            bit1 = double(r < 0);   % знаковые биты
            bit2 = double(im < 0);
            bit3 = double(abs(r) > 2);   % амплитуда (1 и 3 - граница по 2)
            bit4 = double(abs(im) > 2);
            bits_demod = [bits_demod, bit1, bit2, bit3, bit4];
            fprintf('%d%d%d%d ', bit1, bit2, bit3, bit4);
        end
        
    case 3 % 64QAM
        for i = 1:length(c)
            r = real(c(i)) * sqrt(42);
            im = imag(c(i)) * sqrt(42);
            bit1 = double(r < 0);  % знаки 
            bit2 = double(im < 0); 
            amp_r = round(abs(r));  % амплитуда 1 3 5 7
            amp_im = round(abs(im));  
            bit3 = double(amp_r > 4);      % разделяем значения 1 3 и 5 7
            bit4 = double(amp_im > 4);     
            bit5 = double(mod(amp_r, 4) == 3);  % если 1 или 5 - 0, если 3 или 7 - 1
            bit6 = double(mod(amp_im, 4) == 3); 
            bits_demod = [bits_demod, bit1, bit2, bit3, bit4, bit5, bit6];
            fprintf('%d%d%d%d%d%d ', bit1, bit2, bit3, bit4, bit5, bit6);
        end
        
    case 4 % 256QAM
        for i = 1:length(c)
            r = real(c(i)) * sqrt(170);
            im = imag(c(i)) * sqrt(170);
            bit1 = double(r < 0);  % определяем квадрант
            bit2 = double(im < 0);
            amp_r = round(abs(r));
            amp_im = round(abs(im));
            bit3 = double(amp_r > 8);      % делим на группы относительно 8     
            bit4 = double(amp_im > 8);
            bit5 = double(mod(amp_r, 8) >= 4);  % выделяем значения 5,7 (в нижней группе) и 13,15 (в верхней)
            bit6 = double(mod(amp_im, 8) >= 4);
            bit7 = double(mod(amp_r, 4) >= 2);   %  1 для 3, 7, 11, 15     0 для 1, 5, 9, 13
            bit8 = double(mod(amp_im, 4) >= 2);
            bits_demod = [bits_demod, bit1, bit2, bit3, bit4, bit5, bit6, bit7, bit8];
            fprintf('%d%d%d%d%d%d%d%d ', bit1, bit2, bit3, bit4, bit5, bit6, bit7, bit8);
        end
end

fprintf('\n');

% for i = 1:2:length(bits)
%     sum = bits(i) + bits(i+1);
%     switch sum
%         case 0
%             complex = 0.707+0.707i;
%         case 1
%             if bits(i) == 1
%                 complex = -0.707+0.707i;
%             else
%                 complex = 0.707-0.707i;
%             end
%         case 2
%             complex = -0.707-0.707i;
%     end
%     fprintf('(%g%+gi) ', real(complex), imag(complex));
%     c = [c, complex];
% end

% for i = 1:length(c)
%     switch c(i)
%         case 0.707+0.707i
%             bit = 00;
%         case -0.707+0.707i
%             bit = 10;
%         case 0.707-0.707i
%             bit = 01;
%         case -0.707-0.707i
%             bit = 11;
%     end
%     fprintf('%d', bit);
%     bits_demod = [bits_demod, bit];
% end

