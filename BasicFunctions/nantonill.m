% Program to discard 'NaN' from the input.
function out = nantonill(in)
j = 1;
count = 0;
for i = 1:length(in) % Loop for counting the number of 'NaN' occurences. This no. of occurences will then be equal to the length of the output 'out'.
    if ~isnan(in(i))
        count = count + 1;
    end
end
out = zeros(count,1);
for i = 1:length(in) % Loop for filling up the output 'out'. It will have all the non 'NaN' members of the input '
    if ~isnan(in(i))
        out(j) = in(i);
        j = j+1;
    end
end
end