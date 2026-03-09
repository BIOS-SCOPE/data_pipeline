% Need a new script to prepare the BIOS-SCOPE CTD data for BCO-DMO
% This will be based on existing MATLAB scripts that were written by Ruth
% Curry and Krista Longnecker
% Krista Longnecker; 5 March 2026
%
% Some notes from Krista (5 March 2026)
% (1) This script uses the QC'd data from the BATS team, so the code assumes
% you have already downloaded those files from the BATS team DropBox
% account.
% (2) you will need to update the path information and file names
% up through row ~82 in this code. There should be no need to change
% anything past that point.
% (3) The output from this code will be a CSV file that will be saved in
% the place defined at line XX

%% >>>>>   % add ./BIOSSCOPE/CTD_BOTTLE/mfiles into matlab path
addpath(genpath('D:\Dropbox\GitHub_niskin\data_pipeline\MATLAB_code\mfiles')); %This is KL's computer

%% update the folder information before getting started
% all path information will begin with the rootdir
rootdir = 'D:\Dropbox\GitHub_niskin\data_pipeline\';

%use the datadir to temporarily hold your CTD data (make sure this is
%outside where GitHub syncs as it could be a large folder)
datadir = fullfile(rootdir,'RawData'); %put discrete file here
CTDdatadir = fullfile(rootdir,'RawData\CTDrelease_temp'); %put CTD data here...KEEP name so we know which CTD release we are adding
newfile = fullfile(datadir,'BSdataOnly.2026.03.08.csv');   % output file

%what are you going to use for the season information?
%Use the dates defined in the easy-to-read Excel file and convert to
%the format Ruth uses in her code; new file February 2026
%Use this function to make a MATLAB structure with transition dates
seasonsFile = fullfile('BATS_seasons_wKLedits.2026.02.13.xlsx');
%use this function to reformat the dates, set fName in calcDerivedVariables
season_dates = reformat_season_dates(seasonsFile) ; 


%%%%%%%%%%%%%%%% There should be no need to make changes below this point
%%%%%%%%%%%%%%%% Krista Longnecker, 5 March 2026
%%%%%%%%%%%%%%%%

%make sure the only thing in CTDdatadir is the folders with data...no other files is empty before starting...
delete(fullfile(CTDdatadir,'*.txt'))
delete(fullfile(CTDdatadir,'*.mat'))
delete(fullfile(CTDdatadir,'*.csv'))

%start with the code to make one txt file for each cruise
cd(CTDdatadir)
D = dir();
dirlist = D(3:end); %this skips over the directories . and ..
clear D 

cruisesWithData = str2double({dirlist.name}');

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

%%  start by loading and labeling CTD data, including derived variables
cd(CTDdatadir);
dirlist = dir('*_ctd.txt');
%new_cruises = cat(1,dirlist.name); %KL adding 1/4/2024
%cd(datadir);

% MAXZ = 2500;  % row dimension for CTD profiles...does BIOS-SCOPE ever go deeper? YES
MAXZ = 4005; %BIOS-SCOPE has some deep casts that we need to consider

nfiles = length(dirlist);

for ii = 1:nfiles

   fname = dirlist(ii).name;
   infile = fullfile(CTDdatadir,fname);
   newdir = fullfile(CTDdatadir,fname(1:end-8));
   mkdir(newdir);
   cd(newdir);

   do_plots = 0;
   CTD = create_BIOSSCOPE_ctd_files(infile,MAXZ,season_dates,do_plots);
   movefile('CRU*',CTDdatadir);

   cd(CTDdatadir)
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

%%  Loop through files, cruise by cruise, and concatenate the data from all the cruises into one square matrix
dirlist = dir(['*_CTD.mat']);
 
a = 1;
fname = dirlist(a).name;
disp(['Loading ',fname])
load(fname);
clear fname

%use new KL function to make a square table
exportSquare = convert_RCstructure2square(CTD);

for a = 2:length(dirlist)
    fname = dirlist(a).name;
    disp(['Loading ',fname])
    load(fname);

    %use new KL function to make a square table
    exportSquare = cat(1,exportSquare,convert_RCstructure2square(CTD));
    clear fname
end
clear a

cd(datadir);

%trim some columns, there are items in the discrete file that we do not
%want to export
% ID	New_ID	Program	Cruise_ID	Cast	Niskin	yyyymmdd	decy	time_UTC_	latN	lonW	Depth	Nominal_Depth	Temp	CTD_SBE35T_degC_	Conductivity_S_m_	CTD_S	salt	Pressure_dbar_	sig_theta_kg_m_3_	O2_umol_kg_	OxFix	Oxy_Anom1_umol_kg_	BAC_m_1_	Fluo_RFU_	Par	Pot_Temp_degC_	Niskin_temp_degC_	CO2	alk	NO3_NO2_umol_kg_	NO3_NO2_QF	NO3_umol_kg_	NO3_QF	NO2_umol_kg_	NO2_QF	PO4_umol_kg_	PO4_QF	NH4_umol_kg_	NH4_QF	SiO2_umol_kg_	SiO2_QF	POC_ug_kg_	POC_QF	PON_ug_kg_	PON_QF	TOC_umol_kg_	TOC_QF	DOC_umol_kg_	DOC_QF	TN_umol_kg_	TN_QF	TDN_umol_kg_	TDN_QF	Bact_cells_10_8_kg_	Bact_QF	POP_umol_kg_	POP_QF	TDP_nmol_kg_	TDP_QF	SRP_nmol_kg_	SRP_QF	Bsi_umol_kg_	Bsi_QF	Lsi_umol_kg_	Lsi_QF	Pro_cells_ml_	Pro_QF	Syn_cells_ml_	Syn_QF	Piceu_cells_ml_	Piceu_QF	Naneu_cells_ml_	Naneu_QF	BP_Leu_pmol_L_hr_	BP_Leu_QF	TDAA_nmol_L_	TDAA_QF	Asp_nmol_L_	Glu_nmol_L_	His_nmol_L_	Ser_nmol_L_	Arg_nmol_L_	Thr_nmol_L_	Gly_nmol_L_	Tau_nmol_L_	BAla_nmol_L_	Tyr_nmol_L_	Ala_nmol_L_	GABA_nmol_L_	Met_nmol_L_	Val_nmol_L_	Phe_nmol_L_	Ile_nmol_L_	Leu_nmol_L_	Lys_nmol_L_	lt1_mgC_m_3_day_	lt2_mgC_m_3_day_	lt3_mgC_m_3_day_	dark_mgC_m_3_day_	t0_mgC_m_3_day_	pp_mgC_m_3_day_	V1V2_ID	V4_16s_ID	V4_18s_ID	Sunrise	Sunset	MLD_dens125	MLD_bvfrq	MLD_densT2	DCM	VertZone	Season	p1	p2	p3	p4	p5	p6	p7	p8	p9	p10	p11	p12	p13	p14	p15	Chl__	Phae	p18	p19	p20	p21	Kuj_DOC_umol_kg_	Kuj_TN_umol_kg_	metabolite_accession_number
% toKeep = {'New_ID','Program','Cruise_ID','Cast','yyyymmdd'};

%to do: figure out what format BCO-DMO wants
disp(['writing table to ', newfile])
writetable(exportSquare,newfile)


