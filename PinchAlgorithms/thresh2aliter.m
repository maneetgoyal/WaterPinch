%% Alternate Program to update Pinch Point, FW_f, and F_C for Zero Wastewater Discharge Case
% Preference to higher quality sources
% After evauluating the Zero Network Discharge Threshold Case, this program
% will update FW_f if the flowrate constrains are not satisfied, F_C after
% retargeting with the updated FW_f, and PinchP after retargeting with the updated FW_f. The
% program also gives the threshold concentration(s) in the network/cascade.
function [UpdatedInput1,UpdatedInput2,UpdatedInput3,UpdatedInput4] = thresh2aliter(F_C,N,Ind,FW_f,FWConc,PinchP,PinchP_Duplicate,Availability)
if F_C(end) == 0
    fprintf('Threshold Case: Zero Network Discharge.\n');
    fprintf('Here, the WW water discharge was already zero, post trageting.\n');
    % The threshold concetration will/will not exist because...
end
F_C_dummy = -F_C(end); % This dummy variable is being created for aiding the availability check.
if F_C(end) < 0
    [FW_Impure, Availability_Impure, FW_Pure, Availability_Pure] = alitersort(FWConc,FW_f,Availability);
    for m = 1:length(FW_Impure)
        if Availability_Impure(m) <= F_C_dummy && F_C_dummy > 0 && Availability_Impure(m) > 0
            F_C_dummy = F_C_dummy - Availability_Impure(m);
            FW_Impure(m) = FW_Impure(m) + Availability_Impure(m);
            Availability_Impure(m) = 0;
        elseif Availability_Impure(m) > F_C_dummy && F_C_dummy > 0
            Availability_Impure(m) = Availability_Impure(m) - F_C_dummy;
            FW_Impure(m) = FW_Impure(m) + F_C_dummy;
            F_C_dummy = 0;
            break;
        end
    end
    if round(F_C_dummy,6) ~= 0
        if ~isempty(Availability_Pure) && Availability_Pure < F_C_dummy
           error('The availability of pure and impure sources is lower than what is required to satisfy the flowrate constraints.');
        elseif ~isempty(Availability_Pure) && Availability_Pure >= F_C_dummy
            Availability_Pure = Availability_Pure - F_C_dummy;
            FW_Pure = FW_Pure + F_C_dummy;
            F_C_dummy = 0;
        elseif isempty(Availability_Pure)
            error('The availability of impure sources is lower than what is required to satisfy the flowrate constrints. Moreover, no pure source is available to overcome the flowrate deficit.');
        end
    end
    fprintf('Threshold Case: Zero Network Discharge.\n');
    Availability = [Availability_Pure; Availability_Impure];
    FW_f = [FW_Pure; FW_Impure];
    [~, F_C, ~, ~, IFWD] = wca(N,Ind,FW_f,FWConc); % Updating the water cascade using Targeted Values.
    PinchP1 = []; % Initiating the vector which will contain Pinch Points.
    for i = 2:row(N)
        if IFWD(i) == 0 % If Interval Fresh Water Demand is zero, then the corresponding Source concentration is a Pinch Point.
            PinchP1 = [PinchP1; N(i,2)]; % Making new pinch concentration column after the flowrates have been adjusted. 
        end
    end
    PinchP = PinchP1; % Updating the New Pinch Points
%     %% Defining the Threshold Concentration(s)
%     fprintf('The Threshold Concentration(s) are:\n');
%     ThreshCon = setdiff(PinchP_Duplicate,PinchP1);
%     fprintf('%d \n',ThreshCon);
end
UpdatedInput1 = FW_f;
UpdatedInput2 = F_C;
UpdatedInput3 = PinchP;
UpdatedInput4 = Availability;
end