###This R code is for merging new bottlefile data into existing master bottlefile
##adopted from old R code "Join_BATS_ALL_with_master.R" by Shuting Liu ( July 2022, )
# updated by Shuting on Oct 20, 2023 to add more automatic functional and reduce the manual editing 
# Krista Longnecker, update to pull BATS cast details from the updated discrete file...
# Krista Longnecker, tidying up 21 January 2024
# Krista Longnecker, 26 January 2024 change sheet name to 'DATA' (was 'BATS_BS bottle file')
# Krista, 17 May 2024, adding points to help set the path
# Krista, 27 January 2025 correcting typo in section setting the nominal depths
# 
# Some notes from Krista: 
# (1) you will need to update the path information and file names up through row ~40 in this code. 
# There should be no need to change anything past that point.
# (2) This script will open a single worksheet in Excel - the rows there need to be
# appended to the end of the existing bottle file; you should also update the log in the bottle
# file before saving the resulting Excel file with a new date

rm(list =ls.str())

library(dplyr)
library(readxl)

##first, set the path. 
# if you are on a Mac, your path will be something like this --> /users/klongnecker
# if you are on a PC, your path will be something like this --> c:/users/klongnecker
OS <- .Platform$OS.type

if (OS == "unix"){
  # MAC file path
  dPath <- "/Users/ehalewood/Desktop/BIOSSCOPE_working/" 
} else if (OS == "windows"){
  # windows file path
  dPath <- "C:/Users/ehalewood/Desktop/BIOSSCOPE_working/"
} else {
  #something went wrong...could not determine the operating system
  print("ERROR: OS could not be identified")
}

#read in the existing discrete file so that you know what you are matching the columns to
#read in the master file - which is currently an Excel file
fName <- "BATS_BS_COMBINED_MASTER_latest.xlsx"
sheetName <- 'DATA' #updating, Krista keeps typing this wrong! was: BATS_BS bottle file

##get the header information for the CTD data; KL used CTD ID.docx in 91614 folder in
#"ORIG CTD FROM BATS", to make a text file that now sits at GitHub
#gDir <- "C:/Users/klongnecker/Documents/Dropbox/GitHub/data_pipeline/"
#headers <- read.csv(paste0(gDir,"CTD_headerInformation.csv"),sep=",", fileEncoding="UTF-8-BOM", header=F)

gDir <- ("/Users/ehalewood/Desktop/BIOSSCOPE_working/") 
headers <- read.csv(paste0(gDir,"CTD_headerInformation.csv"),sep=",", fileEncoding="UTF-8-BOM", header=F)

cruiseType <- 'BIOSSCOPE' #or BIOSSCOPE #change as needed

# where is the working directory with the new CTD data (will have been downloaded from Google Drive)
newDir <- ("/Users/ehalewood/Desktop/BIOSSCOPE_working/")







########## should not need to update anything below this point
########## Krista Longnecker, 21 January 2024


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

# now, need the new CTD data, it's easiest to change to the working directory (variable defined above)
setwd(newDir)


#different code for BATS vs. BIOSSCOPE cruise
if (cruiseType=='BATS'){
  ##BATS makes a physf file for the BIOSSCOPE project
  #get the list of folders - will go into each folder one at a time and concatenate the results
  D <- dir(pattern = "*BIOSSCOPE_physf*",recursive=T)
} else if (cruiseType=='BIOSSCOPE') {
  D <- dir(pattern = "*_physf*",recursive=T)
}


#now make this a loop - go through one folder of CTD data at a time
for (a in 1:length(D)) {

  ##read in one CTD data file and separate into columns
  new<-read.delim(D[[a]],header=F,sep="")
  
  #put the headers in so I know what is what
  colnames(new) <- headers
  
  check = new$Niskin_ID[1]

  if (!is.na(match(check,discrete$ID))){
    stop("Something is wrong, this sample is already in discrete data file'")
  }
  rm(check)


  #Delete columns to match same columns on BIOSSCOPE Master bottlefile, we use _in data
  #this will remove the entire column from the information in new
  toDelete <-  c("YYYYMMDD_out","Year_day_in","Time_out(GMT)","Lat(N)_out","Long(W)_out","flag","wet_salt2","Wet_O2_1","Wet_O2_2","Wet_O2_3","Oxy_anom2(umol/kg)","Oxy_anom3(umol/kg)")
  new<- new[, -which(colnames(new) %in% toDelete)]
  rm(toDelete) #remove toDelete to keep this clean
  
  #now edit new file column name match master column name, code was this:
  #colnames(new)<-c("New_ID","yyyymmdd","decy","time(UTC)","latN","lonW","Pressure(dbar)","Depth","Temp","CTD_SBE35T(degC)","Conductivity(S/m)","CTD_S","O2(umol/kg)","BAC(m-1)","Fluo(RFU)","PAR","Pot_Temp(degC)","sig_theta(kg/m^3)","salt","Nisken_temp (degC)","Oxy_Anom1(umol/kg)")
  #let's be more explicit about this so I am sure that everything ends up in the right place
  #long...but makes my head spin less 
  idx <- which(colnames(new) %in% "Niskin_ID")
  colnames(new)[idx] <- "New_ID"
  
  idx <- which(colnames(new) %in% "YYYYMMDD_In")
  colnames(new)[idx] <- "yyyymmdd"
  
  idx <- which(colnames(new) %in% "Dec_yr_in")
  colnames(new)[idx] <- "decy"
  
  idx <- which(colnames(new) %in% "Time_in(GMT)")
  colnames(new)[idx] <- "time(UTC)"
  
  idx <- which(colnames(new) %in% "Lat(N)_in")
  colnames(new)[idx] <- "latN"
  
  idx <- which(colnames(new) %in% "Long(W)_in")
  colnames(new)[idx] <- "lonW"
  
  idx <- which(colnames(new) %in% "P(dbar)")
  colnames(new)[idx] <- "Pressure(dbar)"
  
  idx <- which(colnames(new) %in% "z(m)")
  colnames(new)[idx] <- "Depth"
  
  idx <- which(colnames(new) %in% "CTD_temp(degC)")
  colnames(new)[idx] <- "Temp"
  
  idx <- which(colnames(new) %in% "CTD_SBE35T(degC)")
  colnames(new)[idx] <- "CTD_SBE35T(degC)"
  
  idx <- which(colnames(new) %in% "Cond(S_m)")
  colnames(new)[idx] <- "Conductivity(S/m)"
  
  idx <- which(colnames(new) %in% "CTD_salt")
  colnames(new)[idx] <- "CTD_S"
  
  idx <- which(colnames(new) %in% "DO(umol/kg)")
  colnames(new)[idx] <- "O2(umol/kg)"
  
  idx <- which(colnames(new) %in% "BAC(m-1")
  colnames(new)[idx] <- "BAC(m-1)"
  
  idx <- which(colnames(new) %in% "Fl(RFU)")
  colnames(new)[idx] <- "Fluo(RFU)"
  
  idx <- which(colnames(new) %in% "PAR(uE/m^2)")
  colnames(new)[idx] <- "Par"
  
  idx <- which(colnames(new) %in% "Pot_Temp(degC)")
  colnames(new)[idx] <- "Pot_Temp(degC)"
  
  idx <- which(colnames(new) %in% "sig_theta(kg/m^3)")
  colnames(new)[idx] <- "sig_theta(kg/m^3)"
  
  idx <- which(colnames(new) %in% "wet_salt1")
  colnames(new)[idx] <- "salt"
  
  idx <- which(colnames(new) %in% "Nisken_temp(degC)")
  colnames(new)[idx] <- "Niskin_temp (degC)"
  
  idx <- which(colnames(new) %in% "Oxy_anom1(umol/kg)")
  colnames(new)[idx] <- "Oxy_Anom1(umol/kg)"
  
  rm(idx)
  
  #add new columns, will be the same variable multiple times
  new$Program<-rep(cruiseType, nrow(new))  #change to "BATS" if merging new BATS cruises
  
  ##this next bit makes New_ID which will be needed in the discrete data file...
  ## again, different code for BIOSSCOPE cruise vs. BATS cruise
  if (cruiseType=='BIOSSCOPE') { 
    #Shuting's syntax for a BIOS-SCOPE cruise
    new$Cruise_ID<-paste("AE",substr(new$New_ID,2,5),sep="")
  
    #add cast information
    for (i in 1:nrow(new)){
      if (substr(new$New_ID[i],7,7)=="0"){
        new$Cast[i]=substr(new$New_ID[i],8,8)
      } else{
        new$Cast[i]=substr(new$New_ID[i],7,8)
      }
    }
    rm(i)
    
    #add Niskin information
    for (i in 1:nrow(new)){
      if (substr(new$New_ID[i],9,9)=="0"){
        new$Niskin[i]=substr(new$New_ID[i],10,10)
      } else{
        new$Niskin[i]=substr(new$New_ID[i],9,10)
      }
    }
    rm(i)
    
    #New_ID start with 9 for BIOSSCOPE cruise and only BIOSSCOPE cruises have different ID and New_ID
    new$ID<-paste("BS",new$Cruise_ID,".",new$Cast,".",new$Niskin,sep="") 
    
    
  } else if (cruiseType=='BATS') {
    #first, use convertBATS2 to find the matching cruise_ID; first 5 chars in this:
    bi <- substr(D[[a]],1,5)
    m <- which(convertBATS2$Cruise %in% bi)
    new$Cruise_ID <- rep(convertBATS2$Cruise_ID[m],nrow(new))
    rm(bi,m)
  
    
    #all BATS cruises have same New_ID and ID
    new$ID <- new$New_ID
    #add cast, niskin information
    for (i in 1:nrow(new)){
      if (substr(new$New_ID[i],7,7)=="0"){
        new$Cast[i]=substr(new$New_ID[i],8,8)
      } else{
        new$Cast[i]=substr(new$New_ID[i],7,8)
      }
    }
    rm(i)
    
    for (i in 1:nrow(new)){
      if (substr(new$New_ID[i],9,9)=="0"){
        new$Niskin[i]=substr(new$New_ID[i],10,10)
      } else{
        new$Niskin[i]=substr(new$New_ID[i],9,10)
      }
    }
    rm(i)
    
  }
  
  #add Nominal_Depth, depend on each cruise, this range may need to change, check cast sheets
  #set up a column of -990 first (have some depths that are not in Shuting's preset list below)
  Nominal_Depth <- rep(-999,1,nrow(new))
  new <- cbind(new,Nominal_Depth)
  rm(Nominal_Depth)

  for (j in 1:nrow(new)){
    if (new$Depth[j]<7){
      new$Nominal_Depth[j]=1
    } else if (new$Depth[j]<23 & new$Depth[j]>18){
      # if (j <- 3)
      #   browser()
      new$Nominal_Depth[j]=20
    } else if (new$Depth[j]<43 & new$Depth[j]>38){
      new$Nominal_Depth[j]=40
    } else if (new$Depth[j]<53 & new$Depth[j]>48){
      new$Nominal_Depth[j]=50
    } else if (new$Depth[j]<63 & new$Depth[j]>57){
      new$Nominal_Depth[j]=60
    } else if (new$Depth[j]<83 & new$Depth[j]>78){
      new$Nominal_Depth[j]=80
    } else if (new$Depth[j]<92 & new$Depth[j]>87){
      new$Nominal_Depth[j]=90
    } else if (new$Depth[j]<98 & new$Depth[j]>92){
      new$Nominal_Depth[j]=95
    } else if (new$Depth[j]<102 & new$Depth[j]>98){
      new$Nominal_Depth[j]=100
    } else if (new$Depth[j]<107 & new$Depth[j]>102){
      new$Nominal_Depth[j]=105
    } else if (new$Depth[j]<113 & new$Depth[j]>107){
      new$Nominal_Depth[j]=110
    } else if (new$Depth[j]<118 & new$Depth[j]>113){
      new$Nominal_Depth[j]=115
    } else if (new$Depth[j]<123 & new$Depth[j]>118){
      new$Nominal_Depth[j]=120
    } else if (new$Depth[j]<133 & new$Depth[j]>128){
      new$Nominal_Depth[j]=130
    } else if (new$Depth[j]<143 & new$Depth[j]>138){
      new$Nominal_Depth[j]=140
    } else if (new$Depth[j]<163 & new$Depth[j]>158){ #correcting 1/27/2025 was '518', not '158'
      new$Nominal_Depth[j]=160
    } else if (new$Depth[j]<203 & new$Depth[j]>198){
      new$Nominal_Depth[j]=200
    } else if (new$Depth[j]<253 & new$Depth[j]>248){
      new$Nominal_Depth[j]=250
    } else if (new$Depth[j]<304 & new$Depth[j]>298){
      new$Nominal_Depth[j]=300
    } else if (new$Depth[j]<505 & new$Depth[j]>497){
      new$Nominal_Depth[j]=500
    } else if (new$Depth[j]<805 & new$Depth[j]>797){
      new$Nominal_Depth[j]=800
    } else if (new$Depth[j]<858 & new$Depth[j]>853){
      new$Nominal_Depth[j]=855
    } else if (new$Depth[j]<1007 & new$Depth[j]>998){
      new$Nominal_Depth[j]=1000
    } else if (new$Depth[j]<2003 & new$Depth[j]>1998){
      new$Nominal_Depth[j]=2000
    } else if (new$Depth[j]<2605 & new$Depth[j]>2598){
      new$Nominal_Depth[j]=2600
    }                                      
  }
  rm(j)
  
  # comment this out - may be useful later, but for now it's not needed
  # #note some casts (AE2315 C1,C5,C8) annotate surface as 5m nominal_depths instead of 1m, check cast sheets
  # new$Nominal_Depth[which(new$Cruise_ID=="AE2315"& (new$Cast==1 |new$Cast==5|new$Cast==8))]=5
  # #add empty OxFix column
  # new$OxFix<-rep(-999,nrow(new))
  
  #set up a double check here before moving on - do the columns match OK
  sd <- setdiff(colnames(new),colnames(discrete))
  if (length(sd)>0){
    warning("missing columns, this should be zero if everything is found")
  }
  rm(sd)
  
  #put the unused colnames on the empty rows so that I can merge more easily
  uc <- setdiff(colnames(discrete),colnames(new))
  
  #do this in two steps: expand the size of new to match discrete_match
  b = ncol(new)+1
  e = ncol(discrete)
  new[,c(b:e)]<- -999
  colnames(new)[b:e] <- uc
  rm(b,e,uc)
  
  #now do the shuffle; first match the columns
  col2keep = intersect(colnames(discrete),colnames(new))
  #now figure out how to append the new data to discrete_match
  temp <- new[,(match(col2keep,colnames(new)))]
  
  discrete_match <- rbind(discrete_match,temp)
  
  #tidying up
  rm(new, col2keep, temp)

}
rm(a)

#finally, need an easy way to get these new rows into the existing bottle file
# will open up the new matrix as an Excel file and then just copy into the existing bottle file
library(openxlsx2)

# first, make an empty workbook
wb <- wb_workbook()

#put the updated version of discrete here:
wb$add_worksheet("dataToAdd")

#now that I have updated the discrete data, stick it back into the workbook
wb$add_data("dataToAdd",discrete_match)

#this next line will open up the file in Excel. Sadly you will still have to copy
#and paste into a new sheet, but at least you can copy the whole sheet
xl_open(wb)




# #####Below check duplicate is for some old data note, ignore this section if for new data now
# #if you are merging old BATS data, there are some duplicate rows
# BATS<-read.csv("Copy of bats_bottle.csv",header=T)
# BATS_part<-BATS[BATS$decy.....>=2016.1851,]
# #common column name for merge
# colnames(BATS_part)[1]<-"ID"
# #make sure class between two data frames are same before merging
# class(BATS_part[,1])
# BATS_part[,1]<-as.character(BATS_part[,1])
# #there are duplicate rows in BATS_part which will add rows to master if left_join
# class(master[,1])
# colnames(BATS_part)
# duplicate<-BATS_part[duplicated(BATS_part[,c(1:2)]),]
# #check with master, keep the first four rows in duplicate dataframe, and fifth,sixth row in original dataframe
# BATS_part_nodup<-BATS_part[-c(49478-48803,50153-48803,50155-48803,50164-48803,50839-48803,51026-48803),]#row name is from BATS dataframe
# #########################################








