% Compile BATS/BIOSSCOPE CTD files in .csv and .mat formats
% Add fields to Master Bottle file 
% Original code from Ruth Curry, BIOS / ASU
% Krista Longnecker; updated 10 July 2024
%
% Some notes from Krista (10 July 2024)
% (1) you will need to update the path information and file names
% up through row ~82 in this code. There should be no need to change
% anything past that point.
% (2) The output from this code will be a CSV file that will be saved in
% the place defined at line 29
%
% About the seasons - in June 2024 we received updated season information
% from Ruth, this update takes advantage of the updated season information
% from Ruth and will do so in a way that makes it easy to keep making
% seasonal updates moving forward

%% >>>>>   % add ./BIOSSCOPE/CTD_BOTTLE/mfiles into matlab path
addpath(genpath('C:\Users\klongnecker\Documents\GitHub\BATSallTime\MATLAB_code\mfiles')); %This is KL's laptop

%% update the folder information before getting started
%all path information will begin with the rootdir
rootdir = 'C:\Users\klongnecker\Documents\Dropbox\Current projects\Kuj_BIOSSCOPE\RawData\';

%use the workdir to temporarily hold your CTD data
workdir = fullfile(rootdir,'CTDdata\BSworkingCurrent\');

%use the CSVoutdir as a place to export your CSV file at the end
CSVoutdir = 'C:\Users\klongnecker\Documents\Dropbox\GitHub\data_pipeline\data_holdingZone\';

%Bfile is the name of the bottle file you downloaded from the Google Drive
Bfile = fullfile(rootdir,'DataFiles_CTDandDiscreteSamples/BATS_BS_COMBINED_MASTER_latest.xlsx');

%what are you going to use for the season information?
if 1
    %Use the dates defined in the easy-to-read Excel file and convert to
    %the format Ruth uses in her code; update 10 July 2024
    %Use this function to make a MATLAB structure with transition dates
    seasonsFile = fullfile('BATS_seasons_wKLedits.2024.07.05.xlsx');
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



%%%%%%%%%%%%%%%% There should be no need to make changes below this point
%%%%%%%%%%%%%%%% Krista Longnecker, updated 19 January 2024
%%%%%%%%%%%%%%%%

%start with the code to make one txt file for each cruise
cd(workdir)
D = dir();

%KL commenting out this next line...I think it will leave me an empty
%directory 2/8/2024
%D(~[D.isdir]) = []; %syntax from MATLAB central, removes anything not a directory
dirlist = D(3:end); %this skips over the directories . and ..
clear D 

subdirinfo = cell(length(dirlist));
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
          clear riFile
      end
      clear one
  end
  clear aa 
end
clear a

%%  start by loading and labeling CTD data
cd(workdir);
dirlist = dir('*_ctd.txt');
new_cruises = cat(1,dirlist.name); %KL adding 1/4/2024
%cd(workdir);

MAXZ = 2500;  % row dimension for CTD profiles

nfiles = length(dirlist);

    for ii = 1:nfiles

       fname = dirlist(ii).name;
       infile = fullfile(workdir,fname);
       newdir = fullfile(workdir,fname(1:end-8));
       mkdir(newdir);
       cd(newdir);

       do_plots = 0;
       CTD = create_BIOSSCOPE_ctd_files(infile,MAXZ,season_dates,do_plots);
       movefile('CRU*',workdir);

       cd(workdir)
       fmt = '%4d%02d%02d_%1d%04d_CTD.mat';
       outfile = sprintf(fmt,CTD.year(1),CTD.month(1),CTD.day(1),CTD.type(1),CTD.cruise(1));
       disp(['Writing ',outfile]);
       save(outfile,'CTD');
    end
    
%  Check fluor profiles for bad data   (None!) 
    cd(workdir)
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
    
%%  Load the bottle file and create an output structure to store new info 
disp(['Loading ',Bfile]);

sheetName = 'DATA'; %put this down here, updated February 2024 
BB = readtable(Bfile,'sheet',sheetName,'ReadVariableNames',true);
varNames = BB.Properties.VariableNames';
[nrows,ncols] = size(BB);

% extract columns needed to match bottle and ctd casts
s=strcmp(varNames,'New_ID');
icol.batsID= find(s==1,1);
s=strcmp(varNames,'Cruise_ID');
icol.cruiseID= find(s==1,1);
s=strcmp(varNames,'Cast');
icol.cast= find(s==1,1);
s=strcmp(varNames,'Niskin');
icol.niskin= find(s==1,1);
s=strcmp(varNames,'yyyymmdd');
icol.idate= find(s==1,1);
s=strcmp(varNames,'latN');
icol.lat= find(s==1,1);
s=strcmp(varNames,'lonW');
icol.lon= find(s==1,1);
s=strcmp(varNames,'Depth');
icol.depth= find(s==1,1);

%  create a struct with fields for new variables and unique cast/bottle id
%  from existing spreadsheet.  All fields are numeric values
XX = ones(nrows,1) .* -999;
BBadd = struct();
BBadd.New_ID = BB{:,icol.batsID};
BBadd.Cast = BB{:,icol.cast};
BBadd.Niskin = BB{:,icol.niskin};
BBadd.Depth = BB{:,icol.depth};
BBadd.yyyymmdd = BB{:,icol.idate};
BBadd.Sunrise = XX;
BBadd.Sunset = XX;
BBadd.MLD_dens125 = XX;
BBadd.MLD_bvfrq = XX;
BBadd.MLD_densT2 = XX;
BBadd.DCM = XX;
BBadd.VertZone = XX;
BBadd.Season = XX;
clear XX s

%%  Loop through file, cruise by cruise

cruises = BB{:,icol.cruiseID};  %string table var converts to cells
crulist = unique(cruises);
ncru = length(crulist);

for icru = 1:ncru
    theCru = crulist{icru};     % converts cell to a string
    isCru = strcmp(theCru,cruises);
    
    % open corresponding CTD cruise file

    ii = find(isCru == 1,1);
    theID = floor(BBadd.New_ID(ii) * 1e-5);

    cd(workdir)
    dirlist = dir(['*',num2str(theID),'_CTD.mat']);
    if isempty(dirlist)
        disp(['WARNING: No CTD cruise file for ',['CRU_',num2str(theID),'_CTD.mat']]);
        continue
    end
    fname = dirlist.name;
    disp(['Loading ',fname])
    load(fname);

    % use logical indexing to find cruise/cast match
    castlist = unique(BB{isCru,icol.cast});
    ncast = length(castlist);
    
    for icast = 1:ncast
        theCast = castlist(icast);
        castIndx = isCru & BBadd.Cast == theCast;
        ictd = find(CTD.cast == theCast);
        if isempty(ictd)
            disp(['WARNING: no CTD cast found for bottle cast ',theCru,' Cast #',num2str(theCast)]);
            continue
        end
        if ~isempty(ictd)
            CTD.DCM(isnan(CTD.DCM)) = -999;  % change any NaN values to missing 
            istart = find(castIndx == 1,1); 
            iend = find(castIndx == 1,1,'last');
            for ibtl = istart:iend
                zlev = BB{ibtl,icol.depth};  %
                if zlev > 0    % skip bottles where depth is undefined                
                    BBadd.Sunrise(ibtl) = floor(CTD.Sunrise(ictd));
                    BBadd.Sunset(ibtl) = floor(CTD.Sunset(ictd));
                    BBadd.Season(ibtl) = CTD.Season(ictd);
                    BBadd.MLD_dens125(ibtl) = CTD.MLD_dens125(ictd);
                    BBadd.MLD_bvfrq(ibtl) = CTD.MLD_bvfrq(ictd);
                    BBadd.MLD_densT2(ibtl) = CTD.MLD_densT2(ictd);
                    BBadd.DCM(ibtl) = CTD.DCM(ictd);

                    ictdlev = find(CTD.de(:,ictd) >= zlev,1,'first');
                    if isempty(ictdlev)
                        disp(['For bottle depth: ',num2str(zlev),' Using max CTDdepth: ', num2str(max(CTD.de(:,ictd))),' ',num2str(BBadd.New_ID(ibtl))]);
                        ictdlev = find(~isnan(CTD.de(:,ictd)),1,'last');
                    end
                    BBadd.VertZone(ibtl) = CTD.vertZone(ictdlev,ictd);
                    if isnan(CTD.vertZone(ictdlev,ictd))
                        disp('NaN value for vertZone')
                    end
                end
            end
        end
    end
    
      
    clear CTD
end  %for icru

cd(workdir);

newfile = fullfile(CSVoutdir,'ADD_to_MASTER_temporary.csv');   % output file
disp(['writing table to ', newfile])
BBtab = struct2table(BBadd);

if 1
    %add option to trim down BBtab to only include new additions
    %Krista, January 2024
    keep = double.empty;
    %get the five digit BATS cruise numbers from new_cruises
    for a = 1:size(new_cruises,1)
        one = new_cruises(a,1:5);
        s = contains(string(BBtab.New_ID),one);
        ks = find(s==1);
        keep = cat(1,keep,ks);
        clear one s ks
    end
    clear a
    
    forExport = BBtab(keep,:);
    writetable(forExport,newfile);
else
    %export everything - will match the number of rows in the discrete file
    writetable(BBtab,newfile);
end



