%% Program to update Pinch Point, FW_f, and F_C for Zero Wastewater Discharge Case
% Preference to lower quality sources.
% After evauluating the Zero Network Discharge Threshold Case, this program
% will update FW_f if the flowrate constrains are not satisfied, F_C after
% retargeting with the updated FW_f, and PinchP after retargeting with the updated FW_f. The
% program also gives the threshold concentration(s) in the network/cascade.
function [UpdatedInput1,UpdatedInput2,UpdatedInput3,UpdatedInput4] = thresh2(F_C,N,Ind,FW_f,FWConc,PinchP,PinchP_Duplicate,Availability)
if F_C(end) == 0
    fprintf('Threshold Case: Zero Network Discharge.\n');
    fprintf('Here, the WW water discharge was already zero, post trageting.\n');
    % The threshold concetration will/will not exist because...
end
F_C_dummy = -F_C(end); % This dummy variable is being created for aiding the availability check. 
if F_C(end) < 0
    for m = length(Availability):-1:1
        if Availability(m) <= F_C_dummy && F_C_dummy > 0 && Availability(m) > 0
            F_C_dummy = F_C_dummy - Availability(m);
            FW_f(m) = FW_f(m) + Availability(m);
            Availability(m) = 0;
        elseif Availability(m) > F_C_dummy && F_C_dummy > 0
            Availability(m) = Availability(m) - F_C_dummy;
            FW_f(m) = FW_f(m) + F_C_dummy;
            F_C_dummy = 0;
            break;
        end
    end
    if round(F_C_dummy,6) ~= 0
        error('The availability of sources is lower than what is required for satisfying the flowrate constraints.');
    end
    fprintf('Threshold Case: Zero Network Discharge.\n');
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