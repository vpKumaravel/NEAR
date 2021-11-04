function [colors] = NEAR_plotBadChannels (EEG, red_chFlat, red_chLOF, yellow_chPA)

% NEAR_plotBadChannels() - plot the given list of channels in different colors
%
% usage: Used in NEAR - detect bad channels to color-code the bad channels
% as red and yellow to provide feedback to the users
%
% Note: This function can also be used as a stand-alone method to plot channels in yellow and red colors for any other visualization purposes
%
% Color significance: 
% a) Red    - A higher probability of the given channel being an outlier
% b) Yellow - A slighly lower probability of the given channel being an outlier
%
%
% Syntax:  [colors] = NEAR_plotBadChannels (EEG,options..)
%
% Inputs:
%    EEG                      - raw/filtered input EEG 
%    red_chFlat               - List of flat-line channels
%    red_chLOF                - List of LOF-detected outlier channels
%    yellow_chPA              - List of Periodogram-detected outlier channels

%
% Outputs:
%    Plots the eeg data with color coded channels
%    colors (optional)     - List of channel arrays with colors codes

%
% Examples: 
%    [colors] = NEAR_plotBadChannels (EEG, [1 3 5], [4],[124]);
%    [colors] = NEAR_plotBadChannels (EEG, [1 3 5], [],[124]);
%    [colors] = NEAR_plotBadChannels (EEG, [], [1 3 5],[124]);
%

% See also: pop_chanremove.m, NEAR_getBadChannels.m 

% Author: Velu Prabhakar Kumaravel
% PhD Student (FBK & CIMEC-UNITN, Trento, Italy)
% email: velu.kumaravel@unitn.it
% May 2021; Last revision: 20-May-2021


colors = repmat({'k'},1, EEG.nbchan);

for i = 1:length(yellow_chPA)
    colors(1,yellow_chPA(i)) = 	{[0.9290, 0.6940, 0.1250]};
end

for i = 1:length(red_chLOF)
    colors(1,red_chLOF(i)) = {'r'};
end

for i = 1:length(red_chFlat)
    colors(1,red_chFlat(i)) = {'r'};
end

badChans = sort(unique(union(union(red_chFlat, red_chLOF),yellow_chPA)));

if(~isempty(badChans))
    if(size(badChans,1) ~= 1)
        badChans = badChans';
    end
end

% adding the command for the 'reject' button on the plot window

tmpcom = [ '[ALLEEG, EEG, CURRENTSET, com] = pop_chanremove(ALLEEG, EEG, CURRENTSET, [' num2str(badChans) ']); eeglab (''redraw'');' ];

% The following variables are required to be defined to plot 

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

eegplot(EEG.data, 'srate', EEG.srate, 'title', 'Scroll component activities -- eegplot()', ...
    'limits', [EEG.xmin EEG.xmax]*1000, 'color', colors, 'command', tmpcom,  'dispchans', 5, 'spacing', 500, eegplotoptions{:});


end

