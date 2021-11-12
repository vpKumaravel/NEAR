function [outEEG, list_bad, nTot] = generateBADChannelsSSVEP(EEG)
% [outEEG, list_bad, nTot] = generateBADChannelsSSVEP(EEG)
%
% Authors: Velu Kumaravel and Marco Buiatti, CIMeC (University of Trento, Italy), 2021.

list_bad = [1 6 16 35 49];
nTot = length(list_bad);

Hd = generateMotionArtifacts;

L = EEG.pnts;             % Total number of time points
t = (0:L-1)/EEG.srate;    % Time vector

% flat channels
EEG.data(list_bad(1),:) = 0;
% noisy channels
EEG.data(list_bad(2),1:16250) = EEG.data(list_bad(2),1:16250) + filter(Hd, 10*std(EEG.data(list_bad(2),1:16250))*randn(size([1:16250])));
EEG.data(list_bad(2),31250:40000) = EEG.data(list_bad(2),31250:40000) + 10*std(EEG.data(list_bad(2),31250:40000))*randn(size([31250:40000]));
EEG.data(list_bad(2),51250:60000) = EEG.data(list_bad(2),51250:60000) + filter(Hd,  10*std(EEG.data(list_bad(2),51250:60000))*randn(size([51250:60000])));
EEG.data(list_bad(3),:) = EEG.data(list_bad(3),:) + filter(Hd, 10*std(EEG.data(list_bad(3),:))*randn(size(t)));
EEG.data(list_bad(3),51250:60000) = EEG.data(list_bad(3),51250:60000) + filter(Hd, 10*std(EEG.data(list_bad(3),51250:60000))*randn(size(51250:60000)));
EEG.data(list_bad(4), 250: 500) = 150;% electrical discontinuities
EEG.data(list_bad(4), 2500: 3000) = 60;% electrical discontinuities
EEG.data(list_bad(4), 900: 1200) = 80;% electrical discontinuities
EEG.data(list_bad(4),:) = EEG.data(list_bad(4),:) + filter(Hd, 7*std(EEG.data(list_bad(4),:))*randn(size(t)));
EEG.data(list_bad(5),:) = 1;% flat channel

outEEG = EEG;
outEEG.velu.CreatedBadChannels = list_bad;
outEEG.velu.TotalBadChannels = nTot;

end