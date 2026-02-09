function [interleaved, perm] = interleaver(bits, seed)  
    n = length(bits);
    perm = randperm(n);          
    interleaved = bits(perm);    
end

function deinterleaved = deinterleaver(bits, perm)
    n = length(bits);
    inv_perm = zeros(1, n);
    inv_perm(perm) = 1:n;        
    deinterleaved = bits(inv_perm);
end

str = input('Введите битики: ', 's');
bits = str - '0'; 

[interleaved, perm] = interleaver(bits, 42)
fprintf('%d ', interleaved);
fprintf('\n');

deinterleaved = deinterleaver(interleaved, perm);
fprintf('%d ', deinterleaved);
fprintf('\n');