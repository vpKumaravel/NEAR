function [outEEG] = run_NEAR(dname, dloc, params)

% run_NEAR() - runs NEAR pipeline for each subject data with the given
% params

%
% Syntax:  [outEEG] = run_NEAR(dname, dloc, sname, sloc, params)
%
% Inputs:
%    dname                    - Name of the dataset
%    dloc                     - Corresponding file location
%    params                   - A struct file defined by the user to run NEAR with custom configurations

%
% Outputs:
%    outEEG     - NEAR Pre-Processed EEG struct ready to be saved and for further time-frequency analysis

%
% Examples: 
%    [outEEG] = run_NEAR('s12.set', 'D:\\Data\\, params);
%
% Other m-files required: NEAR_plotBadChannels.m, EEGLAB related files


%
% See also: pop_NEAR

% Author: Velu Prabhakar Kumaravel
% PhD Student (FBK & CIMEC-UNITN, Trento, Italy)
% email: velu.kumaravel@unitn.it
% May 2021; Last revision: 19-May-2021

% parameter extraction
isLPF         = params.isLPF;
isHPF         = params.isHPF;
isSegt        = params.isSegt;
isBadCh       = params.isBadCh;
isVisIns      = params.isVisIns;
isBadSeg      = params.isBadSeg;
isInterp      = params.isInterp;
isAvg         = params.isAvg;
lpc           = params.lpc;
nOrder        = params.nOrder;
hptf          = params.hptf;
look_thr       = params.look_thr;
isplot        = params.isplot;
isFlat        = params.isFlat; 
flatWin       = params.flatWin; 
isLOF         = params.isLOF; 
dist_metric   = params.dist_metric;
thresh_lof    = params.thresh_lof;
isPeriodogram = params.isPeriodogram;
frange        = params.frange;
winsize       = params.winsize;
winov         = params.winov;
pthresh       = params.pthresh;
rej_cutoff    = params.rej_cutoff;
rej_mode      = params.rej_mode;
addn_reject    = params.addn_reject;

% import data
EEG = pop_loadset('filename',dname,'filepath',dloc);
origEEG = EEG; % making a copy of raw data

% filter data
if(isLPF)
    EEG = pop_eegfiltnew(EEG, [], lpc, nOrder, 0, [], 0); % low-pass filter
    fprintf('\nData is low-pass filtered\n');
end

if(isHPF)
    EEG=clean_drifts(EEG,hptf, []); %high-pass filter
    fprintf('\nData is high-pass filtered\n');
end

% segment data using fixation intervals
if(isSegt)
    
    if(~isempty(params.sname) && ~isempty(params.sloc))
        try
            lookFile=importdata([params.sloc '\\' params.sname]); % make sure it is generic for MAC and Windows (TO BE FIXED)
        catch
            error('An error occurred in importing the segmentation file. If you think this is a bug, please report on the github repo issues section');
        end
    end
    
    if(~isempty(lookFile))
        try
            tmp = strsplit(dname, '.');
            sheetName = tmp{1};
            lookTimes=NEAR_getLookTimes(lookFile,sheetName,look_thr);
        catch
            error('An error occurred in segmentation. Does the file contain the segmentation intervals for the given subject?\n');
        end
    else
        error('We cannot find the file. Please check the file path and run again.\n');
    end
    
    % segment EEG data
    EEG = pop_select( EEG,'time',lookTimes);
    fprintf('\nSegmentation is done\n');
end

if (isBadCh)
    
    [EEG, flat_ch, lof_ch, periodo_ch, ~] = NEAR_getBadChannels(EEG, isFlat, flatWin, isLOF, thresh_lof, dist_metric, ...
                                                                                                    isPeriodogram, frange, winsize, winov, pthresh, isplot);
    disp('Bad Channel Detection is performed successfully\n');  
    
    if(isVisIns) 
        % visual inspection and reject using 'Reject' button on the GUI
        NEAR_plotBadChannels (EEG, flat_ch, lof_ch, periodo_ch);
    
    else 
        % direct removal of bad channels without any GUI
        badChans = sort(unique(union(union(flat_ch, lof_ch),periodo_ch)));
        
        if(~isempty(badChans))
            if(size(badChans,1) ~= 1)
                badChans = badChans';
            end
        end
        
        EEG = pop_select(EEG, 'nochannel', badChans);
    end
    
else
    disp('NEAR Bad Channel Detection is not employed. Set the variable ''isBadCh'' to 1 to enable bad channel detection\n'); 
end

if(isBadSeg)
    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion','off','LineNoiseCriterion','off', ...
        'Highpass','off','BurstCriterion',rej_cutoff,'WindowCriterion',addn_reject,'BurstRejection',rej_mode,'Distance','Euclidian');

    fprintf('\nArtifacted epochs are corrected by ASR algorithm\n');
end

if(isInterp)
    EEG = pop_interp(EEG, origEEG.chanlocs, 'spherical');
    fprintf('\nMissed channels are spherically interpolated\n');
end

% Note: The following code is valid only for Cz reference systems
% Please change the code accordingly.
if(isAvg)
    EEG = pop_reref(EEG, [],'refloc',struct('labels',{'Cz'},'Y',{0},'X',{5.4492e-16},'Z',{8.8992},'sph_theta',{0},'sph_phi',{90},'sph_radius',{8.8992},'theta',{0},'radius',{0},'type',{''},'ref',{''},'urchan',{132},'datachan',{0}));
    EEG.comments = pop_comments(EEG.comments,'','Average reference, reference channel Cz added',1);
end

outEEG = EEG;

end