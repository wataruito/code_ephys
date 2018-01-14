%##########################################################################
% 2018-01-11
% working4.m
%   Clearning code and add LPFs.
%   Hard coding for drawing spectrogram for speed.
%   Global variable for reading files.
%   If variable exists, no reading.
%
%##########################################################################
% Channel
fileId = 1;
ch = 1;
%   Color limits
cmin = 0.0; cmax = 1.0e+5;
clim = [cmin, cmax];

% Figure layout
fontSize = 9;
%   Upper panel
up.plotMarginLeft = 0.15;
up.plotMarginTop = 0.03;
up.plotHightInterval = 0.045;
up.plotWidth = 0.8;
up.plotHight = 0.045;
%   Lower panel
yInterval = 0.12;
lw.plotMarginLeft = 0.35;
lw.plotMarginTop = up.plotHightInterval * 5 + yInterval;
lw.plotHightInterval = 0.10;
lw.plotWidth = 0.6;
lw.plotHight = 0.10;

% Generate the parent figure
S.hFig = figure('units','pixels',...
    'position',[100 100 1000 1000],...
    'menubar','none',...
    'name','GUI_1',...
    'numbertitle','off',...
    'resize','on'); hold on;
colormap 'jet';
%   Draw grids for the arrangement purpose
% for i = 1 : 10
%     for j = 1 : 10
%         annotation(S.hFig,...
%             'textbox',[0.1*(i-1) 0.1*(j-1) 0.1 0.1],...
%             'String',['     '],...
%             'LineWidth', 0.1, ...
%             'LineStyle', ':',...
%             'EdgeColor', [0 1 0],...
%             'FitBoxToText','off',... % textbox is shrinked to fit text
%             'interpreter', 'none' ); % underscore interpreted by Tex
%     end
% end

% Generate child figures
[S.hAixUp, S.hTitleUp] = genSubPlot(6,fontSize,up);
[S.hAixLw, S.hTitleLw] = genSubPlot(6,fontSize,lw);
%   Set x limit to 0-20s on upper panels
for i = 1:6, S.hAixUp(i).XLim = [0.0 20.0]; end
%   Set x limit to 0-2s on lower panels
for i = 1:6, S.hAixLw(i).XLim = [0.0 2.0]; end

% Generate list object for dispaly file list
dirListFiles = dir('*_specg.mat');
a = struct2cell(dirListFiles);
S.hListBox1 = uicontrol(S.hFig,...
    'style','listbox',...
    'Units','normalized',...
    'position',[0.05 0.05 0.25 0.6],...
    'min',0,'max',2,...
    'fontsize',10,...
    'string',a(1,:));

% Read data and draw them
%   For spectrogram
timeWindowStartUp = 1;
timeWindowStepUp = 2500;
timeWindowEndUp = timeWindowStartUp + timeWindowStepUp - 1;
timeWindowStartLw = 1;
timeWindowStepLw = 250;
timeWindowEndLw = timeWindowStartLw + timeWindowStepLw - 1;
%   For waves
endUp = timeWindowEndUp * 10;
startUp = endUp - timeWindowStepUp * 10 + 1;
endLw = timeWindowEndLw * 10;
startLw = endLw - timeWindowStepLw * 10 + 1;
%   List for file types to be read
type = {'specg','lfp','gamma','alphabeta','theta','delta'};

for i = 1:6
    dirListFiles = dir(['*_' type{i} '.mat']);
    
    if size(dirListFiles, fileId) ~= 0
        fileName = dirListFiles(fileId).name;
        [~, fileNameNoExt, ~] = fileparts(fileName);
        
        % Read spectrogram and store a variable named after filename
        if exist(fileNameNoExt,'var') == 0
            readSpecg(fileName,type{i});
            eval(['global ' fileNameNoExt ';']);
        end
        
        if i == 1
            eval(['t = ' fileNameNoExt '.time;']);
            eval(['freq = ' fileNameNoExt '.freq;']);
            eval(['cfs = squeeze(' fileNameNoExt '.powspctrm(ch,:,:));']);
            
            % Draw spectogram
            %   Draw uppter panel
            imagesc(S.hAixUp(1),t(timeWindowStartUp:timeWindowEndUp),...
                freq,cfs(:,timeWindowStartUp:timeWindowEndUp),clim);
            S.hAixUp(i).XLim = [t(timeWindowStartUp) t(timeWindowEndUp)];
            S.hAixUp(i).YLim = [freq(1) freq(size(freq, 2))];
            %   Draw lower panel
            imagesc(S.hAixLw(1),t(timeWindowStartLw:timeWindowEndLw),...
                freq,cfs(:,timeWindowStartLw:timeWindowEndLw),clim);
            S.hAixLw(i).XLim = [t(timeWindowStartLw) t(timeWindowEndLw)];
            S.hAixLw(i).YLim = [freq(1) freq(size(freq, 2))];
        else
            eval(['waveT(:,i-1) = ' fileNameNoExt '.timestamps;']);
            eval(['waveData(:,i-1) = squeeze(' fileNameNoExt '.data(:,ch));']);
            
            % Draw waves
            %   Draw uppter panel
            plot(S.hAixUp(i),waveT(startUp:endUp,i-1),waveData(startUp:endUp,i-1),'k');
            S.hAixUp(i).XLim = [waveT(startUp,i-1) waveT(endUp,i-1)];
            S.hAixUp(i).YLim = [-500 500];
            %   Draw lower panel
            plot(S.hAixLw(i),waveT(startLw:endLw,i-1),waveData(startLw:endLw,i-1),'k');
            S.hAixLw(i).XLim = [waveT(startLw,i-1) waveT(endLw,i-1)];
            S.hAixLw(i).YLim = [-500 500];
        end
    end
end

h.t = t;
h.freq = freq;
h.cfs = cfs;
h.waveT = waveT;
h.waveData = waveData;
h.clim = clim;


% Start dragzoom utility
dragzoom();

% Put the handel 'h' available from GUI build on S.hGif
% h = [];
h.S = S;
h.timeWindowStartUp = timeWindowStartUp;
h.timeWindowStepUp = timeWindowStepUp;
h.timeWindowStartLw = timeWindowStartLw;
h.timeWindowStepLw = timeWindowStepLw;
% h.specgName = specgName;

guidata(S.hFig, h);
% Initiate KeyPressFcn
set(S.hFig, 'KeyPressFcn', {@keyInterfaceOfFigure, S});

%##########################################################################
function [] = keyInterfaceOfFigure(varargin)
% retrieve handles
hObject =  varargin{1};
eventData = varargin{2};
S = varargin{3};
h = guidata(hObject);

% Identify key pressed
switch eventData.Character
    case {',', '.'}
        switch eventData.Character
            case ','
                if isempty(eventData.Modifier), step = -1;
                elseif strcmp(eventData.Modifier{:},'control'), step = -10;
                elseif strcmp(eventData.Modifier{:},'alt'), step = -100;
                end
            case '.'
                if isempty(eventData.Modifier), step = 1;
                elseif strcmp(eventData.Modifier{:},'control'), step = 10;
                elseif strcmp(eventData.Modifier{:},'alt'), step = 100;
                end
            otherwise,   step = 0;
        end
        
        % For spectrogram (sampling at 125Hz)
        h.timeWindowStartUp = h.timeWindowStartUp + h.timeWindowStepLw/2 * step;
        timeWindowEndUp = h.timeWindowStartUp + h.timeWindowStepUp - 1;
        h.timeWindowStartLw = h.timeWindowStartLw + h.timeWindowStepLw/2 * step;
        timeWindowEndLw = h.timeWindowStartLw + h.timeWindowStepLw - 1;
        % For waves (sampling at 1250Hz)
        endUp = timeWindowEndUp * 10;
        startUp = endUp - h.timeWindowStepUp * 10 + 1;
        endLw = timeWindowEndLw * 10;
        startLw = endLw - h.timeWindowStepLw * 10 + 1;
        %   List for file types to be read
        type = {'specg','lfp','gamma','theta','delta'};
        
        % Redraw the spectrogram
        i = 1;
        %   upper panel
        delete(findobj(h.S.hAixUp(i), 'Type', 'Image'));
        imagesc(h.S.hAixUp(i),h.t(h.timeWindowStartUp:timeWindowEndUp),...
            h.freq,h.cfs(:,h.timeWindowStartUp:timeWindowEndUp),h.clim);
        h.S.hAixUp(i).XLim = [h.t(h.timeWindowStartUp) h.t(timeWindowEndUp)];
        %   lower panel
        delete(findobj(h.S.hAixLw(i), 'Type', 'Image'));
        imagesc(h.S.hAixLw(i),h.t(h.timeWindowStartLw:timeWindowEndLw),...
            h.freq,h.cfs(:,h.timeWindowStartLw:timeWindowEndLw),h.clim);
        h.S.hAixLw(i).XLim = [h.t(h.timeWindowStartLw) h.t(timeWindowEndLw)];

        % Draw waves
        for i = 2:6
            %   Draw uppter panel
            delete(findobj(h.S.hAixUp(i), 'Type', 'Line'));
            plot(h.S.hAixUp(i),h.waveT(startUp:endUp,i-1),h.waveData(startUp:endUp,i-1),'k');
            h.S.hAixUp(i).XLim = [h.waveT(startUp,i-1) h.waveT(endUp,i-1)];
            %   Draw lower panel
            delete(findobj(h.S.hAixLw(i), 'Type', 'Line'));
            plot(h.S.hAixLw(i),h.waveT(startLw:endLw,i-1),h.waveData(startLw:endLw,i-1),'k');
            h.S.hAixLw(i).XLim = [h.waveT(startLw,i-1) h.waveT(endLw,i-1)];
        end
        %h.S.hAixUp(5).XLim = [h.waveT(startUp,1) h.waveT(endUp,1)];
        %h.S.hAixLw(5).XLim = [h.waveT(startLw,1) h.waveT(endLw,1)];
end

% update handles
guidata(hObject, h);
end

%##########################################################################
function [] = readSpecg(fileName,type)

[~, fileNameNoExt, ~] = fileparts(fileName);
eval(['global ' fileNameNoExt ';']);

% Read spectrogram
fprintf(1,['Loading ' type ' data ...' fileName ' ']);
startTime = cputime;
eval([fileNameNoExt ' = load(fileName);']);
fprintf(1,'Completed. Elapsed time = %8.1f s\n',cputime - startTime );
% eval([fileNameNoExt ' = ' fileNameNoExt '.specg;']);
eval([fileNameNoExt ' = ' fileNameNoExt '.' type ';']);
end

%##########################################################################
function [hAxis, hTitle] = genSubPlot(numSubPlot,fontSize,p)

for i = 1:numSubPlot
    positionP = ...
        [p.plotMarginLeft, 1 - p.plotMarginTop - p.plotHightInterval * i,...
        p.plotWidth, p.plotHight];
    hAxis(i) = subplot('Position', positionP); hold on;
    hAxis(i).XGrid = 'on';
    hAxis(i).YGrid = 'on';
    hAxis(i).GridLineStyle = ':';
    hAxis(i).GridColor = [0 0 0];
    hAxis(i).GridAlpha = 1.0;
    if i == numSubPlot
        hAxis(i).FontSize = fontSize;
        xlabel(hAxis(i),'time (s)');
        ylabel(hAxis(i),'LFP (micro V)');
    else
        hAxis(i).FontSize = fontSize;
        hAxis(i).XTickLabel = [];
        ylabel(hAxis(i),'LFP (micro V)');
        if i == 1
            hTitle = title(hAxis(i),['Sweep 1 / ' ]);
            ylabel(hAxis(i),'frequency (Hz)');
        end
    end
end
end
%##########################################################################

