% Works for Single Freshwater Sources.
% A 'Raw' Matrix of class type 'cell' has to be defined beforehand.
% Assmuning that the fresh water concentration is less than or equal to
% limiting inlet concentraion of different operations.
function FW = FreshOnly(RawValues, FW_Concentration)
[r,~] = size(RawValues);
FW = 0; % Freshwater Requirement before the loop in initiated is set to zero!
for ii = 3:r
    if strcmp(RawValues{ii,3},'FC') == 1 % Checking for Fixed Contaminant Load Based Operation
        FW = FW + RawValues{ii,4}/(RawValues{ii,6} - FW_Concentration); % Freshwater Requirement is constantly updated with each iteration.
    elseif strcmp(RawValues{ii,3},'FF') == 1 % Checking for Fixed Flowrate Based Operation
        FW = FW + RawValues{ii,7}; % Freshwater Requirement is constantly updated with each iteration.
    else
        error('The operation type must be either ''FC'' or ''FF''.\n');
    end
end
end