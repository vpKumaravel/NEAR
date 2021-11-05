%% Important Note:
% the sample dataset uploaded here is available on: https://openneuro.org/datasets/ds002034/versions/1.0.1

clc; clear all; eeglab; 
% 1) please ensure eeglab is accessible by MATLAB 
% 2) please ensure that NEAR_ChannelRejection-master folder is put inside
% the plugins folder of EEGLAB



%%
list_sub = {'sub-09_ses-03_task-offlinecatch_run-04_filtered' };
ext = '.set';

list_labels = {'sub-09_ses-03_task-offlinecatch_run-04_labels'};
filepath =cd;
labelpath = cd;


LOF_calibrate = []; % output struct file
counter = 1; % counter for output struct file

for eachfile = 1:numel(list_sub)


    %% Step 1) Import code - please modify this according to the filetype supported by EEGLAB
    EEG = pop_loadset('filename', [list_sub{eachfile} ext] ,'filepath', [filepath filesep]);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    EEG = eeg_checkset( EEG );
    
    
    %% Step 2) Add channel locations and other required preprocessing steps such as Filtering
    
    % Since the example data is already imported with channel locations,
    % and filiter, I am skipping this step here.
    
    %% Step 3) Extract ground truth labels
    
    
    g_t = zeros(1,EEG.nbchan); % declaring ground truth vector
    disp(eachfile);
    T = readtable([labelpath filesep list_labels{eachfile} '.csv']); % read label file corresponding to the current EEG file

%% Extract Ground Truth Labels
    groundTruth = T.x0'; % where x0 contains the list of 0s and 1s in the .csv file. (1 indicates bad channels)
    g_t(find(groundTruth)) = 1;

%% Perform NEAR Bad Channel Detection

list_threshold = 1:0.1:1.5;

for iThreshold = list_threshold % list of threshold values you want to explore. N.B. The lower limit should be >= 1.

    fprintf('\n Current Threshold is %f\n', iThreshold);
    p_t = zeros(1,EEG.nbchan); % declaring predicted labels vector
    
    [~, flat_ch, lof_ch, periodo_ch, ~] = NEAR_getBadChannels(EEG, 1, 5, 1, iThreshold, 'seuclidean',[], ...
        0, [], [], [], [], 0);
    NEARbadChans = sort(unique(union(union(flat_ch, lof_ch),periodo_ch)));
    p_t(NEARbadChans) = 1;
    
    % compute classification performance
    C = confusionmat(g_t,p_t);
    
    TN = C(1,1);
    FN = C(2,1);
    FP = C(1,2);
    TP = C(2,2);
    
    Sensitivity = (TP/(TP+FN));
    Specificity = (TN/(TN+FP));
    Accuracy = ((TN+TP)/(TN+TP+FN+FP));
    Precision = (TP/(TP+FP));
    Recall = Sensitivity;
    F1_scoreNEAR = (2*Precision*Recall)/(Precision+Recall);
    
    fprintf('F1 score is %s\n', F1_scoreNEAR);
    
    % Saving the metrics
    LOF_calibrate(counter).Subject = {list_sub{eachfile}};
    LOF_calibrate(counter).GroundTruth = find(g_t);
    LOF_calibrate(counter).LOF = iThreshold;
    LOF_calibrate(counter).NEAR  = NEARbadChans';
    LOF_calibrate(counter).Precision = Precision;
    LOF_calibrate(counter).Recall = Recall;
    LOF_calibrate(counter).F1_NEAR = F1_scoreNEAR;
    
    counter = counter + 1;
end

end

%% Plot results

vec = [LOF_calibrate.LOF];
count = 1;
mean_LOF = [];
for iT = list_threshold
    idx = vec == iT;
    out = LOF_calibrate(idx);
    mean_LOF(count) = mean([out.F1_NEAR]);
    count = count +1;
    idx = [];
    out = [];
end
figure;plot(list_threshold,mean_LOF);
xlabel('LOF Threshold','fontweight','bold','fontsize',24);
ylabel('F1 Score','fontweight','bold','fontsize',24);
set(get(gca, 'XAxis'), 'FontWeight', 'bold','fontsize',24);
set(get(gca, 'YAxis'), 'FontWeight', 'bold','fontsize',24);

lines = findobj(gcf,'Type','Line');
for i = 1:numel(lines)
    lines(i).LineWidth = 2;
end