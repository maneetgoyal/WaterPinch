function [FW_Pure_Source, FW_Dirty_Source, WW_Gen, Pinch] = dualtarget(Demand_Matrix, Source_Matrix, Pure_Source_Conc, Dirty_Source_Conc)
[r1,~] = size(Demand_Matrix);
[r2,~] = size(Source_Matrix);
format long;
Conc_Vector_Initial = [Pure_Source_Conc Dirty_Source_Conc Demand_Matrix{:,4} Source_Matrix{:,4} 10^6];
Conc_Vector_Final = unique(Conc_Vector_Initial);
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
for ii = 11:r1 % Same concentration demands have been added
    for jj = 1:r1
    if Demand_Matrix{ii,4} == Demand_Matrix{jj,4} && ii~=jj
        Demand_Matrix{ii,3} = Demand_Matrix{ii,3} + Demand_Matrix{jj,3};
        Demand_Matrix{jj,3} = NaN;
        Demand_Matrix{jj,4} = NaN;
    end
    end
end
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
for ii = 5:2:WCT_Rows
    CumulativePureWaterSurplus(ii) = CumulativePureWaterSurplus(ii-2) + PureWaterSurplus(ii-1);
end
for ii = 1:WCT_Rows
    if Concentration(ii) == Pure_Source_Conc
        PureIndex = ii;
        OldPure = Source(ii);
    elseif Concentration(ii) == Dirty_Source_Conc
        DirtyIndex = ii;
        OldDirty = Source(ii);
    end
end
IntervalFreshWaterDemand(PureIndex) = CumulativePureWaterSurplus(PureIndex)/(PurityFresh(Pure_Source_Conc)-Purity(PureIndex));
for ii = 2+PureIndex:2:DirtyIndex
    IntervalFreshWaterDemand(ii) = CumulativePureWaterSurplus(ii)/(PurityFresh(Pure_Source_Conc)-Purity(ii));
end
for ii = DirtyIndex+2:2:WCT_Rows
    IntervalFreshWaterDemand(ii) = CumulativePureWaterSurplus(ii)/(PurityFresh(Dirty_Source_Conc)-Purity(ii));
end
FF2 = -1*min(IntervalFreshWaterDemand(DirtyIndex+1:WCT_Rows));
FF1 = -1*min(IntervalFreshWaterDemand(1:DirtyIndex));
Source(DirtyIndex) = Source(DirtyIndex) + FF2 - FF1;
Source(PureIndex) = Source(PureIndex) + FF1;
NetDemand = Source - Demand;
CumulativeNetDemand(2) = NetDemand(1);
for ii = 4:2:WCT_Rows-1
    CumulativeNetDemand(ii) = CumulativeNetDemand(ii-2) + NetDemand(ii-1);
end
PureWaterSurplus = CumulativeNetDemand.*delta_Purity;
CumulativePureWaterSurplus(3) = PureWaterSurplus(2);
for ii = 5:2:WCT_Rows
    CumulativePureWaterSurplus(ii) = CumulativePureWaterSurplus(ii-2) + PureWaterSurplus(ii-1);
end
IntervalFreshWaterDemand(PureIndex) = CumulativePureWaterSurplus(PureIndex)/(PurityFresh(Pure_Source_Conc)-Purity(PureIndex));
for ii = 2+PureIndex:2:DirtyIndex
    IntervalFreshWaterDemand(ii) = CumulativePureWaterSurplus(ii)/(PurityFresh(Pure_Source_Conc)-Purity(ii));
end
for ii = DirtyIndex+2:2:WCT_Rows
    IntervalFreshWaterDemand(ii) = CumulativePureWaterSurplus(ii)/(PurityFresh(Dirty_Source_Conc)-Purity(ii));
end
FF3 = min(IntervalFreshWaterDemand(DirtyIndex+1:WCT_Rows));
Source(DirtyIndex) = Source(DirtyIndex) - FF3;
NetDemand = Source - Demand;
CumulativeNetDemand(2) = NetDemand(1);
for ii = 4:2:WCT_Rows-1
    CumulativeNetDemand(ii) = CumulativeNetDemand(ii-2) + NetDemand(ii-1);
end
PureWaterSurplus = CumulativeNetDemand.*delta_Purity;
CumulativePureWaterSurplus(3) = PureWaterSurplus(2);
for ii = 5:2:WCT_Rows
    CumulativePureWaterSurplus(ii) = CumulativePureWaterSurplus(ii-2) + PureWaterSurplus(ii-1);
end
IntervalFreshWaterDemand(PureIndex) = CumulativePureWaterSurplus(PureIndex)/(PurityFresh(Pure_Source_Conc)-Purity(PureIndex));
for ii = 2+PureIndex:2:DirtyIndex
    IntervalFreshWaterDemand(ii) = CumulativePureWaterSurplus(ii)/(PurityFresh(Pure_Source_Conc)-Purity(ii));
end
for ii = DirtyIndex+2:2:WCT_Rows
    IntervalFreshWaterDemand(ii) = CumulativePureWaterSurplus(ii)/(PurityFresh(Dirty_Source_Conc)-Purity(ii));
end
jj = 1;
Pinch = zeros(sum(IntervalFreshWaterDemand==0),1); % Preallocated a vector whose length is equal to the number of pinch points.
for ii = 1:WCT_Rows
    if IntervalFreshWaterDemand(ii) == 0 || abs(IntervalFreshWaterDemand(ii)) <= 10^-8
      Pinch(jj) = Concentration(ii);
      jj = jj+1;
    end
end
FW_Pure_Source = FF1 - OldPure;
FW_Dirty_Source = Source(DirtyIndex) - OldDirty;
WW_Gen = CumulativeNetDemand(end-1);
end