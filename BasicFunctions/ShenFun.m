%% Program that generates required flowrates of Nearest Neigbours
function y = ShenFun(x,Cl,Ch,F_Req,Gray_F,Gray_C,FlCl_Before,FhCh_Before,FCEqualBefore)
y(1) = x(1)*Cl + x(2)*Ch + FlCl_Before + FhCh_Before + FCEqualBefore - Gray_F*Gray_C;
y(2) = x(1) + x(2) - F_Req;
end
