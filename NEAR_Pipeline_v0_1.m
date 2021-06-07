% ************************************************************************
% Neonatal EEG Artifacts Removal (NEAR) Pipeline
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

clc;
clear all;
eeglab;



%% Step 0: Dataset Parameters 

dname = 's22.set'; % name of the dataset
dloc  = 'C:\\Users\\velu.kumaravel\\Desktop\\Data Drive\\Data\\Newborn\\Face-like\\'; % corresponding file location
%% Step 1: User-defined Parameters

isLPF    = 1; % set to 0 if your data is already low-pass filtered
isHPF    = 1; % set to 0 if your data is already high-pass filtered
isSegt   = 1; % set to 0 if you do not want to segment the data based on newborn's visual attention for the presented stimuli
isBadCh  = 1; % set to 0 if you do not want to remove the bad channels using NEAR plugin
isVisIns = 1; % set to 1 if you want to visually inspect the detected bad channels before removing them
isBadSeg = 1; % set to 0 if you do not want to remove/correct the bad segments using ASR
isInterp = 1; % set to 0 if you do not want to interpolate the removed bad channels
isAvg    = 1; % set to 0 if you do not want to perform average referencing
%NB: For average referencing, the given command in this pipeline is valid only for 'Cz' reference system. Please change the code if it's not the case for you.

% Low-pass filter parameters begin %
lpc     = 40; % low-pass filter cut-off frequency in Hz; set to [] if isLPF = 0;
nOrder  = 84; % Order depends on the sampling rate and the lpc; 84 is valid for lpc = 40 Hz and srate = 250 Hz; set to [] if isLPF = 0;
% Low-pass filter parameters end %

% High-pass filter parameters begin %
hptf    = [0.15 0.3]; % high-pass transition edge - [low_freq high_freq] in Hz; set to [] if isHPF = 0;
% High-pass filter parameters end %

% Segmentation using fixation intervals - parameters begin %
look_thr = 4999; % consider only the segments that exceed this threshold+1 in ms to retain
% Segmentation using fixation intervals - parameters end %


% Parameters for NEAR - Bad Channels Detection begin %

isplot = 0; % set to 1 if you want to visualize some stats otherwise to 0

% d) flat channels
isFlat  = 1; % flag variable to enable or disable Flat-lines detection method (default: 1)
flatWin = 5; % tolerance level in s(default: 5)

% b) LOF (density-based)
isLOF       = 1;  % flag variable to enable or disable LOF method (default: 1)
dist_metric = 'seuclidean'; % Distance metric to compute k-distance
thresh_lof  = 2.5; % Threshold cut-off for outlier detection on LOF scores


% c) Periodogram (frequency based)
isPeriodogram = 0; % flag variable to enable or disable periodogram method (default: 0)
frange        = [1 20]; % Frequency Range in Hz
winsize       = 1; % window length in s
winov         = 0.66; % 66% overlap factor
pthresh       = 4.5; % Threshold Factor to predict outliers on the computed energy


% Parameters for NEAR - Bad Channels Detection end %

% Parameters for ASR begin %

rej_cutoff = 24;   % A lower value implies severe removal (Recommended value range: 20 to 30)
rej_mode   = 'on'; % Set to 'off' for ASR Correction and 'on for ASR Removal (default: 'on')
add_reject = 'off'; % Set to 'on' for additional rejection of bad segments if any after ASR processing (default: 'off')

% Parameters for ASR end %

%% Step 2: Import data

EEG = pop_loadset('filename',dname,'filepath',dloc);
origEEG = EEG; % making a copy of raw data
eeglab redraw

%% Step 3: Filter data

if(isLPF)
    EEG = pop_eegfiltnew(EEG, [], lpc, nOrder, 0, [], 0); % low-pass filter
end

if(isHPF)
    EEG=clean_drifts(EEG,hptf, []); %high-pass filter
end


%% Step 4: Segment data based on newborns' visual attention

if(isSegt)
    
    try
        lookFile=importdata('segt_visual_attention.xlsx');
    catch
        error('An error occurred in importing the segmentation file. If you think this is a bug, please report on the github repo issues section');
    end
    
    if(~isempty(lookFile))
        try
            tmp = strsplit(dname, '.');
            sheetName = tmp{1};
            lookTimes=NEAR_getLookTimes(lookFile,sheetName,look_thr);
        catch
            error('An error occurred in segmentation. Does the file contain the segmentation intervals for the given subject?\n');
        end
    else
        error('We cannot find the file. Please check the file path and run again.');
    end
    
    % segment EEG data
    EEG = pop_select( EEG,'time',lookTimes);
    eeglab redraw;
end

%% Step 5: Run NEAR bad channel detection tool

if (isBadCh)
    
    [EEG, flat_ch, lof_ch, periodo_ch, LOF_vec] = NEAR_getBadChannels(EEG, isFlat, flatWin, isLOF, thresh_lof, dist_metric, ...
                                                                                                    isPeriodogram, frange, winsize, winov, pthresh, isplot);
    disp('Bad Channel Detection is performed successfully');  
    
    if(isVisIns) 
        % visual inspection and reject using 'Reject' button on the GUI
        [colors] = NEAR_plotBadChannels (EEG, flat_ch, lof_ch, periodo_ch);
    
    else 
        % direct removal of bad channels without any GUI
        badChans = sort(unique(union(union(flat_ch, lof_ch),periodo_ch)));
        
        if(~isempty(badChans))
            if(size(badChans,1) ~= 1)
                badChans = badChans';
            end
        end
        
        EEG = pop_select(EEG, 'nochannel', badChans);
        
        % saves a new dataset
        [ALLEEG, EEG, CURRENTSET, ~] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_ChRemoval']);
        eeglab redraw;
    end
    
else
    
    disp('NEAR Bad Channel Detection is not employed. Set the variable ''isBadCh'' to 1 to enable bad channel detection');
    
end



%% Step 5: Run ASR to correct or remove bad segments

if(isBadSeg)
    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion','off','LineNoiseCriterion','off', ...
        'Highpass','off','BurstCriterion',rej_cutoff,'WindowCriterion',add_reject,'BurstRejection',rej_mode,'Distance','Euclidian');
    
    [ALLEEG, EEG, CURRENTSET, ~] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_ASR']);
    eeglab redraw;
end


                         
%% Step 6: Interpolate bad channels

if(isInterp)
    EEG = pop_interp(EEG, origEEG.chanlocs, 'spherical');
    [ALLEEG, EEG, CURRENTSET, com] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', [EEG.setname '_Int']);
    eeglab redraw;
end


%% Step 7: Average Reference

% Note: This comment is valid only for the EEG system with 'Cz' as the reference electrode. Please change the code if it is not the case for you.

if(isAvg)
    EEG = pop_reref(EEG, [],'refloc',struct('labels',{'Cz'},'Y',{0},'X',{5.4492e-16},'Z',{8.8992},'sph_theta',{0},'sph_phi',{90},'sph_radius',{8.8992},'theta',{0},'radius',{0},'type',{''},'ref',{''},'urchan',{132},'datachan',{0}));
    EEG.comments = pop_comments(EEG.comments,'','Average reference, reference channel Cz added',1);
    eeglab redraw
end

