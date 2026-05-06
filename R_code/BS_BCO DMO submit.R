#Converts BS combined master file into a BCO DMO ready submission file
#E.Halewood 8/19/25
# Krista Longnecker 5 May 2026 -->< updating

#Required packages
# Install if not already installed
packages <- c("readxl", "dplyr", "tidyr", "lubridate", "writexl", "stringr")
installed <- rownames(installed.packages())
to_install <- packages[!packages %in% installed]
if(length(to_install)) install.packages(to_install)

# Load packages
library(readxl)
library(dplyr)
library(tidyr)
library(lubridate)
library(writexl)
library(stringr)

#Read in the excel file and sheet 
# Read the 'DATA' sheet from Excel file
df <- read_excel("/Users/ehalewood/Desktop/BS_merge/BATS_BS_COMBINED_MASTER_latest.xlsx", sheet = "DATA")
#df <- read_excel("BATS_BS_COMBINED_MASTER_latest.xlsx",sheet="DATA")

# #Remove BATS cruises (served separately at BCO DMO)
# df <- df %>%
#   filter(Program != "BATS")
# Move this up here because we only need the BIOS-SCOPE data so there is less
#tidying up needed if we filter first. Search FOR BIOS-SCOPE so we don't get
# BATS or HS
df <- df %>%
  filter(Program == "BIOSSCOPE")


#Krista's brain cannot track all the mutating...so do this the hard way

##first, need to set the time so it is four digits: add in leading zeroes
time4 <- sprintf("%04d",df$`time(UTC)`)
#make a temporary vector with dates and time (otherwise get times of today)
x <- paste(ymd(df$yyyymmdd), time4)
df$time_clean <- strptime(x, "%Y-%m-%d %H%M",tz="UTC")
df$ISO_DateTime_UTC = as.POSIXct(df$time_clean, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")


#modifies latitude and longitude parameter (column) names to conform with BCO-DMO naming conventions
#Converts both columns to numeric
#Applies -abs() to lonW to ensure it's negative (e.g., 64.2 → -64.2)
#Renames latN → Latitude and lonW → Longitude
df <- df %>%
  mutate(
    Latitude = as.numeric(latN),
    Longitude = -abs(as.numeric(lonW))  # just make sure it's negative
  )

#Filter by user specified years
# to make this work need a column with just the year
df$year <- as.numeric(format(df$ISO_DateTime_UTC,"%Y"))

# Example: keep only 2020 and 2021
years_to_keep <- c(2021, 2022, 2023, 2024)

df <- df %>%
  filter(year %in% years_to_keep)

#Keep Only the Specified Columns in this order (matches previous BCO DMO submission for biogeochem datasets)
# KL edited this to keep New_ID when exporting data to BCO-DMO. This is useful for merging
columns_to_keep <- c("New_ID","Program", "Cruise_ID", "Cast", "Niskin", "year", "decy", "ISO_DateTime_UTC",
                     "Latitude", "Longitude", "Depth", "Nominal_Depth", "Temp",
                     "CTD_SBE35T(degC)", "Conductivity(S/m)", "CTD_S", "Pressure(dbar)",
                     "sig_theta(kg/m^3)", "O2(umol/kg)", "BAC(m-1)", "Fluo(RFU)", "Par",
                     "Pot_Temp(degC)", "Niskin_temp (degC)", "NO3+NO2(umol/kg)", "NO3+NO2_QF",
                     "NO3(umol/kg)", "NO3_QF", "NO2(umol/kg)", "NO2_QF", "PO4(umol/kg)",
                     "PO4_QF", "NH4(umol/kg)", "NH4_QF", "SiO2(umol/kg)", "SiO2_QF",
                     "POC (ug/kg)", "POC_QF", "PON (ug/kg)", "PON_QF", "DOC (umol/kg)",
                     "DOC_QF", "TDN (umol/kg)", "TDN_QF", "Bact (cells*10^8/kg)", "Bact_QF",
                     "BP_Leu (pmol/L/hr)", "BP_Leu_QF", "TDAA(nmol/L)", "TDAA_QF",
                     "Asp(nmol/L)", "Glu(nmol/L)", "His(nmol/L)", "Ser(nmol/L)",
                     "Arg(nmol/L)", "Thr(nmol/L)", "Gly(nmol/L)", "Tau(nmol/L)",
                     "BAla(nmol/L)", "Tyr(nmol/L)", "Ala(nmol/L)", "GABA(nmol/L)",
                     "Met(nmol/L)", "Val(nmol/L)", "Phe(nmol/L)", "Ile(nmol/L)",
                     "Leu(nmol/L)", "Lys(nmol/L)", "V1V2_ID", "V4_16s_ID", "V4_18s_ID",
                     "Sunrise", "Sunset", "MLD_dens125", "MLD_bvfrq", "MLD_densT2",
                     "DCM", "VertZone", "Season")

# Retain only columns that exist in the data
columns_to_keep <- columns_to_keep[columns_to_keep %in% names(df)]

df_final <- df %>%
  select(all_of(columns_to_keep))

#Export to Excel and CSV
# Export to Excel
write_xlsx(df_final, "BS_BCODMO_SUBMIT.xlsx")

# Export to CSV
write.csv(df_final, "BS_BCODMO_SUBMIT.csv", row.names = FALSE)




# df$timeC <- paste0(substr(time4,1,2),":",substr(time4,3,4))
# 
# dates = df$date_parsed
# #times = df$timeC
# x <- paste(ymd(df$yyyymmdd), time4)
# 
# 
# 
# 
# 
# 
# 
# 
# time_clean <- strptime(time4,format="%H%M")
# 
# 
# df <- df %>%
#   mutate(
#     date_parsed = ymd(yyyymmdd),
#     time_parsed = hms(timeC),
#     datetime = as.POSIXct(paste(date_parsed, time_parsed), format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
# 
# 
# 
# 
# df <- df %>%
#   mutate(
#     date_parsed = ymd(yyyymmdd),
#     time_parsed = as_hms(timeC))
#     
# 
# hm(paste0(substr(t,1,2),":",substr(t,3,4)))
# 
# 
# df <- df %>%
#   mutate(`time(UTC)` = as.character(`time(UTC)`))
# 
# 
# df <- df %>%
#   mutate(`time(UTC)` = as.character(`time(UTC)`),
#          sprintf("%04d"))
# 
# 
# parsedTime = lubridate::format_ISO8601(df$decy)
# 
# 
# df <- df %>%
#   mutate(
#     date_parsed = ymd(yyyymmdd),
#     time_parsed = hms(`time(UTC)`),
#     datetime = as.POSIXct(paste(date_parsed, time_parsed), format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
#     
# 
# # Create a new column to keep the original for comparison
# df_checked <- df %>%
#   mutate(time_parsed = hms(`time(UTC)`))
# 
# 
# # View only the rows that failed to parse
# failed_rows <- df_checked %>%
#   filter(is.na(time_parsed) & !is.na(`time(UTC)`))
# 
# 
# #ParsedDate = lubridate::ymd(df$yyyymmdd)
# 
# 
# # #Format Date and Time columns
# # # Ensure yyyymmdd and time(UTC) are characters
# # df <- df %>%
# #   mutate(
# #     yyyymmdd = as.character(yyyymmdd),
# #     `time(UTC)` = as.character(`time(UTC)`))
# #     
# # dt <- ymd(paste(df$yyyymmdd,df$`time(UTC)`)) 
#    
# # Create a new column to keep the original for comparison
# df_checked <- df %>%
#   mutate(date_parsed = ymd(yyyymmdd))
# 
# # View only the rows that failed to parse
# failed_rows <- df_checked %>%
#   filter(is.na(date_parsed) & !is.na(yyyymmdd))
# 
#     ,
#     ParsedDate = lubridate::ymd(yyyymmdd),
#     # Create a proper datetime object
#     datetime = as.POSIXct(paste(yyyymmdd, `time(UTC)`), format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
#   )


#Put some code at the end for now
# df <- df %>%
#   mutate(
#     yyyymmdd = as.character(yyyymmdd),
#     `time(UTC)` = as.character(`time(UTC)`),
#     
# # Parse date safely (expecting yyyymmdd as YYYYMMDD)
# ParsedDate = lubridate::ymd(yyyymmdd),
#     
# # Parse time safely
# ParsedTime = suppressWarnings(lubridate::hms(`time(UTC)`))
# 
# #Create ISO_DateTime_UTC Column
# #Combines date and time columns into a single ISO 8601 formatted datetime (BCO DMO required)
# #Clean the yyyymmdd column
# df <- df %>%
#   mutate(
#     yyyymmdd = str_replace_all(as.character(yyyymmdd), "[^0-9]", "")  # Remove non-numeric characters
#   )
# 
# #Identify unparseable values
# df %>%
#   filter(nchar(yyyymmdd) != 8 | is.na(yyyymmdd)) %>%
#   distinct(yyyymmdd)
# 
# #Parse Date and Time
# df <- df %>%
#   mutate(
#     ParsedDate = if_else(nchar(yyyymmdd) == 8, ymd(yyyymmdd), NA_Date_),
#     ParsedTime = suppressWarnings(hms(`time(UTC)`))
#   )
# 
# #Safely Create ISO DateTime Column
# df <- df %>%
#   mutate(
#     ISO_DateTime_UTC = if_else(
#       !is.na(ParsedDate) & !is.na(ParsedTime),
#       format(as.POSIXct(ParsedDate + ParsedTime, tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"),
#       NA_character_
#     )
#   )











