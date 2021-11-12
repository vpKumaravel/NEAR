function EEG=generateJumpsSSVEP(EEG)
% EEG=generateJumpsSSVEP(EEG)
%
% Authors: Marco Buiatti and Velu Kumaravel, CIMeC (University of Trento, Italy), 2021.

stdEEG=mean(std(EEG.data,0,2));
% add artifacts on the first half of the data only, to leave at least one
% whole block of frequency-tagging stimulation
L=round(length(EEG.times)/2);
% L=length(EEG.times);
% jump amplitude in std
A=8; 
% number of jumps
N=30;
jump_timebins=randperm(L,N);
jump_timebins2=randperm(L,N);
% jump duration (time bins)
T=round(abs(400*randn(N,1)));
T2=round(abs(400*randn(N,1)));
for t=1:N
    jump_sign=sign(randn(1));
    for el=1:size(EEG.data,1)
            EEG.data(el,jump_timebins(t):jump_timebins(t)+T(t)-1)=EEG.data(el,jump_timebins(t):jump_timebins(t)+T(t)-1)+jump_sign*stdEEG*(A+(A/4)*randn(1));
            EEG.data(el,jump_timebins2(t):jump_timebins2(t)+T2(t)-1)=EEG.data(el,jump_timebins2(t):jump_timebins2(t)+T2(t)-1)+randn(1)*stdEEG*A*(1+sin(-pi/2 +(1:T2(t))*2*pi/T2(t)))/2;
    end
end



