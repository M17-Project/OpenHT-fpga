clear;
clc;

N = 404;  %order
B = 16;   %bits

%first and second stage, L=5
L = 5;    %number of bands

h = fdesign.nyquist(L, 'n', N);
b = design(h, 'window');

bq = L * b.numerator * (2^(B-1));
rbq = round(bq);
%max(bq)
bq = rbq / (2^(B-1));

%fvtool(L*b.numerator, [1], bq, [1]);

fprintf("Taps for %d band Nyquist filter:\n", L);
fprintf("\t");
for i=1:length(rbq)
    fprintf('x"%04X", ', typecast(int16(rbq(i)), 'uint16')) %saturation is embedded into int16() function
    if mod(i, 5)==0
        fprintf('\n\t');
    end
end
fprintf('\n');

%last stage, L=2
L = 2;    %number of bands

h = fdesign.nyquist(L, 'n', N);
b = design(h, 'window');

bq = L * b.numerator * (2^(B-1));
rbq = round(bq);
%max(bq)
bq = rbq / (2^(B-1));

%fvtool(L*b.numerator, [1], bq, [1]);

fprintf("Taps for %d band Nyquist filter:\n", L);
fprintf("\t");
for i=1:length(rbq)
    fprintf('x"%04X", ', typecast(int16(rbq(i)), 'uint16')) %saturation is embedded into int16() function
    if mod(i, 5)==0
        fprintf('\n\t');
    end
end
fprintf('\n');

