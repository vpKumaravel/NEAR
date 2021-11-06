function [signal, red_chFlat, red_ch, yellow_ch, LOF_vec, thresh_lof_update] = NEAR_getBadChannels(EEG, isFlat, flatWin, isLOF, thresh_lof, dist_metric,isAdapt, ...
                                                                                                    isPeriodogram, frange, winsize, winov, pthresh, isPlot)

%NEAR_getBadChannels() - detect and remove bad channels in the EEG data

%
% Syntax:  [signal, red_chFlat, red_ch, yellow_ch, LOF_vec] = NEAR_getBadChannels(EEG,Options,...)
%
% Inputs:
%    EEG                      - Band-pass filtered input EEG 
%    isFlat                   - Set to 1 to detect flat channels in the data (Default: 1)
%    flatWin                  - Maximum tolerated flatline duration in seconds (Default: 5s)
%    isLOF                    - Set to 1 to detect outlier channels in the data using Local Outlier Factor (LOF) method (Default: 1)
%    thresh_lof               - Threshold to decide outlier channels (Default: 2.5)
%    dist_metric              - Distance metric used in LOF algorithm (Default: sEuclidean)
%    isAdapt                  - Maximum % of channels that can be removed. if the current thresh_lof removes more than this limit, thresh_lof
%                               value will be incremented by 1 until LOF doesn't remove more than the given % of channels.
%    isPeriodogram            - Set to 1 to detect outlier channels in the data using windowed Periodogram analysis (Default: 0)
%    frange                   - Range of frequency values for periodogram analysis in the format [LowFreq HighFreq] in Hz (Default: [1 20] Hz)
%    winsize                  - Window Length for periodogram analysis in s (Default: 1s)
%    winov                    - Window overlap factor for periodogram analysis (Default: 0.66)
%    pthresh                  - Threshold to decide outlier channels based on Periodogram analysis (Default: 4.5)
%    isPlot                   - Set to 1 if you want to see the trend of LOF and Periodogram Energy (db) for all channels (default: 1)
%
% Outputs:
%    signal     - Output EEG struct with bad channels detected and removed
%    red_chFlat - List of flat line channels in the data (if any)
%    red_ch     - List of outlier channels detected by LOF (if any)
%    yellow_ch  - List of outlier channels detected by Periodogram Analysis (if any)
%    LOF_vec    - LOF value for each channel
%
% Examples: 
%    [signal, red_chFlat, red_ch, yellow_ch, LOF_vec] =  NEAR_getBadChannels(EEG, 1, 5, 1, 2.5, 'seuclidean', 0,[],[],[],[]);
%    [signal, red_chFlat, red_ch, yellow_ch, LOF_vec] =  NEAR_getBadChannels(EEG, 0, [], 1, 2.5, 'seuclidean', 0,[],[],[],[]);
%    [signal, red_chFlat, red_ch, yellow_ch, LOF_vec] =  NEAR_getBadChannels(EEG, 1, 5 , 0, [], [], 1,[20 40], 1, 0.66, 4.5)
%
% Other m-files required: cleanFlat.m, files related to LOF


%
% See also: pop_NEAR

% Author: Velu Prabhakar Kumaravel
% PhD Student (FBK & CIMEC-UNITN, Trento, Italy)
% email: velu.kumaravel@unitn.it
% May 2021; Last revision: 19-May-2021

%% Code begins here 
    % variables declaration

    
    red_ch = [];
    red_chFlat = [];
    yellow_ch = [];
    lof_bad_ch = [];
    periodogram_bad_ch = [];
    
    orig_array = [1:EEG.nbchan];
    sr = EEG.srate;
    signal = EEG;
    
    % Call Clean Flat Lines Function (Borrowed from clean_rawdata plugin)
    
    fprintf('\n');
    if(~isFlat)
        disp('Skipping Flat Line Criterion...');
    else
        
        flatLineCh = NEAR_getFlatChannels(signal, flatWin, []);
        if ~isempty(flatLineCh)
            red_chFlat = flatLineCh;
            signal.BadCh.Flat = red_chFlat;
            allOneString = sprintf('%.0f,' , flatLineCh);
            allOneString = allOneString(1:end-1);
            disp(['Flat channel(s) ' allOneString ' have been found and marked for rejection']);
        else
            disp('No flat channels found');
        end
    end
    
    % Detection of flat lines ends here
    
    remaining_elec = setdiff(orig_array, red_chFlat); % Removing the flat channels from further processing
    C = length(remaining_elec);
    x = signal.data(remaining_elec, :);
        
    % Outlier Detection using LOF begins here
    
    fprintf('\n');
    if(~isLOF)
        LOF_vec = [];
        disp('Skipping LOF...');
    else
        if ~isempty(red_chFlat)
            disp(['Performing LOF Algorithm on non-flat ' num2str(C) ' electrode(s)']);
        else
            disp(['Performing LOF Algorithm on ' num2str(C) ' electrode(s)']);
        end
        
        DataSet = DDOutlier.dataSet(x,dist_metric);
        [~,max_nb] = DDOutlier.NaNSearching(DataSet);
        LOF_vec = DDOutlier.LOFs(DataSet,max_nb);
        
        disp('LOF scores are computed successfully');
        
        thresh_lof_update = thresh_lof;
        if(isempty(isAdapt)) % no adaptive thresholding
            lof_bad_ch = remaining_elec(LOF_vec >= thresh_lof);
        else
            % Adaptive Thresholding for LOF Bad Channel Detection
            N = histcounts(LOF_vec,  [thresh_lof 100],'Normalization', 'probability')*100;
            while (N >= 10)
                disp(['More than 10% of channels have an LOF of greater than ' num2str(thresh_lof_update)]);
                disp('Increasing the threshold by 1');
                thresh_lof_update = thresh_lof_update + 1;
                N = histcounts(LOF_vec,  [thresh_lof_update 100],'Normalization', 'probability')*100;
            end
            
            disp(['Adapted threshold  for this dataset is ' num2str(thresh_lof_update)]);
            lof_bad_ch = remaining_elec(LOF_vec >= thresh_lof_update);
        end
        
        if(~isempty(lof_bad_ch))
            red_ch = lof_bad_ch;
            signal.BadCh.Outlier = lof_bad_ch;
            allOneString = sprintf('%.0f,' , lof_bad_ch);
            allOneString = allOneString(1:end-1);
            disp(['Channel(s) ' allOneString ' have been marked for rejection']);
        else
            disp('No bad channels have been found using LOF');
        end
        
        if(isPlot)
            figure;
            bar(remaining_elec, LOF_vec);
            xlabel('Channels', 'FontSize', 24); ylabel('LOF Scores', 'FontSize', 24);
            title('Local Outlier Factor', 'FontSize', 24);
        end
    end
    
    % Outlier Detection using LOF ends here
    
    % Periodogram Analysis begins here

    fprintf('\n');
    if(~isPeriodogram)
        disp('Skipping Periodogram Analysis...');
    else
        
        if ~isempty(red_chFlat)
            disp(['Performing Periodogram Analysis on non-flat ' num2str(C) ' electrode(s)']);
        else
            disp(['Performing Periodogram Analysis on ' num2str(C) ' electrode(s)']);
        end
        
        disp('Windowing the data based on input parameters . . .');
        S = length(x);
        N = winsize*sr;
        wnd = 0:N-1;
        offsets = round(1:N*(1-winov):S-N);
        arrayInd =  bsxfun(@plus,offsets,wnd');
        nw = size(offsets,2);
        
        disp(['Total number of windows: ' num2str(nw)]);
        
        energy_mean = zeros(C,nw);
        energy_averagedWindows = zeros(1,C);
        
        for ch = 1:C
            ch_data = x(ch,:);
            for w = 1:nw
                data = ch_data(arrayInd(:,w));
                [pxx,f] = periodogram(data,[],[],sr);
                ind = f >= frange(1) & f <=frange(2);
                pxx = pxx(ind,:);
                energy_mean(ch,w) = 10*log10(mean(pxx)); % Average Power in db
            end
            energy_averagedWindows(ch) = mean(energy_mean(ch,w)); % Average Power across all windows
        end

        periodogram_bad_ch = remaining_elec(isoutlier(energy_averagedWindows, 'mean', 'ThresholdFactor', pthresh));

  
        if(~isempty(periodogram_bad_ch))
            yellow_ch = periodogram_bad_ch;
            signal.BadCh.Muscle = periodogram_bad_ch;
            allOneString = sprintf('%.0f,' , periodogram_bad_ch);
            allOneString = allOneString(1:end-1);
            disp(['Channel(s) ' allOneString ' have been marked for rejection']);
        else
            disp('No bad channels have been found using Periodogram');
        end
        
        if(isPlot)
            figure;
            bar(remaining_elec,energy_averagedWindows);
            xlabel('Channels', 'FontSize', 24); ylabel('Mean Energy (dB)', 'FontSize', 24);
            title('Periodogram Analysis', 'FontSize', 24);
        end

    end   
    % Periodogram Analysis ends here
end     
%% Code ends here