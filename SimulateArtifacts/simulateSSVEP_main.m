%% Simulation of newborn/infant SSVEP data with artifacts %%
%
% Uses the SEREEGA toolbox:
% GitHub site: https://github.com/lrkrol/SEREEGA
% Reference: https://doi.org/10.1016/j.jneumeth.2018.08.001
% Requirement: Download SEREEGA from the Github site to your computer and add all its (sub)directories to MATLAB's path.
% Read SEREEGA tutorial on the Github site for familiarizing with the SEREEGA simulation.
%
% Authors: Marco Buiatti and Velu Kumaravel, CIMeC (University of Trento, Italy), 2021.

%% Generate EEG data with neurophysiologically plausible ongoing EEG + SSVEP
% dataset duration, in ms
duration = 250 * 1000;
% SSVEP (tag) frequency
tf  = 0.8;
% signal-to-noise ratio
snr=0.05;
% sampling rate
srate = 250;
% data name and path
fname = 'simSSVEP';
fpath = 'C:\Users\marco.buiatti\marco\projects\NEAR\simulation\';

% generate leadfield (requires the file 'sa_nyhead.mat' in the working
% folder)
leadfield   = lf_generate_fromnyhead('montage', 'S64');

% simulate EEG dataset and save
EEG = simulateSSVEP_GT(srate, duration, tf, snr, leadfield);
EEG = pop_saveset( EEG, 'filename', strcat(fname, '.set'),'filepath', fpath);

%% Add Bad Channels
[EEG_bc, list_bad, nTot] = generateBADChannelsSSVEP(EEG);
EEG_bc.BadCh.GroundTruth = list_bad;
fname_bc = [fname '_bc'];
EEG_bc = pop_saveset(EEG_bc, 'filename',strcat(fname_bc,'.set'),'filepath',fpath);

%% Add transitory high-amplitude artefacts
EEG_bc_j=generateJumpsSSVEP(EEG_bc);
fname_bc_j = [fname_bc '_j'];
EEG_bc_j = pop_saveset(EEG_bc_j, 'filename',strcat(fname_bc_j,'.set'),'filepath',fpath);
