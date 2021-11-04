function [ALLEEG, OUTEEG, CURRENTSET, com] = pop_chanremove(ALLEEG, INEEG, CURRENTSET, channels)

% pop_chanremove() - pop-window to edit bad channels and remove from an EEG dataset.
%
% Usage: Removes channels detected by NEAR Plugin
%
% NOTE : Can also be used as a standalone function to remove the given list of 'bad' channels by the user 
%
% Syntax:  [ALLEEG, OUTEEG, CURRENTSET, com] = pop_chanremove(ALLEEG, EEG, CURRENTSET, channels)
%
% Inputs:
%    ALLEEG     - EEGLAB system parameter
%    INEEG      - Input EEG struct
%    CURRENTSET - EEGLAB system parameter
%    channels   - vector of channels to remove from the data.
%
%
% Outputs:
%    ALLEEG     - updated ALLEEG
%    OUTEEG     - Output EEG struct (with removed channels)
%    CURRENTSET - updated CURRENTSET
%    com        - updated command parameter
%
%
% Example: 
%    [ALLEEG, EEG, CURRENTSET, com] = pop_chanremove(ALLEEG, EEG, CURRENTSET, 44); eeglab redraw;
%
%
% See also: plotbadchannels.m, NEAR_getBadChannels.m 
%
% Author: Velu Prabhakar Kumaravel
% PhD Student (FBK & CIMEC-UNITN, Trento, Italy)
% email: velu.kumaravel@unitn.it
% May 2021; Last revision: 20-May-2021



com='';
if nargin < 4
   help pop_chanremove;
   return;
end

if(isempty(channels))
   fprintf('No channels to remove. Exit.'); 
   return;
end


	% popup window parameters

    uilist    = { { 'style' 'text' 'string' 'Channel(s) to remove from data:' } ...
                  { 'style' 'edit' 'string' int2str(channels) } ...
                };
            
    geom = { [2 1.3] };
	result       = inputgui( 'uilist', uilist, 'geometry', geom, 'helpcom', 'pophelp(''pop_chanremove'')', ...
                                     'title', 'NEAR - Remove channels from data -- pop_chanremove()');
                                 if isempty(result)
                                     fprintf('Operation cancelled ...\n');
                                     OUTEEG = INEEG;
                                     return;
                                 end
    
	channels   = eval( [ '[' result{1} ']' ] );
    if(isempty(channels))
        disp('Channel Removal is aborted');
        OUTEEG = INEEG;
        OUTEEG.BadCh = [];
    else
        INEEG = pop_select(INEEG, 'nochannel', channels);
        [ALLEEG, OUTEEG, CURRENTSET, com] = pop_newset(ALLEEG, INEEG, CURRENTSET, 'setname', [INEEG.setname '_ChRemoval']);
        eeglab redraw;
    end
        
end
