%takes in a stream and seperates it into its liquid and vapor components
%and recalculates the new streams' enthalpies and the necessary temperature to 
%achieve pressure output
function [stream7, stream11]= SeparatorPot(stream6, Pout)
[nH, nM, nB, nT, T, P, H, nH1, nM1, nB1, nT1]=dealR(stream6);
h=@(T) HMixFlow([nH, nM, nB, nT], T, Pout) - H;
Tout=fzero(h,T);
[Hout, vapFlow, liqFlow] = HMixFlow(stream6,Tout,Pout);
stream7=([vapFlow(1), vapFlow(2), vapFlow(3), vapFlow(4), Tout, Pout, Hout, 0,0,0,0]);
stream7(7) = HMixFlow(stream7(1:4), Tout, Pout);
stream11=([0,0,liqFlow(3), liqFlow(4), Tout, Pout, Hout, 0,0,liqFlow(3), liqFlow(4)]);
stream11(7) = HMixFlow(stream11(1:4), Tout, Pout);
end