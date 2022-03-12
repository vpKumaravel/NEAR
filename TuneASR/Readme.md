Step 1) The main file is getOptASRparam.m in which you define the names of your training data files and the location; and you define the ASR parameters (k, ASR removal or correction mode). 

Step 2) Go to evalASRparams.m and define your measure of interest to evaluate the performance of ASR. For example, SNR or FTR for frequency-tagging analysis, SME for ERP analysis.(Remember to use EEG1 for extracting this measure)

Step 3) Simply type getOptASRparam in your command window and the results can be found in a table T ready to be visualized.
