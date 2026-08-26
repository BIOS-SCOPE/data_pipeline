# data_pipeline 
Updated 24 August 2026; Krista Longnecker 

This data_pipeline is also available at Zenodo at this DOI:
<img width="191" height="20" alt="image" src="https://github.com/user-attachments/assets/b37fbb40-e86b-4c72-9fe6-6655a58b311b" />

BIOS-SCOPE conducts multiple cruises and relies on samples collected during BATS cruises. The data streams include CTD data and discrete samples. The CTD data are used to calculate derived variables. The data from the discrete samples is pulled together with the CTD data to create a 'master_bottle_file' for everyone to use. This GtiHub repository discusses the CTD data and discrete data files. If you are interested in the data-portal being developed to link in the sequence data, that is available [here](https://github.com/BIOS-SCOPE/data-portal).

The remainder of this repository describes how this is done, provides details and code from different people, and ends with a to-do list.

Details on the scripts are covered either in the PDF presented [here](https://github.com/BIOS-SCOPE/data_pipeline/blob/main/Longnecker_BIOSSCOPE_dataPipeline_update_2026.pdf) or in this figure:
<img src="https://github.com/BIOS-SCOPE/data_pipeline/blob/main/data_pipeline_figure_latest.jpg"  width="105%" height="105%">

## After a cruise 
* The CTD data goes to Craig Carlson to serve as an archive; no work is done on these files.
* The BATS team processes the CTD data. For the BATS cruises, use the data at BCO-DMO, which is updated at BCO-DMO every six months. For the BIOS-SCOPE cruises, files are transferred to us separately. As of spring 2026, Craig, Rachel, and Krista have access to the processed data for BIOS-SCOPE.
* Rachel (or Krista) moves the processed CTD data onto the BIOS-SCOPE Google Drive. The data specific to BIOS-SCOPE will be here in the BIOS-SCOPE Google Drive:\
```./1.0 DATA/1.0 ORIG CTD FROM BATS/CTDrelease_20260326```\

The BCO-DMO website for the BATS cruises, and Hydrostation S cruises, and the BLOOM cruises is [here](https://www.bco-dmo.org/project/2124), from there you want the two decibar averaged CTD profiles collected at the BATS site. This is updated every six months.

## Step 1: Download CTD data from BCO-DMO and/or BIOS-SCOPE specific location
First, get the data from the BIOS-SCOPE Google Drive and from BCO-DMO. This is just a matter of downloadings and putting them some where that is not seen by GitHub as the files are too big for storing on GitHub.

## Step 2: Pre-processing CTD files (in MATLAB)
The pipeline was updated in 2026 now that data from both BCO-DMO and coming directly to the BIOS-SCOPE project. The new file is [preProcessingCTDfiles.m ](https://github.com/BIOS-SCOPE/data_pipeline/blob/main/MATLAB_code/preProcessingCTDfiles).\
The data at BCO-DMO includes any BATS cruises, Hydrostation S cruises, and the BLOOM cruises. As these go back to the beginning of BATS sampling, this will be more than we generally need.\
We are also still getting BIOS-SCOPE only data, which is now BIOS-SCOPE cruises and anytime a BIOS-SCOPE sample is collected (on a BATS, HS, or BLOOM cruise). This overlaps a little with the data from BCO-DMO. Hence, at this step, process all the files, but then will have to trim things down as it will be to large if we have all possible cruise/cast/niskin information.

The pre-processing script will go through all the cruises and save the output as a file that is CRU_#####_ctd.csv. Other formats (txt and mat files) have been turned off as they are no longer necessary. The processing script organizes the data so we can use it later and calculates the derived values (season, vertical zone, sunrise/sunset, and mixed layer depths). 

## Step 3: Shuting's pipeline (in R)
This file has been updated to allow us to use BATS data from BCO-DMO and you can do them both at once. The updated R file is [Join_BATS_All_with_master_v5.R](https://github.com/BIOS-SCOPE/data_pipeline/blob/main/R_code/Join_BATS_All_with_master_v5.R). 

:heavy_exclamation_mark: One key note - this will *not* go back and recalculate seasons for cruise/cast/niskins that are already in the MASTER FILE.

Before you dive into the R script, get the latest version of ```BATS_BS_COMBINED_MASTER_latest.xlsx``` from the BIOS-SCOPE Google Drive. Then, update the list of cruises on the CruisesAndStations tab of the worksheet.

Run the R script, which does the following:
* read in the current master file (```BATS_BS_COMBINED_MASTER_latest.xlsx```) and use that to set the headers for the data incoming data
* get the headers that are used on the BATS CTD data files
* Go through one cruise at a time and
    * read in the ```_physf``` file
    * delete the columns we do not want and rename columns as needed
    * get cruise, cast, and Niskin information from the New_ID
    * add in the nominal depths
    * resize everything so it can be pasted into the existing bottle file
* Repeat for all cruises and open the end result as an Excel file (this will happen automatically when you run the R script)

Now you have to do some manual copy/paste:
* Use copy/paste to append the new rows at the end of the BIOS-SCOPE master file
* Update the log in the master file
* Save the file with a new date

## Step 4: Merge in discrete dataset as it becomes available (in R)
You will always have the calculated variables from Ruth's code, and there will be other datases as they become available (e.g., nutrients, Shimadzu data, cell counts, and more). One important note: the merge is done based on **New_ID**, so the new datafile must have a column with the new ID (begins in 1,2, or 9). There is an example file in the data_holdingZone folder (```sampleDataFile_useAsExampleForYourData.xlsx```) so you can see the format needed for an Excel file holding new data. New data can be in an Excel file or a CSV file. 

Krista updated Shuting's code (new available [Join_discreteData_v3.R](https://github.com/BIOS-SCOPE/data_pipeline/blob/main/R_code/Join_discreteData_v3.R)). Generally the new script does the following:
* reads in the current bottle file
* reads in the discrete data file to be added to the existing bottle file
    * checks to see if there are duplicate samples in the incoming discrete data file
    * asks the user if this is expected
         * if it is expected, the script will average the samples to provide one value for each sample
         * if it is not expected, the script will cancel with an error message so the user can see what happened
* matches the column names between the existing file and the temporary columns in the new file
* opens up the full set of discrete data as an Excel worksheet

At this point, you do have to do some manual copy/pasting:
* Copy the entire worksheet that will open in Excel when the R code is done
* Paste into the existing discrete file
* Get the headers with the proper colors - this is the first row in the 'Bottle File Header' worksheet.
* Update the log and save the discrete file with a new date.

## Step 5: Upload this new discrete file back to the BIOS-SCOPE (working) Google Drive 
To do this and still retain the links do the following:
* Put a copy of the latest file into the 'old versions' folder with a date 
* Right click on the latest file in the BIOS-SCOPE Working Google Drive
* Scroll down to File Information, and then Manage Versions
* Select 'upload new version' from the menu box that will come up.

## Other notes...side uses of this repository
#### updated June 2026
* Start gathering up details on the BIOS-SCOPE samples collected by the BATS team. Using their sampling logs to generate an inventory. Use the ```BATS_sampling_all.R``` script that is in the R code folder.
* also use ```MATLAB_code/makeLUtableForSynoptic.m``` to make a table with the derived values calculated in MATLAB, one line per cruise. Need this for makeSynoptic. 

#### updated March 2026
Krista expanding the repository to include code that will prepare the CTD data for BCO-DMO. The BIOS_SCOPE_Team/1.0 DATA/1.0 CURRENT CTD FILES folder is also updated with the current BATS CTD data release (CTDrelease_20260326), which includes all BATS cruises with BIOS-SCOPE samples back to 2017 and the BIOS-SCOPE cruises starting in 2019. The earlier BIOS-SCOPE cruises (2016 to 2018, five cruises AE1614, AE1620, AE1703, AE1712, AE1819) are available in the Google Drive, and were calibrated in 2020. They are not a part of the regular BATS data processing, so they are not a part of the CTD data released by BATS. The updated version of the older cruises have been manually gathered into the 1.0 CURRENT CTD FILES folder. 

#### updated February 2026
Krista used BATSallTime repository to calculate the seasons from the BATS CTD data. The gliders were in the water less, so this was the best way to get seasonal information.

## Using this code to prepare CTD data for BCO-DMO
Krista created a new MATLAB script to prepare CTD data for BCO-DMO. The script is [biosscope_ctd_forBCODMO_2016to2025.m](https://github.com/BIOS-SCOPE/data_pipeline/blob/main/MATLAB_code/biosscope_ctd_forBCODMO_2016to2025.m). The end result is a CSV file that can be uploaded to BCO-DMO. The metadata for each variable is given in ```ParameterMetadata_forBCODMO.csv```, which is also available in this repository.

## tasks to-do list
Krista 
- [ ] Make the merge of derived values into the existing bottle file smoother, the copy-paste is not ideal
- [ ] Need way to track what has and has not been done for a given cruise
- [ ] Automate download of data file from BCO-DMO
