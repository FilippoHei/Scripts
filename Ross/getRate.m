function [RateMap, expt, rate] = getRate(binSz, nSamples, fs, sortedData, dataDir)


promptStrings = {'expt name:'};
defaultInputs = {'Rate',};
answ = inputdlg(promptStrings,'Inputs', [1, 30],defaultInputs);
expt = answ{1,1};

%promptStrings = {'Bin size [s]:'};
%defaultInputs = {'0.05',};
%answ = inputdlg(promptStrings,'Inputs', [1, 30],defaultInputs);
%binSz = str2double(answ(1));

%promptStrings = {'Sampling Frequency (fs)'};
%defaultInputs = {'3.003003003003003e+04',};
%answ = inputdlg(promptStrings,'Inputs', [1, 30],defaultInputs);
%fs = str2double(answ(1));

% binSamples is the number of elements in spiketrain per bin.
binSamples = fs*binSz;

% Need the number of bins we're gonna pop our data into.
nBins = round(nSamples/binSamples);


% Need to create an empty matrix that's eagerly awaiting all our cluster
% counts.
goodsIdx =cellfun(@(x) x~=3,sortedData(:,3));
goods = goodsIdx;
gdCells = sortedData(goods,:);
% Need to know the number of bad clusters that we're not going to bother with.
szT = length(gdCells);
counts = zeros(nBins, szT);

for b = 1:szT   % cluster by cluster
        for a = 1:nBins
            fsV = fs*gdCells{b,2}'; 
            logicalfsV = (fsV >(a-1)*binSamples) & (fsV <= a*binSamples);
            counts(a,b) = sum(logicalfsV);
        end
          % rate = counts/binSz;
        % figure; bar(rate(:,b));
end
rate = counts/binSz;
xaxisSec = [0:nBins]'*binSz;
yaxisClNo = [1:szT];

RateMap = figure;
imagesc(xaxisSec, yaxisClNo, rate');
xlabel('Time (s)');
ylabel('Cluster No.');
title(expt);
txt = {['Bin Size = ', num2str(binSz) 's']};
text(8328,-2.7,1.4e-14, txt);
%Use fire colormap
colormap(fire);
colorbar;
%use caxis command to hardcode colormap so that we can more easily compare
caxis([0 50]);

configureFigureToPDF(figure(RateMap));
saveas(figure(RateMap), expt, 'emf');  
save(fullfile(dataDir, [expt]), 'rate', 'RateMap', '-v7.3');
end


%across conditions-- try it out with autogenerated values to get a sense of
%the appropriate scaling

%Add labels!

%RAM Can you programmatically save the figure file?
% savefig('RateMap.fig'); print('RateMap.pdf','-dpdf'); print('RateMap.emf','-dmeta');
%RAM Are you always using 50 ms or 500 ms for binsizes? Asnw: No, 1s bin size for
% these files
%RAM Add binsize to title or somewhere on plot
%RAM Wrap everything in a function as below and save in new .m file

%RAM programatically save results to a new data file using save command at
% command line