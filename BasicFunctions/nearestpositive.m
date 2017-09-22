function a = nearestpositive(A,b)
diff = zeros(length(A),1);
for ii = 1:length(A)
    diff(ii) = A(ii) - b;
    if diff(ii) <= 0
        diff(ii) = nan;
    end
end
for ii = 1:length(diff)
    if diff(ii) == min(diff)
        a = A(ii);
    end
end