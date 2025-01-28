%Set up to calculate Ruth's derived variables from all BATS cruises (e.g.,
%MLD, season, and VZ); starting with BATS cruise #1
%based on Ruth's prior code : create_biosscope_files_2022_2023.m
% Original code from Ruth Curry, BIOS / ASU
% Krista Longnecker; 8 February 2024
% Use this file to make a lookup table that will feed into makeSynoptic
% (which is in R right now...switching between languages)
% Krista Longnecker; 21 June 2024
clear all 
close all

%% >>>>>   % add ./BIOSSCOPE/CTD_BOTTLE/mfiles into matlab path
addpath(genpath('C:\Users\klongnecker\Documents\Dropbox\GitHub\data_pipeline\MATLAB_code\mfiles'));

%% update the folder information before getting started
rootdir = 'C:\Users\klongnecker\Documents\Dropbox\Current projects\Kuj_BIOSSCOPE\RawData\';
%Krista has put the next two folders outside the space accessible by GitHub
%These files are too large to put into GitHub
workdir = fullfile(rootdir,'RCcalcBATS\data_temporary\');
% workdir = fullfile(rootdir,'RCcalcBATS\data_copySmall_testing\');

outdir = fullfile(rootdir,'RCcalcBATS\data_holdingZone\');

%set this to one if you want to see a plot for each cast (that will clearly
%be a ton of plots, so this is best used if you to look at a preset number
%of casts within the full set of casts)
do_plots = 0;
   
%now do the calculations

%Ruth set this up for txt files, but the BATS txt files are a pain, use
%the BATS *mat files
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
   
   %use modified function from KL, 2/8/2024
   CTD = calculate_BATSderivedVariables(infile,do_plots,outdir,0);
   %make a table, easier to manipulate; have to write a custom script to
   %make a table given the complexity of these structures
   trim = 1; %set this to one to only keep the values that are one per cruise/cast
   T = convert_RCstructure2table(CTD,trim); %this is a new KL function 6/21/2024
   stepOne = [stepOne;T];
   
   clear idx T
end
clear ii

%I made an absurd mess, but this will work for now
stepTwo = cell2mat(table2array(stepOne));
stepThree = array2table(stepTwo,'VariableNames',stepOne.Properties.VariableNames);

%Now export stepTwo as a CSV file for R
writetable(stepThree,fullfile(outdir,'BATSderivedValues_lookupTable.2024.06.21.csv'))

