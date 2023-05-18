% Constellation map generator
% 
% Wojciech Kaczmarski SP5WWP
% M17 Project, May 2023
clear;
clc;

one=double(0x4000);
%M=16;

%c = qammod((0:M-1), M)/3/sqrt(2);
%scatterplot(c);

%fprintf('0x%04X, 0x%04X\n', typecast(int16(real(c(1))*one), 'uint16'), typecast(int16(imag(c(1))*one), 'uint16'));

%vals
fprintf('0x%04X\n', typecast(int16(-sqrt(2)/2*one), 'uint16'));
fprintf('0x%04X\n', typecast(int16(-sqrt(2)/2/3*one), 'uint16'));
fprintf('0x%04X\n', typecast(int16(+sqrt(2)/2/3*one), 'uint16'));
fprintf('0x%04X\n', typecast(int16(+sqrt(2)/2*one), 'uint16'));