%% This Program updates the Source/Demand Pool after water allocation.
% out = new pool
% in = old pool
% flag = conc. which needs to be removed
function out = concUpdate(in,flag)
for i = 1:length(in)
    if in(i) == flag
        in(i) = [];
        break;
    end
end
out = in;
end