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
% 2) Download the NEAR pipeline (github link: https://github.com/Velu44/NEAR_TestRep) and extract the files in the folder \eeglabxxx\plugins\..
%
%
% Please cite the following references for in any manuscripts produced utilizing NEAR pipeline:
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

%% Define subject lists, file locations, and parameters for NEAR pipeline

dnames_list = { 's108.set', 's216.set'};
dloc = 'D:\\XXX\\YY';
isSave = 1; % set to 0 if you do not want the preprocessed data to be saved


params.isLPF    = 1; % set to 0 if your data is already low-pass filtered
params.isHPF    = 1; % set to 0 if your data is already high-pass filtered
params.isSegt   = 1; % set to 0 if you do not want to segment the data based on newborn's visual attention for the presented stimuli
params.isBadCh  = 1; % set to 0 if you do not want to remove the bad channels using NEAR plugin
params.isVisIns = 0; % set to 0 if you do not want to visually inspect the detected bad channels before removing them
params.isBadSeg = 1; % set to 0 if you do not want to remove the bad channels using NEAR plugin
params.isInterp = 1; % set to 0 if you do not want to interpolate the removed bad channels
params.isAvg    = 1; % set to 0 if you do not want to perform average referencing of EGI system

% Low-pass filter parameters begin %
params.lpc     = 40; % low-pass filter cut-off frequency in Hz; set to [] if isLPF = 0;
params.nOrder  = 84; % Order depends on the sampling rate and the lpc; 84 is valid for lpc = 40 Hz and srate = 250 Hz; set to [] if isLPF = 0;
% Low-pass filter parameters end %

% High-pass filter parameters begin %
params.hptf    = [0.15 0.3]; % high-pass transition edge - [low_freq high_freq] in Hz; set to [] if isHPF = 0;
% High-pass filter parameters end %

% Segmentation using fixation intervals - parameters begin %
params.sname = 'segt_visual_attention.xlsx';
params.sloc  = 'C:\\zzz\\yy';
params.look_thr = 4999; % consider only the segments that exceed this threshold+1 in ms to retain
% Segmentation using fixation intervals - parameters end %


% Parameters for NEAR - Bad Channels Detection begin %

params.isplot = 0; % set to 1 if you want to visualize some stats otherwise to 0

% d) flat channels
params.isFlat  = 1; % flag variable to enable or disable Flat-lines detection method (default: 1)
params.flatWin = 5; % tolerance level in s(default: 5)

% b) LOF (density-based)
params.isLOF       = 1;  % flag variable to enable or disable LOF method (default: 1)
params.dist_metric = 'seuclidean'; % Distance metric to compute k-distance
params.thresh_lof  = 2.5; % Threshold cut-off for outlier detection on LOF scores


% c) Periodogram (frequency based)
params.isPeriodogram = 0; % flag variable to enable or disable periodogram method (default: 0)
params.frange        = [1 20]; % Frequency Range in Hz
params.winsize       = 1; % window length in s
params.winov         = 0.66; % 66% overlap factor
params.pthresh       = 4.5; % Threshold Factor to predict outliers on the computed energy


% Parameters for NEAR - Bad Channels Detection end %

% Parameters for ASR begin %

params.rej_cutoff = 24;   % A lower value implies severe removal (Recommended value range: 20 to 30)
params.rej_mode   = 'on'; % Set to 'off' for ASR Correction and 'on for ASR Removal (default: 'on')
params.addn_reject = 'off'; % Set to 'on' for additional rejection of bad segments if any after ASR processing (default: 'off')

for iSub = 1:1
    [outEEG] = run_NEAR(dnames_list{iSub}, dloc, params);
    
    if(isSave)
        tmpName = strsplit(dnames_list{iSub},'.');
        sName   = tmpName{1};
        % Save data on the same location dloc
        outEEG = pop_saveset( outEEG, 'filename',[sName '_NEAR_prep.set'],'filepath', dloc);
    end
    
    %perform your post-processing the NEAR pre-processed data%%
    %                                                         %
    %                                                         %
    %                                                         %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
end
