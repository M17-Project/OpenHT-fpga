% cordic coeffs table - fixed point
clear;
clc;

bits=16; %for bits=16, 0x4000=+1.0

fprintf("Coeff list:\nN\t\tVAL\t\t\t\tHEX\n");
T=zeros(20, 1);
r=1; i=1;
for i=1:20
    r=r*cos(atan(1/(2^(i-1))));
    T(i)=r;
    fprintf("%d\t\t%.12f\t0x%X\n", i, r, round(r*2^(bits-2)));
end