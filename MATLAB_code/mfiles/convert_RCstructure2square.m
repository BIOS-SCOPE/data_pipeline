function exportSquare = convert_RCstructure2square(structureIn)
%function exportSquare = convert_RCstructure2square(structureIn)
%The structures holding the CTD have a mix of sizes, so I need a custom
%function to make them into a square matrix to export.
%This is loosely based on KL's earlier function: convert_RCstructure2table
%That being said, this is messy
%
% structureIn is one of the CTD structures from Ruth's code
% exportSquare is the resulting square matrix (table?)
% Krista Longnecker, 21 June 2024
% Krista Longnecker, 8 March 2026 

tableOut = table();

fn = fieldnames(structureIn);

for a = 1:length(fn)
    tableOut(1,fn(a)) = {structureIn.(fn{a})'};    
end
clear a

%how many rows for each variable? I will always have two values - 
% one small number (equal to number of casts)
% and one bigger number that is the length of the concatenated data
ni = structfun(@length,structureIn);
fo = find(ni > min(ni));

% Now make a square matrix:
temp = [];
%get the size from thelast column in tableOut
nrows = size(cell2mat(tableOut{1,end}),2);

for a = 1 : fo(1) - 1
    %fill in the details that are one per cruise
    one = cell2mat(tableOut{1,a});
    r = repmat(one,1,nrows);
    temp(:,a) = reshape(r',[],1);
    clear one
end
clear a

%now do the CTD data
for aa = fo(1) : fo(end)
    one = cell2mat(tableOut{1,aa});
    temp(:,aa) = reshape(one',[],1);
    clear one 
end
clear aa

exportSquare = array2table(temp);
exportSquare.Properties.VariableNames = tableOut.Properties.VariableNames;

%finally, trim out the rwos that are all NaN, this is a by product of the
%need to pad the matrix to account for the uneven number of depths sampled
%across a cruise
i = isnan(exportSquare.pr);
exportSquare(i,:) =[];

