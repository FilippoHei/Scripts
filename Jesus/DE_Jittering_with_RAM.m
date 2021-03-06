% 30.08.19 Jittering analysis by using the Data Explorer. 
clearvars
%% Load the data
dataDir = 'D:\190702_Jittering_3720_1520_1520';
cd(dataDir)
binFiles = dir('*.bin'); %only works for some reason if we are in directory already
[~,expName,~] = fileparts(binFiles.name);  %a basic string for the experiment name RAM

% Loading the sampling frequency, the sorted clusters, and the conditions
% and triggers.
expSubfix = fullfile(dataDir,expName);
try
    load([expSubfix,'_sampling_frequency.mat'],'fs')
catch
    fprintf(1,'Seems like the kilosort-phy pipeline hasn''t been touched!\n')
    return
end


%load analysis files if it exists
try
    load([expSubfix,'analysis.mat'],'Conditions','Triggers')
catch
    if exist([expSubfix, '_CondSig.mat'],'file')   %if CondSig exists, then directly call delay protocol
        getDelayProtocol(dataDir);
    else   %if not, then make it 
        try     
            getConditionSignalsBF(fopen([expSubfix,'.smrx']))
            getDelayProtocol(dataDir);
        catch
            fprintf(1,'Confusing naming. Cannot continue\n')
            return
        end
    end
    load([expSubfix,'analysis.mat'],'Conditions','Triggers')
end




try
    load([expSubfix,'_all_channels.mat'],'sortedData')
catch
    try
        importPhyFiles(dataDir);
    catch
        fprintf(1,'Error importing the phy files into Matlab format\n')
        return
    end
    load([expSubfix,'_all_channels.mat'],'sortedData')
end
%% Constructing the helper 'global' variables
% Number of total samples
Ns = min(structfun(@numel,Triggers));
% Total duration of the recording
Nt = Ns/fs;  %seconds
% Useless clusters (labeled as noise or they have very low firing rate)
badsIdx = cellfun(@(x) x==3,sortedData(:,3));
bads = find(badsIdx);
totSpkCount = cellfun(@numel,sortedData(:,2)); %count spikes per unit
clusterSpikeRate = totSpkCount/Nt;  %divide by seconds to get rate
MinimumSpikeRate=0.01;  % in Hz change this to vary minimum spike rate allowed 
silentUnits = clusterSpikeRate < MinimumSpikeRate;  %find low rate units
bads = union(bads,find(silentUnits)); %add low rate units to bad category (merging real neural signal with noise!)
goods = setdiff(1:size(sortedData,1),bads); %define the good units as not bad
badsIdx = StepWaveform.subs2idx(bads,size(sortedData,1));

% Logical spike trace for the first good cluster  % I don?t completely
% understand why E is doing this but I trust it RAM
spkLog = StepWaveform.subs2idx(round(sortedData{goods(1),2}*fs),Ns);
% Subscript column vectors for the rest good clusters
spkSubs = cellfun(@(x) round(x.*fs),sortedData(goods(2:end),2),...
    'UniformOutput',false);
% Number of good clusters 
Ncl = numel(goods);
% Redefining the stimulus signals from the low amplitude to logical values
mObj = StepWaveform(Triggers.whisker,fs);
mSubs = mObj.subTriggers;
piezo = mObj.subs2idx(mSubs,mObj.NSamples);
try
    laser = Triggers.light;
catch
    laser = Triggers.laser;
end
lObj = StepWaveform(laser,fs);
lSubs = lObj.subTriggers;
laser = lObj.subs2idx(lSubs,lObj.NSamples);
mObj.delete;lObj.delete;
continuousSignals = {piezo;laser};
clearvars *Obj piezo laser
%% User controlling variables to change details of PSTHs
% Time window to see the cluster activation in seconds
timeLapse = [0.31, 0.41];  % time before and time after, seconds (this variable will control output data that we save below)
% Bin size for PSTHs
binSz = 0.0005; %in seconds

% Subscript to indicate the conditions with all whisker stimulations,
% whisker control, laser control, and the combination whisker and laser.
allWhiskerStimulus = 1;
whiskerControl = 9;
laserControl = 8;
consideredConditions = 3:9;
Nccond = length(consideredConditions);
% Time windows to evaluate if a unit is responsive or not.
spontaneousWindow = [-0.01, -0.002];
responseWindow = [0.002, 0.01];
% Adding all the triggers from the piezo and the laser in one array
allWhiskersPlusLaserControl = ...
    union(Conditions(allWhiskerStimulus).Triggers,...
    Conditions(laserControl).Triggers,'rows');
%% Logical and numerical stack for computations
% dst - dicrete stack has a logical nature
% cst - continuous stack has a numerical nature
% Both of these stacks have the same number of time samples and trigger
% points. They differ only in the number of considered events.
[dst, cst] = getStacks(spkLog, allWhiskersPlusLaserControl,...
    'on',timeLapse,fs,fs,[spkSubs;{Conditions(laserControl).Triggers}],...
    continuousSignals);
% Number of clusters + the piezo as the first event + the laser as the last
% event, number of time samples in between the time window, and number of
% total triggers.
[Ne, Nt, NTa] = size(dst);   %got confused because it meant something else earlier RAM
% Computing the time axis for the stack
tx = (0:Nt)/fs - timeLapse(1);  
% Boolean flags indicating which trigger belongs to which condition (delay
% flags)
delFlags = false(NTa,Nccond);
counter2 = 1;
for ccond = consideredConditions
    delFlags(:,counter2) = ismember(allWhiskersPlusLaserControl(:,1),...
        Conditions(ccond).Triggers(:,1));
    counter2 = counter2 + 1;
end
Na = sum(delFlags,1);
%% Computing which units/clusters/putative neurons respond to the stimulus
% Logical indices for fetching the stack values
sponActStackIdx = tx >= spontaneousWindow(1) & tx <= spontaneousWindow(2);
respActStackIdx = tx >= responseWindow(1) & tx <= responseWindow(2);
% The spontaneous activity of all the clusters, which are allocated from
% the second until one before the last row, during the defined spontaneous
% time window, and the whisker control condition. 
sponTimeMarginal = sum(...
    dst(2:Ne-1,sponActStackIdx,delFlags(:,Nccond)),2);
sponTimeMarginal = squeeze(sponTimeMarginal);
sponActPerTrial = sum(sponTimeMarginal,2)/Na(Nccond);
% Similarly for the responsive user-defined time window
respTimeMarginal = sum(...
    dst(2:Ne-1,respActStackIdx,delFlags(:,Nccond)),2);
respTimeMarginal = squeeze(respTimeMarginal);
respActPerTrial = sum(respTimeMarginal,2)/Na(Nccond);
activationIndex = -log(sponActPerTrial./respActPerTrial);  %ask E about this
whiskerResponsiveUnitsIdx = activationIndex > 1;  %%change this to include for all
display(find(whiskerResponsiveUnitsIdx))
%% Getting the relative spike times for the whisker responsive units (wru)
% For each condition, the first spike of each wru will be used to compute
% the standard deviation of it.
cellLogicalIndexing = @(x,idx) x(idx);
isWithinResponsiveWindow =...
    @(x) x > responseWindow(1) & x < responseWindow(2);

Nwru = sum(whiskerResponsiveUnitsIdx);
unitSelectionIdx = [whiskerResponsiveUnitsIdx(2:Ncl);false];

allSelectionIdx = [true(Ncl-1,1);false];   %selection index for all neurons, exclude light at end

firstSpike = zeros(Nwru,Nccond);

PopRelativeSpikeTimes=cell(size(delFlags,2),1); %collect population triggered spikes
for ccond = 1:size(delFlags,2)
    relativeSpikeTimes = getRasterFromStack(dst,~delFlags(:,ccond),...
        unitSelectionIdx, timeLapse, fs, true, true);
    relativeSpikeTimes(:,~delFlags(:,ccond)) = [];
    PopRelativeSpikeTimes{ccond}=getRasterFromStack(dst,~delFlags(:,ccond),...
        allSelectionIdx, timeLapse, fs, true, 0);  %
    
    relativeSpikeTimes(~whiskerResponsiveUnitsIdx(1),:) = [];
    respIdx = cellfun(isWithinResponsiveWindow, relativeSpikeTimes,...
        'UniformOutput',false);
    spikeTimesINRespWin = cellfun(cellLogicalIndexing,...
        relativeSpikeTimes, respIdx, 'UniformOutput',false);
    for ccl = 1:Nwru
        frstSpikeFlag = ~cellfun(@isempty,spikeTimesINRespWin(ccl,:));
        firstSpike(ccl,ccond) = std(...
        cell2mat(spikeTimesINRespWin(ccl,frstSpikeFlag)));    
    end
end

ClusterIds=sortedData(goods,1);
%psthConditions=Conditions(3:end);  %this needs to be fixed for next script
save([expName '_PopulationSpikeAnalysis'],'PopRelativeSpikeTimes','Conditions','dataDir','expName','tx','timeLapse','ClusterIds')
% This line looks pretty for saving the relative spike times. Indeed, it
% does.
%% Plotting the population activity
for ccond = 1:Nccond
    [PSTH, trig, sweeps] = getPSTH(...
        dst([true;whiskerResponsiveUnitsIdx;false],:,:),timeLapse,...
        ~delFlags(:,ccond),binSz,fs);
    fig = plotClusterReactivity(PSTH,trig,sweeps,timeLapse,binSz,...
        [{'Piezo'};sortedData(goods(whiskerResponsiveUnitsIdx),1)],...
        Conditions(consideredConditions(ccond)).name);
    configureFigureToPDF(fig);
   print(fig,fullfile(dataDir,sprintf('%s %s.pdf',...
        expName, Conditions(consideredConditions(ccond)).name)),...
       '-dpdf','-fillpage')
end
