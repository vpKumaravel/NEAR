%************************************************************************
% ASR Parameter Tuning
% Version 0.1
% Developed at FBK & CIMeC (UNITN), Trento, Italy
%
% Author: Velu Prabhakar Kumaravel 
% Contact: velu.kumaravel@unitn.it / vpr.kumaravel@gmail.com
%
% ASR is a widely used artifacts removal tool for EEG. The crucial
% user-defined parameters can vary depending on the level of noisiness,
% kind of population studied, EEG recording setup, Experimental protocol
% etc.,
%
% As of now, there is no single parameter settings for all. This script
% might be useful to understand the best parameters (where the neural
% response is maximized) on a subset of total number of subjects (Training
% Data in the Machine Learning context).
%
% This script is not ready-to-go but can be updated easily with little
% programming skills.
%
% The crucial part to be added by the user of this script is the quality
% measure defined in line 38 of evalASRparams.m file (replacing the dummy
% value 1.)
%
% Ideally, ASR should be run after removing the bad channels. Therefore, it
% is recommended to run this script after that step.
%
% The variable rawEEG should be created as stated in REQUIREMENT 2 below.
%
% This software is released under the GNU General Public License version 3
% *************************************************************************
%% README

% REQUIREMENT: Ensure adding relevant pre-processing steps such as
% filtering etc., and define the quality measure to calibrate ASR
% Parameter.


%%
clc;
clear;
close all;
eeglab;
%%

datanames_chRemoved = {'sXX_chRemoved.set' ,...
    'sYY_NoBadChannels.set'}; % List of datasets to be processed


dloc = 'C:\\XXX\\YY\\'; % Location of the datasets on the drive

rawEEG = EEG; % Create this variable as suggested in the comments section

range_k = [1 50]; % Enter the range of ASR parameters that you'd like to evaluate
k_step  = 1; % Enter the step size (default: 1)

burstRej = 'off'; % off for ASR Correction; on for ASR Removal.

k_in_array = range_k(1):k_step:range_k(2); %
process_array = repmat({burstRej},length(k_in_array),1); % 'on' or 'off'

T = table;

outfname = 'test.csv'; % change the name you wish - NB: the file will be saved in the current MATLAB directory

for i = 1:length(datanames_chRemoved)

    try
        
        fname   = datanames_chRemoved{i};
        tmpName = strsplit(fname, '.');
        sname   = tmpName{1}; % first cell of split contains the name of the dataset
        [measure, error_log] = evalASRparams(dloc, fname, k_in_array, process_array, rawEEG);
                
        if(i == 1)
            T.Subject = repmat({sname},length(k_in_array),1);
            T.K = k_in_array';
            T.Process = process_array;
            T.Measure = measure;
            T.Error = error_log';
        else
            temp = T(1:length(k_in_array),:);
            temp.Subject = repmat({sname},length(k_in_array),1);
            temp.K = k_in_array';
            temp.Process = process_array;
            temp.Measure = measure;
            temp.Error = error_log';
            T = [T; temp];
        end
        
        writetable(T, outfname);
        
    catch EX
        
        disp(EX);
        
    end
end

%% Figure
% Once you get the measures for each k and each processing mode
% the following plot could give you insights

% X-axis - k_in_array
% Y-axis - Measure for each k 
% Repeat this for another processing mode

% A sample script would be 

figure();
plot(k_in_array, T_on.Measure); % for burst rejection "on"
hold on;
plot(k_in_array, T_off.Measure); % for burst rejection "off"




