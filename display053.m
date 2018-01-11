%% ########################################################################
% display052working
%
% Function:
%   1. User interface to specify processed channel data
%   2. Read all data from the channel
%   3. Generate base figure
%       list of files
%       plot of sweep data
%       plot of 1st and 2nd response
%   4. User interface to specify the range of evoked reponses
%   5. Evoke the following data process
%       subtract base
%       calculate peak and slope
%       plot the peak and slope
%       output text file
%
% Need to improve
%   a) Selecting current sweep not only by moving one sweep, but also 10 and 100 sweeps
%   b) In the base figure, refresh reading files by append only new files.
%
% Done
%   a) workTimeSerise now has all relative time in millisecond for every
%   sweeps
%   b) listbox of files read.
%   c) Grid drawing on the figure to determine the size of each object
%   d) hr representation of x axis of slope and amplitude
%   e) Read additional atf files by pressing buttum
%
%##########################################################################

%% ########################################################################
function [] = display053

% Specify a atf file for choosing the target channel
[atfFile, atfFilePath, ~] = uigetfile('*.atf','Select a .atf file','MultiSelect', 'off');

% Read all the same channel atf files and aggregate
totalSweepNumber = 0;
dataSeriseFiles = dir('xxxx.xxx');
workDataSerise = zeros();
workTimeSerise = zeros();
totalSecOrigin = 0;
[dataSeriseFiles, workDataSerise, workTimeSerise,...
    totalSweepNumber, totalSecOrigin] = ...
    aggregate_data...
    (atfFilePath, atfFile,...
    dataSeriseFiles, workDataSerise, workTimeSerise,...
    totalSweepNumber, totalSecOrigin);

%##########################################################################
% Generate figure
% generation_figure(dataSeriseFiles, workDataSerise, workTimeSerise);
% function [] = generation_figure(dataSeriseFiles, workDataSerise, workTimeSerise)
%##########################################################################

% extract total sweep number and datapoint of one sweep
% [sampleNumberOfSweep, totalSweepNumber] = size(workDataSerise);
% Parameters
grayColor = [0.7 0.7 0.7]; % definitiion of grey
axisLimitSubplot2 = [98 110 -inf inf]; % subplot2 time axis range
axisLimitSubplot3 = [148 160 -inf inf]; % subplot3 time axis range
plotNumberAtOnce = 21; % should be odd
grayRange = [1, plotNumberAtOnce];

%##########################################################################
%  Generating initial figure
%##########################################################################
S.hFig = figure('units','pixels',...
    'position',[100 100 1000 1000],...
    'menubar','none',...
    'name','GUI_1',...
    'numbertitle','off',...
    'resize','on'); hold on;

%### Subplot 1 ############################################################
S.hSub1 = subplot('Position', [0.1, 0.45, 0.8, 0.3]); hold on;
S.hPlot1 = gobjects(1,totalSweepNumber); % Initialize array for graphics objects
hAxis = gca;hAxis.XGrid = 'on';hAxis.YGrid = 'on';hAxis.GridLineStyle = ':';
hAxis.GridColor = [0 0 0];hAxis.GridAlpha = 1.0;
% plot the entire sweeps
for sweep = 1: plotNumberAtOnce
    S.hPlot1(sweep) = plot(S.hSub1,...
        workTimeSerise(:,1)-workTimeSerise(1,1), workDataSerise(:,sweep),...
        'Color', grayColor,...
        'LineWidth',0.001);
end
% title and labels
S.hSub1Title = title(['Sweep 1 / ' num2str(totalSweepNumber)]);
xlabel('time (ms)'); ylabel('LFP (micro V)');

%### Subplot 2 ############################################################
% S.hSub2 = subplot(2,2,3); hold on;
S.hSub2 = subplot('Position', [0.1, 0.1, 0.3, 0.25]); hold on;
axis(S.hSub2,axisLimitSubplot2,'auto y'); % limit the range of display
hAxis = gca;hAxis.XGrid = 'on';hAxis.YGrid = 'on';hAxis.GridLineStyle = ':';
hAxis.GridColor = [0 0 0];hAxis.GridAlpha = 1.0;
S.hPlot2 = gobjects(1,totalSweepNumber); % Initialize array for graphics objects
% plot the entire sweeps
for sweep = 1: plotNumberAtOnce
    S.hPlot2(sweep) = plot(S.hSub2,...
        workTimeSerise(:, 1)-workTimeSerise(1,1), workDataSerise(:, sweep),...
        'Color', grayColor,...
        'LineWidth',0.001);
end
% title and labels
title('1st response');
xlabel('time (ms)'); ylabel('LFP (micro V)');

%### Subplot 3 ############################################################
S.hSub3 = subplot('Position', [0.6, 0.1, 0.3, 0.25]); hold on;
% S.hSub3 = subplot(2,2,4); hold on;
axis(S.hSub3,axisLimitSubplot3,'auto y'); % limit the range of display
hAxis = gca;hAxis.XGrid = 'on';hAxis.YGrid = 'on';hAxis.GridLineStyle = ':';
hAxis.GridColor = [0 0 0];hAxis.GridAlpha = 1.0;
S.hPlot3 = gobjects(1,totalSweepNumber); % Initialize array for graphics objects
% plot the entire sweeps
for sweep = 1: plotNumberAtOnce
    S.hPlot3(sweep) = plot(S.hSub3,...
        workTimeSerise(:, 1)-workTimeSerise(1,1),workDataSerise(:, sweep),...
        'Color', grayColor,...
        'LineWidth',0.001);
end
% title and labels
title('2nd response');
xlabel('time (ms)'); ylabel('LFP (micro V)');

%### Push button 1 ########################################################
%   evoke subtraction and calculate slope and peak to be plotted
S.hPb1 = uicontrol('Parent', S.hFig,...
    'style','push',...
    'Units','normalized',...
    'position',[0.1 0.01 0.2 0.03],...
    'fontsize',10,...
    'string','Calculate amplitude and slope');

%### Push button 2 ########################################################
%   evoke subtraction and calculate slope and peak to be plotted
S.hPb2 = uicontrol('Parent', S.hFig,...
    'style','push',...
    'Units','normalized',...
    'position',[0.5 0.80 0.2 0.03],...
    'fontsize',10,...
    'string','Read additional files');

%### Annotation 1 #########################################################
%   display file list in the figure
% a = struct2cell(dataSeriseFiles);
% [d1,d2] = size(a);
% annotationString = '';
% for i = 1 : d2
%     annotationString = [annotationString a{1 , i} ',  '];
% end
% annotation(S.hFig,...
%     'textbox',[0.1 0.7 0.3 0.3],...
%     'String',annotationString,...
%     'FitBoxToText','on',... % textbox is shrinked to fit text
%     'interpreter', 'none',...
%     'BackgroundColor', 'white'); % underscore interpreted by Tex

%### List 1 #########################################################
%   display file list in the figure
a = struct2cell(dataSeriseFiles);
S.hAnno1 = uicontrol(S.hFig,...
    'style','listbox',...
    'Units','normalized',...
    'position',[0.1 0.80 0.3 0.15],...
    'min',0,'max',2,...
    'fontsize',10,...
    'string',a(1,:));

%### Cursors ##############################################################
%   cursors in subplot2
cursorPosition1 = 102.0;
hCursor11 = plot(S.hSub2,...
    [cursorPosition1, cursorPosition1],...
    [-3000.0, 3000.0],...
    'Color', 'blue');
hCursor12 = plot(S.hSub2,...
    [cursorPosition1 + 5.0, cursorPosition1 + 5.0],...
    [-3000.0, 3000.0],...
    'Color', 'blue');
%   cursors in subplot3
cursorPosition2 = 152.0;
hCursor21 = plot(S.hSub3,...
    [cursorPosition2, cursorPosition2],...
    [-3000.0, 3000.0],...
    'Color', 'blue');
hCursor22 = plot(S.hSub3,...
    [cursorPosition2 + 5.0, cursorPosition2 + 5.0],...
    [-3000.0, 3000.0],...
    'Color', 'blue');

%### Normalized grids by Annotation textbox ###############################
%   Display normalized grids in the figure for arrangement of objects
for i = 1 : 10
    for j = 1 : 10
        annotation(S.hFig,...
            'textbox',[0.1*(i-1) 0.1*(j-1) 0.1 0.1],...
            'String',['     '],...
            'LineWidth', 0.1, ...
            'LineStyle', ':',...
            'EdgeColor', [0 1 0],...
            'FitBoxToText','off',... % textbox is shrinked to fit text
            'interpreter', 'none' ); % underscore interpreted by Tex
    end
end
%### Annotation ###########################################################
%   display cursor start stop

hAnno2 = annotation(S.hFig,...
    'textbox',[0.1 0.37 0.1 0.02],...
    'String',['start: ' num2str(cursorPosition1) ' ms'],...
    'FitBoxToText','off',... % textbox is shrinked to fit text
    'interpreter', 'none' ); % underscore interpreted by Tex

hAnno3 = annotation(S.hFig,...
    'textbox',[0.3 0.37 0.1 0.02],...
    'String',['end: ' num2str(cursorPosition1 + 5.0) ' ms'],...
    'FitBoxToText','off',... % textbox is shrinked to fit text
    'interpreter', 'none' ); % underscore interpreted by Tex

hAnno4 = annotation(S.hFig,...
    'textbox',[0.6 0.37 0.1 0.02],...
    'String',['start: ' num2str(cursorPosition2) ' ms'],...
    'FitBoxToText','off',... % textbox is shrinked to fit text
    'interpreter', 'none' ); % underscore interpreted by Tex

hAnno5 = annotation(S.hFig,...
    'textbox',[0.8 0.37 0.1 0.02],...
    'String',['end: ' num2str(cursorPosition2 + 5.0) ' ms'],...
    'FitBoxToText','off',... % textbox is shrinked to fit text
    'interpreter', 'none' ); % underscore interpreted by Tex

%### Transfering variable visible inside other function ###################
sweep = 1;      % need to define before make variable visible

handles = guihandles(S.hFig);

handles.atfFilePath = atfFilePath;
handles.atfFile = atfFile;
handles.dataSeriseFiles = dataSeriseFiles;
handles.workDataSerise = workDataSerise;
handles.workTimeSerise = workTimeSerise;
handles.totalSweepNumber = totalSweepNumber;
handles.totalSecOrigin = totalSecOrigin;

handles.hSub1 = S.hSub1;
handles.hSub2 = S.hSub2;
handles.hSub3 = S.hSub3;

handles.axisLimitSubplot2 = axisLimitSubplot2;
handles.axisLimitSubplot3 = axisLimitSubplot3;

handles.hSub1Title = S.hSub1Title;

handles.hPlot1 = S.hPlot1;
handles.hPlot2 = S.hPlot2;
handles.hPlot3 = S.hPlot3;

handles.sweep = sweep;
handles.plotNumberAtOnce = plotNumberAtOnce;
handles.grayRange = grayRange;

handles.hCursor11 =  hCursor11;
handles.hCursor12 =  hCursor12;
handles.hCursor21 =  hCursor21;
handles.hCursor22 =  hCursor22;

handles.hAnno2 = hAnno2;
handles.hAnno3 = hAnno3;
handles.hAnno4 = hAnno4;
handles.hAnno5 = hAnno5;

guidata(S.hFig, handles);

%### Start dragzoom utility ###############################################
dragzoom();

%### Change color of current sweep to red #################################
changePlotColorRed(S, sweep);

%### Initiate callbacks ###################################################
%   It is necessary to set the call back at the end; otherwise, the struct
%   "S" contains only part of all.work
set(S.hFig, 'KeyPressFcn', {@keyInterfaceOfFigure, S});
set(S.hPb1, 'callback', {@pb1_call, S});
set(S.hPb2, 'callback', {@pb2_call, S});

%##########################################################################
function...
    [dataSeriseFiles, workDataSerise, workTimeSerise,...
    totalSweepNumber, totalSecOrigin] = ...
    aggregate_data...
    (path, file,...
    dataSeriseFiles, workDataSerise, workTimeSerise,...
    totalSweepNumber, totalSecOrigin)

% Extracting channel number from filename by the string pattern _ch??.atf
underscore_indices = strfind(file, '_'); % identify the indices for '_'
atf_indices = strfind(file, '.atf');
channelNumber = file(underscore_indices(end)+1 : atf_indices(end)-1);

% Reading sweep files
% Generate directory file list by 'dir *_ch??.atf
% Append sweeps from the list of files into workDataSerise
[previousDataSeriseFilesNumber, ~] = size(dataSeriseFiles);
dataSeriseFiles = dir([path '*_' channelNumber '.atf']);
[dataSeriseFilesNumber, ~] = size(dataSeriseFiles);

timeSeriseFiles = dir([path '*_' channelNumber '_time_aux.mat']);
[timeSeriseFilesNumber, ~] = size(timeSeriseFiles);

if previousDataSeriseFilesNumber < dataSeriseFilesNumber
    
    for i = previousDataSeriseFilesNumber + 1 : dataSeriseFilesNumber
        filename = [path dataSeriseFiles(i).name];
        load(filename, '-ascii');
        [pathstr,fileNameNoExt,ext] = fileparts(filename);
        [sampleNumberOfSweep, sweepNumber] = size(eval(fileNameNoExt));
        if i == 1, workDataSerise = zeros(sampleNumberOfSweep, sweepNumber * dataSeriseFilesNumber); end
        workDataSerise(:,1 + totalSweepNumber : sweepNumber + totalSweepNumber)...
            = eval(fileNameNoExt);
        clear eval(fileNameNoExt);
        
        % Reading relative time files
        % Generate directory file list by 'dir *_ch??_time_aux
        % Append absolute time from the list of files into workTimeSerise
        filename = [path timeSeriseFiles(i).name];
        load(filename);
        [sampleNumberOfSweep, sweepNumber] = size(timeSerise);
        if i == 1, workTimeSerise = zeros(sampleNumberOfSweep, sweepNumber * dataSeriseFilesNumber); end
        
        % Calculate absolute second from each file name
        % The begining of the initial file set as totalSecOrigin
        [pathstr,fileNameNoExt,ext] = fileparts(filename);
        underscore_indices = strfind(fileNameNoExt, '_');
        dateString = fileNameNoExt(underscore_indices(1)+1 : underscore_indices(2)-1);
        timeString = fileNameNoExt(underscore_indices(2)+1 : underscore_indices(3)-1);
        dateFormatIn = 'yymmdd';
        timeFormatIn = 'HHMMSS';
        timeVec = datevec(timeString, timeFormatIn);
        totalSec = datenum(dateString, dateFormatIn) * 24 * 60 * 60 + ...
            timeVec(4) * 60 * 60 + timeVec(5) * 60 + timeVec(6);
        if i ==1, totalSecOrigin = totalSec; end
        totalSec = totalSec - totalSecOrigin;
        workTimeSerise(:,1 + totalSweepNumber : sweepNumber + totalSweepNumber)...
            = timeSerise(:, 1 : sweepNumber) * 1000.0 + totalSec * 1000.0;
        clear timeSerise;
        
        if i == 1, totalSweepNumber = sweepNumber;
        else totalSweepNumber = totalSweepNumber + sweepNumber; end
        
    end
end

%##########################################################################
function [] = changePlotColorRed(S, sweep)
% Change color of the target plots in the three subplots to red

handles = guidata(S.hFig);

set(handles.hPlot1(sweep),'Color','red');
uistack(handles.hPlot1(sweep),'top');

set(handles.hPlot2(sweep),'Color','red');
uistack(handles.hPlot2(sweep),'top');

set(handles.hPlot3(sweep),'Color','red');
uistack(handles.hPlot3(sweep),'top');

guidata(S.hFig, handles);

%##########################################################################
function [] = keyInterfaceOfFigure(varargin)
hObject =  varargin{1};
eventdata = varargin{2};
S = varargin{3};
handles = guidata(hObject);

grayColor = [0.7 0.7 0.7]; % define grey color

% Draw current sweep in red and a range of sweep in gray
switch eventdata.Character
    case {',', '.', 'k', 'l', 'K', 'L'}
        switch eventdata.Character
            case ','
                if isempty(eventdata.Modifier), step = -1;
                elseif strcmp(eventdata.Modifier{:},'control'), step = -10;
                elseif strcmp(eventdata.Modifier{:},'alt'), step = -100;
                end
            case '.'
                if isempty(eventdata.Modifier), step = 1;
                elseif strcmp(eventdata.Modifier{:},'control'), step = 10;
                elseif strcmp(eventdata.Modifier{:},'alt'), step = 100;
                end
            otherwise,   step = 0;
        end
        
        % Judge there is still room to move current sweep
        if (strcmp(eventdata.Character, ',') && (handles.sweep + step > 0)) || ...
                (strcmp(eventdata.Character, '.') && (handles.sweep + step - handles.totalSweepNumber <= 0))
            
            sweepPrevious = handles.sweep; % Remember current sweep number
            handles.sweep = handles.sweep + step;
            
            % Calculate range of sweeps drawn in grey
            grayRangePrevious = handles.grayRange;
            
            grayRangeWorking = [handles.sweep - (handles.plotNumberAtOnce-1)/2,...
                handles.sweep + (handles.plotNumberAtOnce-1)/2];
            if grayRangeWorking(1) < 1
                handles.grayRange = [1, handles.plotNumberAtOnce];
            elseif grayRangeWorking(2) > handles.totalSweepNumber
                handles.grayRange = [handles.totalSweepNumber - handles.plotNumberAtOnce + 1, handles.totalSweepNumber];
            else
                handles.grayRange = grayRangeWorking;
            end
            
            % Change color of previous sweep to grey
            set(handles.hPlot1(sweepPrevious),'Color', grayColor);
            set(handles.hPlot2(sweepPrevious),'Color', grayColor);
            set(handles.hPlot3(sweepPrevious),'Color', grayColor);
            
            % Scanning if previous grey plots still sit inside the new range
            % If ouside, delete the plots
            for i = grayRangePrevious(1) : grayRangePrevious(2)
                if i < handles.grayRange(1) || i > handles.grayRange(2)
                    delete(handles.hPlot1(i));
                    delete(handles.hPlot2(i));
                    delete(handles.hPlot3(i));
                end
            end
            
            % Scanning if new grey plots outside the previous range
            % If outside, draw the plots
            for i = handles.grayRange(1) : handles.grayRange(2)
                if i < grayRangePrevious(1) || i > grayRangePrevious(2)
                    handles.hPlot1(i) = ...
                        plot(handles.hSub1,...
                        handles.workTimeSerise(:,1)-handles.workTimeSerise(1,1),...
                        handles.workDataSerise(:,i),...
                        'Color', grayColor, 'LineWidth',0.001);
                    handles.hPlot2(i) = ...
                        plot(handles.hSub2,...
                        handles.workTimeSerise(:,1)-handles.workTimeSerise(1,1),...
                        handles.workDataSerise(:,i),...
                        'Color', grayColor, 'LineWidth',0.001);
                    handles.hPlot3(i) = ...
                        plot(handles.hSub3,...
                        handles.workTimeSerise(:,1)-handles.workTimeSerise(1,1),...
                        handles.workDataSerise(:,i),...
                        'Color', grayColor, 'LineWidth',0.001);
                end
            end
            
            % Change sweep number at figure title
            handles.hSub1Title.String =...
                ['Sweep ', num2str(handles.sweep), ' / ', num2str(handles.totalSweepNumber)];
            
            % Change color of current sweep to red
            % I need update handles before callin changePlotColorRed
            guidata(hObject, handles);
            changePlotColorRed(S, handles.sweep);
        end
end

if (strcmp(eventdata.Character, '<') || strcmp(eventdata.Character, '>'))
    if strcmp(eventdata.Character, '<')
        xoffset = -0.1;
    elseif strcmp(eventdata.Character, '>')
        xoffset = 0.1;
    end
    
    if (gca == handles.hSub2)
        pos = get(handles.hCursor11, 'XData');
        pos = pos + xoffset;
        set(handles.hCursor11, 'XData', pos);
        set(handles.hAnno2, 'String',['start: ' num2str(pos(1)) ' ms']);
        
        pos = get(handles.hCursor12, 'XData');
        pos = pos + xoffset;
        set(handles.hCursor12, 'XData', pos);
        set(handles.hAnno3, 'String',['end: ' num2str(pos(1)) ' ms']);
        
    elseif (gca == handles.hSub3)
        pos = get(handles.hCursor21, 'XData');
        pos = pos + xoffset;
        set(handles.hCursor21, 'XData', pos);
        set(handles.hAnno4, 'String',['start: ' num2str(pos(1)) ' ms']);
        
        pos = get(handles.hCursor22, 'XData');
        pos = pos + xoffset;
        set(handles.hCursor22, 'XData', pos);
        set(handles.hAnno5, 'String',['end: ' num2str(pos(1)) ' ms']);
        
    end
end

% Put the cursors at the top of the figure
uistack(handles.hCursor11,'top');
uistack(handles.hCursor12,'top');
uistack(handles.hCursor21,'top');
uistack(handles.hCursor22,'top');

guidata(hObject, handles);

%##########################################################################
function [] = pb1_call(varargin)
% Function by pressing this button
%   1. subtract base
%       we have access of handles.workTimeSerise and handles.workDataSerise.
%   2. Draw the subtracted response
%   3. calculate slope (15 to 35%) and peak amplitude
%   4. output spreadsheet and plot graph

hObject =  varargin{1};
eventdata = varargin{2};
S = varargin{3};
handles = guidata(hObject);

work = handles.workDataSerise;
[d1, sweepNumber] = size(work);

%##########################################################################
%  Subtract the baseline
%##########################################################################
% The range of evoked response
pos1 = get(handles.hCursor11, 'XData');
pos2 = get(handles.hCursor21, 'XData');
timeStartResponseArray = [pos1(1), pos2(1)];
% Subtraction of baseline will be done in the rage of 20 ms both before and
% after the evoked response
timeExpansion = 20.0;
% starting time of evoked response(ms)
for timeStartResponse = timeStartResponseArray
    timeEndResponse = timeStartResponse + 5.0;
    timeStartRange = timeStartResponse - timeExpansion;
    timeEndRange = timeEndResponse + timeExpansion;
    % convert time to index of the data array
    indexStartResponse = int16(timeStartResponse * 25);
    indexEndResponse = int16(timeEndResponse * 25);
    indexStartRange = int16(timeStartRange * 25);
    indexEndRange = int16(timeEndRange * 25);
    
    for sweep = 1:sweepNumber
        baselineStartValue = work(indexStartResponse, sweep);
        baselineEndValue = work(indexEndResponse, sweep);
        baselineSlope = (baselineEndValue - baselineStartValue) / double(indexEndResponse - indexStartResponse);
        
        ind = indexStartRange;
        while ind <= indexEndRange
            if (ind <= indexStartResponse)
                work(ind, sweep) = work(ind, sweep) - baselineStartValue;
            elseif (ind > indexStartResponse && ind < indexEndResponse)
                work(ind, sweep) = work(ind, sweep) - baselineStartValue - (baselineSlope * (ind - indexStartResponse));
            elseif (ind >= indexEndResponse)
                work(ind, sweep) = work(ind, sweep) - baselineEndValue;
            end
            ind = ind + 1;
        end
    end
end

%##########################################################################
%  Generating figure and the subtracted plots
%##########################################################################
grayColor = [0.7 0.7 0.7]; % definitiion of grey
axisLimitSubplot2 = [90 120 -500 500]; % subplot2 time axis range
axisLimitSubplot3 = [140 170 -500 500]; % subplot3 time axis range
for generatingFigure = 1: 1
    S1.hFig = figure('units','pixels',...
        'position',[100 100 1000 1000],...
        'menubar','none',...
        'name','GUI_1',...
        'numbertitle','off',...
        'resize','on'); hold on;
    %### Normalized grids by Annotation textbox ###############################
    %   Display normalized grids in the figure for arrangement of objects
    for i = 1 : 10
        for j = 1 : 10
            annotation(S1.hFig,...
                'textbox',[0.1*(i-1) 0.1*(j-1) 0.1 0.1],...
                'String',['     '],...
                'LineWidth', 0.1, ...
                'LineStyle', ':',...
                'EdgeColor', [0 1 0],...
                'FitBoxToText','off',... % textbox is shrinked to fit text
                'interpreter', 'none' ); % underscore interpreted by Tex
        end
    end
    %### Subplot 2 ############################################################
    S1.hSub2 = subplot('Position', [0.1, 0.65, 0.3, 0.3]); hold on;
    %    axis(S1.hSub2,axisLimitSubplot2); % limit the range of display
    axis(S1.hSub2,handles.axisLimitSubplot2,'auto y'); % limit the range of display
    hAxis = gca;hAxis.XGrid = 'on';hAxis.YGrid = 'on';hAxis.GridLineStyle = ':';
    hAxis.GridColor = [0 0 0];hAxis.GridAlpha = 1.0;
    S1.hPlot2 = gobjects(1,sweepNumber); % Initialize array for graphics objects
    % plot the entire sweeps
    for sweep = 1: sweepNumber
        S1.hPlot2(sweep) = plot(S1.hSub2,...
            handles.workTimeSerise(:,1)-handles.workTimeSerise(1,1),work(:, sweep),...
            'Color', grayColor,...
            'LineWidth',0.001);
    end
    % title and labels
    title('1st response');
    xlabel('time (ms)'); ylabel('LFP (micro V)');
    
    %### Subplot 3 ############################################################
    S1.hSub3 = subplot('Position', [0.6, 0.65, 0.3, 0.3]); hold on;
    %    axis(S1.hSub3,axisLimitSubplot3); % limit the range of display
    axis(S1.hSub3,handles.axisLimitSubplot3, 'auto y'); % limit the range of display
    hAxis = gca;hAxis.XGrid = 'on';hAxis.YGrid = 'on';hAxis.GridLineStyle = ':';
    hAxis.GridColor = [0 0 0];hAxis.GridAlpha = 1.0;
    S1.hPlot2 = gobjects(1,sweepNumber); % Initialize array for graphics objects
    S1.hPlot3 = gobjects(1,sweepNumber); % Initialize array for graphics objects
    % plot the entire sweeps
    for sweep = 1: sweepNumber
        S1.hPlot3(sweep) = plot(S1.hSub3,...
            handles.workTimeSerise(:,1)-handles.workTimeSerise(1,1),work(:, sweep),...
            'Color', grayColor,...
            'LineWidth',0.001);
    end
    % title and labels
    title('2nd response');
    xlabel('time (ms)'); ylabel('LFP (micro V)');
    
    %### Cursors ##############################################################
    %   cursors in subplot2
    cursorPosition1 = timeStartResponseArray(1);
    plot(S1.hSub2,...
        [cursorPosition1, cursorPosition1],...
        [-3000.0, 3000.0],...
        'Color', 'blue');
    plot(S1.hSub2,...
        [cursorPosition1 + 5.0, cursorPosition1 + 5.0],...
        [-3000.0, 3000.0],...
        'Color', 'blue');
    %   cursors in subplot3
    cursorPosition2 = timeStartResponseArray(2);
    plot(S1.hSub3,...
        [cursorPosition2, cursorPosition2],...
        [-3000.0, 3000.0],...
        'Color', 'blue');
    plot(S1.hSub3,...
        [cursorPosition2 + 5.0, cursorPosition2 + 5.0],...
        [-3000.0, 3000.0],...
        'Color', 'blue');
end

%##########################################################################
%  Calculate slope (15 to 35%) and peak amplitude
%##########################################################################
peakSlope = zeros(2, 2, sweepNumber);

for i = 1:2
    timeStartResponse = timeStartResponseArray(i);
    timeEndResponse = timeStartResponseArray(i) + 5.0;
    % convert time to index of the data array
    indexStartResponse = int16(timeStartResponse * 25);
    indexEndResponse = int16(timeEndResponse * 25);
    for sweep = 1:sweepNumber
        % identify the peak and peak amplitude
        ind = indexStartResponse;
        while ind <= indexEndResponse
            if (peakSlope(i, 1, sweep) > work(ind, sweep))
                peakSlope(i, 1, sweep) = work(ind, sweep);
            end
            ind = ind + 1;
        end
        
        % identify data point of 15% and 35% of peak amplitude
        ind = indexStartResponse;
        peak15 = peakSlope(i, 1, sweep) * 0.15;
        peak35 = peakSlope(i, 1, sweep) * 0.35;
        while ind <= indexEndResponse
            if (work(ind, sweep) < peak15)
                timeOfpeak15 = handles.workTimeSerise(ind, 1);
                indOfpeak15 = ind;
                break;
            end
            ind = ind + 1;
        end
        
        while ind <= indexEndResponse
            if (work(ind, sweep) < peak35)
                timeOfPeak35 = handles.workTimeSerise(ind, 1);
                indOfpeak35 = ind;
                break;
            end
            ind = ind + 1;
        end
        peakSlope(i, 2, sweep) = ...
            (work(indOfpeak35, sweep) - work(indOfpeak15, sweep)) /...
            (timeOfPeak35 - timeOfpeak15);
    end
end

%### plot ############################################################
S1.hSub4 = subplot('Position', [0.1, 0.1, 0.8, 0.4]); hold on;
%axis(S1.hSub3,axisLimitSubplot3); % limit the range of display
%S1.hPlot3 = gobjects(1,sweepNumber); % Initialize array for graphics objects
% plot the entire sweeps

MarkerColors = {[0.5 0.5 1] [0.7 0.7 1];
    [1 0.5 0.5] [1 0.7 0.7]};
k = 1;
for i = 1:2
    for j = 1:2
        partPeakSlope(k, :) = squeeze(peakSlope(i, j, :));
        plot(S1.hSub4, handles.workTimeSerise(1,:)/3600000.0, partPeakSlope(k, :),...
            'LineStyle', 'none', ...
            'Marker', 'o', ...
            'MarkerSize', 2,...
            'MarkerFaceColor', MarkerColors{i,j},...
            'MarkerEdgeColor', MarkerColors{i,j});
        k = k + 1;
    end
end
hAxis = gca; hAxis.XTick = 0:1:100;
hAxis.XGrid = 'on'; hAxis.YGrid = 'on'; hAxis.GridLineStyle = ':';
hAxis.GridColor = [0 0 0]; hAxis.GridAlpha = 1.0;

% output calculated amplitudes and slopes
% partPeakSlope = squeeze(partPeakSlope');
% save('temp.dat', 'partPeakSlope', '-tabs', '-ascii');
outputForPlot = horzcat(handles.workTimeSerise(1,:)'/3600000.0, squeeze(partPeakSlope'));
save('temp.dat', 'outputForPlot', '-tabs', '-ascii');



% title and labels
title('slope and amplitude of evoked responses');
xlabel('time (hr)'); ylabel('fEPSP slope (micro V/ms) and amplitude (micro V)');
legend('1st amp', '1st slope', '2nd amp', '2nd slope');

% fig2plotly();

%### Start dragzoom utility ###############################################
dragzoom(S1.hFig);





guidata(hObject, handles);

%##########################################################################
function [] = pb2_call(varargin)
% Function by pressing "Read additional files"
%   1. Do dir
%   2. Update listbox
%   3. Compare with the previouse dir
%   4. Read and append new files to dataSerise and timeSerise
%   5. Update sweep total number in the figure

hObject =  varargin{1};
eventdata = varargin{2};
S = varargin{3};

handles = guidata(hObject);


% Read all the same channel atf files and aggregate
[handles.dataSeriseFiles, handles.workDataSerise,...
    handles.workTimeSerise, handles.totalSweepNumber, handles.totalSecOrigin] = ...
    aggregate_data(handles.atfFilePath, handles.atfFile,...
    handles.dataSeriseFiles, handles.workDataSerise,...
    handles.workTimeSerise, handles.totalSweepNumber, handles.totalSecOrigin);

a = struct2cell(handles.dataSeriseFiles);
S.hAnno1.String = a(1,:);

S.hSub1Title.String = ['Sweep 1 / ' num2str(handles.totalSweepNumber)];

guidata(hObject, handles);

%##########################################################################
