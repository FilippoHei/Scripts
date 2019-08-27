% Melina script for data loading and notch filtering
clear all  %start with empty workspace

%Loading the recording; this also defines the filename using the file
%manually selected

%%
read_Intan_RHD2000_file  %to do is to remove gui and just do a loop to import all data in directory
%relativePath=path((numel(rawDir)+2):end);
%savePath=[saveDirRoot '\' relativePath];
%cd(saveDirRoot)
% if ~isdir(relativePath)
%     [SUCCESS,MESSAGE,MESSAGEID] = mkdir(savePath,relativePath);
%     if SUCCESS,
%         display(['made new directory ' savePath])
%     else display(MESSAGE)
%     end
% else
%     display(['directory ' savePath ' already exists'])
% end
% cd(savePath)

%% then filter out 50 Hz line noise and filter for spikes
fs = frequency_parameters.amplifier_sample_rate; %original rate
[rows, cols] = size(amplifier_data);
if cols < rows
    amplifier_data = amplifier_data';
    aux = rows;
    rows = cols;
    cols = aux;
end

ds_factor=10; %by what factor should signal be downsampled by? 
fs_ds=fs/ds_factor;
cutFreq_spike = [600, 1499]; %is this too narrow?
cutFreq_low  = [.1, 200]; %what are we talking about here?

%%
cd(path)

save ExportParameters ds_factor fs_ds cutFreq_spike cutFreq_low path filename
save board_dig_in_data board_dig_in_data

%% filtering

dataCell = cell(rows,1);
dataCell_sp=cell(rows,1);%empty structs for filtered data

for cch = 1:min(size(amplifier_data))
    fprintf(1,'Dealing with channel %d\n', cch)
    ds_signal=resample(amplifier_data(cch,:),1,ds_factor);  %downsample
    dataCell(cch) = {iir50NotchFilter(ds_signal,fs_ds)}; %remove 50 Hz
    dataCell_sp(cch) = {iirSpikeFilter(dataCell{cch},fs_ds,cutFreq_spike)};
end

dataCell_low =cell(rows,1);
for cch = 1:min(size(amplifier_data))
    fprintf(1,'Dealing with channel %d\n', cch)
    dataCell_low(cch) = {iirSpikeFilter(dataCell{cch},fs_ds,cutFreq_low)};
end

fprintf(1,'Saving dataCell... %d\n', cch)
save dataCell dataCell path filename
fprintf(1,'Saving dataCell_low... %d\n', cch)
save dataCell_low dataCell_low path filename
fprintf(1,'Saving dataCell_sp... %d\n', cch)
save dataCell_sp dataCell_sp path filename


%%

