%% Program to generate a Water Network for Single Contaminant Based Hybrid Systems
% Limitations: Will work only for Single Source. Only for Single Pinch
% Point.
% Assumptions: Source and Demand Data are stored in the same Excel File in
% the same Sheet

function N = nnaup(FileName,Sheet,SPoints,DPoints,FWConc)
%% Fetching the Data from MS-Excel Worksheet
[NumS,TxtS,SData] = xlsread(FileName,Sheet,SPoints); % Source Data
[NumD,TxtD,DData] = xlsread(FileName,Sheet,DPoints); % Demand Data
%% Sorting Data in ascending order of Concentration
SData = mysort(NumS,TxtS,SData);
DData = mysort(NumD,TxtD,DData);
%% Getting the FW and WW Targets and Pinch Point(s)
[PinchP,F_Matrix, WW] = intprt_v2(FileName,Sheet,SPoints,DPoints,FWConc,Inf);
FW = F_Matrix(2); 
if numel(PinchP) > 1
    error('Multiple Pinch Points exist for this process network.\n');
end
%% Initializing the First Two Rows and Columns of the Network Matrix
Source_Size = row(SData) + 1;
flag = 'y'; % If flag is equal to y, then FW conc sources are not present in the initial data.
for ii = 1:row(SData)
    if FWConc == SData{ii,4};
        Source_Size = row(SData);
        flag = 'n'; % If flag is equal to n, then there exists a source which has a conc. equal to that of fresh water.
        break;
    end
end
Demand_Size = row(DData) + 1; % +1 for WW Stream
SCon = zeros(Source_Size,1); % Initializing the First Column of Network Matrix. Contains Source Concentrations.
SFlow = zeros(Source_Size,1); % Initializing the Second Column of Network Matrix. Contains Source Flowrates.
DCon = zeros(Demand_Size,1); % Initializing First Row of Network Matrix. Contains Demand Concentrations.
DFlow = zeros(Demand_Size,1); % Initializing Second Row of Network Matrix. Contains Demand Flowrates.

%% Setting the Source Parents in the Network Matrix
if flag == 'y' % If flag is equal to y, then FW conc sources are not present in the initial data.
    SCon(1) = FWConc;
    SFlow(1) = FW;
    for ii = 2:Source_Size
        SCon(ii) = SData{ii-1,4};
        SFlow(ii) = SData{ii-1,3};
    end
elseif flag == 'n' % If flag is equal to n, then there exists a source which has a conc. equal to that of fresh water.
    SCon(1) = FWConc;
    SFlow(1) = SData{1,4} + FW;
    for ii = 2:Source_Size
        SCon(ii) = SData{ii,4};
        SFlow(ii) = SData{ii,3};
    end
end
%% Setting the Demand Parents in the Network Matrix
for ii = 1:Demand_Size-1
DCon(ii) = DData{ii,4};
DFlow(ii) = DData{ii,3};
end
DFlow(end) = WW;

%% Initializing the Network Matrix
N = zeros(length(SCon)+2,length(DCon)+2);
N(1:2,1:2) = nan;
N(3:end,1:2) = [SCon SFlow];
N(1:2,3:end) = [DCon'; DFlow'];
%% Graying Out the Cross Pinch Regions
PinchConcCount = sum(SCon == PinchP);
for ii = 1:length(SCon) % For Finding the Row Index
    if SCon(ii) == PinchP
        DIR = (ii+2); % Desired Index (Row)
    end
end
DIC = []; % Initializing Desired Index (Column). Sometimes, there may be no demand concentration which is higher than the source pinch concnetration and as a result DIC will remain an empty matrix.
for ii = 1:length(DCon) % For Finding the Column Index
    if DCon(ii) > PinchP
        DIC = (ii+2); % Desired Index (Column)
        break; % Because we want the nearest higher concentration.
    end
end
if ~isempty(DIC) % Setting Gray Area.
    N(DIR+1:end,3:DIC-1) = nan;
    N(3:DIR-1-(PinchConcCount-1),DIC:end-1) = nan;
elseif DIR == length(SCon)+2
    fprintf('No Gray Area.\n');
else
    N(DIR+1:end,3:end-1) = nan;
end
N(2,end) = WW; % Introduced WW Flow rate in the Network Matrix
N(3:DIR-1-(PinchConcCount-1),end) = nan; % Sources whose concentrations are 'less' than pinch concentration will not be discarded as wastewater.
Grayed = N;
%% Making the Network using NNA (Shenoy,2012): Below Pinch
[rN,cN] = size(N);
SourcePool1 = N(3:DIR,1);
if isempty(DIC)
    DIC = cN-1;
end
% Source-Sink Mapping in Below the Pinch Region.
for ii = 3:DIC-1 % Demands
    FCEqualBefore = 0;
    for jj = 3:DIR % Sources
        if N(1,ii) == N(jj,1) % If conc. of demand = conc. of source
            if N(2,ii) >= N(jj,2) && N(2,ii) > 0 % Demand >= Source
                N(jj,ii) = N(jj,2); % Allocating
                N(2,ii) = N(2,ii) - N(jj,2); % Updating demand
                FCEqualBefore = FCEqualBefore + N(1,ii)*N(jj,2); % This is added for the conditions wherein equal concentration source doesn't satisfy the demand. So whatever amount of equal-concentration-source is available, it is fed to the demand amd the equivalent contaminant load is also recorded to be later fed in to the fsolve function.
                N(jj,2) = 0; % Updating Source
                SourcePool1 = concUpdate(SourcePool1,N(1,ii));
                N(jj,1) = NaN;
            elseif N(2,ii) < N(jj,2) && N(2,ii) > 0 % Demand < Source
                N(jj,ii) = N(2,ii); % Allocating
                N(jj,2) = N(jj,2) - N(2,ii); % Updating Source
                FCEqualBefore = FCEqualBefore + N(1,ii)*N(2,ii); % This is added for the conditions wherein equal concentration source is more than the demand. So whatever amount of equal-concentration-source is required, it is fed to the demand amd the equivalent contaminant load is also recorded to be later fed in to the fsolve function.
                N(2,ii) = 0; % Updating Demand
            end
        end
    end
        FlCl_Before = 0; FhCh_Before = 0; % Initial Values of some inputs to ShenFun
        while N(2,ii) > 0 % While the demand is not met.
            [Cl, Ch] = Shenoy(SourcePool1,N(1,ii));
            for mm = 3:DIR % mm is just a loop index
                if N(mm,1) == Cl
                    Fl = round(N(mm,2),4); % Available Flowrate of Lower Concentration
                    ss = mm; % Storing this index for its use in correcting the Lower Conc. Source Availability after allocation.
                elseif N(mm,1) == Ch
                    Fh = round(N(mm,2),4); % Available Flowrate of Higher Concentration
                    qq = mm; % Storing this index for its use in correcting the Higher Conc. Source Availability after allocation.
                    break; % Added because the required info on Conc and Flowrate has already been taken.
                end
            end
            y = round((fsolve(@(x) ShenFun(x,Cl,Ch,N(2,ii),Grayed(2,ii),N(1,ii),FlCl_Before,FhCh_Before,FCEqualBefore),[Fl;Fh])),4); % Finding the demands of Cl and Ch
            if y(1) < Fl && y(2) < Fh % Both the demands are lower than availabilities. So the demand will be completely met.
                N(2,ii) = 0; % Demand has been reduced to zero since it is completely met.
                N(ss,2) = N(ss,2) - y(1); % Availability of Cl is now reduced since some of it is allocated to the demand.
                N(qq,2) = N(qq,2) - y(2); % Availability of Cl is now reduced since some of it is allocated to the demand.
                N(ss,ii) = y(1); % Allocation of Cl in the Network Matrix.
                N(qq,ii) = y(2); % Allocation of Ch in the Network Matrix.
            elseif y(1) > Fl && y(2) <= Fh % Only Ch availability is more than the demand. So whatever Cl is available will be used completely.
                N(2,ii) = N(2,ii) - Fl; % The demand is updated.
                N(ss,2) = 0; % Availability of Cl is now reduced to 0 since all of it is allocated to the demand.
                N(ss,ii) = Fl; % Allocation of Cl in the Network Matrix.
                FlCl_Before = FlCl_Before + Fl*Cl; % Updating the contaminant load.
                SourcePool1 = concUpdate(SourcePool1,Cl); % Updating the number of available sources.
                N(:,1) = searcon(Cl,N(:,1)); % Replacing Cl with nan in the Source Concentration Column.
            elseif y(1) <= Fl && y(2) > Fh % Only Cl availability is more than the demand. So whatever Ch is available will be used completely.
                N(2,ii) = N(2,ii) - Fh; % The demand is updated.
                N(qq,2) = 0; % Availability of Ch is now reduced to 0 since all of it is allocated to the demand.
                N(qq,ii) = Fh; % Allocation of Ch in the Network Matrix.
                FhCh_Before = FhCh_Before + Fh*Ch; % Updating the contaminant load.
                SourcePool1 = concUpdate(SourcePool1,Ch); % Updating the number of available sources.
                N(:,1) = searcon(Ch,N(:,1)); % Replacing Ch with nan in the Source Concentration Column.
            elseif y(1) >= Fl && y(2) >= Fh % Both Cl and Ch availability is less than that required so both of them will be used completely.
                N(2,ii) = N(2,ii) - y(1) - y(2);
                N(ss,2) = 0; % Availability of Cl is now reduced to 0 since all of it is allocated to the demand.
                N(qq,2) = 0; % Availability of Ch is now reduced to 0 since all of it is allocated to the demand.
                N(ss,ii) = Fl; % Allocation of Cl in the Network Matrix.
                N(qq,ii) = Fh; % Allocation of Ch in the Network Matrix.
                FlCl_Before = FlCl_Before + Fl*Cl; % Updating the contaminant load.
                FhCh_Before = FhCh_Before + Fh*Ch; % Updating the contaminant load.
                SourcePool1 = concUpdate(SourcePool1,Cl); % Updating the number of available sources.
                N(:,1) = searcon(Cl,N(:,1)); % Replacing Cl with nan in the Source Concentration Column.
                SourcePool1 = concUpdate(SourcePool1,Ch); % Updating the number of available sources.
                N(:,1) = searcon(Ch,N(:,1)); % Replacing Ch with nan in the Source Concentration Column.
            elseif y(1) == Fl && y(2) < Fh
                N(2,ii) = 0; % Demand has been reduced to zero since it is completely met.
                N(ss,2) = 0; % Availability of Cl is now reduced since some of it is allocated to the demand.
                N(qq,2) = N(qq,2) - y(2); % Availability of Cl is now reduced since some of it is allocated to the demand.
                N(ss,ii) = y(1); % Allocation of Cl in the Network Matrix.
                N(qq,ii) = y(2); % Allocation of Ch in the Network Matrix.
                SourcePool1 = concUpdate(SourcePool1,Cl);
                N(:,1) = searcon(Cl,N(:,1));
            elseif y(1) < Fl && y(2) == Fh
                N(2,ii) = 0; % Demand has been reduced to zero since it is completely met.
                N(ss,2) = N(ss,2) - y(1); % Availability of Cl is now reduced since some of it is allocated to the demand.
                N(qq,2) = 0; % Availability of Cl is now reduced since some of it is allocated to the demand.
                N(ss,ii) = y(1); % Allocation of Cl in the Network Matrix.
                N(qq,ii) = y(2); % Allocation of Ch in the Network Matrix.
                SourcePool1 = concUpdate(SourcePool1,Ch);
                N(:,1) = searcon(Ch,N(:,1));
            end
        end
end
%% Making the Network using NNA (Shenoy,2012): Above Pinch
SourcePool2 = N(DIR:rN,1);
for ii = DIC:cN-1 % Source-Sink Mapping in Below the Pinch Region.
     FCEqualBefore = 0;
    for jj = DIR-(PinchConcCount-1):rN
        if N(1,ii) == N(jj,1) % If conc. of demand = conc. of source
            if N(2,ii) >= N(jj,2) && N(2,ii) > 0 % Demand >= Source
                N(jj,ii) = N(jj,2); % Allocating
                N(2,ii) = N(2,ii) - N(jj,2); % Updating demand
                FCEqualBefore = FCEqualBefore + N(1,ii)*N(jj,2); % This is added for the conditions wherein equal concentration source doesn't satisfy the demand. So whatever amount of equal-concentration-source is available, it is fed to the demand amd the equivalent contaminant load is also recorded to be later fed in to the fsolve function.
                N(jj,2) = 0; % Updating Source
                SourcePool2 = concUpdate(SourcePool2,N(1,ii));
                N(jj,1) = NaN;
            elseif N(2,ii) < N(jj,2) && N(2,ii) > 0 % Demand < Source
                N(jj,ii) = N(2,ii); % Allocating
                N(jj,2) = N(jj,2) - N(2,ii); % Updating Source
                FCEqualBefore = FCEqualBefore + N(1,ii)*N(2,ii); % This is added for the conditions wherein equal concentration source is more than the demand. So whatever amount of equal-concentration-source is required, it is fed to the demand amd the equivalent contaminant load is also recorded to be later fed in to the fsolve function.
                N(2,ii) = 0; % Updating Demand
            end
        end
    end
        FlCl_Before = 0; FhCh_Before = 0; % Initial Values of some inputs to ShenFun
        while N(2,ii) > 0 % While the demand is not met.
            [Cl, Ch] = Shenoy(SourcePool2,N(1,ii));
            for mm = DIR:rN % mm is just a loop index
                if N(mm,1) == Cl
                    Fl = round(N(mm,2),4); % Available Flowrate of Lower Concentration
                    ss = mm; % Storing this index for its use in correcting the Lower Conc. Source Availability after allocation.
                elseif N(mm,1) == Ch
                    Fh = round(N(mm,2),4); % Available Flowrate of Higher Concentration
                    qq = mm; % Storing this index for its use in correcting the Higher Conc. Source Availability after allocation.
                    break; % Added because the required info on Conc and Flowrate has already been taken.
                end
            end
            y = round((fsolve(@(x) ShenFun(x,Cl,Ch,N(2,ii),Grayed(2,ii),N(1,ii),FlCl_Before,FhCh_Before,FCEqualBefore),[Fl;Fh])),4); % Finding the demands of Cl and Ch
            if y(1) < Fl && y(2) < Fh % Both the demands are lower than availabilities. So the demand will be completely met.
                N(2,ii) = 0; % Demand has been reduced to zero since it is completely met.
                N(ss,2) = N(ss,2) - y(1); % Availability of Cl is now reduced since some of it is allocated to the demand.
                N(qq,2) = N(qq,2) - y(2); % Availability of Cl is now reduced since some of it is allocated to the demand.
                N(ss,ii) = y(1); % Allocation of Cl in the Network Matrix.
                N(qq,ii) = y(2); % Allocation of Ch in the Network Matrix.
             elseif y(1) > Fl && y(2) <= Fh % Only Ch availability is more than the demand. So whatever Cl is available will be used completely.
                N(2,ii) = N(2,ii) - Fl; % The demand is updated.
                N(ss,2) = 0; % Availability of Cl is now reduced to 0 since all of it is allocated to the demand.
                N(ss,ii) = Fl; % Allocation of Cl in the Network Matrix.
                FlCl_Before = FlCl_Before + Fl*Cl; % Updating the contaminant load.
                SourcePool2 = concUpdate(SourcePool2,Cl); % Updating the number of available sources.
                N(:,1) = searcon(Cl,N(:,1)); % Replacing Cl with nan in the Source Concentration Column.
            elseif y(1) <= Fl && y(2) > Fh % Only Cl availability is more than the demand. So whatever Ch is available will be used completely.
                N(2,ii) = N(2,ii) - Fh; % The demand is updated.
                N(qq,2) = 0; % Availability of Ch is now reduced to 0 since all of it is allocated to the demand.
                N(qq,ii) = Fh; % Allocation of Ch in the Network Matrix.
                FhCh_Before = FhCh_Before + Fh*Ch; % Updating the contaminant load.
                SourcePool2 = concUpdate(SourcePool2,Ch); % Updating the number of available sources.
                N(:,1) = searcon(Ch,N(:,1)); % Replacing Ch with nan in the Source Concentration Column.
            elseif y(1) >= Fl && y(2) >= Fh % Both Cl and Ch availability is less than that required so both of them will be used completely.
                N(2,ii) = N(2,ii) - y(1) - y(2);
                N(ss,2) = 0; % Availability of Cl is now reduced to 0 since all of it is allocated to the demand.
                N(qq,2) = 0; % Availability of Ch is now reduced to 0 since all of it is allocated to the demand.
                N(ss,ii) = Fl; % Allocation of Cl in the Network Matrix.
                N(qq,ii) = Fh; % Allocation of Ch in the Network Matrix.
                FlCl_Before = FlCl_Before + Fl*Cl; % Updating the contaminant load.
                FhCh_Before = FhCh_Before + Fh*Ch; % Updating the contaminant load.
                SourcePool2 = concUpdate(SourcePool2,Cl); % Updating the number of available sources.
                N(:,1) = searcon(Cl,N(:,1)); % Replacing Cl with nan in the Source Concentration Column.
                SourcePool2 = concUpdate(SourcePool2,Ch); % Updating the number of available sources.
                N(:,1) = searcon(Ch,N(:,1)); % Replacing Ch with nan in the Source Concentration Column.
            elseif y(1) == Fl && y(2) < Fh
                N(2,ii) = 0; % Demand has been reduced to zero since it is completely met.
                N(ss,2) = 0; % Availability of Cl is now reduced since some of it is allocated to the demand.
                N(qq,2) = N(qq,2) - y(2); % Availability of Cl is now reduced since some of it is allocated to the demand.
                N(ss,ii) = y(1); % Allocation of Cl in the Network Matrix.
                N(qq,ii) = y(2); % Allocation of Ch in the Network Matrix.
                SourcePool2 = concUpdate(SourcePool2,Cl);
                N(:,1) = searcon(Cl,N(:,1));
            elseif y(1) < Fl && y(2) == Fh
                N(2,ii) = 0; % Demand has been reduced to zero since it is completely met.
                N(ss,2) = N(ss,2) - y(1); % Availability of Cl is now reduced since some of it is allocated to the demand.
                N(qq,2) = 0; % Availability of Cl is now reduced since some of it is allocated to the demand.
                N(ss,ii) = y(1); % Allocation of Cl in the Network Matrix.
                N(qq,ii) = y(2); % Allocation of Ch in the Network Matrix.
                SourcePool2 = concUpdate(SourcePool2,Ch);
                N(:,1) = searcon(Ch,N(:,1));
            end
        end
 end
 %% Sketching the Wastewater Stream
 N(DIR-(PinchConcCount-1):end,end) = N(DIR-(PinchConcCount-1):end,2);
 N(DIR-(PinchConcCount-1):end,2) = 0; % Updating the Sources which supply to Wastewater Stream.
 if N(2,end) - sum(N(DIR-(PinchConcCount-1):end,end)) > 1e-1 % The sum of the remaining amounts of sources including and above the Pinch Point must be equal to the targetted value.
     error('Wastewater Flowrate is not matching with targetted value.');
 end
 N(1,end) = sum(Grayed(DIR-(PinchConcCount-1):end,1).*N(DIR-(PinchConcCount-1):end,end))/N(2,end); % Wastewater Concentration
 WWCon = N(1,end);
 N(2,end) = 0; % Updating the wastewater target since there is no error above.
 
 %% Network Dressing
 if sum(N(3:end,2) == 0) == length(N(3:end,2)) && sum(N(2,3:end) == 0) == length(N(2,3:end))
     N(:,1:2) = Grayed(:,1:2);
     N(1:2,3:end) = Grayed(1:2,3:end);
     N(1,end) = WWCon; % The wastewater concentration was removed due to dressing, therefore, it is again fed to the network.
 else
     error('Either the Leftover Sources or the Satisfied Demands (including Wastewater Target) are not summing upto zero.');
 end
format short;
end