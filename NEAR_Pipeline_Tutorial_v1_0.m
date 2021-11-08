% ************************************************************************
% Neonatal EEG Artifacts Removal (NEAR) Pipeline Tutorial Script
% Version 0.1
% Developed at FBK & CIMeC (UNITN), Trento, Italy

% Contributors to NEAR pipeline:
% Velu Prabhakar Kumaravel (velu.kumaravel@unitn.it / vpr.kumaravel@gmail.com)
% Marco Buiatti (marco.buiatti@unitn.it)
%
%
% NEAR uses EEGLAB toolbox. Please execute the following installations:
%
% 1) EEGLab:  https://sccn.ucsd.edu/eeglab/downloadtoolbox.php/download.php
% 2) Download the NEAR pipeline (github link: https://github.com/vpKumaravel/NEAR_TestRep) and extract the files in the folder \eeglabxxx\plugins\..
% Alternatively, you can use EEGLAB GUI (File - Manage EEGLAB Extensions - Search (for NEAR) - Install/Update)
%
%
% Please cite the following references for in any manuscripts produced utilizing NEAR pipeline:
%
% (0) NEAR: To be added.
%
% (1) EEGLAB: A Delorme & S Makeig (2004) EEGLAB: an open source toolbox for analysis of single-trial EEG dynamics. Journal of Neuroscience Methods, 134, 9?21.
%
% (2) Blue Bird (2021). Density-based Outlier Detection Algorithms (https://github.com/BlueBirdHouse/DDoutlier), GitHub. Retrieved May 19, 2021.
%
% (3) Clean_Rawdata Plugin: https://github.com/sccn/clean_rawdata, GitHub. Retrieved May 19, 2021.
%
% This pipeline is released under the GNU General Public License version 3.
%
% *************************************************************************
%% Clear variable space and run eeglab


addpath(genpath(('...')) % Enter the path of the EEGLAB folder in this line

clc;
clear all;
eeglab;

addpath(genpath(cd));


%% Step 0: Dataset Parameters 

dname = 'xxx.set'; % name of the dataset with extension (.set, .mff, .raw, .edf)
dloc = 'yyy';% corresponding file location

chanlocation_file = 'xxx\eeglab2021.0\sample_locs\GSN-HydroCel-129.sfp';
%% Step 1: User-defined Parameters

isLPF    = 1; % set to 1 if you want to perform Low Pass Filtering
isHPF    = 1; % set to 1 if you want to perform High Pass Filterting
isSegt   = 0; % set to 0 if you do not want to segment the data based on baby's attention for the presented visual stimuli
isERP    = 0; % set to 1 if you want to epoch the data for ERP processing
isBadCh  = 1; % set to 1 if you want to employ NEAR Bad Channel Detection 
isBadSeg = 1; % set to 1 if you want to emply NEAR Bad Epochs Rejection/Correction (using ASR)
isVisIns = 1; % set to 1 if you want to visualize intermediate cleaning of NEAR Cleaning (bad channels + bad segments)
isInterp = 1; % set to 1 if you want to interpolate the removed bad channels (by Spherical Interpolation)
isAvg    = 1; % set to 1 if you want to perform average referencing
isReport = 1; % set to 1 if you would like a comprehensive summary of the preprocessing done for each file
isSave   = 1; % set to 1 if you want to save the pre-processed data


% Low-pass filter parameters begin %
lpc     = 40; % low-pass filter cut-off frequency in Hz; set to [] if isLPF = 0;
% Low-pass filter parameters end %

% High-pass filter parameters begin %
hptf    = []; % high-pass transition edge - [low_freq high_freq] in Hz; set to [] if isHPF = 0;
% (OR)
hpc  = 0.1; % high-pass cut-off frequency in Hz; set to [] if you had set hptf;

% High-pass filter parameters end %

% Segmentation using fixation intervals - parameters begin %
segt_file = 'segt_visual_attention.xlsx';
segt_loc  = 'xx';
look_thr = 4999; % consider only the segments that exceed this threshold+1 in ms to retain. Set it to [] if you do not want to apply thresholding.
% Segmentation using fixation intervals - parameters end %

% Epoch data for ERP datasets
erp_event_markers = {'Eyes Open', 'Eyes Closed'}; % enter all the condition markers
erp_epoch_duration = [0 1.2]; % duration of epochs (in seconds)
erp_remove_baseline = 1; % 0 for no baseline correction; 1 otherwise
baseline_window = [0  200]; % baseline period in ms; leave it empty [] in case of entire epoch baselining

% Parameters for NEAR - Bad Channels Detection begin %

% a) flat channels
isFlat  = 1; % flag variable to enable or disable Flat-lines detection method (default: 1)
flatWin = 5; % tolerance level in s(default: 5)

% b) LOF (density-based)
isLOF       = 1;  % flag variable to enable or disable LOF method (default: 1)
dist_metric = 'seuclidean'; % Distance metric to compute k-distance; other option: 'euclidean' (refer to the manuscript for details)
thresh_lof  = 2.5; % Threshold cut-off for outlier detection on LOF scores (threshold should be at least 1.5 {Breunig† et al., 2000})
isAdapt = 10; % The threshold will be incremented by a factor of 1 if the given threshold detects more than xx % 
                %of total channels (eg., 10); if this variable left empty [], no adaptive thresholding is enabled.
             

% c) Periodogram (frequency based) - Optional
isPeriodogram = 0; % flag variable to enable or disable periodogram method (default: 0)
frange        = [1 20]; % Frequency Range in Hz
winsize       = 1; % window length in s
winov         = 0.66; % 66% overlap factor
pthresh       = 4.5; % Threshold Factor to predict outliers on the computed energy


% Parameters for NEAR - Bad Channels Detection end %

% Parameters for ASR begin %

rej_cutoff = 20;   % A lower value implies severe removal (Recommended value range: 20 to 30)
rej_mode   = 'on'; % Set to 'off' for ASR Correction and 'on for ASR Removal (default: 'on')
add_reject = 'off'; % Set to 'on' for additional rejection of bad segments if any after ASR processing (default: 'off')

% Parameters for ASR end %

% Parameter for interpolation begin %

interp_type = 'v4'; % other options to replace 'spherical': 'spacetime', 'invdist' or 'v4' - Reference: pop_interp.m

% Parameter for interpolation end %

% Parameter for Re-referencing begin %
% reref = 30; % alternatively, channel name can be set as follows
reref =  {'Cz'}; % reref can also be the channel name.

% Parameter for Re-referencing begin %
%% Step 2a: Import data

[filepath,name,ext] = fileparts([dloc filesep dname]);

if(isempty(ext))
    error('The file name should contain an extension. e.g., .set');
    
elseif(strcmp(ext, '.set')==1)
    
    EEG = pop_loadset('filename',dname,'filepath',[dloc filesep]);
    
elseif strcmp(ext, '.mff')==1
    if exist('mff_import', 'file')==0
        error(['"mffmatlabio" plugin is not available in EEGLAB plugin folder. Please install the plugin to import .mff files' ...
            ]);
    else
        EEG=mff_import([dloc filesep dname]);
    end
    
elseif strcmp(ext, '.raw')==1
    if exist('pop_fileio', 'file')==0
        error(['"pop_fileio" plugin is not available in EEGLAB plugin folder. Please install the plugin to import .mff files' ...
            ]);
    else
        EEG = pop_fileio([dloc filesep dname], 'dataformat','auto');
    end
    
elseif strcmp(ext, '.edf')==1
    if exist('pop_biosig', 'file')==0
        error(['"pop_biosig" plugin is not available in EEGLAB plugin folder. Please install the plugin to import .edf files' ...
            ]);
    else    
        EEG = pop_biosig([dloc filesep dname]);
    end
    
else
    error('Your data is not of .set/.mff/.raw/.edf format, please edit the import data function appropriate to your data.');
end

EEG = eeg_checkset(EEG);
origEEG = EEG; % making a copy of raw data
eeglab redraw

%% Step 2b: Import the channel locations

if(isempty(chanlocation_file))
    EEG=pop_chanedit(EEG, 'load',{chanlocation_file 'filetype' 'autodetect'});
    EEG = eeg_checkset( EEG );
elseif(isempty(EEG.chanlocs))
    warning('Your data lacks channel location information.');
end

%% Step 2c: Make the data to continuous if required
% ASR works only for continuous data, therefore, we are changing the
% epoched data to continuous.

if(numel(size(EEG.data)) == 3) 
    EEG = eeg_epoch2continuous(EEG); % making the data continuous to perform NEAR preprocessing
    isERP = 1; % to later epoch the data
end


%% Step 3: Filter data (Optional)

if(isLPF)
    EEG = pop_eegfiltnew(EEG, [], lpc, [], 0, [], 0); % low-pass filter
    % (or)
    %EEG = pop_eegfiltnew(EEG, 'hicutoff',lpc,'plotfreqz',0);
end

if(isHPF)
    if(isempty(hptf))
        EEG = pop_eegfiltnew(EEG, 'locutoff',hpc,'plotfreqz',0);
    else
        EEG=clean_drifts(EEG,hptf, []);
    end
end


%% Step 4: Segment data based on visual attention (Optional)
% if you have particular requirement, like, you know the time intervals in
% which data was recorded noisier due to technical faults, for example,
% you may adapt this part of the pipeline by inserting the time intervals
% to be retained.

if(isSegt)
    
    try
        lookFile=importdata([segt_loc filesep segt_file]);
    catch
        error('An error occurred in importing the segmentation file. If you think this is a bug, please report on the github repo issues section');
    end
    
    if(~isempty(lookFile))
        try
            tmp = strsplit(dname, '.');
            sheetName = tmp{1};
            lookTimes=NEAR_getLookTimes(lookFile,sheetName,look_thr);
        catch
            error('An error occurred in segmentation. Please find our template document in the repository to edit your time intervals.\n');
        end
    else
        error('We cannot find the file. Please check/correct the file path and run again.');
    end
    
    % segment EEG data
    EEG = pop_select( EEG,'time',lookTimes);
    eeglab redraw;
end

%% Step 5: Run NEAR bad channel detection tool

if (isBadCh)
    
    [EEG, flat_ch, lof_ch, periodo_ch, LOF_vec, thresh_lof_update] = NEAR_getBadChannels(EEG, isFlat, flatWin, isLOF, thresh_lof, dist_metric, isAdapt, ...
                                                                                                    isPeriodogram, frange, winsize, winov, pthresh, isVisIns);
    disp('Bad Channel Detection is performed successfully');  
    
    if(isVisIns) 
        % visual inspection and reject using 'Reject' button on the GUI
        % if executed as a block execution (i.e., only step 5)
        colors = repmat({'k'},1, EEG.nbchan);
        
        for i = 1:length(periodo_ch)
            colors(1,periodo_ch(i)) = 	{[0.9290, 0.6940, 0.1250]};
        end
        
        for i = 1:length(lof_ch)
            colors(1,lof_ch(i)) = {'r'};
        end
        
        for i = 1:length(flat_ch)
            colors(1,flat_ch(i)) = {'r'};
        end
        
        badChans = sort(unique(union(union(flat_ch, lof_ch),periodo_ch)));
        
        if(~isempty(badChans))
            if(size(badChans,1) ~= 1)
                badChans = badChans';
            end
        end
        
        colrej = EEG.reject.rejmanualcol;
        rej    = EEG.reject.rejglobal;
        rejE   = EEG.reject.rejglobalE;
        superpose = 0;
        elecrange = [1:EEG.nbchan];
        macrorej  = 'EEG.reject.rejglobal';
        macrorejE = 'EEG.reject.rejglobalE';
        reject = 1;
        icacomp   = 1;
        
        eeg_rejmacro; % script macro for generating command and old rejection arrays
        
        eegplot(EEG.data, 'srate', EEG.srate, 'title', 'NEAR Bad Channels Plot (Red and Yellow Electrodes are bad)', ...
            'limits', [EEG.xmin EEG.xmax]*1000, 'color', colors,  'dispchans', 5, 'spacing', 500, eegplotoptions{:});
      end  
    

        EEG = pop_select(EEG, 'nochannel', badChans);
        
        % saves a new dataset
        [ALLEEG, EEG, CURRENTSET, ~] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_ChRemoval']);
        eeglab redraw;
    
    
else
    
    disp('NEAR Bad Channel Detection is not employed. Set the variable ''isBadCh'' to 1 to enable bad channel detection');
    
end



%% Step 6a: Run ASR to correct or remove bad segments

if(isBadSeg)
    EEG_copy = EEG;
    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion','off','LineNoiseCriterion','off', ...
        'Highpass','off','BurstCriterion',rej_cutoff,'WindowCriterion',add_reject,'BurstRejection',rej_mode,'Distance','Euclidian');
    
    if(strcmp(rej_mode, 'on'))
        modified_mask = ~EEG.etc.clean_sample_mask;
    else
        modified_mask = sum(abs(EEG_copy.data-EEG.data),1) > 1e-10; 
    end
    
    tot_samples_modified = (length(find(modified_mask)) * 100) / EEG_copy.pnts;
    change_in_RMS = -(mean(rms(EEG.data,2)) - mean(rms(EEG_copy.data,2))*100)/mean(rms(EEG_copy.data,2)); % in percentage
    
    if(isVisIns)
        try
            vis_artifacts(EEG,EEG_copy);
        catch
            warning('vis_artifacts failed. Skipping visualization.')
        end
    end
    [ALLEEG, EEG, CURRENTSET, ~] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_ASR']);
    eeglab redraw;
end

%% Step 6b: ERP analysis (epoching, removing baselining) (Optional)

if(isERP)
    try
        EEG = pop_epoch( EEG, erp_event_markers, erp_epoch_duration, 'epochinfo', 'yes');
        EEG = eeg_checkset( EEG );
        if(erp_remove_baseline)
            EEG = pop_rmbase( EEG, baseline_window ,[]);
            EEG = eeg_checkset( EEG );
        end
    catch
        error('Either Insufficient Data or incomplete parameters for epoching');
    end 
end                      
%% Step 7: Interpolate bad channels (Optional)

if(isInterp)
    EEG = pop_interp(EEG, origEEG.chanlocs, interp_type); 
    [ALLEEG, EEG, CURRENTSET, com] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_Int']);
    eeglab redraw;
end


%% Step 8: Average Reference (Optional)

if(isempty(reref))
      warning('Skipping rereferencing as the parameter reref is empty. An example setup: reref = {''Cz''} or reref = [30]');
else
    if(isAvg) % average referencing
        
         if(isnumeric(reref))
             EEG = pop_chanedit(EEG, 'setref',{1:EEG.nbchan, reref});
         else 
             labels = {EEG.chanlocs.labels};
             ch_idx = find(cellfun(@(x)isequal(x, cell2mat(reref)),labels));
             if(isempty(ch_idx)); warning('The reference channel label does not exist in the dataset. Please check the channel locations file.');end
             EEG = pop_chanedit(EEG, 'setref',{1:EEG.nbchan, ch_idx});
         end
        EEG = pop_reref( EEG, []);
   
    else % otherwise
        
        if(isnumeric(reref))
            EEG = pop_reref( EEG, reref);
        else
            labels = {EEG.chanlocs.labels};
            ch_idx = find(cellfun(@(x)isequal(x, reref),labels));
            if(isempty(ch_idx)); warning('The reference channel label does not exist in the dataset. Please check the channel locations file.');end
            EEG = pop_reref( EEG, ch_idx);
        end
        
    end
    eeglab redraw;
end

%% Step 9: Save Data & Report

% Create output folders to save data
if isSave
    if exist([dloc filesep 'NEAR_Processed'], 'dir') == 0
        mkdir([dloc filesep 'NEAR_Processed'])
    end
    
    
    % save LOF values for each channel (as .mat)
    
    save([[dloc filesep 'NEAR_Processed'] filesep name '_LOF_Values.mat'], 'LOF_vec'); % save .mat format
    
    % Save data 
    EEG = pop_saveset(EEG, 'filename',[name '_NEAR_prep.set'],'filepath', [dloc filesep 'NEAR_Processed']);
    
end

if isReport
    if exist([dloc filesep 'NEAR_Reports'], 'dir') == 0
        mkdir([dloc filesep 'NEAR_Reports'])
    end
    
    report.FileName = name;
    report.FileLoc = dloc;
    if(isLPF)
        report.LowPassFiltering = {['A low pass filtering is applied on the data with the cut-off = ' num2str(lpc) ' Hz' ]};
    else
        report.LowPassFiltering = {'No low pass filter applied'};
    end
    
    if(isHPF)
        if(isempty(hpc))
            report.HighPassFiltering = {['A high pass filtering is applied on the data with the transition edge [' num2str(hptf) '] Hz' ]};
        else
            report.HighPassFiltering = {['A high pass filtering is applied on the data with the cut-off = ' num2str(hpc) ' Hz' ]};
        end
    else
        report.HighPassFiltering = {'No high pass filter applied'};
    end
    
    if(isSegt)
        report.SegmentationLookUp = {'A segmentation based on LookTimes is applied'};
    else
        report.SegmentationLookUp = {'No segmentation based on LookTimes is applied'};
    end
     
    if(isERP)
        tmp = [erp_event_markers',[repmat({' , '},numel(erp_event_markers)-1,1);{[]}]]';
        events = [tmp{:}];
        report.ERP = {['The data is epoched with respect to events [' events '] for the duration [' num2str(erp_epoch_duration) '] s.']};
    else
        report.ERP = {'No segmentation based on LookTimes is applied'};
    end
    
    if(isBadCh)
        report.NEAR_BadChannels = {[num2str(badChans)]};
        report.LOF_Threshold = {[num2str(thresh_lof_update)]};
    else
        report.NEAR_BadChannels = {'No bad channel detection is employed'};
    end
    
    if(isBadSeg)
        report.NEAR_BadSegments = {['For the given ASR Parameter ' num2str(rej_cutoff) ', about ' num2str(tot_samples_modified) '% of samples are modified/rejected.'...
            ' About ' num2str(change_in_RMS) '% of RMS variance is reduced by ASR']};
    else
        report.NEAR_BadSegments = {'No bad epochs correction/rejection is employed'};
    end
    
    if(isInterp)
        report.Interpolation = {[interp_type ' interpolation is done for the missing channels (if any): ' num2str(badChans)]};
    else
        report.Interpolation = {'No Interpolation is applied'};
    end
    
    if(isAvg)
        if(isempty(reref))
            report.Rerefencing = {'Average re-referencing is performed'};
        else
            if(isnumeric(reref))
                refch = num2str(reref);
            else
                refch = cell2mat(reref);
            end
            report.Rerefencing = {['Re-referencing is performed with respect to the channel: ' refch]};
        end
        
    else
        report.Rerefencing = {'No Re-referencing is performed'};
    end
    
    
    if(isSave)
        report.Save = {['The processed file can be found in the folder ' [dloc filesep 'NEAR_Processed']]};
    else
        report.Save = {'The processed file is not opted to be saved. Set isSave = 1 if you want to save.'};
    end
    
    
    
    
    d = {'Parameter', 'Value';...
        'File Name', name ;'File Location', dloc; ...
        'Low Pass Filtering', report.LowPassFiltering; ...
         'High Pass Filtering', report.HighPassFiltering; ...
         'Segmentation (Look Times)', report.SegmentationLookUp; ...
         'Bad Channels', report.NEAR_BadChannels; ...
         'LOF Threshold', report.LOF_Threshold; ...
         'Bad Segments (ASR)', report.NEAR_BadSegments; ...
         'Epoching (ERP)', report.ERP; ...
         'Interpolation', report.Interpolation; ...
         'Re-referencing', report.Rerefencing; ...
         'Save Status', report.Save};
     
     writetable(cell2table(d), [dloc filesep 'NEAR_Reports' filesep name '.csv'], 'WriteVariableNames', 0)
end


