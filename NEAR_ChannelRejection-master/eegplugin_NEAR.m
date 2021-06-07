% eegplugin_NEAR() - a wrapper to plug-in NEAR pipeline into EEGLAB
% 
% Usage:
%   >> eegplugin_NEAR(fig,try_strings,catch_strings);
%
%   see also: pop_NEAR.m, NEAR_getBadChannels.m
%
% Author: Velu Prabhakar Kumaravel
% PhD Student (FBK & CIMEC-UNITN, Trento, Italy)
% email: velu.kumaravel@unitn.it
%
%
% History:
% 05/26/2021 ver 0.10 by Velu Prabhakar Kumaravel. Created.
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


function eegplugin_NEAR(fig, try_strings, catch_strings)

cmd = [ try_strings.check_data ...
        '[EEG,EEG,CURRENTSET,LASTCOM] = pop_NEAR(ALLEEG,EEG,CURRENTSET);' ...
        catch_strings.new_and_hist ];

    toolsmenu = findobj(fig, 'tag', 'tools');
    uimenu( toolsmenu, 'label', 'NEAR - Channel Rejection', ...
    'callback', cmd);




