function a = leastpositive(A)
for ii = 1:length(A)
    if A(ii) <= 0
        A(ii) = NaN;
    end
end
a = min(A);
end