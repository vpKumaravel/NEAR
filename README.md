# NEAR - Neonatal EEG Artifact Removal

This is a public repository of NEAR, an artifact removal pipeline for human newborn EEG data. <br />

There are two ways to install NEAR bad channel detection tool: <br />

1) Use EEGLAB GUI (File - Manage EEGLAB Extensions - Search for NEAR - Install/Update). **NOTE: This option is not available yet (NEAR will be publicly linked to EEGLAB once the manuscript is accepted for publications) <br />**
2) Download the project as .zip file. Extract the .zip file and place the folder "NEAR_ChannelRejection-master" in your EEGLAB/Plugins folder. 

Installation check: Type 'help pop_NEAR.m' in the command window. If there's no error, you're good to go. <br />

Dependencies: <br />

(1) EEGLAB Software <br />
(2) Statistics and Machine Learning Toolbox - for knnsearch

Suggestions for a fruitful learning activity: <br />
<br />
(1) Please read the NEAR_UserManual.pdf file on the repository <br />
<br />
(2) To familiarize with the user parameters, execute the step-by-step preprocessing using **NEAR_Pipeline_Tutorial_v1_0.m**. You may also refer to the appendix of our manuscript. <br />
<br />
(3) To run NEAR for a single subject EEG file, please use the **NEAR_singlesubject_processing.m** file <br />
<br />
(4) To perform NEAR preprocessing for a batch of EEG files, the **NEAR_batch_processing.m** file can be used <br />
<br />

(5) To tune LOF Threshold, you need the ground truth bad channels already. By default, F1 Score is used as the quality metric. If you prefer accuracy, or precision/recall, the code can be easily modified. The file calibrateLOFThreshold.m in **tuneLOF** folder helps you do that. A sample EEG file is also available for a hands-on experience. ;-)
<br />

(6) To tune ASR user-defined parameters ASR Cut-off Parameter (_k_) and ASR Processing Mode (_Correction & Removal_), use the files in **TuneASR** as template and customize the code as per your requirements (more details in the comments section of each file). <br />



This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version. <br />

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. <br />

You should have received a copy of the GNU General Public License along with this program; if not, see http://www.gnu.org/licenses/.

### Citation   
```
@article{NEAR2022
  title={NEAR: An artifact removal pipeline for human newborn EEG data.},
  author={V.P. Kumaravel, E.Farella, E.Parise, and M.Buiatti},
  journal={Journal of Developmental Cognitive Neuroscience (Special Issue: EEG Methods for Developmental Cognitive Neuroscientists: A Tutorial Approach)},
  doi={https://doi.org/10.1016/j.dcn.2022.101068},
  year={2022}
}
```
