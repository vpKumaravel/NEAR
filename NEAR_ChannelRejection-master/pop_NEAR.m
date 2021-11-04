% pop_NEAR - Launches GUI to collect user inputs for NEAR_getBadChannels().
%
% Neonatal EEG Artifacts Removal (NEAR) is a pipeline dedicated to neonatal
% and/or developmental EEG. This pop function is to identify and remove bad
% channels.
%
% Method 1: Detect and Remove Flat Lines (reused the code - clean_FlatLines from ASR)
% Method 2: Detect Outlier channels using Local Outlier Factor (LOF)
% Method 3 (optional): Remove Outlier channels using Periodogram Analysis
%
% LOF and Periodogram analysis are done with the non-flat line channels
% unless 'Method 1' is deselected by the user.
%
% Usage:
%   >>  [ALLEEG,EEG,CURRENTSET,com] = pop_NEAR(ALLEEG,EEG,CURRENTSET);
%
% To remove methods, simply uncheck the item
% The default parameters can be changed, if needed.
%
% Output: EEG is the output EEGLAB struct
% EEG.BadCh contains the list of bad channels detected by each of the
% methods
%
%
% See also: NEAR_getBadChannels.m
%
% Author: Velu Prabhakar Kumaravel
% PhD Student (FBK & CIMEC-UNITN, Trento, Italy)
% email: velu.kumaravel@unitn.it
% May 2021; Last revision: 19-May-2021
%
%
% Copyright (C) 2021, Velu Prabhakar Kumaravel, FBK, CIMEC
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%

%------------- BEGIN CODE -------------------------------------------------

function [ALLEEG,EEG,CURRENTSET,com] = pop_NEAR(ALLEEG,EEG,CURRENTSET,varargin)

com = '';
import_error = 1;

if(~isempty(EEG.data))
    
    % Adding an EEG Structure Field to trace the list of Bad Channels
   
    EEG.BadCh = struct();
    EEG.BadCh.Flat = [];
    EEG.BadCh.Outlier = [];
    EEG.BadCh.Muscle = [];
    
    if nargin < 1
        help pop_main_CR;
        return;
    end
    
    if nargin < 4
        

        cb_setflat =  'set(findobj(''parent'', gcbf, ''tag'', ''editFlat'')    , ''enable'', ''on'');';
        cb_resetflat =  'set(findobj(''parent'', gcbf, ''tag'', ''editFlat'')    , ''enable'', ''off'');';
        cb_iflat    = [ 'set(findobj(''parent'', gcbf, ''tag'', ''strTitle'')      , ''value'', ~get(gcbo, ''value''));' ...
            'if get(gcbo, ''value''),' cb_setflat ...
            'else,'                    cb_resetflat ...
            'end;' ];
        
        cb_setoutlier =  ['set(findobj(''parent'', gcbf, ''tag'', ''cutoff_lof'')    , ''enable'', ''on'');' ...
            'set(findobj(''parent'', gcbf, ''tag'', ''dist_metric'')    , ''enable'', ''on'');'];
        cb_resetoutlier = ['set(findobj(''parent'', gcbf, ''tag'', ''cutoff_lof'')    , ''enable'', ''off'');' ...
             'set(findobj(''parent'', gcbf, ''tag'', ''dist_metric'')    , ''enable'', ''off'');'];
        cb_ioutlier    = [ 'set(findobj(''parent'', gcbf, ''tag'', ''strOut'')      , ''value'', ~get(gcbo, ''value''));' ...
            'if get(gcbo, ''value''),' cb_setoutlier ...
            'else,'                    cb_resetoutlier ...
            'end;' ];
        
        
        cb_setmotion =  ['set(findobj(''parent'', gcbf, ''tag'', ''wname'')    , ''enable'', ''on'');' ...
            'set(findobj(''parent'', gcbf, ''tag'', ''frange'')    , ''enable'', ''on'');' ...
            'set(findobj(''parent'', gcbf, ''tag'', ''win_size_p'')    , ''enable'', ''on'');' ...
            'set(findobj(''parent'', gcbf, ''tag'', ''win_ov_p'')    , ''enable'', ''on'');' ...
             'set(findobj(''parent'', gcbf, ''tag'', ''powthr_wav'')    , ''enable'', ''on'');'
            ];
        cb_resetmotion = ['set(findobj(''parent'', gcbf, ''tag'', ''wname'')    , ''enable'', ''off'');' ...
            'set(findobj(''parent'', gcbf, ''tag'', ''frange'')    , ''enable'', ''off'');' ...
            'set(findobj(''parent'', gcbf, ''tag'', ''win_size_p'')    , ''enable'', ''off'');' ...
            'set(findobj(''parent'', gcbf, ''tag'', ''win_ov_p'')    , ''enable'', ''off'');' ...
             'set(findobj(''parent'', gcbf, ''tag'', ''powthr_wav'')    , ''enable'', ''off'');'
            ];
        cb_imotion   = [ 'set(findobj(''parent'', gcbf, ''tag'', ''strWavelet'')      , ''value'', ~get(gcbo, ''value''));' ...
            'if get(gcbo, ''value''),' cb_setmotion ...
            'else,'                    cb_resetmotion ...
            'end;' ];
        
        
        uilist = { { 'style' 'text' 'string' 'Channel Rejection Methods' 'FontWeight' 'bold' 'tag' 'strTitle' }...
            { 'style' 'checkbox' 'string' 'Remove Flatlines' 'FontWeight' 'bold' 'value' 1 'callback' cb_iflat }...
            { 'style' 'text' 'string' 'Flat Line - Window Duration (s)' } ...
            { 'style' 'edit' 'tag' 'editFlat' 'string' '5' 'enable' 'on'} ...
            {} ...
            { 'style' 'checkbox' 'string' 'Remove Outliers (LOF Method)' 'FontWeight' 'bold' 'value' 1  'callback' cb_ioutlier} ...
            { 'style' 'text' 'string' 'LOF Cut-off' 'tag' 'strOut' } ...
            { 'style' 'edit' 'tag' 'cutoff_lof' 'string' '2.5'  'enable' 'on' } ...
            { 'style' 'text' 'string' 'Distance Metric' 'tag' 'strOut' } ...
            { 'style' 'edit' 'tag' 'dist_metric' 'string' 'seuclidean'  'enable' 'on' } ...
            { 'style' 'text' 'string' 'Other possible distance metrics: euclidean, spearman, correlation' }...
            { 'style' 'text' 'string' 'Adaptive thresholding if detected bad channels exceed % of total channels' 'tag' 'strOut' } ...
            { 'style' 'edit' 'tag' 'dist_metric' 'string' '10'  'enable' 'on' } ...
            {} ...
            { 'style' 'checkbox' 'string' 'Detect Motion Noise (Spectral Analysis)' 'FontWeight' 'bold' 'value' 0  'callback' cb_imotion} ...
            { 'style' 'text' 'string' 'Frequency Band (Hz)' } ...
            { 'style' 'edit'  'tag' 'frange' 'string' '[1 20]'  'enable' 'on'} ...
            { 'style' 'text' 'string' 'Window Size (s)' } ...
            { 'style' 'edit' 'tag' 'win_size_p' 'string' '1'  'enable' 'on'} ...
            { 'style' 'text' 'string' 'Window Overlap Factor' } ...
            { 'style' 'edit' 'tag' 'win_ov_p' 'string' '0.66'  'enable' 'on'} ...
            { 'style' 'text' 'string' 'Threshold Factor' } ...
            { 'style' 'edit' 'tag' 'powthr_wav' 'string' '4.5'  'enable' 'on'} ...
            };
        
        geom = { [1] [1] [5 3.5] [1] [1] [5 3.5] [5 3.5]  [1] [5 3.5] [1] [1] [5 3.5] [5 3.5] [5 3.5] [5 3.5]};
        result = inputgui( 'uilist', uilist, 'geometry', geom,  'title', 'NEAR - Channel Rejection Tool', ...
            'helpcom', 'pophelp(''pop_NEAR'')');
        
        
        if isempty(result)
            fprintf('Operation cancelled ...\n');
            return;
        end
        
        options = { 'isFlat' result{1} 'flatWin' str2num(result{2}) 'isOutlier' result{3} 'cutoff_lof' str2num(result{4})  ...    
        'dist_metric', result{5} 'isAdapt' str2num(result{6}) 'isMuscle' result{7} 'frange' eval( [ '[' result{8} ']' ] ) 'win_size_p' str2num(result{9})  'win_ov_p'  str2num(result{10})...
            'pthresh' str2num(result{11})};
        
    else
        options = varargin;
    end
    
    opt = finputcheck( options, { 'isFlat' , 'real' [] 1;
        'flatWin' 'real' []                      5;
        'isOutlier' , 'real' [] 1;
        'cutoff_lof' 'real'   []                      2.5;
        'dist_metric', 'string' [] 'seuclidean';
        'isAdapt', 'real' [] 10;
        'isMuscle' , 'real' [] 1;
        'frange' 'real' [] [1 20];
       'win_size_p', 'integer' [] 1;
        'win_ov_p', 'integer' [] 0.66;
        'pthresh', 'integer' [] 4.5;
        }, 'pop_NEAR');
    
    if isstring(opt), error(opt); end
    
    opt.isPlot = 1;
    % Call the methods function to compute bad channels using the selected methods
    [EEG, red_chFlat, red_ch, yellow_ch] = NEAR_getBadChannels(EEG,opt.isFlat, opt.flatWin,  opt.isOutlier, opt.cutoff_lof, opt.dist_metric, opt.isAdapt, opt.isMuscle, opt.frange, opt.win_size_p, opt.win_ov_p, opt.pthresh, opt.isPlot);
    
    
    if (~isempty(red_chFlat) || ~isempty(red_ch) || ~isempty(yellow_ch))
        [colors] = NEAR_plotBadChannels(EEG,red_chFlat, red_ch,yellow_ch); % plot the bad channels and let the user decide
        EEG.comments = pop_comments(EEG.comments,'','Bad channels were detected using NEAR',1);
    else
        EEG.comments = pop_comments(EEG.comments,'','No bad channels were detected using NEAR',1);
    end
    
    
else
    fprintf(2,'\nPlease import data to perform bad channel detection\t');
    fprintf(2,'\nExiting operation...\n');
    import_error = 0;
end

if(import_error)
    fprintf('\n');
    disp('Summary: ');
    disp(EEG.BadCh);
end

% Output eegh.
com = sprintf('[ALLEEG,EEG,CURRENTSET,com] = pop_NEAR(ALLEEG,EEG,CURRENTSET, %s);', vararg2str(options));
eegh(com);
com = ''; % set com to null otherwise pop_newset opens up unnecessarily.

return;

%------------- END OF CODE ------------------------------------------------

