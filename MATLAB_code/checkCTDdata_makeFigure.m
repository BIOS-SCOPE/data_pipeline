%read in the MASTER file with discrete information and make some
%plots...this is a visual check that all went OK
% 21 August 2026 Krista Longnecker
clear all
close all

%% >>>>>   % add ./BIOSSCOPE/CTD_BOTTLE/mfiles into matlab path
addpath(genpath('D:\Dropbox\GitHub_niskin\data_pipeline\MATLAB_code\mfiles')); %This is KL's computer

%% update the folder information before getting started
%all path information will begin with the rootdir
rootdir = 'D:\Dropbox\GitHub_niskin\data_pipeline\';

%use the datadir to temporarily hold your CTD data (make sure this is
%outside where GitHub syncs as it could be a large folder)
datadir = fullfile(rootdir,'RawData'); %put discrete file here

CTDdatadir = fullfile(rootdir,'RawData\CTDrelease_20260326'); %put CTD data here...KEEP name so we know which CTD release we are adding
%CTDdatadir = fullfile('D:\Dropbox\Current projects\Kuj_BIOSSCOPE\RawData\CTDdata\BSworkingCurrent'); %testing

%Bfile is the name of the bottle file you downloaded from the Google Drive
Bfile = fullfile(datadir,'BATS_BS_COMBINED_MASTER_latest.xlsx');

if 1
    %%  Load the bottle file and create an output structure to store new info 
    sheetName = 'DATA'; %put this down here, updated February 2024 
    BB = readtable(Bfile,'sheet',sheetName,'ReadVariableNames',true);
    varNames = BB.Properties.VariableNames';
    [nrows,ncols] = size(BB);
end

%new function in MATLAB (or at least new to me)
BB = standardizeMissing(BB,-999);

k = find(BB.Depth<20);
gscatter(BB.yyyymmdd(k),BB.Temp(k),BB.Season(k),[],[],30)

dt = datetime(BB.yyyymmdd,'ConvertFrom','yyyymmdd');
m = month(dt);

subplot(221)
gscatter(m(k),BB.Temp(k),BB.Season(k),[],[],30)
xlabel('month')
ylabel('temperature')
title('Temperature should be warmer in the summer months')

subplot(223)
gscatter(m(k),BB.MLD_dens125(k),BB.Season(k),[],[],30)
xlabel('month')
ylabel('MLD_dens125')
title('Is MLD reasonably based on season? Colors are season')

subplot(222)
gscatter(m(k),BB.Sunrise(k),BB.Program(k),[],[],30)
xlabel('month')
ylabel('sunrise')
title('Another way to check, sunrise is earlier in the summer months')

subplot(224)
gscatter(BB.lonW(k),BB.latN(k),BB.Program(k),[],[],30)
set(gca,'xdir','reverse')
xlabel('longitude W, note the flip in orientation')
ylabel('latitude')
title('Check lat/lon (+/- values), outliers are likely different in the original data files')
title_up('only plotting samples < 20 m')

set(gcf,'position',[39 207 1204 936])

%save the result for an easy visual check
set(gcf,'paperpositionmode','auto')
saveas(gcf,['visualCheckCTDdata.jpg'],'jpg')

