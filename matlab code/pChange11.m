%takes in a stream and changes its pressure, which can lead to
%enthalpy changes and phase changes so they are also recalculated
function [stream12]= pChange(stream11, Pout)
[nH, nM, nB, nT, T, P, H, nH1, nM1, nB1, nT1]=dealR(stream11);
h=@(T) HMixFlow([nH, nM, nB, nT], T, Pout) - H;
Tout=fzero(h,T);
[Hout, vapFlow, liqFlow] = HMixFlow(stream11(1:4),Tout,Pout);
stream12=([vapFlow(1), vapFlow(2), vapFlow(3)+liqFlow(3), vapFlow(4)+liqFlow(4), Tout, Pout, Hout, 0,0,liqFlow(3), liqFlow(4)]);
end