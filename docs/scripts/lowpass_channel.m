% FIR channel filter
% 
% Wojciech Kaczmarski SP5WWP
% M17 Project, June 2023

clear;
clc;

n=80;   %order

b=firpm(n, [0, 6.25/25, 7.5/25, 1], [1, 1, 0, 0], [1, 1]);
b = b * (1.0/max(b));
fvtool(b);

%convert the taps to VHDL array
one=double(0x7FFF);
fprintf('\ttype coefficients is array(0 to NUM_TAPS-1) of signed(15 downto 0);\nsignal coeff_s: coefficients := (\n');
for i=1:4:n+1
    if(i<n+1)
        fprintf('\t\tx\"%04X\", x\"%04X\", x\"%04X\", x\"%04X\",\n', typecast(int16(b(i)*one),'uint16'), ...
            typecast(int16(b(i+1)*one),'uint16'), ...
            typecast(int16(b(i+2)*one),'uint16'), ...
            typecast(int16(b(i+3)*one),'uint16'))
    else
        fprintf('\t\tx\"%04X\"\n', typecast(int16(b(i)*one),'uint16'))
    end
end
fprintf('\t);\n');
