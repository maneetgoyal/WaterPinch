%% Program to Update FWConc, N and Ind depending upon freshwater source availability.
function [New_FWConc,New_N,New_Ind] = fzbl(FW_f,Availability,FWConc,N,Ind)
for i = 1:length(Ind)
    if FW_f(i) > Availability(i) % If the targeted flowrate at the concentration under consideration is more than what is available, then whatever is available is added to the source of that particular concentration.
        N(Ind(i),6) = N(Ind(i),6) + Availability(i);
        FWConc(i) = []; % The concentration corresponding to the new greater source is removed or put to 'nill' for re-targeting.
        Ind(i) = []; % The concentration index (index: level at which that particular concentration lies in the second column of the WCT) corresponding to the new greater source is removed or put to 'nill' for re-targeting.
    end
end
New_FWConc = FWConc; % Updated set of FW Cocentration(s) is the output.
New_N = N; % N is the matrix containing the first six columns of the WCT. Here, it is updated if some of the sources have been updated.
New_Ind = Ind; % The index column is updated and is one of the outputs. It contains new reduced number of levels.
end