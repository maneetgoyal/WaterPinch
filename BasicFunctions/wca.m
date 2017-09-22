% Program to carry out WCA
function [delP, F_C, PWSurp, cumPWSurp, IFWD] = wca(N,Ind,FW,FWC)
%% Putting the FW Conc and Indices in descending order.
Ind = sort(Ind,'descend');
[~, I] = sort(FWC,'descend');
FW = FW(I); % Accordingly, the flowrates have to be set in the right order, corresponding to the right concentration.
%% Updating the Sources Values of the FW Concentration Sources
N(Ind,6) = N(Ind,6) + FW;
%% Calculating the remaining columns of the WCT
delP = -1*diff(N(:,3));
F_C = cumsum(N(1:end-1,6));
PWSurp = delP.*F_C;
cumPWSurp = cumsum(PWSurp);
cumPWSurp = [NaN;cumPWSurp];
%% Calculating the Interval Fresh Water Demand
IFWD = nan(row(N),1); % Pre-allocating the Interval Freshwater Demand Column
a = Ind(1);
b = row(N);
if length(Ind) > 1
    for i = 1:length(Ind)-1 % The value of the lower index is changed. For i = length(Ind), a will try to access out-of-bounds/non-existent value of Ind. Hence, it is restricted to length(Ind)-1. 
        for j = a+1:b
            IFWD(j) = cumPWSurp(j)/(N(a,3)-N(j,3));
        end
    b = a; % The value of the lower index is changed. 
    a = Ind(i+1);
    end
    for j = a+1:b % For the last index set. For interval freshwater demand calculation.
        IFWD(j) = cumPWSurp(j)/(N(a,3)-N(j,3));
    end
else % If only one FW Source is there!
    for j = a+1:b
        IFWD(j) = cumPWSurp(j)/(N(a,3)-N(j,3));
    end
end
% IFWD(1) = nan. This is non-existent because the denominator terms contain the difference b/w the same values, i.e., 0. The conceptual reason is...
IFWD = round(IFWD,6); % Rounding off to 6 significant digits because more accuracy may not be required. Moreover, excessively small value can be treated as pinch point itself because...
end