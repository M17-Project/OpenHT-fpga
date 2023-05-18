%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Hilbert filter                 %
% python & VHDL consts generator %
%                                %
% Wojciech Kaczmarski, SP5WWP    %
% M17 Project                    %
% Jan 2023                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc;

fa=0.02;    %lower freq normalized to f_s/2
fb=0.98;    %upper freq normalized to f_s/2
n=80;      %number of taps

%generate taps with firpm()
b = firpm(n, [fa, fb], [1, 1], 'h')*sqrt(10);   %h for Hilbert
%b = rcosdesign(0.5, n/10, 10);

%alternative way
%d = fdesign.hilbert('N,TW', n, fa*2);
%Hd = design(d, 'equiripple', 'SystemObject', true);
%b=Hd.Numerator;

fvtool(b, 1);
%zerophase(b, 1, 'whole');
%zerophase(Hd, 'whole');

%convert to a python array
fprintf("[");
for i=1:n+1
    if i<n+1
        fprintf("%1.12f, ", b(i));
    else
        fprintf("%1.12f", b(i));
    end
end
fprintf("]\n\n");

%convert to a VHDL array
one=double(0x4000);
fprintf('type fir_taps is array (integer range 0 to TAPS_NUM-1) of std_logic_vector (15 downto 0);\nconstant taps : fir_taps := (\n');
for i=1:4:n+1
    if(i<n)
        fprintf('\tx\"%04X\", x\"%04X\", x\"%04X\", x\"%04X\",\n', typecast(int16(b(i)*one),'uint16'), ...
            typecast(int16(b(i+1)*one),'uint16'), ...
            typecast(int16(b(i+2)*one),'uint16'), ...
            typecast(int16(b(i+3)*one),'uint16'));
    else
        fprintf('\tx\"%04X\"\n', typecast(int16(b(i)*one),'uint16'));%, ...
            %typecast(int16(b(i+1)*one),'uint16'), ...
            %typecast(int16(b(i+2)*one),'uint16'))
    end
end
fprintf(');\n');
