%% Simulation of newborn/infant ERP data with artifacts %%
%
% Uses the SEREEGA toolbox:
% GitHub site: https://github.com/lrkrol/SEREEGA
% Reference: https://doi.org/10.1016/j.jneumeth.2018.08.001
% Requirement: Download SEREEGA from the Github site to your computer and add all its (sub)directories to MATLAB's path.
% Read SEREEGA tutorial on the Github site for familiarizing with the SEREEGA simulation.
%
% Authors: Marco Buiatti and Velu Kumaravel, CIMeC (University of Trento, Italy), 2021.

%% Generate EEG data with neurophysiologically plausible ongoing EEG + ERP
%
% epoch duration, in ms
duration = 2000;
% number of epochs
nep = 32;
% signal-to-noise ratio
snr=0.07;
% sampling rate
srate = 250;
% data name and path
fname = 'simERP';
fpath = 'C:\Users\marco.buiatti\marco\projects\NEAR\simulation\';

% generate leadfield (requires the file 'sa_nyhead.mat' in the working
% folder, obtained from https://www.parralab.org/nyhead/ , link in "Lead
% field of the New York Head (Matlab format)."
leadfield   = lf_generate_fromnyhead('montage', 'S64');

% simulate EEG Ground Truth dataset and save
EEG = simulateERP_GT(srate, duration, nep, snr, leadfield);
EEG = pop_saveset( EEG, 'filename', strcat(fname, '.set'),'filepath', fpath);

%% Add Bad Channels
[EEG_bc, list_bad, nTot] = generateBADChannelsERP(EEG);
EEG_bc.BadCh.GroundTruth = list_bad;
fname_bc = [fname '_bc'];
EEG_bc = pop_saveset(EEG_bc, 'filename',strcat(fname_bc,'.set'),'filepath',fpath);

%% Add transitory high-amplitude artefacts
EEG_bc_j=generateJumpsERP(EEG_bc);
fname_bc_j = [fname_bc '_j'];
EEG_bc_j = pop_saveset(EEG_bc_j, 'filename',strcat(fname_bc_j,'.set'),'filepath',fpath);
