function EEG = simulateSSVEP_GT(srate, duration, tf, snr, leadfield)
% EEG = simulateSSVEP_GT(srate, duration, tf, snr, leadfield)
% srate = EEG sampling rate
% duration = total time length, in ms
% tf = SSVEP tag frequency
% snr = signal-to-noise ratio
%
% Example:
% srate = 250;
% length=250000; % total length, in ms
% tf=0.8;
% snr=0.08;
% leadfield = forward leadfield for projecting source data to scalp. If left empty, it is computed but it requires the file 'sa_nyhead.mat' in the working folder. 
%
% Authors: Marco Buiatti and Velu Kumaravel, CIMeC (University of Trento, Italy), 2021.

timepoints=(duration/1000)*srate;
config      = struct('n', 1, 'srate', srate, 'length', duration);

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

% generate SSVEP as a new data class
t = (0:timepoints-1)/srate;        % Time vector, in seconds
SSVEP =  sin(2*pi*tf*t);
data = struct();
data.data = SSVEP;
data.index = {'e', ':'};
data.amplitude = 0.5;
data.amplitudeType = 'relative';
data = utl_check_class(data, 'type', 'data');
SSVEP_component = utl_create_component(sourceV1, data, leadfield);
SSVEP_scalp = generate_scalpdata(SSVEP_component, leadfield, config);

% mixing SSVEP and noise with an SNR=snr
signal_scalp = utl_mix_data(SSVEP_scalp, noise_scalp, snr);
% converting to EEGLAB dataset format
EEG = utl_create_eeglabdataset(signal_scalp, config, leadfield);
% normalizing the average EEG to 10 microvolts (value taken from real
% newborn EEG data)
EEG.data=10*EEG.data/mean(std(EEG.data,0,2));



