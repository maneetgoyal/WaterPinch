% Works for Multiple Freshwater Sources. Just remember to enter the
% concentration in ascending order.
% A 'Raw' Matrix of class type 'cell' has to be defined beforehand.
function FW = FreshOnly_Star(RawValues, FW_Concentration)
ll = length(FW_Concentration); % Number of Sources of Fresh Water
[r,~] = size(RawValues); % No. of rows in Raw Matrix
oo = r-2; % No. of Operations in Raw Matrix
Dff = zeros(oo,ll); % Preallocating matrix containing differences between limiting inlet concentration of specified operation and fresh water concentration of different sources.
Min_Diff_Conc = zeros(oo,1); % Preallocating matric that will contain the appropriate freshwater source for the concerned operation.
ConcernedIndex = zeros(oo,1); % Preallocating matrix that will contain the appropriate fresh water source location (in the FW vector) for  the concerned operation.
FW = zeros(ll,1);
for ii = 3:r % Signaling the loop to proceed from row 3 of the Raw Matrix
    for jj = 1:ll % Singalling the loop to proceed from the first value of FW_Concentration vector
    Dff(ii-2,jj) = RawValues{ii,5} - FW_Concentration(jj,1);
    end
end
for ii = 1:oo % This loop will pop up an error if none of the available freshwater sources are satisfying the inlet concentration constraint of any operation under consideration.
    if sum(Dff(ii,:)>=0) == 0
        error('The freshwater sources are not satisfying the inlet concentration constraint of operation %s.\n',RawValues(ii+2,2));
    end
end
for ii = 1:oo % This loop will eradicate all the sources which are violating the inlet concentration constraint.
    for jj = 1:ll
        if Dff(ii,jj) < 0
            Dff(ii,jj) = NaN;
        end
    end
end
for ii = 1:oo % This loop will prepare the Min_Diff_Conc Vector that will help in using the poorest allowable quality of Fresh Water.
    for jj = 1:ll
        if Dff(ii,jj) == min(Dff(ii,:))
            Min_Diff_Conc(ii) = FW_Concentration(jj);
            ConcernedIndex(ii) = jj;
        end
    end
end
for ii = 3:r
    if strcmp(RawValues{ii,3},'FC') == 1 % Checking for Fixed Contaminant Load Based Operation
        FW(ConcernedIndex(ii-2)) = FW(ConcernedIndex(ii-2)) + RawValues{ii,4}/(RawValues{ii,6} - Min_Diff_Conc(ii-2)); % Freshwater Requirement is constantly updated with each iteration.
    elseif strcmp(RawValues{ii,3},'FF') == 1 % Checking for Fixed Flowrate Based Operation
        FW(ConcernedIndex(ii-2)) = FW(ConcernedIndex(ii-2)) + RawValues{ii,7}; % Freshwater Requirement is constantly updated with each iteration.
    else
        error('The operation type must be either ''FC'' or ''FF''.\n');
    end
end
end