%% Program to interpret WCT for Pinch Points, Fresh Water and Wastewater Targets.
function [PinchP,F_Matrix, WW] = intprt_v2(FileName,Sheet,SPoints,DPoints,FWConc,Availability)
%% Different Forms the function can take.
if nargin == 5 % If the availabilities of different sources are not mentioned, then they are assumed to be infinite.
    Availability = inf*ones(1,length(FWConc));
end
if nargin == 4 % If the FWConc(s) are not given, then only one pure freshwater source is assumed. Pure FW source implies that its contaminant concentration is zero. 
    FWConc = 0;
    Availability = inf*ones(1,length(FWConc));
end
Availability = Availability'; % In this program, the availablities are required in the column form.
Availability_Dupli = Availability; % This Dupli variable is to be used while making the augmented matrix. Dupli variable is required because this variable gets updated in size if the availability of any FW source is less than the targeted value at the same concentration.
%% Initial importing, organizing and targeting.
[FWConc,J] = sort(FWConc,'ascend');
FWConc_Dupli = FWConc; % Duplicating this variable for use in the "The Limitated Availability" Case.
Availability = Availability(J);
[N, Ind] = imnor(FileName,Sheet,SPoints,DPoints,FWConc); % First Six Columns of WCT generated along with Concentraion Levels of the fed FW Concentrations.
FW_f = trgt(N,Ind,FWConc); % Multi/Single Pure/Impure Source Targeting
FW_f_Dupli = FW_f; % Duplicating this variable for use in the "The Limitated Availability" Case.
%% Availability Check
F_Matrix_Augment = [];
xx = 1; % First index of F_Matrix_Augment
while sum(FW_f > Availability) >= 1
    [New_FWConc,New_N,New_Ind] = fzbl(FW_f,Availability,FWConc,N,Ind); % Performing the availability/feasibility check.
    FWConc = New_FWConc; % Updated variable after the feasibility check.
    N = New_N; % Updated variable after the feasibility check.
    Ind = New_Ind; % Updated variable after the feasibility check.
    if isempty(FWConc) && isempty(Ind)
        error('The availability of the input FW concentration(s) is to be increased to make the WCT feasible.');
    end
    for j = 1:length(Availability) % For discarding the sources which are completely exhausted/emptied.
        if FW_f(j) > Availability(j)
            Availability(j) = nan; % If the availability is les than the targeted value, that source is completely dried/exhausted. Hence, the avialbility is reduced to 'NaN'. This 'NaN' is also discarded from the Availability Vector.
        end
    end
    Availability = nantonill(Availability); % Discarding the 'NaN' entries from the Availability vector.
    FW_f = trgt(N,Ind,FWConc); % Retargeting with update N (the limited sources have been added in the cascade).
    [F_Matrix_Augment(xx,:), FWConc_Dupli, Availability_Dupli] = FWAug_v2(FWConc_Dupli,Availability_Dupli,FWConc);
    xx = xx + 1;
end
%% Updating Water Cascade
[~, F_C, ~, ~, IFWD] = wca(N,Ind,FW_f,FWConc); % Updating the water cascade using Targeted Values.
%% Contaminant Load Check
% All IFWD values should be non-negative.
if sum(isnan(IFWD)) >= 2
    error('The given FW concentration(s) are not satisfying Contaminant Load Constraints. Add a higher quality source.');
end
% if sum(IFWD < 0) >= 1
%     error('The availability of the input FW concentration(s) is to be increased to make the WCT feasible.');
% end
%% Recording Pinch Points
PinchP = []; % Initiating the vector which will contain Pinch Points.
for i = 2:row(N)
    if IFWD(i) == 0 % If Interval Fresh Water Demand is zero, then the corresponding Source cocnetration is a Pinch Point.
      PinchP = [PinchP; N(i,2)];
    end
end
PinchP_Duplicate = PinchP; % We want to copy the value of PinchP because if the threshold case holds for the concerned problem, the new points given by PinchP1 will be set to PinchP and further use of orginal value of PinchP will not be possible.
%% Zero Network Discharge: Threshold Case
Availability = Availability - FW_f;
if F_C(end) == 0 || F_C(end) < 0
    [UpdatedInput1,UpdatedInput2,UpdatedInput3,~] = thresh2(F_C,N,Ind,FW_f,FWConc,PinchP,PinchP_Duplicate,Availability);
    FW_f = UpdatedInput1;
    F_C = UpdatedInput2;
    PinchP = UpdatedInput3;
end
%% Recording WW Flowrate and Freshwater Flowarates
WW = F_C(end); % Recording WW Flowrate.
if WW < 0
    error('Flowrate Constraint is not satisfied. Go for debugging');
end
F_Matrix = [(sort(FWConc,'ascend'))' FW_f]; % This will make a matrix which will contain the FW concentrations (that were already fed as input) along with the corresponding targeted FW values.
%% Limited Availability Case
% In the limited availablity case, if the targeted value is more than the
% available value, then targeting is carried out by adding the limited
% available value to the source of the same concentration. In this
% arrangement, the limited value source does not appear in the final
% answer. So in this portion of the code, we present a sub-routine that
% will restore the limited availablility source in the final answer (i.e.
% in F_Matrix.)
F_Matrix = [F_Matrix; F_Matrix_Augment];
%% Flagging the Redundant Fresh Water Sources
for i = 1:row(F_Matrix)
    if F_Matrix(i,2) == 0
        fprintf('Fresh Water Source No. %d is a Redundant Source.\n',i);
    end
end
end