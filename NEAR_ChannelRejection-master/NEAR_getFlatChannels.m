function  flatch = NEAR_getFlatChannels(signal, max_flatline_duration, max_allowed_jitter)

% Remove flat-lined channels.

% flatch = NEAR_plotBadChannels(Signal,MaxFlatlineDuration,MaxAllowedJitter)
%
% This is an automated artifact rejection function which ensures that 
% the data contains no flat-lined channels.
%
% In:
%   Signal : continuous data set, assumed to be appropriately high-passed (e.g. >0.5Hz or
%            with a 0.5Hz - 2.0Hz transition band)
%
%   MaxFlatlineDuration : Maximum tolerated flatline duration. In seconds. If a channel has a longer
%                         flatline than this, it will be considered abnormal. Default: 5
%
%   MaxAllowedJitter : Maximum tolerated jitter during flatlines. As a multiple of epsilon.
%                      Default: 20
%
% Out:
%   Flatch : Detected flat channels (if any)
%
% Examples:
%   % use with defaults
%   flatch = NEAR_getFlatChannels(EEG);
%
%   Author: Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%           2012-08-30
%
%  Modification: Velu Prabhakar Kumaravel, FBK / CIMEC-UNITN, Trento, Italy
%           2021-05-22

% Copyright (C) Christian Kothe, SCCN, 2012, ckothe@ucsd.edu
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU
% General Public License as published by the Free Software Foundation; either version 2 of the
% License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
% even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% General Public License for more details.
%
% You should have received a copy of the GNU General Public License along with this program; if not,
% write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
% USA

if ~exist('max_flatline_duration','var') || isempty(max_flatline_duration) max_flatline_duration = 5; end
if ~exist('max_allowed_jitter','var') || isempty(max_allowed_jitter) max_allowed_jitter = 20; end

flatch = [];
const_decimal = 2e-10;

MAX_FLAT_TIME = max_flatline_duration;
if MAX_FLAT_TIME > 0 && MAX_FLAT_TIME < 1  %#ok<*NODEF>
    MAX_FLAT_TIME = size(signal.data,2)*MAX_FLAT_TIME;
else
    MAX_FLAT_TIME = signal.srate*MAX_FLAT_TIME;
end


% flag channels
removed_channels = false(1,signal.nbchan);
for c=1:signal.nbchan
    zero_intervals = reshape(find(diff([false abs(diff(signal.data(c,:)))<(max_allowed_jitter*const_decimal) false])),2,[])';
    if max(zero_intervals(:,2) - zero_intervals(:,1)) > MAX_FLAT_TIME
        removed_channels(c) = true; end
end

% remove them
if all(removed_channels)
    disp('Warning: all channels have a flat-line portion; not removing anything.');
elseif any(removed_channels)

    flatch = find(removed_channels);
    
    if isfield(signal.etc,'clean_channel_mask')
        signal.etc.clean_channel_mask(signal.etc.clean_channel_mask) = ~removed_channels;
    else
        signal.etc.clean_channel_mask = ~removed_channels;
    end
end
