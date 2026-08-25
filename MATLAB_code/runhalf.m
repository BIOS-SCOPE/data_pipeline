%%  Loop through file, cruise by cruise

cruises = BB{:,icol.cruiseID};  %string table var converts to cells
crulist = unique(cruises);
ncru = length(crulist);

for icru = 1:ncru
    theCru = crulist{icru};     % converts cell to a string
    isCru = strcmp(theCru,cruises); %same size as BBadd, will be one for matches to theCru

    % open corresponding CTD cruise file
    ii = find(isCru == 1,1);
    theID = floor(BBadd.New_ID(ii) * 1e-5);

    cd(CTDdatadir)
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
        castIndx = isCru & strcmp(BBadd.Cast,theCast);

        %comment KL 6/6/2026 ictd = strcmp(CTD.cast,theCast);
        ictd = find(CTD.cast == str2double(theCast));

        if isempty(ictd)
            %disp(['WARNING: no CTD cast found for bottle cast ',theCru,' Cast #',num2str(theCast)]);
            disp(['WARNING: no CTD cast found for bottle cast ',theCru,' Cast #',theCast]); %KL change 6/6/2026
            continue
        end
        if ~isempty(ictd)
            CTD.DCM(isnan(CTD.DCM)) = -999;  % change any NaN values to missing 
            istart = find(castIndx == 1,1); 
            iend = find(castIndx == 1,1,'last');
            for ibtl = istart:iend
                zlev = BB{ibtl,icol.depth};  %
                if zlev > 0    % skip bottles where depth is undefined  
                    if isequal(ibtl,1)
                        %fprintf('here')
                        disp(['The ID ', num2str(theID), ', New_ID: ', num2str(CTD.BATS_id(ictd)),' season:',num2str(CTD.Season(ictd)),' cruise: ',num2str(CTD.cruise(ictd))])
                        fprintf('here')
                    end

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

cd(datadir);

newfile = fullfile(datadir,'ADD_to_MASTER_temporary.csv');   % output file
disp(['writing table to ', newfile])
BBtab = struct2table(BBadd);

%export everything - will match the number of rows in the discrete file
% June 2026 note: with the data coming from BCO-DMO, we will always have
% new and old data together so you MUST export everything
writetable(BBtab,newfile);

