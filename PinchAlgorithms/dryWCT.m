% This program will target for hybrid operations and even dirty source. 
% The FW_Concentration is the lowest freshwater concentration
% available with us. Works only for Single Source.
function dry = dryWCT(Demand_Matrix,Source_Matrix,FW_Concentration)
[r1,~] = size(Demand_Matrix);
[r2,~] = size(Source_Matrix);
format long;
Conc_Vector_Initial = [FW_Concentration Demand_Matrix{:,4} Source_Matrix{:,4} 10^6];
Conc_Vector_Final = unique(Conc_Vector_Initial);

%% Initializing Different Columns of the Dry WCT
WCT_Rows = 2*length(Conc_Vector_Final) - 1;
Level = nan(WCT_Rows,1);
Concentration = nan(WCT_Rows,1);
Purity = nan(WCT_Rows,1);
delta_Purity = nan(WCT_Rows,1);
Demand = nan(WCT_Rows,1);
Demand(1:2:end-1) = 0;
Source = nan(WCT_Rows,1);
Source(1:2:end-1) = 0;
CumulativeNetDemand = nan(WCT_Rows,1);
CumulativePureWaterSurplus = nan(WCT_Rows,1);
IntervalFreshWaterDemand = nan(WCT_Rows,1);
Purity_FW = (10^6-FW_Concentration)/10^6;

%% Making requisite changes to the WCT
jj = 1;
for ii = 1:2:WCT_Rows % For setting First Three Columns of WCT
    Level(ii) = jj;
    Concentration(ii) = Conc_Vector_Final(jj);
    Purity(ii) = (10^6 - Concentration(ii))/(10^6);
    jj = jj+1;
end
for ii = 2:2:WCT_Rows % For setting delta_Purity
    delta_Purity(ii) = Purity(ii-1) - Purity(ii+1);
end
% for ii = 11:r1 % Same concentration demands have been added
%     for jj = 1:r1
%     if Demand_Matrix{ii,4} == Demand_Matrix{jj,4} && ii~=jj
%         Demand_Matrix{ii,3} = Demand_Matrix{ii,3} + Demand_Matrix{jj,3};
%         Demand_Matrix{jj,3} = NaN;
%         Demand_Matrix{jj,4} = NaN;
%     end
%     end
% end
for ii = 1:2:WCT_Rows % Allocation of Demands
    for jj = 1:r1
        if Concentration(ii) == Demand_Matrix{jj,4}
            Demand(ii) = Demand(ii) + Demand_Matrix{jj,3};
        end
    end
end
for ii = 1:2:WCT_Rows % Allocation of Sources
    for jj = 1:r2
        if Concentration(ii) == Source_Matrix{jj,4}
            Source(ii) = Source(ii) + Source_Matrix{jj,3};
        end
    end
end
NetDemand = Source - Demand;
CumulativeNetDemand(2) = NetDemand(1);
for ii = 4:2:WCT_Rows-1
    CumulativeNetDemand(ii) = CumulativeNetDemand(ii-2) + NetDemand(ii-1);
end
PureWaterSurplus = CumulativeNetDemand.*delta_Purity;
CumulativePureWaterSurplus(3) = PureWaterSurplus(2);
IntervalFreshWaterDemand(3) = CumulativePureWaterSurplus(3)/(Purity_FW-Purity(3));
for ii = 5:2:WCT_Rows
    CumulativePureWaterSurplus(ii) = CumulativePureWaterSurplus(ii-2) + PureWaterSurplus(ii-1);
    IntervalFreshWaterDemand(ii) = CumulativePureWaterSurplus(ii)/(Purity_FW-Purity(ii));
end
dry = [Level Concentration Purity delta_Purity Demand Source NetDemand CumulativeNetDemand PureWaterSurplus CumulativePureWaterSurplus IntervalFreshWaterDemand];
end