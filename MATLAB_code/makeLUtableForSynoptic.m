% Use this file to make a lookup table with the calculated variables 
% that will feed into makeSynoptic
% (which is in R right now...switching between languages..slightly unfortunate)
% Krista Longnecker; 21 June 2024
% Krista Longnecker, 6 June 2026
clear all 
close all

%% >>>>>   % add ./BIOSSCOPE/CTD_BOTTLE/mfiles into matlab path
addpath(genpath('D:\Dropbox\GitHub_niskin\data_pipeline\MATLAB_code\mfiles'));

%% update the folder information before getting started
rootdir = 'D:\Dropbox\GitHub_niskin\data_pipeline\RawData\';
%Krista has put the next two folders outside the space accessible by GitHub
%These files are too large to put into GitHub
workdir = fullfile(rootdir,'CTDrelease_20260326\');
outdir = fullfile(rootdir);

%start with some tidying up
cd(workdir)
dirlist = dir('*.mat');
%delete some names...not the best way to do this, but will work
s = contains({dirlist.name},'YR');
ks = find(s==1);
dirlist(ks) = []; clear s ks
s = contains({dirlist.name},'bats_ctd.mat');
ks = find(s==1);
dirlist(ks) = []; clear s ks
s = contains({dirlist.name},'bval_ctd.mat');
ks = find(s==1);
dirlist(ks) = []; clear s ks
s = contains({dirlist.name},'working.mat');
ks = find(s==1);
dirlist(ks) = []; clear s ks

nfiles = length(dirlist);
stepOne = table();

% doFiles = 1; %use for testing, smaller number of files
% doFiles = ; %use for testing, more files in case you need to test the loop
doFiles = nfiles; %do everything
for ii = 1:doFiles;
    fname = dirlist(ii).name;
    infile = fullfile(workdir,fname);
    
    S = whos('-file',infile); 
    Sn = {S.name}; 
    %then pull the data from the structure, will be gf#####_data (where ##### is
    %the BATS cruise id)
    r = contains(Sn,'_data');
    kr = find(r==1); %which part of the structure has the data?
    riMAT = load(infile,Sn{kr});
    %ugly MATLAB hack to pull out the data into a matrix and put into Ruth's
    %format; TTin is a 1 x 12 cell, one variable per cell
    v = fieldnames(riMAT);
    TTin = riMAT.(v{1}); %this will read in matrix
    
    %make a table, easier to manipulate; have to write a custom script to
    %make a table given the complexity of these structures
    trim = 1; %set this to one to only keep the values that are one per cruise/cast
    % T = convert_RCstructure2table(CTD,trim); %this is a new KL function 6/21/2024
    T = convert_RCstructure2table(TTin,1);
    stepOne = [stepOne;T];
   clear idx T
end
clear ii

%I made an absurd mess, but this will work for now
stepTwo = cell2mat(table2array(stepOne));
stepThree = array2table(stepTwo,'VariableNames',stepOne.Properties.VariableNames);

%Now export stepTwo as a CSV file for R
writetable(stepThree,fullfile(outdir,'BATSderivedValues_lookupTable.2026.06.07.csv'))

