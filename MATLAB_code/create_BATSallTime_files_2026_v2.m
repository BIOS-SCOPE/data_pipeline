% Compile BATS/BIOSSCOPE CTD files in .csv and .mat formats
% Original code from Ruth Curry, BIOS / ASU
% Krista Longnecker; first updated 10 July 2024
%
% Some notes from Krista (10 July 2024)
% (1) you will need to update the path information and file names
% up through row ~22 in this code. There should be no need to change
% anything past that point.
%
% About the seasons - in June 2024 we received updated season information
% from Ruth, this update takes advantage of the updated season information
% from Ruth and will do so in a way that makes it easy to keep making
% seasonal updates moving forward
% Krista Longnecker, updated 13 February 2026 ---> new seasons
% Krista Longnecker, updated 7 June 2026 --> using data from BCO-DMO
% Krista Longnecker, alter 12 June 2026 - use to gather all BATS files
% AND using data from BCO-DMO...which is in an very different format 
% Krista Longnecker, 24 August 2026 new computer to match at the start

%%add options depending on computer, KL is jumping between computers
if isequal(getenv('COMPUTERNAME'),'CORTADO')
    %% add ./BIOSSCOPE/CTD_BOTTLE/mfiles into matlab path
    addpath(genpath('C:\DropBox\GitHub_cortado\BATSallTime\MATLAB_code\mfiles'));    

    %% update the folder information before getting started
    % Krista has put the next two folders outside the space accessible by 
    % GitHub because they are too large to put into GitHub
    % can use the files in data_pipeline, no need to copy them to new
    % repository
    rootdir = 'C:\DropBox\GitHub_cortado\data_pipeline\';
    %use the datadir to temporarily hold your CTD data (make sure this is
    %outside where GitHub syncs as it could be a large folder)
    datadir = fullfile(rootdir,'RawData'); %put BCO-DMO data file here  
elseif isequal(getenv('COMPUTERNAME'),'DESKTOP-QB9J1SQ')
    %% add ./BIOSSCOPE/CTD_BOTTLE/mfiles into matlab path
    addpath(genpath('D:\DropBox\GitHub_niskin\BATSallTime\MATLAB_code\mfiles'));    

    %% update the folder information before getting started
    % Krista has put the next two folders outside the space accessible by 
    % GitHub because they are too large to put into GitHub
    % can use the files in data_pipeline, no need to copy them to new
    % repository
    rootdir = 'D:\DropBox\GitHub_niskin\data_pipeline\';
    %use the datadir to temporarily hold your CTD data (make sure this is
    %outside where GitHub syncs as it could be a large folder)
    datadir = fullfile(rootdir,'RawData'); %put BCO-DMO data file here 

end

% %Get the CTD data file from BCO-DMO (https://www.bco-dmo.org/dataset/3918)
% Primary data file for dataset ID 3918, version 11
% File:bats_ctd_v011_update.txt
% Creation date: 3 December 2025
% Data date (cruise) limits: December 1988(cruise 10001) - June 2025 (cruise 10428)
%
% Will parse out the BCO-DMO into individual files as so much of Ruth's
% code is based on that
CTDdatadir = fullfile(datadir,'BCODMOdataset3918_BATS_v11');
CTDprocessedDir = fullfile(datadir,'/processedCTDdata'); %might be a better way to organize these files
%note this is now one file with all the data as a square matrix
CTDdata = fullfile(CTDdatadir,'3918_v11_bats_ctd.csv'); 

%what are you going to use for the season information?
if 1
    %Use the dates defined in the easy-to-read Excel file and convert to
    %the format Ruth uses in her code; update 10 July 2024
    %Use this function to make a MATLAB structure with transition dates
    seasonsFile = fullfile('../BATS_seasons_wKLedits.2026.06.15.xlsx');
    %use this function to reformat the dates, set fName in calcDerivedVariables
    season_dates = reformat_season_dates(seasonsFile) ; 
elseif 0
    %load in an existing file
    %Comment this out...want to be sure that people really want to use old data
    %load('C:\Users\klongnecker\Documents\Dropbox\GitHub\data_pipeline\MATLAB_code\Season_dates_NOTcurrent.mat');
else
    % define season transition dates from glider DAvg plots and save....
    % If glider not available can use general dates:  15-Dec: 01-Apr : 20-Apr : 01-Nov
    % and check against Hydrostation MLD and DCM 
     season_dates = struct();
        season_dates.mixed = [datenum('15-Dec-2015'), datenum('01-Apr-2016');...
                              datenum('22-Nov-2016'), datenum('10-Apr-2017');...
                              datenum('01-Jan-2018'), datenum('05-Apr-2018');...
                              datenum('15-Dec-2018'), datenum('27-Mar-2019');...
                              datenum('06-Dec-2019'), datenum('01-Apr-2020');...
                              datenum('15-Dec-2020'), datenum('01-Apr-2021');...  
                              datenum('26-Nov-2021'), datenum('05-Apr-2022');...
                              datenum('15-Dec-2022'), datenum('01-Apr-2023')];
        season_dates.spring = [datenum('01-Apr-2016'),datenum('20-Apr-2016');...
                              datenum('10-Apr-2017'), datenum('26-Apr-2017');...
                              datenum('05-Apr-2018'), datenum('26-Apr-2018');...
                              datenum('27-Mar-2019'), datenum('18-Apr-2019');...
                              datenum('01-Apr-2020'), datenum('15-Apr-2020');...
                              datenum('01-Apr-2021'), datenum('25-Apr-2021');...
                              datenum('05-Apr-2022'), datenum('01-May-2022');...
                              datenum('01-Apr-2023'), datenum('25-Apr-2023')];
        season_dates.strat = [datenum('20-Apr-2016'), datenum('01-Nov-2016');...
                              datenum('26-Apr-2017'), datenum('01-Oct-2017');...
                              datenum('26-Apr-2018'), datenum('01-Nov-2018');...
                              datenum('18-Apr-2019'), datenum('06-Nov-2019');...
                              datenum('15-Apr-2020'), datenum('01-Nov-2020');...
                              datenum('25-Apr-2021'), datenum('20-Oct-2021');...
                              datenum('01-May-2022'), datenum('01-Nov-2022');...
                              datenum('25-Apr-2023'), datenum('01-Nov-2023')];
        season_dates.fall = [datenum('01-Nov-2016'), datenum('22-Nov-2016');...
                              datenum('01-Oct-2017'), datenum('01-Jan-2018');...
                              datenum('01-Nov-2018'), datenum('15-Dec-2018');...
                              datenum('06-Nov-2019'), datenum('06-Dec-2019');...
                              datenum('01-Nov-2020'), datenum('15-Dec-2020');...
                              datenum('20-Oct-2021'), datenum('26-Nov-2021');...
                              datenum('01-Nov-2022'), datenum('15-Dec-2022');...
                              datenum('01-Nov-2023'), datenum('15-Dec-2023')];
end



% %%%%%%%%%%%%%%%% There should be no need to make changes below this point
% %%%%%%%%%%%%%%%% Krista Longnecker, updated 15 June 2026
% %%%%%%%%%%%%%%%%

%read in the CTD data as a table
C = readtable(CTDdata);

do_plots = 0; %set this to 1 if you want plots - unlikely for a large number of cruises

% how many unique cruises are there? Will go through each cruise one at a time
uniqueCruises = unique(C.Cruise_num);

for ii = 1:length(uniqueCruises)    
   %find the rows for one cruise
   k = find(C.Cruise_num == uniqueCruises(ii)); 
   oneCruise = C(k,:);
   CTD = create_BATS_ctd_files(oneCruise,season_dates,do_plots,CTDprocessedDir); %update KL 6/12/2026

   cd(CTDprocessedDir)
   fmt = '%4d%02d%02d_%1d%04d_CTD.mat';
   outfile = sprintf(fmt,CTD.year(1),CTD.month(1),CTD.day(1),CTD.type(1),CTD.cruise(1));
   disp(['Writing ',outfile]);
   save(outfile,'CTD');
end

%  Check fluor profiles for bad data   (None!) 
cd(CTDdatadir)
dirlist = dir('*_CTD.mat');
icru_bad =[];

for ii=1:length(dirlist)
    fname = dirlist(ii).name;
    load(fname);
    icast_bad = [];
     for iprof = 1:length(CTD.cast)
        if any(find(CTD.fluor_filt(:,iprof) > 1 | CTD.fluor_filt(:,iprof) < -0.05))
            icru_bad = [icru_bad; CTD.BATS_id(iprof) ];
            disp([num2str(CTD.BATS_id(iprof)),' cast # ',num2str(CTD.cast(iprof))])
        end
     end
end
    

