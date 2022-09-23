function [vaporPressure] = VaporPressure(substance,TC)
%calculates the vapor pressure of substances identified by a string label

%  TC (=) C
%  vapor pressure (=) bar

% supply current fit parameters for B and T

switch substance
    case 'B'  %  benzene
        C = [ 4.35896188165890     1443.64176677900     251.386250440021 ];
    case 'T'  % toluene
        C = [ 4.26851097032244     1483.77528135568     235.700734199848 ];
end

vaporPressure = 10^(C(1) - C(2)/(TC + C(3))) ;
end
