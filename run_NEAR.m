function [outEEG] = run_NEAR(dname, dloc, params, ALLEEG)

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
% First Version: May 2021; Last revision: Nov, 4, 2021

% parameter extraction
isLPF         = params.isLPF;
isHPF         = params.isHPF;
isSegt        = params.isSegt;
isERP         = params.isERP;
isBadCh       = params.isBadCh;
isVisIns      = params.isVisIns;
isBadSeg      = params.isBadSeg;
isInterp      = params.isInterp;
isAvg         = params.isAvg;
isReport      = params.isReport;
isSave        = params.isSave;

lpc           = params.lpc;

hptf          = params.hptf;
hpc           = params.hpc;

look_thr      = params.look_thr;

erp_em        = params.erp_event_markers; 
erp_ed        = params.erp_epoch_duration; 
erp_rb        = params.erp_remove_baseline; 
erp_bw        = params.baseline_window; 

isFlat        = params.isFlat; 
flatWin       = params.flatWin; 
isLOF         = params.isLOF; 
dist_metric   = params.dist_metric;
thresh_lof    = params.thresh_lof;
isAdapt       = params.isAdapt;
isPeriodogram = params.isPeriodogram;
frange        = params.frange;
winsize       = params.winsize;
winov         = params.winov;
pthresh       = params.pthresh;
rej_cutoff    = params.rej_cutoff;
rej_mode      = params.rej_mode;
add_reject    = params.add_reject;
reref         = params.reref;

addpath(genpath(pwd)); % Adding all subfolders to the current directory

% import data
[filepath,name,ext] = fileparts([dloc filesep dname]);

if(strcmp(ext, '.set')==1)
    EEG = pop_loadset('filename',dname,'filepath',[dloc filesep]);   
else
    error('Your data is not of .set format, please edit the import data function appropriate to your data.');
end

origEEG = EEG; % making a copy of raw data

if(numel(size(EEG.data)) == 3) 
    EEG = eeg_epoch2continuous(EEG); % making the data continuous to perform NEAR preprocessig
    isERP = 1; % to later epoch the data
end


% filter data
if(isLPF)
    EEG = pop_eegfiltnew(EEG, [], lpc, [], 0, [], 0); % low-pass filter
    fprintf('\nData is low-pass filtered\n');
end


if(isHPF)
    if(isempty(hptf))
        EEG = pop_eegfiltnew(EEG, 'locutoff',hpc,'plotfreqz',1);
    else
        EEG=clean_drifts(EEG,hptf, []);
    end
    fprintf('\nData is high-pass filtered\n');
end

% segment data using fixation intervals (Look Times)
if(isSegt)
    if(~isempty(params.sname) && ~isempty(params.sloc))
        try
            lookFile=importdata([params.sloc filesep params.sname]); 
        catch
            error('An error occurred in importing the segmentation file. If you think this is a bug, please report on the github repo issues section');
        end
    end
    
    if(~isempty(lookFile))
        try
            sheetName = name;
            lookTimes=NEAR_getLookTimes(lookFile,sheetName,look_thr);
        catch
           error('An error occurred in segmentation. Please find our template document in the repository to edit your time intervals.\n');
        end
    else
        error('We cannot find the file. Please check the file path and run again.\n');
    end
    
    % segment EEG data
    EEG = pop_select( EEG,'time',lookTimes);
    fprintf('\nSegmentation is done\n');
end

if (isBadCh)
    
    [EEG, flat_ch, lof_ch, periodo_ch, LOF_vec] = NEAR_getBadChannels(EEG, isFlat, flatWin, isLOF, thresh_lof, dist_metric, isAdapt, ...
                                                                                                    isPeriodogram, frange, winsize, winov, pthresh, isVisIns);
    disp('Bad Channel Detection is performed successfully');  
    
    if(isVisIns)
        % visual inspection and reject using 'Reject' button on the GUI
        colors = repmat({'k'},1, EEG.nbchan);
        
        for i = 1:length(periodo_ch)
            colors(1,periodo_ch(i)) = 	{[0.9290, 0.6940, 0.1250]};
        end
        
        for i = 1:length(lof_ch)
            colors(1,lof_ch(i)) = {'r'};
        end
        
        for i = 1:length(flat_ch)
            colors(1,flat_ch(i)) = {'r'};
        end
        
        badChans = sort(unique(union(union(flat_ch, lof_ch),periodo_ch)));
        
        if(~isempty(badChans))
            if(size(badChans,1) ~= 1)
                badChans = badChans';
            end
        end
        
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
        
        eegplot(EEG.data, 'srate', EEG.srate, 'title', 'NEAR Bad Channels Plot (Red and Yellow Electrodes are bad)', ...
            'limits', [EEG.xmin EEG.xmax]*1000, 'color', colors,  'dispchans', 5, 'spacing', 500, eegplotoptions{:});
    end
    EEG = pop_select(EEG, 'nochannel', badChans);
else
    
    disp('NEAR Bad Channel Detection is not employed. Set the variable ''isBadCh'' to 1 to enable bad channel detection');
    
end

if(isBadSeg)
    EEG_copy = EEG;
    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion','off','LineNoiseCriterion','off', ...
        'Highpass','off','BurstCriterion',rej_cutoff,'WindowCriterion',add_reject,'BurstRejection',rej_mode,'Distance','Euclidian');
    
    if(strcmp(rej_mode, 'on'))
        modified_mask = ~EEG.etc.clean_sample_mask;
    else
        modified_mask = sum(abs(EEG_copy.data-EEG.data),1) > 1e-10; 
    end
    
    tot_samples_modified = (length(find(modified_mask)) * 100) / EEG_copy.pnts;
    
    if(isVisIns)
        try
            vis_artifacts(EEG,EEG_copy);
        catch
            warning('vis_artifacts failed. Skipping visualization.')
        end
    end
    fprintf('\nArtifacted epochs are corrected by ASR algorithm\n');
end

if(isERP)
    try
        EEG = pop_epoch( EEG, erp_em, erp_ed, 'epochinfo', 'yes');
        EEG = eeg_checkset( EEG );
        if(erp_rb) %baseline removal opted
            EEG = pop_rmbase( EEG, erp_bw ,[]);
            EEG = eeg_checkset( EEG );
        end
    catch
        error('Either Insufficient Data or incomplete parameters for epoching');
    end 
end 
    
if(isInterp)
    EEG = pop_interp(EEG, origEEG.chanlocs, 'spherical');
    fprintf('\nMissed channels are spherically interpolated\n');
end


if(isAvg)
    EEG = pop_reref( EEG, []);
else
    if(isempty(reref))
        warning('Skipping rereferencing as the parameter reref is empty. An example setup: reref = ''Cz''');
    elseif(isnumeric(reref))
        EEG = pop_reref( EEG, reref);
    else
        labels = {EEG.chanlocs.labels};
        ch_idx = find(cellfun(@(x)isequal(x, reref),labels));
        EEG = pop_reref( EEG, ch_idx);
    end
end

if isSave
    if exist([dloc filesep 'NEAR_Processed'], 'dir') == 0
        mkdir([dloc filesep 'NEAR_Processed'])
    end
    
    % Save data on the same location dloc
    EEG = pop_saveset(EEG, 'filename',[name '_NEAR_prep.set'],'filepath', [dloc filesep 'NEAR_Processed']);
    
end

if isReport
    if exist([dloc filesep 'NEAR_Reports'], 'dir') == 0
        mkdir([dloc filesep 'NEAR_Reports'])
    end
    
    report.FileName = name;
    report.FileLoc = dloc;
    if(isLPF)
        report.LowPassFiltering = {['A low pass filtering is applied on the data with the cut-off = ' num2str(lpc) ' Hz' ]};
    else
        report.LowPassFiltering = {'No low pass filter applied'};
    end
    
    if(isHPF)
        if(isempty(hpc))
            report.HighPassFiltering = {['A high pass filtering is applied on the data with the transition edge [' num2str(hptf) '] Hz' ]};
        else
            report.HighPassFiltering = {['A high pass filtering is applied on the data with the cut-off = ' num2str(hpc) ' Hz' ]};
        end
    else
        report.HighPassFiltering = {'No high pass filter applied'};
    end
    
    if(isSegt)
        report.SegmentationLookUp = {'A segmentation based on LookTimes is applied'};
    else
        report.SegmentationLookUp = {'No segmentation based on LookTimes is applied'};
    end
     
    if(isERP)
        tmp = [erp_em',[repmat({' , '},numel(erp_em)-1,1);{[]}]]';
        events = [tmp{:}];
        report.ERP = {['The data is epoched with respect to events [' events '] for the duration [' num2str(erp_ed) '] s.']};
    else
        report.ERP = {'No segmentation based on LookTimes is applied'};
    end
    
    if(isBadCh)
        report.NEAR_BadChannels = {[num2str(badChans)]};
    else
        report.NEAR_BadChannels = {'No bad channel detection is employed'};
    end
    
    if(isBadSeg)
        report.NEAR_BadSegments = {['For the given ASR Parameter ' num2str(rej_cutoff) ', about ' num2str(tot_samples_modified) '% of samples are modified/rejected']};
    else
        report.NEAR_BadSegments = {'No bad epochs correction/rejection is employed'};
    end
    
    if(isInterp)
        report.Interpolation = {['Spherical interpolation is done for the missing channels (if any): ' num2str(badChans)]};
    else
        report.Interpolation = {'No Interpolation is applied'};
    end
    
    if(isAvg)
        if(isempty(reref))
            report.Rerefencing = {'Average re-referencing is performed'};
        else
            if(isnumeric(reref))
                refch = num2str(reref);
            else
                refch = cell2mat(reref);
            end
            report.Rerefencing = {['Re-referencing is performed with respect to the channel: ' refch]};
        end
        
    else
        report.Rerefencing = {'No Re-referencing is performed'};
    end
    
    
    if(isSave)
        report.Save = {['The processed file can be found in the folder ' [dloc filesep 'NEAR_Processed']]};
    else
        report.Save = {'The processed file is not opted to be saved. Set isSave = 1 if you want to save.'};
    end
    
    
    
    
    d = {'Parameter', 'Value';...
        'File Name', name ;'File Location', dloc; ...
        'Low Pass Filtering', report.LowPassFiltering; ...
         'High Pass Filtering', report.HighPassFiltering; ...
         'Segmentation (Look Times)', report.SegmentationLookUp; ...
         'Bad Channels', report.NEAR_BadChannels; ...
         'Bad Segments (ASR)', report.NEAR_BadSegments; ...
         'Epoching (ERP)', report.ERP; ...
         'Interpolation', report.Interpolation; ...
         'Re-referencing', report.Rerefencing; ...
         'Save Status', report.Save};
     
     writetable(cell2table(d), [dloc filesep 'NEAR_Reports' filesep name '.csv'], 'WriteVariableNames', 0)
end

outEEG = EEG;

end