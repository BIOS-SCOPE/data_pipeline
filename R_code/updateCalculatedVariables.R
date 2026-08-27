# Use this script to update the dereived values calculated by a MATLAB script.
# When new cruises are added, the new version of the R script does not go back
# and re-enter those values. In other words, if the derived values change as a 
# result of MATLAB reprocessing, this will be useful
# The derived values are: 
# ("Sunrise","Sunset","MLD_dens125","MLD_bvfrq","MLD_densT2","DCM","Season")
# Krista Longnecker 26 August 2026

rm(list =ls.str())

library(dplyr)
library(readxl)

# if you are on a Mac, your path will be something like this --> /users/klongnecker
# if you are on a PC, your path will be something like this --> c:/users/klongnecker

##first, set the path. This folder is NOT synced to GitHub.
dPath <- "D:/Dropbox/GitHub_niskin/data_pipeline/RawData/"

#read in the existing discrete file so that you know what you are matching the columns to
fName <- "BATS_BS_COMBINED_MASTER_latest.xlsx"

sheetName <- 'DATA' #updated to a simple name as Krista keeps typing this wrong! was: BATS_BS bottle file

##get the header information for the CTD data; KL used CTD ID.docx in 91614 folder in
#"ORIG CTD FROM BATS", to make a text file that now sits at GitHub
gDir <- "D:/Dropbox/GitHub_niskin/data_pipeline/"
headers <- read.csv(paste0(gDir,"CTD_headerInformation.csv"),sep=",", fileEncoding="UTF-8-BOM", header=F)

# directory with the processed CTD data from the MATLAB script (this folder is NOT synced to GitHub)
processedDir <- paste0(gDir,'RawData/processedCTDdata/')

#read in the data files, first the existing bottle file
discrete <- suppressWarnings(read_excel(paste0(dPath,fName),
                                        sheet = sheetName,
                                        guess_max = Inf))

#before moving on, tidy up and remove this package
detach("package:readxl",unload=TRUE)

#cheat and use the existing matrix as a template for the new data to be added 
discrete_match <- discrete[1,]
discrete_match <- discrete_match[-1,]

#need the five digit cruise
discrete$cruise5 <- substr(discrete$New_ID,start=1,stop=5)

#Get the unique list of cruises, will use this to load each datafile
uniqueCruises <- discrete %>%
  group_by(cruise5) %>%
  slice(1) %>%
  ungroup() %>%
  select("cruise5") %>%
  filter(cruise5 != '61319') #deal with that individually

# iterate through files in the processed CTD data 
setwd(processedDir)

useCol = c("Sunrise","Sunset","MLD_dens125","MLD_bvfrq","MLD_densT2","DCM","Season")

for (idx in 1:dim(uniqueCruises)[1]) {
    print(uniqueCruises$cruise5[idx]) #use this so I know where I am
  
    matlab<-read.csv(paste0('CRU_',uniqueCruises$cruise5[idx],'_ctd.csv'),header=T,sep=",")
    matlab$cruise5 <- substr(matlab$BATS_id,start=1,stop=5)
    
    matlab <- matlab %>%
      group_by(Cruise,Cast) %>%
      slice(1) %>%
      ungroup() %>%
      select("cruise5","Cast","Sunrise","Sunset","MLD_dens125","MLD_bvfrq","MLD_densT2","DCM","Season") %>%
      mutate(Sunrise = as.double(Sunrise)) %>%
      mutate(Sunset = as.double(Sunset)) %>%
      mutate(Season = as.double(Season)) %>%
      mutate(Cast = as.character(Cast))
    
    matlab <- as.data.frame(matlab)

    for (idx2 in 1:dim(matlab)[1]) {
      #need iterate through casts and put the information into discrete
      ma <- which((matlab$cruise5[idx2] == discrete$cruise5) & (matlab$Cast[idx2] == discrete$Cast))
      if (length(ma) > 0 ) {
        oneRow = matlab[idx2,useCol]
        tr = oneRow[rep(1,length(ma)),]
        discrete[ma,useCol] <- tr
        rm(oneRow,tr)
      }        
      rm(ma)
    }
    rm(idx2)
    rm(matlab)
}
rm(idx)

toUpdate = discrete[,c("New_ID",useCol)]

# finally, need a  way to get the updated columns into the existing bottle file
# will open up the new matrix as an Excel file and then just copy into the existing bottle file
# This needs a different library in R
library(openxlsx2)

# first, make an empty workbook
wb <- wb_workbook()

#put the updated version of discrete here:
wb$add_worksheet("dataToAdd")

#now that I have updated the discrete data, stick it back into the workbook
wb$add_data("dataToAdd",toUpdate)

#this next line will open up the file in Excel. Sadly you will still have to copy
#and paste into a new sheet, but at least you can copy the whole sheet
xl_open(wb)


