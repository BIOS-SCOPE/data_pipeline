% Compile BATS/BIOSSCOPE CTD files in .csv and .mat formats
% Original code from Ruth Curry, BIOS / ASU (as create_biosscope_files.m)
% Krista Longnecker; first updated 10 July 2024
%
% Some notes from Krista (25 August 2024)
% (1) you will need to update the path information and file names
% up through row ~76 in this code. There should be no need to change
% anything past that point.
% (2) You will need data from two sources: BCO-DMO and the data release
% just for the BIOS-SCOPE project (currently available on DropBox)
% (3) Be sure to put the data folders outside the space accessible by 
% GitHub because they are too large to put into GitHub
% (4) This m-file will process all the CTD files into different folders,
% setting it up that way as so much of the downstream work relies on that
% format

% About the seasons - in June 2024 we received updated season information
% from Ruth, this update takes advantage of the updated season information
% from Ruth and will do so in a way that makes it easy to keep making
% seasonal updates moving forward
% Krista Longnecker, updated 13 February 2026 ---> new seasons
% Krista Longnecker, updated 7 June 2026 --> using data from BCO-DMO
% Krista Longnecker, alter 12 June 2026 - use to gather all BATS files
% AND using data from BCO-DMO...which is in an very different format 
% Krista Longnecker, 25 August 2026 move to data_pipeline as first part 
% of pre-processing the CTD files (for BATS and BIOS-SCOPE projecct)

%%add options depending on computer, KL is jumping between computers
if isequal(getenv('COMPUTERNAME'),'CORTADO')
    % add mfiles into MATLAB path
    addpath(genpath('C:\DropBox\GitHub_cortado\data_pipeline\MATLAB_code\mfiles'));    
    % set the root working directory
    rootdir = 'C:\DropBox\GitHub_cortado\data_pipeline\';    
elseif isequal(getenv('COMPUTERNAME'),'DESKTOP-QB9J1SQ')
    % same idea as above, different computer 
    addpath(genpath('D:\DropBox\GitHub_niskin\data_pipeline\MATLAB_code\mfiles'));    
    rootdir = 'D:\DropBox\GitHub_niskin\data_pipeline\';
end

% Some folders will be the same regardless of computer:
%use the datadir to temporarily hold your CTD data 
datadir = fullfile(rootdir,'RawData'); 
% put the processed CTD files here: one folder per cruise
CTDprocessedDir = fullfile(datadir,'/processedCTDdata'); 

% %Get the CTD data file from BCO-DMO (https://www.bco-dmo.org/dataset/3918)
% Primary data file for dataset ID 3918, version 11
% File:bats_ctd_v011_update.txt
% Creation date: 3 December 2025
% Data date (cruise) limits: December 1988(cruise 10001) - June 2025 (cruise 10428) 
% one datafile for all the cruises
% Downloaded from BCO-DMO manually June 2026
BCODMOdatadir = fullfile(datadir,'BCODMOdataset3918_BATS_v11');
BCODMOdata = fullfile(BCODMOdatadir,'3918_v11_bats_ctd.csv'); 

% Also need the data release for the BIOS-SCOPE project...much of this
% overlaps with what has been submitted to BCO-DMO, but the BIOS-SCOPE-only
% cruises are also in here
BIOSSCOPEdatadir = fullfile(rootdir,'RawData\CTDrelease_20260326'); %KEEP name so we know which CTD release we are adding

%what are you going to use for the season information?
if 1
    %Use the dates defined in the easy-to-read Excel file and convert to
    %the format Ruth uses in her code; update 10 July 2024
    %Use this function to make a MATLAB structure with transition dates
    seasonsFile = fullfile('BATS_seasons_wKLedits.2026.06.15.xlsx');
    %use this function to reformat the dates, set fName in calcDerivedVariables
    season_dates = reformat_season_dates(seasonsFile) ; 
elseif 0
    %load in an existing file
    %Comment this out...want to be sure that people really want to use old data
end

do_plots = 0; %set this to 1 if you want plots - unlikely for a large number of cruises
showOutput = 0; %set this to 1 if you want to see more details as files are processed
warning('off','MATLAB:nearlySingularMatrix') %turn this off
warning('off','MATLAB:singularMatrix') %turn this off
warning('off', 'curvefit:fit:invalidStartPoint')

% %%%%%%%%%%%%%%%% There should be no need to make changes below this point
% %%%%%%%%%%%%%%%% Krista Longnecker, updated 15 June 2026
% %%%%%%%%%%%%%%%%

%% start with the data from BATS/Hydrostation S/BLOOM cruises (source:BCO-DMO)

%read in the CTD data as a table
C = readtable(BCODMOdata);

% how many unique cruises are there? Will go through each cruise one at a time
uniqueCruises = unique(C.Cruise_num);

% for ii = 1:length(uniqueCruises)    
for ii = 3
   %find the rows for one cruise
   k = find(C.Cruise_num == uniqueCruises(ii)); 
   oneCruise = C(k,:);
   CTD = create_BATS_ctd_files(oneCruise,season_dates,do_plots,CTDprocessedDir,showOutput); %update KL 8/25/2026

   if 0 %for now, turn off *mat files, cannot read those into R (which is the next step)
       cd(CTDprocessedDir)
       fmt = '%4d%02d%02d_%1d%04d_CTD.mat';
       outfile = sprintf(fmt,CTD.year(1),CTD.month(1),CTD.day(1),CTD.type(1),CTD.cruise(1));
       disp(['Writing ',outfile]);
       save(outfile,'CTD');
       clear fmt outfile
   end

   clear k oneCruise CTD 
end
clear ii
clear C %done with BCO-DMO file

%% Move on to the BIOS-SCOPE data release
% Filter so we only process files from cruises that we do NOT already have

% Start by getting the list of folders  - this will be both BIOS-SCOPE cruises
% and cruises where BIOS-SCOPE sampling was done
cd(BIOSSCOPEdatadir);
%first tidy up and make sure there are no existing *txt files
delete('*.txt')

%this will get *all* the directories, some of which will be duplicates
dirAll = dir(BIOSSCOPEdatadir);
toIgnore = strcmp({dirAll.name}, '.') | strcmp({dirAll.name}, '..');
dirAll = dirAll(~toIgnore); %remove . and .. as MATLAB is not smart enough to skip them
clear toIgnore

%match to existing work based on folder names
isFolder = [dirAll.isdir];
foldersOnly = dirAll(isFolder);
dirName = {foldersOnly.name}; 

%only work on the new folders, use setdiff to find that subset
[c ia] = setdiff(str2double(dirName),uniqueCruises); %unique_cruises is double, but dirName is strings)

dirlist = dirAll(ia);
clear c ia isFolder foldersOnly dirName

%now iterate through each of the new cruise folders
for a = 1 : length(dirlist)
  thisdir = dirlist(a).name;
  temp = dir(fullfile(thisdir, '*c*_QC.dat'));
  %argh, MATLAB on Windows is ignoring case, so this is trapping all the
  %files names *BIOSSCOPE* which we do not want
  
  for aa = 1:length(temp)
      %take the *dat file (all EXCEPT the one marked BIOS-SCOPE) and make
      %it a text file. Will put that text file (somewhere)
      one = strcat(temp(aa).folder,filesep,temp(aa).name);
      if ~contains(temp(aa).name,'BIOSSCOPE') %skip this file
          fid = fopen(strcat(thisdir,'_ctd.txt'),'a');
          riFile = fileread(one);
          fprintf(fid,'%s',riFile);  
          fclose(fid);
          clear riFile fid
      end
      clear one
  end
  clear aa thisdir temp
end
clear a dirlist

%  Now, load and label CTD data, still working in the BIOS-SCOPE data directory
cd(BIOSSCOPEdatadir);
dirlist = dir('*_ctd.txt');
new_cruises = cat(1,dirlist.name); %KL adding 1/4/2024

nfiles = length(dirlist);
for ii = 1:nfiles
   fname = dirlist(ii).name;
   infile = fullfile(BIOSSCOPEdatadir,fname);
   newdir = fullfile(BIOSSCOPEdatadir,fname(1:end-8));
   mkdir(newdir);
   cd(newdir);

   %really is easier to have a separate files for BIOS-SCOPE files as there
   %are some formatting differences
   CTD = create_BIOSSCOPE_ctd_files_v2(infile,season_dates,do_plots,CTDprocessedDir,showOutput);
   %movefile('CRU*',CTDprocessedDir);

   if 0 %for now, turn off *mat files, cannot read those into R (which is the next step)
       cd(CTDprocessedDir)
       fmt = '%4d%02d%02d_%1d%04d_CTD.mat';
       outfile = sprintf(fmt,CTD.year(1),CTD.month(1),CTD.day(1),CTD.type(1),CTD.cruise(1));
       disp(['Writing ',outfile]);
       save(outfile,'CTD');
       clear fmt outfile
   end
   
   clear fname infile newdir CTD

end



%  Check fluor profiles for bad data   (None!) 
cd(CTDprocessedDir)
dirName = dir('*_CTD.mat');
icru_bad =[];

for ii=1:length(dirName)
    fname = dirName(ii).name;
    load(fname);
    icast_bad = [];
     for iprof = 1:length(CTD.cast)
        if any(find(CTD.fluor_filt(:,iprof) > 1 | CTD.fluor_filt(:,iprof) < -0.05))
            icru_bad = [icru_bad; CTD.BATS_id(iprof) ];
            disp(['Bad fluor data: ',num2str(CTD.BATS_id(iprof)),' cast # ',num2str(CTD.cast(iprof))])
        end
     end
end
    

