#read in all the BATS group sampling logs (BATS, BVal, and Hydrostation)
# to pull all possible sample types
# Krista Longnecker 3 June 2026

library(data.table) # you need to install this package from CRAN
library(dplyr)
library(readr) #this is part of the tidyverse package
library(here) #install this (once, install.packages("here))
#library(tidyverse) #amazing 
library(lubridate) #great for handling date data

library(readxl) #reading excel files
library(purrr)
library(writexl)#Use the following to install castr if it doesnt load above.  See here for details https://rdrr.io/github/jiho/castr/


rm(list = ls()) #start with a clean workspace (better for testing)


baseDir = "D:/Dropbox/GitHub_niskin/data_pipeline/R_code"
# Define the path to the data file
wDir <- "../RawData/BATS & HS CAST SHEETS"

# #three folders in there for BATS, BVal, and HS
# bvalDir <- "BVal Cast Sheets"
# wPath <- paste0(wDir,"/",bvalDir)
# files <- list.files(path = wDir,recursive = TRUE, full.names = TRUE)

# #sometimes there is a file labeled 'BIOS-SCOPE', other times there are just individual cast files that are relevant.
# #start by pulling information from any file labeled 'BIOS-SCOPE'
# patterns <- c("BIOS-SCOPE","H-R DOM","HR_DOM") #some files with a different extension (cruise 10323 and 61319)
# possible <- paste(patterns,collapse="|")
# files <- list.files(path = wDir,pattern = possible,recursive = TRUE, full.names = TRUE)

#Rachel's bacterial is not always collected on the core casts, so we need all sheets
#some of the older files are xls, so filtering on xlsx removes them
files <- list.files(path = wDir,pattern = "xls", recursive = TRUE, full.names = TRUE)


#turns out BATS has a sample type that is listed as a number. Will be easier to 
#merge on that because the names change from sheet to sheet. I will need to confirm
#that I have guess right about the numbers.

#use the first file to set up the dataframe...
idx <- 1

#read in the full file and then search for rows/columns that set the bounds of what we need
# the BATS sampling logs sometimes add things outside that box
temp <- suppressMessages(read_excel(files[idx], .name_repair = ~make.unique(.x, sep = "_"))) #only 2+ instance is renamed
#will always be a row with cast = 0: use that to find the number of header lines
headerToSkip <- (which(temp[,1]==0)) - 1
one <- suppressMessages(read_excel(files[idx], skip=headerToSkip,.name_repair = ~make.unique(.x, sep = "_"))) #only 2+ instance is renamed

#only keep to the second instance of Nisken/Niskin/nisken/niskin
n <- which((one=="Niskin" | one=="Nisken" | one=="niskin" | one=="nisken"),arr.ind=TRUE)
bottomRow <- max(n[,'row'])
rightSide <- max(n[,'col'])

#remove last row (BATS repeats information)
one <- one[-bottomRow,]

#only keep up to the second Niskin column 
one <- one[,1: (rightSide-1)]

one <- one %>% mutate(across(everything(), as.character))

#tidyup
rm(temp,headerToSkip,bottomRow,rightSide)

#add all cast information from the file...need some error checking
# (tidy up names...spelling and match to names/numbers for BIOS-SCOPE samples)
#make all the names lower case as a start
colnames(one) <- tolower(colnames(one))

#definitely a better way to do this, but I am running out of steam
colnames(one) <- gsub("% cast","cruise_cast",colnames(one))
colnames(one) <- gsub("%cast","cruise_cast",colnames(one))
colnames(one) <- gsub("nisken","niskin",colnames(one))
colnames(one) <- gsub("niskin","niskin",colnames(one))

# BATS puts ## of sample type in different row, but that is the one that should match across cruises...
# search for the number and add to column names in main sheet if it does not already exist
k <- which (one[1,] > 0) 

# iterate through all the columns with a number...make a column name if is does not exist
for (idx2 in 1:length(k)) {
  #colnames(one)[k][idx2] <- paste0(colnames(one)[k][idx2],"_",as.character(one[1,k[idx2]])) 
  colnames(one)[k][idx2] <- paste0(as.character(one[1,k[idx2]]) ,"_",colnames(one)[k][idx2]) 
}

#parse cast information into cruise/cast/niskin
one$cruise = substr(as.character(one$cruise_cast),1,5)
one <- one %>% relocate(cruise,.after = cruise_cast)
one$cast = substr(as.character(one$cruise_cast),6,8)
one <- one %>% relocate(cast,.after = cruise)

#now put cruise / cast in row that is zero, use for sorting later
one[1,'cast'] <- one[2,'cast']
one[1,'cruise'] <- one[2,'cruise']

df <- one
rm(one)




## ----doRestFiles

#start with 2 because files[1] was used to setup the matrix

for (idx in 2:length(files)) {
   #read in the full file and then search for rows/columns that set the bounds of what we need
  # the BATS sampling logs sometimes add things outside that box
  temp <- suppressMessages(read_excel(files[idx], .name_repair = ~make.unique(.x, sep = "_"))) #only 2+ instance is renamed
  #will always be a row with cast = 0: use that to find the number of header lines
  h = which(temp[,1]==0 | is.na(temp[,1]))[1] #have both 0 and NA, and rows with comments below the main box
  headerToSkip <- (h) - 1
  one <- suppressMessages(read_excel(files[idx], skip=headerToSkip,.name_repair = ~make.unique(.x, sep = "_"))) #only 2+ instance is renamed
  
  #can have cases where there is cast sheet, but nothing worked...skip those casts
  if (dim(one)[2] < 6) {
    next
  }
  
  

  #only keep to the second instance of Nisken/Niskin/nisken/niskin
  n <- which((one=="Niskin" | one=="Nisken" | one=="niskin" | one=="nisken"),arr.ind=TRUE)

  
  if (rlang::is_empty(n)) {
    
    #don't have the duplicated last row, search colnames for the second Niskin
    v <- tolower(colnames(one))
    rightSide <- which(grepl("nisk",v))[2]
    one <- one[,1: (rightSide-1)]
    rm(v,rightSide)
    
  } else {
    bottomRow <- max(n[,'row'])
    rightSide <- max(n[,'col'])
    #remove last row (BATS repeats information)
    one <- one[-bottomRow,]
    
    #also delete the second Niskin column
    #only keep to rightSide - 1
    one <- one[,1: (rightSide-1) ]   
    rm(bottomRow,rightSide)
  }

  
  one <- one %>% mutate(across(everything(), as.character))
  
  #tidyup
  rm(temp,headerToSkip)

  
  #add all cast information from the file...need some error checking
  # (tidyup names...spelling and match to names/numbers for BIOS-SCOPE samples)
  #make all the names lower case as a start
  colnames(one) <- tolower(colnames(one))
  
  #definitely a better way to do this, but I am running out of steam
  colnames(one) <- gsub("% cast","cruise_cast",colnames(one))
  colnames(one) <- gsub("%cast","cruise_cast",colnames(one))
  colnames(one) <- gsub("nisken","niskin",colnames(one))
  colnames(one) <- gsub("niskin","niskin",colnames(one))
  
  # BATS puts ## of sample type in different row, but that is the one that should match across cruises...
  # search for the number and add to column names in main sheet if it does not already exist
  k <- which (one[1,] > 0) 
  
  # super inefficient, but how my brain is thinking today
  # iterate through all the columns with a number...make a column name if is does not exist
  for (idx2 in 1:length(k)) {
    #colnames(one)[k][idx2] <- paste0(colnames(one)[k][idx2],"_",as.character(one[1,k[idx2]])) 
    colnames(one)[k][idx2] <- paste0(as.character(one[1,k[idx2]]) ,"_",colnames(one)[k][idx2]) 
  }
  
  #parse cast information into cruise/cast/niskin
  one$cruise = substr(as.character(one$cruise_cast),1,5)
  one <- one %>% relocate(cruise,.after = cruise_cast)
  one$cast = substr(as.character(one$cruise_cast),6,8)
  one <- one %>% relocate(cast,.after = cruise)

  #now put cruise / cast in row that is zero, use for sorting later
  one[1,'cast'] <- one[2,'cast']
  one[1,'cruise'] <- one[2,'cruise']
  
  
  df <- bind_rows(df,one)
  rm(one)
  
}




## ----getUnique

# tidy up the df with the sample numbers
df <- df[,order(colnames(df))]
#only keep rows where Cruise_cast is not zero or NA
df <- df[df$cruise_cast != 0,]
df <- df[!is.na(df$cruise_cast),]

df <- df %>% relocate(flag)
df <- df %>% relocate(depth)
df <- df %>% relocate(niskin)
df <- df %>% relocate(cast)
df <- df %>% relocate(cruise)
df <- df[, colSums(is.na(df)) < nrow(df)]
#change zeros to NA
df[df==0] <- NA

#count how many samples of each type were collected
#change  0 to NA
df_counts <- as.data.frame(colSums(df>0,na.rm=TRUE))
df_counts$row_names <- rownames(df_counts)



## export the result as Excel file for the group

write_xlsx(df_counts,'../RawData/counts_all.xlsx')
write_xlsx(df,'../RawData/BIOSSCOPE_BATSsamples_to2024_all.xlsx')


