% RSSI FIR lowpass filter
% 
% Wojciech Kaczmarski SP5WWP
% M17 Project, May 2023
clear;
clc;

n=80;           %order
f1=20/1500/2;   %pass band edge
f2=160/1500/2;  %stop band edge

b=firpm(n, [0, f1, f2, 1], [1, 1, 0, 0]);
b=b/sum(b)*4.0;
%fvtool(b);

%convert the taps to VHDL array
one=double(0x4000);
fprintf('type coefficients is array(0 to NUM_TAPS-1) of signed(15 downto 0);\nsignal coeff_s: coefficients := (\n');
for i=1:4:n+1
    if(i<n+1)
        fprintf('\tx\"%04X\", x\"%04X\", x\"%04X\", x\"%04X\",\n', typecast(int16(b(i)*one),'uint16'), ...
            typecast(int16(b(i+1)*one),'uint16'), ...
            typecast(int16(b(i+2)*one),'uint16'), ...
            typecast(int16(b(i+3)*one),'uint16'))
    else
        fprintf('\tx\"%04X\"\n', typecast(int16(b(i)*one),'uint16'))
    end
end
fprintf(');\n');
