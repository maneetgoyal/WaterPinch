% Program for Importing and Organizing Data
function [N, Ind] = imnor(FileName,Sheet,SPoints,DPoints,FWConc)
%% Fetching the Data from MS-Excel Worksheet
[~,~,SData] = xlsread(FileName,Sheet,SPoints); % Source Data
[~,~,DData] = xlsread(FileName,Sheet,DPoints); % Demand Data
FWConc = sort(FWConc,'ascend');
%% Setting Levels, Concentration and Purity Columns
r1 = row(DData);
r2 = row(SData);
Conc_Vector_Initial = [FWConc DData{:,4} SData{:,4} 10^6]; % All the Concentrations that are there in the Data Sets
Conc = unique(Conc_Vector_Initial); % The duplicate entries are removed and the modified data is arranged in ascending order.
k = (1:length(Conc))'; % Purity Levels
format long; % This is required because purity calculations lead to same purities for close concentrations upon rounding off.
Pury = PurityFresh(Conc);
%% Allocation of Flowrates
Demand = zeros(length(Conc),1);
for ii = 1:length(Conc) % Allocation of Demands
    for jj = 1:r1
        if Conc(ii) == DData{jj,4}
            Demand(ii) = Demand(ii) + DData{jj,3};
        end
    end
end
Source = zeros(length(Conc),1);
for ii = 1:length(Conc) % Allocation of Sources
    for jj = 1:r2
        if Conc(ii) == SData{jj,4}
            Source(ii) = Source(ii) + SData{jj,3};
        end
    end
end
NetDemand = Source - Demand;
N = [k Conc' Pury' Demand Source NetDemand];
%% Getting Level/Index of Fresh Water Concentrations
Ind = zeros(length(FWConc),1);
for i = 1:length(FWConc)
    for j = 1:length(k)
        if FWConc(i) == Conc(j)
            Ind(i) = j;
            break;
        end
    end
end
end