%Set up to calculate Ruth's derived variables from all BATS cruises (e.g.,
%MLD, season, and VZ); starting with BATS cruise #1
%based on Ruth's prior code : create_biosscope_files_2022_2023.m
% Original code from Ruth Curry, BIOS / ASU
% Krista Longnecker; 8 February 2024
% Some notes from Krista (8 February 2024)
% (1) you will need to update the path information and file names
% up through row ~27 in this code. There should be no need to change
% anything past that point.
% (2) The output from this code will be (1) a series CSV files, one per cruise,
% that will be saved in 'outdir', defined at line 22, and (2) one giant
% file with all the information concatenated together.
clear all 
close all

%% >>>>>   % add ./BIOSSCOPE/CTD_BOTTLE/mfiles into matlab path
addpath(genpath('C:\Users\klongnecker\Documents\Dropbox\GitHub\data_pipeline\MATLAB_code\mfiles'));

%% update the folder information before getting started
rootdir = 'C:\Users\klongnecker\Documents\Dropbox\Current projects\Kuj_BIOSSCOPE\RawData\';
%Krista has put the next two folders outside the space accessible by GitHub
%These files are too large to put into GitHub
workdir = fullfile(rootdir,'RCcalcBATS\data_temporary\');
outdir = fullfile(rootdir,'RCcalcBATS\data_holdingZone\');

%set this to one if you want to see a plot for each cast (that will clearly
%be a ton of plots, so this is best used if you to look at a preset number
%of casts wihtin the full set of casts)
do_plots = 0;
   
%now do the calculations

%Ruth set this up for txt files, but the BATS txt files are a pain, use
%their *mat files
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

% doFiles = 1; %use for testing, smaller number of files
% doFiles = ; %use for testing, more files in case you need to test the loop
% doFiles = nfiles; %do everything
% for ii = 1:doFiles;
for ii = [1,200:202]
   fname = dirlist(ii).name;
   infile = fullfile(workdir,fname);
   
   %use modified function from KL, 2/8/2024
   CTD = calculate_BATSderivedVariables(infile,do_plots,outdir,0);
end
clear ii

%now that you have all the files you can concatenate them. What are the
%files?
D = dir(outdir);
D([D.isdir]) = [];

%use the first file to setup the framework
fname = D(1).name;
infile = fullfile(outdir,fname);
allBATS = readtable(infile);
%then start the loop with the next file in line (this will be slow as it is
%sequentially making a matrix that will grow in size)
%change syntax to allow creation of a smaller file for testing
  for aa = 2:length(D)
      fprintf('on loop %d of %d\n',aa,nfiles);
      %read in a CSV file
      fname = D(aa).name;
      infile = fullfile(outdir,fname);
      allBATS = cat(1,allBATS,readtable(infile));
      clear fname infile
 end
 clear aa 
  
%Now export allBATS as a file...this will be pretty big
writetable(allBATS,fullfile(outdir,'BATSwithDerivedValues_subset.2024.06.19.csv'))

clear
