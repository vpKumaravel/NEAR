%%
% NEAR Pipeline Evaluation
%
% Function to evaluate all FTR values - returns ftr arrays and error log
%
% loc_in = input file location
% fname_in = file name
% k_in_array = list of K values for ASR (a.k.a., asr cut-off parameter)
% process_array = list of "Processing" values - on or off - length should be equal to k_in_array
% 'ON'  = 'ASR Removal'
% 'OFF' = 'ASR Correction' 
% rawEEG = EEG structure of a similar data but without removal of bad channels
%
% Velu Prabhakar Kumaravel, FBK/CIMeC (UNITN), Italy

function [measure, error_log] = evalASRparams(loc_in, fname_in, k_in_array, process_array)


EEG = pop_loadset('filename', fname_in,'filepath', loc_in);
measure = zeros(length(k_in_array), 1);


for p = 1:length(k_in_array)
    
    disp('Add other relevant preprocessing measures');
    
    EEG1 = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion','off','LineNoiseCriterion','off','Highpass','off','BurstCriterion',k_in_array(p),'WindowCriterion','off','BurstRejection',process_array{p},'Distance','Euclidian');

    
    try 
        
        disp('Use EEG1 to perform your post-processing here: epoching, computing psd measures etc.,');

        measure(p) = 1; % Compute your measure using EEG1 and save it here.
        error_log{p} = 'Success';
        
        
    catch Error
        error_log{p} = Error.message;
        disp(Error);
        measure(p) = 0;
    end
    
end

end