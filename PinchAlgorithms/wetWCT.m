% If the Source(s) has been modified, then this function will update the
% entire WCT accordingly. It puts in the freshwater allocation in 'dry' WCT
% also. If a source exists whose concentration is more than that of the
% demand concentration(s), then only those demands whose concentration constraints
% are not violated, will be satisfied.

%% Program to Generate Targets, Pinch Concentrations. It will also give the Wet WCT in which all the demand deficits have been covered by the target/minimum FW Supply.
function [info, wet] = wetWCT(dry,FW_Concentration)
%% Checking whether the deficit exists.
[WCT_Rows,~] = size(dry);
for ii = 1:WCT_Rows % This loop will turn all Infinite values to NaN. We are doing it so that the infinite values do not interfere with our targeting process.
    if abs(dry(ii,11)) == inf
        dry(ii,11) = nan;
    end
end
if min(dry(:,11)) < 0 % This loop tell us whether any deficit is there or not. Accordingly, we can decide whether we want to accept the results or not.
    fprintf('Deficit Exists.\n');
    for ii = 1:WCT_Rows
        if dry(ii,2) == FW_Concentration
            dry(ii,6) = dry(ii,6) + (-1*min(dry(:,11)));
            break;
        end
    end
else
    fprintf('No Deficit in Interval FW Demand Vector.\n');
end
%% Reducing very very small figures to zero.
M = min((dry(:,11))); % This M value is the Freshwater Demand.
if abs(M) < 10^-8
    M = 0;
end
%% Prepping the Wet WCT
wet(:,1:6) = dry(:,1:6); % We have just copied Levels, Concentration, Purity, delta_Purity, Demand and updated Source from the Dry WCT.
wet(:,7) = dry(:,6) - dry(:,5); % Specified the Net Demand.
Purity_FW = PurityFresh(FW_Concentration); % PurityFresh gives the Purity for Freshwater Source Concentration.
CumulativeNetDemand = nan(WCT_Rows,1);
CumulativePureWaterSurplus = nan(WCT_Rows,1);
IntervalFreshWaterDemand = nan(WCT_Rows,1);
CumulativeNetDemand(2) = wet(1,7);
for ii = 4:2:WCT_Rows-1
    CumulativeNetDemand(ii) = CumulativeNetDemand(ii-2) + wet(ii-1,7);
end
PureWaterSurplus = CumulativeNetDemand.*wet(:,4);
CumulativePureWaterSurplus(3) = PureWaterSurplus(2);
IntervalFreshWaterDemand(3) = CumulativePureWaterSurplus(3)/(Purity_FW-wet(3,3));
for ii = 5:2:WCT_Rows
    CumulativePureWaterSurplus(ii) = CumulativePureWaterSurplus(ii-2) + PureWaterSurplus(ii-1);
    IntervalFreshWaterDemand(ii) = CumulativePureWaterSurplus(ii)/(Purity_FW-wet(ii,3));
end
wet(:,8:11) = [CumulativeNetDemand PureWaterSurplus CumulativePureWaterSurplus IntervalFreshWaterDemand];

for ii = 1:WCT_Rows % This loop eradicates very very small values and turns infinite values to NaN.
    if abs(wet(ii,11)) < 10^-8
        wet(ii,11) = 0;
    elseif abs(wet(ii,11)) == inf
        wet(ii,11) = NaN;
    end
end

jj = 1;
Pinch = zeros(sum(wet(:,11)==0),1); % Preallocated a vector whose length is equal to the number of pinch points.
for ii = 1:WCT_Rows
    if wet(ii,11) == 0
      Pinch(jj) = wet(ii,2);
      jj = jj+1;
    end
end

%% Prepping the Info Cell Matrix
info = cell(2,4); 
info{1,1} = 'Minimum FW';
info{2,1} = abs(M);
info{1,2} = 'WW Generated';
info{2,2} = CumulativeNetDemand(end-1);
info{1,3} = 'No. of Pinch Point(s)';
info{2,3} = sum(wet(:,11)==0);
info{1,4} = 'Pinch Point(s)';
info{2,4} = Pinch;
end