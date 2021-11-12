function EEG = simulateERP_GT(srate, duration, nep, snr, leadfield)
% EEG = simulateERP_GT(srate, duration, nep, snr, leadfield)
% srate = EEG sampling rate
% duration = epoch time length, in ms
% nep = number of epochs
% snr = signal-to-noise ratio
% leadfield = forward leadfield for projecting source data to scalp. If left empty, it is computed but it requires the file 'sa_nyhead.mat' in the working folder. 
%
% Example:
% srate = 250;
% duration=1000;
% nep=52;
% snr=0.05;
%
% Authors: Marco Buiatti and Velu Kumaravel, CIMeC (University of Trento, Italy), 2021.

config      = struct('n', nep, 'srate', srate, 'length', duration);

% generate leadfield
if isempty(leadfield)
    leadfield   = lf_generate_fromnyhead('montage', 'S64');
end

% generate 62 sources of noise in random voxels
noise_source  = lf_get_source_spaced(leadfield, 62, 25);

% generate two symmetrical sources in the early visual cortex
source1 = lf_get_source_nearest(leadfield, [-8 -76 10]);
source2 = lf_get_source_nearest(leadfield, [8 -76 10]);
sourceV1=[source1 source2];

% generate noise signal both in random voxels and in V1 voxels
noise_signal      = struct('type', 'noise', 'color', 'brown', 'amplitude', 1);
noise_components  = utl_create_component([noise_source sourceV1], noise_signal, leadfield);
noise_scalp       = generate_scalpdata(noise_components, leadfield, config);

% generate ERP
erp = struct();
erp.peakLatency = 500;      % in ms, starting at the start of the epoch
erp.peakWidth = 200;        % in ms
erp.peakAmplitude = 1;      % in microvolt
erp = utl_check_class(erp, 'type', 'erp');
c = struct();
c.source = sourceV1;      % obtained from the lead field, as above
c.signal = {erp};       % ERP class, defined above
ERP_component = utl_check_component(c, leadfield);
ERP_scalp = generate_scalpdata(ERP_component, leadfield, config);

config.marker = 'event';  % the epochs' time-locking event marker
config.prestim = 200;

% mix ERP and noise with an SNR=snr
signal_scalp = utl_mix_data(ERP_scalp, noise_scalp, snr);
% convert to EEGLAB dataset format
EEG = utl_create_eeglabdataset(signal_scalp, config, leadfield);
% convert to continuous to apply the other preprocessing steps
EEG = eeg_epoch2continuous(EEG);
% normalize the average EEG to 10 microvolts (value taken from real
% newborn EEG data)
EEG.data=10*EEG.data/mean(std(EEG.data,0,2));



