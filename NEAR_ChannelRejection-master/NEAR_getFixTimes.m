function segt=NEAR_getFixTimes(m,subj,thr)

% Input:
% m = matrix of segmentation times, imported from excel file with importdata
% subj = subject number
% thr = minimal segment duration (in ms)
% Output:
% segt = segmentation times (beginning, end)
%
% Author: Marco Buiatti, CIMeC (University of Trento, Italy), 2018-.

m_loc=eval(['m.data.' num2str(subj)]);

segt_loc(:,1)=m_loc(~isnan(m_loc(:,1)),1); % BEGIN visual attention time in ms
segt_loc(:,2)=m_loc(~isnan(m_loc(:,2)),2); % END visual attention time in ms

fixt = [segt_loc(:,2) - segt_loc(:,1)]; % Total period of visual attention

% Accept only if the total period is greater than the given threshold
segt(:,1)=segt_loc(fixt>thr,1)/1000; 
segt(:,2)=segt_loc(fixt>thr,2)/1000;
