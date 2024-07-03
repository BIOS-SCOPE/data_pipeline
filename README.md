# data_pipeline 
Updated 3 July 2024; Krista Longnecker

This is a dead end  - I was working on the BATSallTime seasons and moved the data_pipeline repository quite far from where it should be. Leave here as a branch, but do not work on this anymore.






The repository was started during a small group meeting for the BIOS-SCOPE project. BIOS-SCOPE conducts multiple cruises and relies on samples and data collected during BATS cruises. The data streams include CTD data and discrete samples. The CTD data are used to calculate derived variables. The data from the discrete samples is pulled together with the CTD data to create a 'master_bottle_file' for everyone to use. This GtiHub repository discusses the CTD data and discrete data files. If you are interested in the data-portal being developed to link in the sequence data, that is available [here](https://github.com/BIOS-SCOPE/data-portal).

The remainder of this repository describes how this is done, provides details and code from different people, and ends with a to-do list for each member of this small group.

Details on the scripts are covered either in the PDF presented [here](https://github.com/BIOS-SCOPE/data_pipeline/blob/main/BIOSSCOPE_dataPipeline_LongneckerEtAl.pdf) or in this figure:
<img src="https://github.com/BIOS-SCOPE/data_pipeline/blob/main/data_pipeline_figure.2024.01.21.jpg"  width="105%" height="105%">

## After a cruise 
* The CTD data goes to Craig Carlson to serve as an archive; no work is done on these files.
* The BATS team processes the CTD data and posts it on Dropbox. As of fall 2023, Craig and Rachel have access to the processed data on BIOS-SCOPE.
* Rachel moves the processed CTD data onto the BIOS-SCOPE Google Drive. Data will be here in the BIOS-SCOPE Google Drive:\
```./1.0 DATA/1.0 ORIG CTD FROM BATS```\
```./CTDrelease_20230626  (these begin with “1” or “2”)```\
```./BIOS-SCOPE Cruises  (these begin with “9”)```

## Step 1: Download CTD files from BIOS-SCOPE Google drive
To work on the CTD data, get the data from the BIOS-SCOPE Google Drive. This is best done in batches, where each 'batch' is CTD data from multiple cruises, possibly over multiple years. You will need to process data from BATS cruises separately from BIOSSCOPE cruises.
 
On Google Drive you will find subfolders for each cruise. Each subfolder contains various ascii files (one per each CTD cast, plus the physf_QC and MLD.dat files). Go into the CTDrelease_20230626 and highlight the cruise folders that are new --> download them to a zip file.\
Make a processing folder (e.g., BIOSSCOPE_working) and move the downloaded zip archives there. Unzip the files. 

## Step 2: Shuting's pipeline (in R)
This file was updated by Krista (January 2024), the update modified Shuting's code to go through a series of folders to find new CTD data. The code will require you to indicate if you are working on 'BATS' data or 'BIOSSCOPE' data (at line 30). The updated R file is [Join_BATS_All_with_master_v3.R](https://github.com/BIOS-SCOPE/data_pipeline/blob/main/R_code/Join_BATS_All_with_master_v3.R), and you can click the link to see the file on GitHub. 

The code now does the following (after data files have been downloaded from Google Drive as described above:
* read in the current master file (```BATS_BS_COMBINED_MASTER_latest.xlsx```) and then use that to set the headers for the data incoming data
* get the headers that are used on the BATS CTD data files
* Go through one cruise at a time and
    * read in the ```BIOSSCOPE_physf``` file
    * delete the columns we do not want and rename columns as needed
    * get the cast and Niskin information from the New_ID
    * add in the nominal depths
    * resize everything so it can be pasted into the existing bottle file
* Repeat for all cruises and open the end result as an Excel file (this will happen automatically when you run the R script)

Now you have to do some manual copy/paste:
* Use copy/paste to append the new rows at the end of the BIOS-SCOPE master file
* Update the log in the master file
* Save the file with a new date

## Step 3: Ruth Curry's pipeline (in MATLAB)
Once Shuting's code has been used to add the necessary samples to the master bottle file, then you can run Ruth's code to calculate the derived variables. 

Krista has updated [create_biosscope_files_2022_2023_Krista.m ](https://github.com/BIOS-SCOPE/data_pipeline/blob/main/MATLAB_code/create_biosscope_files_2022_2023_Krista.m ) to pick up where the previous processing script ended. This file will start with 10390 (March 2022) and then go to 10404 (May 2023). The path information is set for Krista's desktop, this would need to be updated for other computers.

One special note about season transition dates. This information could be from (a) glider data, or (b) from Hydrostation S data, or (c) pre-set dates. Ruth will make a readme file to detail what year relies on which option. The output from Ruth's script will make this file: ```Season_dates_all.mat```

Generally the rest of the code does the following:
*	Loads CTD files from BATS, labels them with physical framework parameters
*	Outputs CSV and MAT files
*	Reads Master bottle file, creates structure with added fields
*	Loops through bottle data cruise by cruise, matches the corresponding CTD cast, computes a set derived physical properties and adds the values to the bottle cast
*	The end result is a file that is called ```ADD_to_MASTER_temporary.csv``` which is saved to a holding zone
 
The next step is to use ```Join_discreteData_v2.R``` to add the calculated variables to the existing bottle file.

Once a set of CTD data has been processed, you don't need to redo the MATLAB steps unless the data gets reprocessed by BATS.

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

Finally, upload this new discrete file back to the BIOS-SCOPE Google Drive, put it in ```./1.0 DATA/1.0 CURRENT BOTTLE FILE```. Move the old bottle file into the 'Old Versions' folder.


## Craig's path to make 'one cast' for cruise
Craig currently working in R to make one single cast for each cruise so we can pull in data from pumps etc.
For the data portal, using these synpotic casts, the idea is to use cast and nominal depth as the key for merging.
Krista has Craig's code and will work on this next (1/24/2024)

## Calculating derived variables from BATS data
update 9 February 2024\
There is a general interest in BIOS-SCOPE to calculate Ruth's parameters for all BATS data, back to BATS cruise #001. There is now a MATLAB script to do this [calcDerivedVariables_BATSallTime.m ](https://github.com/BIOS-SCOPE/data_pipeline/blob/main/MATLAB_code/calcDerivedVariables_BATSallTime.m ). The output is one file with everyone and a series of CSV files, one per cruise. The full file is quite large, so it is now sitting in the BIOS-SCOPE Google Drive.

## tasks to-do list
Ruth
- [ ] put glider data and metadata into BCO-DMO format

Krista 
- [ ] Work on Craig's code (need to figure out how to handle CTD data)
- [ ] Need way to track what has and has not been done for a given cruise
- [ ] Put output from Ruth's code onto Google Drive (all the CSV/MAT/TXT files)

Rachel
- [ ]  Discuss pipeline with Rod and finalize the CTD processing.
- [ ]  Does Dom needs to reprocess BIOS-SCOPE cruises?
- [ ]  Figure out why we have two folders for BIOS-SCOPE 91916 cruise on Google Drive ('91916' and '91916_QC'). Sort out which is right and move the other folder
- [ ]  difference between wet oxygen 1, 2, 3 and salts 1, 2 in the CTD files

## Some git notes for Krista
Edit file(s) on my local computer, then to get the files back to GitHub, use this set of commands to put onto GitHub:

```git add -A``` *or* ```git add MATLAB_code/\ *``` (or whatever folder you want)\
```git commit -am "Brief description goes here"``` (can use the bit in quotes to describe the update)\
```git push```\
(enter the passcode I use to get files to GitHub)
