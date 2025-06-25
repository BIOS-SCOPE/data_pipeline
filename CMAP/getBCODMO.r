# make a script to access data at BCO-DMO, hopefully can use an API to get what I want
# KL 25 June 2025

#API is listed on website as in progress, so seems like I will have to gather the data manually

#BIOS-SCOPE discrete data are here: 
wPage <- 'https://datadocs.bco-dmo.org/file/KAAGNEBc2V61jx/survey_biogeochemical.csv'

#https://datadocs.bco-dmo.org/file/m7zBJ4GTjvNzDY/964826_v1_pump_poc_pon_biosscope.csv
#https://datadocs.bco-dmo.org/file/XYG3xXqfkkjG5x/964684_v1_amino_acids_biosscope_2021.csv
#https://datadocs.bco-dmo.org/file/7Dxl3PMCmEl8lX/964801_v1_pump_carbohydrates_biosscope_2021.csv


#super easy once I have the URL:
data <- read.csv(url(wPage))

#then have other information on each dataset page that we will want (no sense copy/pasting when it's all available)
#maybe some scraping is in order since they don't have an API



#now I just need to convert this to the CMAP format


