function [FData,WW] = crude(FileName,Sheet,SPoints,DPoints,FWConc)
% FWConc = [0 25 50 75 100 125];
% [NumS,TxtS,SData] = xlsread('Sample Matrices.xlsm',16,'L11:Q13'); % Source Data
% [NumD,TxtD,DData] = xlsread('Sample Matrices.xlsm',16,'F11:K13'); % Demand Data
% FWConc = [0 50];
% [NumS,TxtS,SData] = xlsread('Sample Matrices.xlsm',23,'L9:Q16'); % Source Data
% [NumD,TxtD,DData] = xlsread('Sample Matrices.xlsm',23,'F9:K15'); % Demand Data
[NumS,TxtS,SData] = xlsread(FileName,Sheet,SPoints); % Source Data
[NumD,TxtD,DData] = xlsread(FileName,Sheet,DPoints); % Demand Data
%% Sorting Data in ascending order of Concentration
FWConc = sort([FWConc 1000000]);
SData = mysort(NumS,TxtS,SData);
DData = mysort(NumD,TxtD,DData);
FW = zeros(length(FWConc),1);
for jj = 1:row(DData)
    for ii = 1:length(FWConc)
        if FWConc(ii) > DData{jj,4} && strcmp(DData{jj,5},'FF') == 1
            FW(ii-1) = FW(ii-1) + DData{jj,3};
            break;
        elseif FWConc(ii) > DData{jj,4} && strcmp(DData{jj,5},'FC') == 1
            for mm = 1:row(SData)
                if strcmp(SData{mm,2},DData{jj,2}) == 1
                    Cout = SData{mm,4};
                    break;
                end
            end
            FW(ii-1) = FW(ii-1) + (DData{jj,6}/(Cout-FWConc(ii-1)));
            break;
        end
    end
end
FW = FW(1:end-1);
FWConc = FWConc(1:end-1);
FData = [FWConc' FW];
Loss = 0;
for ii = 1:row(DData)
    for jj = 1:row(SData)
        if SData{jj,2} == DData{ii,2}
           Loss = Loss + DData{ii,3} - SData{jj,3};
        end
    end
end
for jj = 1:row(SData)
    if sum(NumS(jj,1) == NumD(:,1)) == 0
        Loss = Loss - NumS(jj,3);
    end
end
for ii = 1:row(DData)
    if sum(NumD(ii,1) == NumS(:,1)) == 0
        Loss = Loss + NumD(ii,3);
    end
end
WW = sum(FW) - Loss;
end