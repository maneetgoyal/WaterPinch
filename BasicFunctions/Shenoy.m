%% Program that gives nearest neighbours to a particular concentration after assuming that the same concentration does not lie in the pool of the concentrations from which the neighbours will be selected.
function [Cl,Ch] = Shenoy(SourceC,d)
S = unique([SourceC',d]);
if d == S(1) || d == S(end)
    disp(d);
    error('The concerned sink cannot be satisfied by the available sources.');
end
for ii = 1:length(S)
    if S(ii) == d
        Cl = S(ii-1); % Lower Conc. than given.
        Ch = S(ii+1); % Higher Conc. than given.
        break;
    end
end
end