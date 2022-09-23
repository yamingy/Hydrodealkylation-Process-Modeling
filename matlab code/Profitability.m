function [BET,TCI,profit] = Profitability( ...
                reactor,...
                condenser,...
                sepPot,...
                compressor,...
                distillation,...
                pump,...
                furnace,...
                feed,...
                purge,...
                product,...
                outputFlag)   
% calculates profitability for the HDA process
% uses the simplified break-even-time measure

% Status:
% 2019 Oct 4 - NOT YET ADAPTED FOR HDA
% 2019 Nov 12 - full form completed; some details to be added
% 2019 Nov 18 - released

% The input arguments are described in the script testProfitability.m
% Use the template in that file to prepare the input for this function.

% fixed parameters and conversion factors
R = 8.31434; % (Pa m3 mol-1 K-1) universal gas constant
steelDensity = 8000; % (kg m-3);
liqDen = 9300; % (mol m-3) rho 790 kg m-3 at avg MM of 85 g mol-1
s_per_h = 3600;
s_per_month = s_per_h*24*30;
h_per_year = 24*350; % 350 day operating year
J_per_MJ = 1e6;
dol_per_kdol = 1000;
mol_per_kmol = 1000;
g_per_kg = 1000;
W_per_kW = 1000;
W_per_MW = 1e6;
L_per_m3 = 1000; 
Pa_per_bar = 1e5; 

% molar masses
MMH = 2.01588; % (kg kmol-1)
MMM = 16.0428; % (kg kmol-1)
MMB = 78.1136; % (kg kmol-1)
MMT = 92.1405; % (kg kmol-1)

% price and cost data
H2Price = 3; % ($ kg-1) purchase of H2 at source
toluenePrice = 0.8  ; % ($ kg) purchase
benzenePrice = 1.5  ; % ($ kg) sale
fuelGasPrice = 0.15 ; % ($ kg) sale
CWCost = 0.00051; % ($ MJ-1)
fuelCost = 0.0022; % ($ MJ-1)
steamCost = 0.0041; % ($ MJ-1)
elecCost = 0.042; % ($ MJ-1)

% economic numbers
FOCfraction = 0.1; % (y-1)fraction of FCI to estimate fixed Op Costs
onsiteFactor = 3.2; % multiply purchase cost to estimate installed cost
offsiteFactor = 1.89; % multiply purchase cost to estimate installed cost

% print header
if outputFlag > 0
    disp ' '
    disp 'Cost Estimates and Profitability Calculations'
    disp '*******************************************************************'
    % capital cost
    disp 'Capital cost items'
    disp '---------------------------------------------------------------------'
end

% initialize counters
capCostCounter = 0; % (k$) for all equipment
cwCostCounter = 0; % (W) for reactor outlet condenser + distillation Qc
stmCostCounter = 0; % (W) for distillation reboiler
fuelCostCounter = 0; % (W) for reactor preheater
elecCostCounter = 0; % (W) for compressor and pump

% reactor (cost correlation from Towler - cylindrical vessel)
% approximate as a cylindrical can, ignoring curved heads
% input argument 'reactor' contains diameter, length, pressure
diameter = reactor(1); % (m)
length = reactor(2); % (m)
pressure = reactor(3); % (bar)
thickness = VesselThickness(diameter,pressure); % (m)

% compute vessel mass
wallVolume = pi*diameter*length*thickness; % (m3)
headVolume = 2*(pi/4)*diameter^2*thickness; % (m3)
mass = (wallVolume+headVolume)*steelDensity; % (kg)

% compute capital cost
reactorCost = (10200 + 31*mass^0.85)/dol_per_kdol; % (k$)
capCostCounter = capCostCounter + reactorCost; % (k$)

% display
if outputFlag > 0
    disp('reactor:    ')
    disp '    cost(k$)        length(m)      diameter(m)     '
    fprintf('%12.1f %12.1f %12.1f\n',reactorCost,length,diameter)
end

% condenser (cost correlation from Towler - S&T heat exchanger)
% I'm assuming hi-P will be tubeside, so no P effect on shell cost
% input argument 'condenser' contains area, duty
area = condenser(1); % (m2)
duty = condenser(2); % (W)

% compute capital cost
condenserCost = (28000 + 54*area^1.2)/dol_per_kdol; % (k$)
capCostCounter = capCostCounter + condenserCost; % (k$)

% operating cost
cwCostCounter = cwCostCounter + duty; % (W)

% display
if outputFlag > 0
    disp('condenser:    ')
    disp '    cost(k$)        area(m2)        duty(kW) '
    fprintf('%12.1f %12.1f %12.1f\n',condenserCost,area,duty/W_per_kW)
end

% sepPot (cost correlation from Towler - vessel)
% input argument "sepPot" contains V flow, pressure
VFlow = sepPot(1); % (mol s-1)
pressure = sepPot(2); % (bar)

% vapor flow
% assumed to be at 1000 K
Tpot = 1000; % (K)
volFlow = VFlow*R*Tpot/(pressure*Pa_per_bar); % (m3 s-1)

% diameter criterion is velocity
vpot = 1; % (m s-1)
area = volFlow/vpot; % (m2)
diameter = sqrt(4*area/pi); % (m)
height = 2*diameter; % (m) 
thickness = VesselThickness(diameter,pressure); % (m)

% compute vessel mass
wallVolume = pi*diameter*height*thickness; % (m3)
headVolume = 2*(pi/4)*diameter^2*thickness; % (m3)
mass = (wallVolume+headVolume)*steelDensity; % (kg)

% compute capital cost
sepPotCost = (10200 + 31*mass^0.85)/dol_per_kdol; % (k$)
capCostCounter = capCostCounter + sepPotCost; % (k$)

% display
if outputFlag > 0
    disp('separator pot:    ')
    disp '    cost(k$)        height(m)      diameter(m)     '
    fprintf('%12.1f %12.1f %12.1f\n',sepPotCost,height,diameter)
end

% compressor (cost correlation from Towler - cylindrical)
% input argument "compressor" contains work requirement (W)
work = compressor/W_per_kW; % (kW)

% compute capital cost
compressorCost = (580000 + 20000*work^0.6)/dol_per_kdol; % (k$)
capCostCounter = capCostCounter + compressorCost; % (k$)

% operating cost
elecCostCounter = elecCostCounter + compressor; % (W)

% display
if outputFlag > 0
    disp('compressor:    ')
    disp '    cost(k$)         work(kW) '
    fprintf('%12.1f %12.1f\n',compressorCost,work)
end

% distillation (cost correlation from Towler - cylindrical vessel, plus
% trays, a S&T condenser, and a thermosiphon reboiler.)

% input argument "distillation" contains diameter,height,
% nTrays, Qc,Qr, and pressure
diameter = distillation (1); % (m) 
height = distillation (2); % (m) 
nTrays = distillation(3); 
Qc = distillation(4); % (W)
Qr = distillation(5); % (W)
pressure = distillation(6); % (bar)

% compute wall thickness
thickness = VesselThickness(diameter,pressure); % (m)

% compute vessel mass
wallVolume = pi*diameter*height*thickness; % (m3)
headVolume = 2*(pi/4)*diameter^2*thickness; % (m3)
mass = (wallVolume+headVolume)*steelDensity; % (kg)

% compute capital cost (shell + trays)
distillationCost = (10200 + 31*mass^0.85)/dol_per_kdol ...
    + nTrays*(130 + 440*diameter^1.8); % (k$)
capCostCounter = capCostCounter + distillationCost; % (k$)

% display
if outputFlag > 0
    disp('distillation:    ')
    disp '    cost(k$)         height(m)   diameter(m)  N trays'
    fprintf('%12.1f %12.1f %12.1f %12.1f\n',distillationCost,height,diameter,nTrays)
end

% overhead condenser
% assume U = 700 W m-2 K-1 and LMTD = 50 C;
area = Qc/(700*50); % (m2)

% compute capital cost
OHcondenserCost = (28000 + 54*area^1.2)/dol_per_kdol; % (k$)
capCostCounter = capCostCounter + OHcondenserCost; % (k$)

% operating cost
cwCostCounter = cwCostCounter + Qc; % (W)

% display
if outputFlag > 0
    disp('overhead condenser:    ')
    disp '    cost(k$)        area(m2)    duty(kW) '
    fprintf('%12.1f %12.1f %12.1f\n',OHcondenserCost,area,Qc/W_per_kW)
end

% reboiler
% assume U = 600 W m-2 K-1 and LMTD = 30 C;
area = Qr/(600*30); % (m2)

% compute capital cost
reboilerCost = (30400 + 122*area^1.1)/dol_per_kdol; % (k$)
capCostCounter = capCostCounter + reboilerCost; % (k$)

% operating cost
stmCostCounter = stmCostCounter + Qr; % (W)

% display
if outputFlag > 0
    disp('reboiler:    ')
    disp '    cost(k$)        area(m2)    duty(kW) '
    fprintf('%12.1f %12.1f %12.1f\n',reboilerCost,area,Qr/W_per_kW)
end

% pump (cost correlation from Towler - centrifugal)
% input argument "pump" contains work requirement and liquid flow
work = pump(1); % (W)
molFlow = pump(2); % (mol s-1)

% estimate volume flow by assuming organic density at 8000 mol m-3
volFlow = molFlow/liqDen*L_per_m3; % (L s-1)

% compute capital cost
pumpCost = (8000 + 240*volFlow^0.9)/dol_per_kdol; % (k$)
capCostCounter = capCostCounter + pumpCost; % (k$)

% operating cost
elecCostCounter = elecCostCounter + work; % (W)

% display
if outputFlag > 0
    disp('pump:    ')
    disp '    cost(k$)         work(kW) '
    fprintf('%12.1f %12.1f\n',pumpCost,work/W_per_kW)
end

% furnace (cost correlation from Towler - fired heater)
% input argument "furnace" contains heat duty
duty = furnace/W_per_MW; % (MW)

% compute capital cost
furnaceCost = (80000 + 109000*duty^0.8)/dol_per_kdol; % (k$)
capCostCounter = capCostCounter + furnaceCost; % (k$)

% operating cost
fuelCostCounter = fuelCostCounter + furnace; % (W)

% display
if outputFlag > 0
    disp('furnace:    ')
    disp '    cost(k$)         duty(MW) '
    fprintf('%12.1f %12.1f\n',furnaceCost,duty)
end

% fixed-capital investment
fixedCapInvest = capCostCounter*onsiteFactor*offsiteFactor; % (k$)

% display
if outputFlag > 0
    disp ' '
    disp 'Fixed capital investment'
    disp '---------------------------------------------------------------------'
    disp '    total purchase cost of equipment(k$)         '
    fprintf('%12.1f \n',capCostCounter)
    disp '    FCI - all equipment installed(k$)         '
    fprintf('%12.1f \n',fixedCapInvest)
end

% chemical inventory working capital
% presume 1 month supply of H and T
% input argument "feed" contains H and T flows (mol s-1)
Tflow = feed(1);
Hflow = feed(2);
Tinventory = Tflow*s_per_month; % (mol month-1)
Hinventory = Hflow*s_per_month; % (mol month-1)
Tmass = Tinventory*MMT/g_per_kg; % (kg)
Hmass = Hinventory*MMH/g_per_kg; % (kg)
TworkCap = Tmass*toluenePrice/dol_per_kdol; % (k$)
HworkCap = Hmass*H2Price/dol_per_kdol; % (k$)
workingCapital = TworkCap + HworkCap; % (k$)

% display
if outputFlag > 0
    disp ' '
    disp 'Working capital '
    disp '---------------------------------------------------------------------'
    disp 'chemical inventory:    toluene'
    disp '    cost(k$)        mass(kg)    '
    fprintf('%12.1f %12.1f \n',TworkCap,Tmass)
    disp 'chemical inventory:    H2'
    disp '    cost(k$)        mass(kg)    '
    fprintf('%12.1f %12.1f \n',HworkCap,Hmass)
    disp 'Working capital(k$)         '
    fprintf('%12.1f \n',workingCapital)
    disp ' '
    disp 'Total capital investment (k$)'
    disp '---------------------------------------------------------------------'
    TCI = fixedCapInvest + workingCapital; % (k$)
    fprintf('%12.1f \n',TCI)
end

% operating cost
% T purchase
TmassFlow = Tflow*MMT/mol_per_kmol; % (kg s-1)
cost = TmassFlow*toluenePrice/dol_per_kdol; % (k$ s-1)*
Tcost = cost*s_per_h*h_per_year; % (k$ y-1)
if outputFlag > 0
    disp ' '
    disp 'Operating cost items (k$ year-1)'
    disp '---------------------------------------------------------------------'
    fprintf('%12.1f   toluene purchase\n',Tcost)
end

% H2 purchase
HmassFlow = Hflow*MMH/mol_per_kmol; % (kg s-1)
cost = HmassFlow*H2Price/dol_per_kdol; % (k$ s-1)*
Hcost = cost*s_per_h*h_per_year; % (k$ y-1)
if outputFlag > 0
    fprintf('%12.1f   H2 purchase\n',Hcost)
end

% fuel gas credit
% input argumment "purge" contains 4 mole flows in H M B T order (mol s-1)
fuelMassFlow = purge*[MMH MMM MMB MMT]'; % (g s-1) note vector product
cost = fuelMassFlow*fuelGasPrice/g_per_kg/dol_per_kdol; % (k$ s-1)
FGcost = -cost*s_per_h*h_per_year; % (k$ y-1)  notice the - sign: a credit
if outputFlag > 0
    fprintf('%12.1f   fuel gas credit \n',FGcost)
end

% cooling water
cost = cwCostCounter*CWCost/J_per_MJ/dol_per_kdol; % (k$ s-1)
Ccost = cost*s_per_h*h_per_year; % (k$ y-1)  
if outputFlag > 0
    fprintf('%12.1f   cooling water \n',Ccost)
end

% steam
cost = stmCostCounter*steamCost/J_per_MJ/dol_per_kdol; % (k$ s-1)
Scost = cost*s_per_h*h_per_year; % (k$ y-1)  
if outputFlag > 0
    fprintf('%12.1f   steam \n',Scost)
end

% fuel oil
cost = fuelCostCounter*fuelCost/J_per_MJ/dol_per_kdol; % (k$ s-1)
Fcost = cost*s_per_h*h_per_year; % (k$ y-1)  
if outputFlag > 0
    fprintf('%12.1f   fuel oil \n',Fcost)
end

% electricity
cost = elecCostCounter*elecCost/J_per_MJ/dol_per_kdol; % (k$ s-1)
Ecost = cost*s_per_h*h_per_year; % (k$ y-1)  
if outputFlag > 0
    fprintf('%12.1f   electricity \n',Ecost)
end

% fixed operating costs
% calculated as fraction of the fixed-capital investment
FOcost = FOCfraction*fixedCapInvest; % (k$ y-1)
if outputFlag > 0
    fprintf('%12.1f   fixed operating costs \n',FOcost)
end

% sum up the operating cost
operatingCost = Tcost+Hcost+FGcost+Ccost+Fcost+Scost+Ecost;
if outputFlag > 0
    disp 'Total operating costs (k$ y-1)         '
    fprintf('%12.1f \n',operatingCost)
end

% revenue
% product sale
% input argument "product" contains mole flows of B and T (mol s-1)
massB = product(1)*MMB/mol_per_kmol; % (kg s-1)
massT = product(2)*MMT/mol_per_kmol; % (kg s-1)
massProduct = massB + massT; % (kg s-1)
revenue = massProduct*benzenePrice/dol_per_kdol; % (k$ s-1)
revenue = revenue*s_per_h*h_per_year; % (k$ y-1)
if outputFlag > 0
    disp ' '
    disp 'Revenue (k$ y-1)'
    disp '---------------------------------------------------------------------'
    fprintf('%12.1f \n',revenue)
end
% profit calcs
profit = revenue - operatingCost; % (k$ y-1)
if outputFlag > 0
    disp ' '
    disp 'Profitability'
    disp '---------------------------------------------------------------------'
    disp '    profit (k$ y-1)         '
    fprintf('%12.1f \n',profit)
end

% calculate BET
BET = TCI/profit; % (y)
if outputFlag > 0
    disp '    break-even time (y)         '
    fprintf('%12.1f \n',BET)
end

end

function thickness = VesselThickness(diameter,pressure)
% calculates required wall thickness for pressure vessel
% here specific to hot carbon steel

% conversion factors
bar_per_psi = 1e-5/1.45038e-4;
mm_per_m = 1000; 

% data
S = 5900; % (psi) from Towler table - max allowable stress
maStress = S*bar_per_psi; % (bar)

% operating parameters
MAWP = 1.1*pressure; % (bar) max allowable working pressure
weldEfficiency = 1; % all welds radiographed
corrAllow = 2; % (mm) non-corrosive materials, but very hot

% stress formula
t = MAWP*diameter*mm_per_m/(2*maStress*weldEfficiency - 1.2*MAWP); % (mm)

% check thickness against minimum allowed
if diameter < 1
    tReqd = max([t 5]);
elseif diameter < 2
    tReqd = max([t 7]);
elseif diameter < 2.5
    tReqd = max([t 9]);
elseif diameter < 3
    tReqd = max([t 10]);
elseif diameter < 3.5
    tReqd = max([t 12]);
else 
    tReqd = max([t 15]);
end

tSpecified = tReqd + corrAllow;

thickness = tSpecified/mm_per_m; % (m)

end