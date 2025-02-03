#recalculate all the nominal depths
#KL 3 February  2025
library(dplyr)
library(readxl) #use this to read in the master file

dPath <- "C:/Users/klongnecker/Documents/Dropbox/Current projects/Longnecker_BIOSSCOPE/" 
fName <- "BATS_BS_COMBINED_MASTER_latest.xlsx"

#read in the existing bottle file (using values from above)
sheetName <- "DATA" #(was "BATS_BS bottle file")
#definitely want suppressWarnings here to prevent one error message for each row
discrete <- suppressWarnings(read_excel(paste0(dPath,fName),
                                        sheet = sheetName,
                                        guess_max=Inf))

#make a new data.frame so I can compare new v. old if needed
discrete_updated <-as.data.frame(discrete)

#Use the code from the makeSynoptic project to generate the nominal depths
discrete_updated$target.depth <- cut(new$Depth, breaks=c(0,7, seq(13,103,10),seq(110,230,20),240,260,
                        seq(275,4225,50),4550), labels=c(1, seq(10,120,10),
                        seq(140,220,20),230,250,275,seq(300,4220,50),4530)) #fills target.depth bins

#need the other library to make a sheet that can be copied into Excel
library(openxlsx2)
wb <- wb_workbook()
wb$add_worksheet("forPasting")
wb$add_data("forPasting",discrete_updated)
xl_open(wb)


