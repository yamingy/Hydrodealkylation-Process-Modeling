%take in stream 9 which is all vapor and calculate work to compress it to the pressure
%specified, assuming adiabatic operation, and no PE or KE
function[stream10, W]= Compressor(stream9, Pout)
%stream 9 is all vapor
[nH, nM, nB, nT, Tin, Pin, Hin, nH1, nM1, nB1, nT1]=dealR(stream9);
n=1.25;
R=8.314; %J mol^-1 K^-1;
%calculates work using polytropic compression to raise pressure to Pout
W=((n*R*(Tin+273))/(n-1)*((Pout/Pin)^((n-1)/n)-1))*(nH+nM+nB+nT);%work/molarflow*molarflows
Hout= Hin+W; %Energy Balance assuming their is no Q, PE, KE
h= @(T) HMixFlow([nH, nM, nB, nT],T,Pout) - Hout;
Tout= fzero(h, Tin);
stream10= [nH, nM,nB, nT, Tout, Pout, Hout, nH1, nM1, nB1, nT1];
end
