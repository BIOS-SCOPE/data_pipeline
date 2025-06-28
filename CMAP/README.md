# data_pipeline
Setup script to convert the BIOS-SCOPE data into the format expected by CMAP.\
Krista Longnecker, 27 June 2025

## Updates as I go along, most recent at the top
### 27/28 June 2025
Sidestep and work on getting MetaboLights data ready for CMAP as that is just FTP access. First file is ``MetabolightsToCMAP.ipynb``, will make into a *py file later. My Python is rusty so it took me a while to get the indexing right. I have the dataset up correctly for CMAP, next will be to work on the metadata.

### 25 June 2025
Change to start with data at BCO-DMO and use Python script to go from BCO-DMO repository to a format required by CMAP.

### 23/24 June 2025
Using ``makeCMAP.R`` to convert the BIOS-SCOPE data into a worksheet with the three tabs expected by CMAP. Updated after I read through the dataset submission details, only minor edits so far. I need to get some details on the various instruments before proceeding.

#### To do
- [ ] MetaboLights: need to work on format of metadata
- [ ] need more details on measurement and instruments
- [ ] pass validation at CMAP

