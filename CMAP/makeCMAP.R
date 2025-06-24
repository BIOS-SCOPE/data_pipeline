#write up a script to convert the BIOS-SCOPE data to the required format for CMAP
# Krista Longnecker, 23 June 2025

library(dplyr)
#there are multiple options for reading/writing Excel files, use this version first
library(readxl) #use this to read in the master file
library(lubridate)

#set up the right path for the discrete data file, this varies by operating system and computer
OS <- .Platform$OS.type
if (OS == "unix"){
  # MAC file path - change to what works on your computer
  dPath <- "/users/klongnecker/" 
} else if (OS == "windows"){
  # windows file path - change to what works on your computer
  dPath <- "C:/Users/klongnecker/Documents/Dropbox/Current projects/Longnecker_BIOSSCOPE/" 
} else {
  #something went wrong...could not determine the operating system
  print("ERROR: OS could not be identified")
}

#start with the name of file that will be the end result of all this
fName_CMAP <- "BIOSSCOPE_data_latest.xlsx"

##need the existing discrete file (Excel file that is *not* on GitHub, update to your own path)
fName <- "BATS_BS_COMBINED_MASTER_latest.xlsx"

#read in the data from the existing bottle file 
discrete <- suppressWarnings(read_excel(paste0(dPath,fName),sheet = 'DATA'))

#will also need the variable information from the discrete file as well
#We will need to add some information to the discrete file in order to meet CMAP's guidelines
wbVar = suppressWarnings(read_excel(paste0(dPath,fName),
                                              sheet = 'Bottle File Header',
                                              skip = 3))

##start by gathering up the data from the project
##start by gathering up the data from the project
##start by gathering up the data from the project
##first, read in the dataset template from CMAP: use that as the base for file with BIOS-SCOPE data
fName <- "datasetTemplate.xlsx"
cmap <- suppressWarnings(read_excel(fName,sheet = 'data'))

#pull the column names from cmap and use to make a new dataframe with what I need
cols <- colnames(cmap)[1:4] #remaining are generic
df <- as.data.frame(matrix(ncol = length(cols), nrow = dim(discrete)[1], dimnames = list(NULL, cols)))

#required variables are time,lat,lon,depth
#time --> CMAP requirement is this: #< Format  %Y-%m-%dT%H:%M:%S,  Time-Zone:  UTC,  example: 2014-02-28T14:25:55 >
#do this in two steps so I can check the output more easily
temp <- discrete %>% mutate(date = date_decimal(decy)) %>% mutate(date_cmap=format(date,"%Y-%m-%dT%H:%M:%S"))
df$time <- temp$date_cmap
rm(temp)

#lat (-90 to 90) and lon (-180 to 180)
df$lat <- discrete$latN
df$lon <- -discrete$lonW #note negative to go from W to decimal
df$depth <- discrete$Depth

#all remaining columns can be considered data (may do some trimming later for times)
discrete_trim <- subset(discrete,select=-c(latN,lonW,Depth))

#df is the assembled data
df <- cbind(df,discrete_trim)

#now move to the details about the variables
#now move to the details about the variables
#now move to the details about the variables
#get the metadata requested for each variable from the CMAP dataset template
sheetName <- "vars_meta_data"
vars <- suppressWarnings(read_excel(fName,sheet = sheetName))

#pull the column names from cmap and use to make a new dataframe with what I need
nVars = dim(wbVar)[1] #already skipped the empty rows at the top
cols <- colnames(vars)
df2 <- as.data.frame(matrix(ncol = length(cols), nrow = nVars, dimnames = list(NULL, cols)))
#now populate this dataframe with information about the variables
#this is only a partial list of variables for the moment
df2$var_short_name <- wbVar$Header
df2$var_long_name <- wbVar$Description
df2$var_sensor <- 'need this'
df2$var_unit <- wbVar$Unit


#finally gather up the dataset_meta_data
#finally gather up the dataset_meta_data
#assemble the details here, might setup in a separate text file later
df3 <- data.frame(dataset_short_name = 'tblBIOSSCOPE_v1')
df3$dataset_long_name	<- 'BIOS-SCOPE discrete sample data'
df3$dataset_version	<- 'v1'
df3$dataset_release_date	<- '2025-06-25'
df3$dataset_make	<- 'observation'
df3$dataset_source	<- 'BIOS' #? UCSB? multiple?
df3$dataset_distributor	<- 'BIOS-SCOPE project team'
df3$dataset_acknowledgement	<- 'We thank the BIOS-SCOPE project team and the BATS team for assistance with sample collection, processing, and analysis. The efforts of the captains, crew, and marine technicians of the R/V Atlantic Explorer are a key aspect of the success of this project This work supported by funding from the Simons Foundation International'
df3$dataset_history	<- 'not applicable'
df3$dataset_description	<- 'Data from discrete samples collected during the BIOS-SCOPE project from 2016 until 2025'
df3$dataset_references	<- 'Data from 2016 until 2019 are also available at BCO-DMO as DOI:10.26008/1912/bco-dmo.861266.1 '
df3$climatology	<- 0

#get the list of cruise names from here:
t <- as.list(unique(discrete$Cruise_ID))
df3$cruise_names <- toString(t)
rm(t)

# #before moving on, tidy up and remove this package
detach("package:readxl",unload=TRUE)

#this next library is better at writing files, particularly those files that have multiple worksheets
library(openxlsx)
dataset_names <- list('data' = df, 'dataset_meta_data' = df3, 'vars_meta_data' = df2)
write.xlsx(dataset_names, file = fName_CMAP)

