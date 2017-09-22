% Function for sorting the input matrix (NumS) in such a way that the
% concentrations are in ascending order.
function outS = mysort(NumS,TxtS,SData)
[NumS(:,4),I1] = sort(NumS(:,4));
NumS(:,1:3) = NumS(I1,1:3);
NumS(:,6) = NumS(I1,6);
TxtS = TxtS(I1,:);
SData(:,2) = TxtS(:,1);
SData(:,5) = TxtS(:,4);
for ii = 1:row(SData)
  SData{ii,1} = NumS(ii,1);
  SData{ii,3} = NumS(ii,3);
  SData{ii,4} = NumS(ii,4);
  SData{ii,6} = NumS(ii,6);
end
outS = SData;
end