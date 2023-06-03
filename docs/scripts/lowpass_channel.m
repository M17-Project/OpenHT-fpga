% FIR channel filter
% 
% Wojciech Kaczmarski SP5WWP
% M17 Project, June 2023

clear;
clc;

%----------------------------- 6.25k -----------------------------%
n=80;       %order
fc=6.25/2;  %channel bw
a=0.2;      %bw excess

b0=firpm(n, [0, (fc*(1-a))/25, fc*(1+a)/25, 1], [1, 1, 0, 0], [1, 1]);
b0 = b0 * (1.0/max(b0))/4;

%convert the taps to VHDL array
one=double(0x7FFF);
fprintf('%1.2fk channel filter taps:\n', fc*2);
for i=1:4:n+1
    if(i<n+1)
        fprintf('\t\tx\"%04X\", x\"%04X\", x\"%04X\", x\"%04X\",\n', typecast(int16(b0(i)*one),'uint16'), ...
            typecast(int16(b0(i+1)*one),'uint16'), ...
            typecast(int16(b0(i+2)*one),'uint16'), ...
            typecast(int16(b0(i+3)*one),'uint16'))
    else
        fprintf('\t\tx\"%04X\"\n', typecast(int16(b0(i)*one),'uint16'))
    end
end
fprintf('\n');

%----------------------------- 12.5k -----------------------------%
n=80;       %order
fc=12.5/2;  %channel bw
a=0.1;      %bw excess

b1=firpm(n, [0, (fc*(1-a))/25, fc*(1+a)/25, 1], [1, 1, 0, 0], [1, 1]);
b1 = b1 * (1.0/max(b1))/2;

%convert the taps to VHDL array
one=double(0x7FFF);
fprintf('%1.2fk channel filter taps:\n', fc*2);
for i=1:4:n+1
    if(i<n+1)
        fprintf('\t\tx\"%04X\", x\"%04X\", x\"%04X\", x\"%04X\",\n', typecast(int16(b1(i)*one),'uint16'), ...
            typecast(int16(b1(i+1)*one),'uint16'), ...
            typecast(int16(b1(i+2)*one),'uint16'), ...
            typecast(int16(b1(i+3)*one),'uint16'))
    else
        fprintf('\t\tx\"%04X\"\n', typecast(int16(b1(i)*one),'uint16'))
    end
end
fprintf('\n');

%----------------------------- 25k -----------------------------%
n=80;       %order
fc=25/2;    %channel bw
a=0.05;     %bw excess

b2=firpm(n, [0, (fc*(1-a))/25, fc*(1+a)/25, 1], [1, 1, 0, 0], [1, 1]);
b2 = b2 * (1.0/max(b2));

%convert the taps to VHDL array
one=double(0x7FFF);
fprintf('%1.2fk channel filter taps:\n', fc*2);
for i=1:4:n+1
    if(i<n+1)
        fprintf('\t\tx\"%04X\", x\"%04X\", x\"%04X\", x\"%04X\",\n', typecast(int16(b2(i)*one),'uint16'), ...
            typecast(int16(b2(i+1)*one),'uint16'), ...
            typecast(int16(b2(i+2)*one),'uint16'), ...
            typecast(int16(b2(i+3)*one),'uint16'))
    else
        fprintf('\t\tx\"%04X\"\n', typecast(int16(b2(i)*one),'uint16'))
    end
end

fvtool(b0, [1], b1, [1], b2, [1]);
