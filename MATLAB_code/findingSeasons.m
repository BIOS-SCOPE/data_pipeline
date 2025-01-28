%find MLD and DCM in BATS data, by year, decide on seasons
%KL 25 June 2024
clear all 
close all

wDir = 'C:\Users\klongnecker\Documents\Dropbox\Current projects\Kuj_BIOSSCOPE\RawData';
load(strcat(wDir,filesep,'allBATS_findingMLDandDCM_testing.mat'));

%lots of MLD options
MLD = allBATS.MLD_dens125;
k = find(MLD==-999);
MLD(k) = NaN;
clear k

k = find(allBATS.DCM==-999);
allBATS.DCM(k) = NaN;
clear k

%start with one plot (one year); plot time v. MLD and DCM, then see how I
%can do some sort of smoothing to match to Ruth's parameters
uy = unique(year);

ms = 15;
cmap = (cbrewer('qual','Set1',3));

for a = 3
    %k = find(year == uy(a));
    k = find(year == 2018);
    dtm = allBATS.decy(k) - year(k);
    figure(a)
%     plot(dtm,allBATS.DCM(k),'.','markersize',ms,'markerfacecolor',cmap(1,:),...
%         'markeredgecolor',cmap(1,:))
%     hold on
%     plot(dtm,MLD(k),'.','markersize',ms,'markerfacecolor',cmap(3,:),...
%         'markeredgecolor',cmap(3,:))
%     xlim([0.9 12.1])
    ra
%     legend('DCM','MLD')
    set(gcf,'position',[-1151 254 1054 813])
    title(year(k(1)),'fontweight','bold')
    
    x = dtm;
    y = MLD(k);
    i = ~isnan(y);
    x = x(i);
    y = y(i);
       
    fitobject = fit(x,y,'poly4')
    hold on
    h = plot(fitobject,x,y);
    set(h(1),'color',cmap(2,:),'markersize',ms,'displayname','MLD')
    set(h(2),'color',cmap(2,:),'linewidth',5,'displayname','MLD fitted')

    %same for the DCM
    x = dtm;
    y = allBATS.DCM(k);
    i = ~isnan(y);
    x = x(i);
    y = y(i);
    
    fitobject = fit(x,y,'poly4')
    hold on
    hh = plot(fitobject,x,y);
    set(hh(1),'color',cmap(3,:),'markersize',ms,'displayname','DCM')
    set(hh(2),'color',cmap(3,:),'linewidth',5,'displayname','DCM fitted')
    
    line([0 1],[100 100],'color','k','displayname','100m')
    line([0 1],[30 30],'color','k','displayname','30m')
    
    %2018 numbers from Ruth's physical framework PDF
    cmg = flipud(cbrewer('seq','Greys',5));
    [doy,fraction] = date2doy(datenum('4/5/2018'));
    line([fraction fraction],[0 200],'color',cmg(1,:),'linewidth',3,'displayname','mixed ends')

    [doy,fraction] = date2doy(datenum('4/26/2018'));
    line([fraction fraction],[0 200],'color',cmg(2,:),'linewidth',3,'displayname','spring ends')

    [doy,fraction] = date2doy(datenum('10/1/2018'));
    line([fraction fraction],[0 200],'color',cmg(3,:),'linewidth',3,'displayname','stratified ends')

    [doy,fraction] = date2doy(datenum('12/31/2018'));
    line([fraction fraction],[0 200],'color',cmg(4,:),'linewidth',3,'displayname','fall ends')


end



