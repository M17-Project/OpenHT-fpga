% FIR halfband filter
% 
% Wojciech Kaczmarski SP5WWP
% M17 Project, June 2023

clear;
clc;

n     = 80;     %order
Astop = 40;     %stopband attenuation (dB)
Fs    = 400e3;  %sampling frequency

h = fdesign.halfband('Type', 'Lowpass', 'n,ast', n, Astop, Fs);
b = design(h, 'equiripple');

b.numerator = b.numerator * (1.0/max(b.numerator));

fvtool(b);

%convert the taps to VHDL array
one=double(0x7FFF);
fprintf('constant coeff_s: coefficients := (\n');
for i=1:4:n+1
    if(i<n+1)
        fprintf('\tx\"%04X\", x\"%04X\", x\"%04X\", x\"%04X\",\n', typecast(int16(b.numerator(i)*one),'uint16'), ...
            typecast(int16(b.numerator(i+1)*one),'uint16'), ...
            typecast(int16(b.numerator(i+2)*one),'uint16'), ...
            typecast(int16(b.numerator(i+3)*one),'uint16'))
    else
        fprintf('\tx\"%04X\"\n', typecast(int16(b.numerator(i)*one),'uint16'))
    end
end
fprintf(');\n');