%% Program to produce rows which will be augmented to the final FW matrix.
%% To Create a row which is to be augmented to the FW_Matrix in the Limited Availability Case
% This program will create the row which will be augmented to the
% F_Matrix output when the availability of a certain input source is less
% than the targeted value of the same concentration. This type of arrangement
% is required because when a particular source is lower than its
% target/required value, retargeting is carried out by increasing the
% source value of the limited FW Source in the cascade table. In the
% process, the concnerned FW source is lost. This program will allow us to
% retain that particular FW Source and later augment the same to the final
% FW_Matrix.
function [F_Row_Augment, FWConc_Dupli, Availability_Dupli] = FWAug_v2(FWConc_Dupli,Availability_Dupli,FWConc)
[~, i] = setdiff(FWConc_Dupli,FWConc);
F_Row_Augment = [FWConc_Dupli(i) Availability_Dupli(i)];
FWConc_Dupli(i) = [];
Availability_Dupli(i) = [];
end