#checking the calculated values, I know I have issues in at least one cruise
#Krista 26 August 2026

rm(list =ls.str())

library(dplyr)
library(readxl)

##first, set the path. This folder is NOT synced to GitHub.
# if you are on a Mac, your path will be something like this --> /users/klongnecker
# if you are on a PC, your path will be something like this --> c:/users/klongnecker
OS <- .Platform$OS.type

if (OS == "unix"){
  # MAC file path
  dPath <- "/users/klongnecker/" 
} else if (OS == "windows"){

  # windows file path
  dPath <- "D:/Dropbox/GitHub_niskin/data_pipeline/RawData/"

} else {
  #something went wrong...could not determine the operating system
  print("ERROR: OS could not be identified")
}

#read in the existing discrete file so that you know what you are matching the columns to
fName <- "BATS_BS_COMBINED_MASTER_latest.xlsx"

sheetName <- 'DATA' #updated to a simple name as Krista keeps typing this wrong! was: BATS_BS bottle file

##get the header information for the CTD data; KL used CTD ID.docx in 91614 folder in
#"ORIG CTD FROM BATS", to make a text file that now sits at GitHub
gDir <- "D:/Dropbox/GitHub_niskin/data_pipeline/"
headers <- read.csv(paste0(gDir,"CTD_headerInformation.csv"),sep=",", fileEncoding="UTF-8-BOM", header=F)

# cruiseType <- 'BATS' #either BIOSSCOPE or BATS #set below based on Bottle_ID

# where is the working directory with the new CTD data (this folder is NOT synced to GitHub)
newDir <- "D:/Dropbox/GitHub_niskin/data_pipeline/RawData/CTDrelease_20260326"
processedDir <- paste0(gDir,'RawData/processedCTDdata/')



########## should not need to update anything below this point
########## Krista Longnecker, 24 August 2026 


#start reading in the data files, first the existing bottle file

#definitely want suppressWarnings here to prevent one error message for each row
discrete <- suppressWarnings(read_excel(paste0(dPath,fName),
                                        sheet = sheetName,
                                        guess_max = Inf))

#get the BATS cruise information from existing bottle file 
convertBATS2 <- suppressWarnings(read_excel(paste0(dPath,fName),sheet = 'CruisesAndStations'))
convertBATS2$Cruise <- suppressWarnings(as.integer(convertBATS2$Cruise))
rm(dPath,fName,sheetName)

#before moving on, tidy up and remove this package
detach("package:readxl",unload=TRUE)

#cheat and use the existing matrix as a template for the new data to be added 
discrete_match <- discrete[1,]
discrete_match <- discrete_match[-1,]

discrete$cruise5 <- substr(discrete$New_ID,start=1,stop=5)

#will iterate through this: 
df <- discrete %>%
  group_by(cruise5) %>%
  slice(1) %>%
  ungroup() %>%
  select("cruise5","Cast","Sunrise","Sunset","MLD_dens125","MLD_bvfrq","MLD_densT2","DCM","Season")

cf <- data.frame(matrix(NA,nrow = dim(df)[1],ncol=9))
issues <- matrix(NA,nrow = dim(df)[1],ncol = 1)

# now, need the output from the MATLAB code...that is where I seem to have an issue
# iterate through files in the processed CTD data directory and compare what is in the file with what should be in the file
setwd(processedDir)
#D = dir()

for (idx in 1:dim(df)[1]) {
  #inefficient as I will read the same file multiple times...
  if (df$cruise5[idx] != '61319') {
    print(df$cruise5[idx])
    matlab<-read.csv(paste0('CRU_',df$cruise5[idx],'_ctd.csv'),header=T,sep=",")
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
    
    #need iterate through casts
    ma <- which((matlab$cruise5 == df$cruise5[idx]) & (matlab$Cast == df$Cast[idx]))
    cf[idx,] = matlab[ma,]
    
    if (isTRUE(all.equal(df[idx,],matlab[ma,]))) {
      issues[idx] = 'ok'
    } else {
      issues[idx] = 'issue'
    }    
    rm(ma,matlab)    
  }
}
rm(idx)

newdf <- bind_cols(df,cf)

