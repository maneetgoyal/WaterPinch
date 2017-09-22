% Program to search the index of a concentration.
function out = searcon(C,N)
for i = 1:length(N)
    if N(i) == C
        N(i) = nan;
        out = N;
        break;
    end
end