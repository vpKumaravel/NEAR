% ************************************************************************
% Neonatal EEG Artifacts Removal (NEAR) Pipeline Script
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

%%

% N.B: Please run the NEAR_Pipeline_Tutorial_v1_0.m file to get
% familiarized with the parameters for a sample subject before running this
% script.

%% Clear variables and open EEGLAB

clc;
clear all;
eeglab;

addpath(genpath(cd));

%% Define User-Parameters here

% Please read the parameters.doc file for more information: LINK to be
% provided


params.isLPF    = 0; % set to 1 if you want to perform Low Pass Filtering
params.isHPF    = 0; % set to 1 if you want to perform High Pass Filterting
params.isSegt   = 0; % set to 0 if you do not want to segment the data based on newborn's visual attention for the presented stimuli
params.isERP    = 0; % set to 1 if you want to epoch the data for ERP processing
params.isBadCh  = 1; % set to 1 if you want to employ NEAR Bad Channel Detection 
params.isBadSeg = 1; % set to 1 if you want to emply NEAR Bad Epochs Rejection/Correction (using ASR)
params.isVisIns = 1; % set to 1 if you want to visualize intermediate cleaning of NEAR Cleaning (bad channels + bad segments)
params.isInterp = 1; % set to 1 if you want to interpolate the removed bad channels (by Spherical Interpolation)
params.isAvg    = 1; % set to 1 if you want to perform average referencing
params.isReport = 1; % set to 1 if you would like a comprehensive summary of the preprocessing done for each file
params.isSave   = 1; % set to 1 if you want to save the pre-processed data

% Low-pass filter parameters begin %
params.lpc     = 40; % low-pass filter cut-off frequency in Hz; set to [] if isLPF = 0;
% Low-pass filter parameters end %

% High-pass filter parameters begin %
params.hptf    = [0.15 0.3]; % high-pass transition edge - [low_freq high_freq] in Hz; set to [] if isHPF = 0;
% (OR)
params.hpc  = []; % high-pass cut-off frequency in Hz; set to [] if you had set hptf;

% High-pass filter parameters end %

% Segmentation using fixation intervals - parameters begin %
% N.B: The following parameters can be set to [] if params.isSegt = 0
params.sname = 'segt_visual_attention.xlsx'; % the visual segmentation coding file
params.sloc  = 'C:\Users\velu.kumaravel\Desktop\Data Drive\Code\NEAR_v1_0\NEAR'; % location of the xlsx file
params.look_thr = 4999; % consider only the segments that exceed this threshold+1 in ms to retain; alternatively can be set to [] if no thresholding is preferred
% Segmentation using fixation intervals - parameters end %

% Parameters for NEAR - Bad Channels Detection begin %

% d) flat channels
params.isFlat  = 1; % flag variable to enable or disable Flat-lines detection method (default: 1)
params.flatWin = 5; % tolerance level in s(default: 5)

% b) LOF (density-based)
params.isLOF       = 1;  % flag variable to enable or disable LOF method (default: 1)
params.dist_metric = 'seuclidean'; % Distance metric to compute k-distance
params.thresh_lof  = 2.5; % Threshold cut-off for outlier detection on LOF scores
params.isAdapt = 10; % The threshold will be incremented by a factor of 1 if the given threshold detects more than xx % 
                %of total channels (eg., 10); if this variable left empty [], no adaptive thresholding is enabled.
         

% c) Periodogram (frequency based)
params.isPeriodogram = 0; % flag variable to enable or disable periodogram method (default: 0)
params.frange        = [1 20]; % Frequency Range in Hz
params.winsize       = 1; % window length in s
params.winov         = 0.66; % 66% overlap factor
params.pthresh       = 4.5; % Threshold Factor to predict outliers on the computed energy


% Parameters for NEAR - Bad Channels Detection end %

% Parameters for NEAR- Bad Segments Correction/Rejection using ASR begin %

params.rej_cutoff = 20;   % A lower value implies severe removal (Recommended value range: 20 to 30)
params.rej_mode   = 'on'; % Set to 'off' for ASR Correction and 'on for ASR Removal (default: 'on')
params.add_reject = 'off'; % Set to 'on' for additional rejection of bad segments if any after ASR processing (default: 'off')

% Parameters for NEAR- Bad Segments Correction/Rejection using ASR end %

% Parameters for ERP epoching begin %

% N.B: The following parameters can be set to [] if params.isERP = 0
params.erp_event_markers = {'Event A', 'Event B'}; % enter all the condition markers
params.erp_epoch_duration = [0 1200]; % duration of epochs (in seconds)
params.erp_remove_baseline = 1; % 0 for no baseline correction; 1 otherwise
params.baseline_window = [0  200]; % baseline period in ms; leave it empty [] in case of entire epoch baselining

% Parameters for ERP epoching end %

% Parameter for interpolation begin %

params.interp_type = 'spherical'; % other values can be 'v4'. Please refer to pop_interp.m for more details.

% Parameter for interpolation end %



% Parameter for Re-referencing begin %
params.reref = 30; % if isAvg was set to 0, this parameter must be set.
%params.reref = {'E124'}; % reref can also be the channel name.

% Parameter for Re-referencing begin %

params.isSave = 1; % set to 0 if you do not want the preprocessed data to be saved

%% Define Subject to be analyzed and the File Path

dname = 'sim2_bc_j.set'; % name of the dataset
dloc = 'C:\Users\velu.kumaravel\Desktop\Data Drive\Code\GIT\SEREEGA\Datasets';

params.chanlocation_file = 'C:\Users\velu.kumaravel\Downloads\eeglab2021.0\eeglab2021.0\sample_locs\GSN64v2_0.sfp';
%% Run NEAR


fprintf('Current dataset: %s\n', dname);

% Run NEAR
[outEEG] = run_NEAR(dname, dloc, params, ALLEEG);

% you may add your downstream analysis code here e.g., ERP analysis and
% use outEEG as your pre-processed EEG structure

