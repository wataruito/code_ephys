function intan2neurosuit
% intan2neurosuit - Convert Intan file to Neurosuit format.
%
%  Extract recording data Intan amplifier data files (*.int) and convert
%  the format readable by Neurosuit.
%
%  USAGE
%    (Inside the directory where Intan files exit)
%    >> intan2neurosuit
%
%  INPUTS
%
%    channels(required) -must be first input, numeric
%                        list of channels to load (use keyword 'all' for all)
%                        channID is 0-indexing, a la neuroscope
%  Name-value paired inputs:
%    basepath           - folder in which .lfp file will be found (default
%                           is pwd)
%                           folder should follow buzcode standard:
%                           whateverPath/baseName
%                           and contain file baseName.lfp
%    basename           -base file name to load
%    intervals          -list of time intervals [0 10; 20 30] to read from
%                           the LFP file (default is [0 inf])
%
%  OUTPUT
%
%    lfp             struct of lfp data. Can be a single struct or an array
%                    of structs for different intervals.  lfp(1), lfp(2),
%                    etc for intervals(1,:), intervals(2,:), etc
%    .data           [Nt x Nd] matrix of the LFP data
%    .timestamps     [Nt x 1] vector of timestamps to match LFP data
%    .interval       [1 x 2] vector of start/stop times of LFP interval
%    .channels       [Nd X 1] vector of channel ID's
%    .samplingRate   LFP sampling rate [default = 1250]
%    .duration       duration, in seconds, of LFP interval
%
%
%  EXAMPLES
%
%    % channel ID 5 (= # 6), from 0 to 120 seconds
%    lfp = bz_GetLFP(5,'restrict',[0 120]);
%    % same, plus from 240.2 to 265.23 seconds
%    lfp = bz_GetLFP(5,'restrict',[0 120;240.2 265.23]);
%    % multiple channels
%    lfp = bz_GetLFP([1 2 3 4 10 17],'restrict',[0 120]);
%    % channel # 3 (= ID 2), from 0 to 120 seconds
%    lfp = bz_GetLFP(3,'restrict',[0 120],'select','number');

% Copyright (C) 2004-2011 by Michaël Zugaro
% editied by David Tingley, 2017
%
% NOTES
% -'select' option has been removed, it allowed switching between 0 and 1
%   indexing.  This should no longer be necessary with .lfp.mat structs
%
% TODO
% add saveMat input
% expand channel selection options (i.e. region or spikegroup)
% add forcereload

%#########################################################################
% Convert Intan .int file to Axon format
%
% Functions:
%   This program chops Intan recording file into 400 ms sweeps centered at
%   the triger from aux1 and aux2 for right and left side recording, respectively.
%   Resulting data will be output into the same directory of the input
%   file.
%#########################################################################
% Bug fix
% 2017-12-13
% When total 6 channel recording, 5th and 6th extracting data is 0.
% Define the belonging either right/left in from_int_file_to_atf_time_trigger_files
% for the additional recording channels.
%#########################################################################

disp(['The working folder: ' pwd])
dataSeriseFiles = dir([pwd filesep '*.int']); % Get file list of *.int
[dataSeriseFilesNumber, ~] = size(dataSeriseFiles);

for k = 1:dataSeriseFilesNumber
    [~, fileNameNoExt, ~] = fileparts(dataSeriseFiles(k).name);
    [d1, ~] = size(dir([pwd filesep fileNameNoExt '*.atf']));
    if d1 == 0
        [intFileNameExt,t,amps,data,aux] = ...
            read_intan_data_2([pwd filesep dataSeriseFiles(k).name]);
        
        frame_convertor(intFileNameExt,t,aux);
        
        from_int_file_to_atf_time_trigger_files(intFileNameExt,t,amps,data,aux);
    end
    disp(['completed ', num2str(k), '/', num2str(dataSeriseFilesNumber)]);
end

function [filename,t,amps,data,aux] = read_intan_data_2(filename)

% [t,amps,data,aux] = read_intan_data
%
% Opens file selection GUI to select and then read data from an Intan
% amplifier data file (*.int).
%
% t = time vector (in seconds)
% amps = vector listing active amplifier channels
% data = matrix of electrode-referred amplifier signals (in microvolts)
% aux = matrix of six auxiliary TTL input signals
%
% Example usage:
%  >> [t,amps,data,aux] = read_intan_data;
%  >> plot(t,data(:,1));
%
% Version 1.1, June 26, 2010
% (c) 2010, Intan Technologies, LLC
% For more information, see http://www.intantech.com
% For updates and latest version, see http://www.intantech.com/software.html
%
% 06-22-10 Added GUI file selection and optimized: Craig Patten, Plexon, Inc.

% use MATLAB predefined gui uigetfile to select the file(s) to analyze
% [file, path, filterindex] = uigetfile('*.int','Select a .int file','MultiSelect', 'off');
% filename = [path,file];

fid = fopen(filename, 'r');

% Read first three header bytes encoding file version
for i=1:3
    header(i) = fread(fid, 1, 'uint8');
end

if (header(1) ~= 128)
    error('Improper data file format.');
end

if (header(2) ~= 1 || header(3) ~= 1)
    warning('Data file version may not be compatible with this m-file.');
end

% Now see which amplifier channels are saved in this file.
for i=1:64
    amp_on(i) = fread(fid, 1, 'uint8');
end

num_amps = sum(amp_on);

% Create a list of amplifier channels in this file.
amps = zeros(1,num_amps);
index = 1;
for i=1:64
    if (amp_on(i) == 1)
        amps(index) = i;
        index = index + 1;
    end
end

% Now search for the end of the file to find out the length of the data.
% t_count = 0;
% while (~feof(fid))
%    fread(fid, 1+4*num_amps, 'uint8');
%    t_count = t_count + 1;
% end
% t_count = t_count - 1;
% t_max = t_count/25000;

%-----------------------------------
% replace above code with a more efficient method CDP 06-24-10
s = dir(filename);
filesize = s.bytes;
t_count = (filesize - 67)/(num_amps*4 + 1);
t_max = t_count/25000;
%-----------------------------------

% print channel (singular) when there is only one channel! CDP 06-24-10
if num_amps == 1;
    fprintf(1, '\nData file contains %0.2f seconds of data from %d amplifier channel.\n', t_max, num_amps);
    fprintf(1, 'Channel: ');
else
    fprintf(1, '\nData file contains %0.2f seconds of data from %d amplifier channels.\n', t_max, num_amps);
    fprintf(1, 'Channels: ');
end

for i=1:num_amps
    fprintf(1, '%d ', amps(i));
end
fprintf(1, '\n\n');

% Pre-allocate large data matrices.
aux = zeros(t_count,6,'uint8');
t = (0:1:(t_count-1))/25000;
t = t';
%--------------------------------------
% Replace code code below with much faster code CDP 06-24-10
% Go back to the beginning of the file...
frewind(fid);

% ...skip the header this time...
fread(fid, 3+64, 'uint8');

% allocate space to read the entire file
data2 = zeros((filesize-67),1,'uint8');
% read the entire file
fprintf(1, 'Reading data file... ');
data2 = fread(fid,(filesize-67),'uint8=>uint8');
fprintf(1, 'Completed!\n');

% extract the digital data
fprintf(1, 'Extracting aux data... ');
aux_data = data2((num_amps*4)+1:num_amps*4+1:filesize-67);

% extract individual bits
aux = [bitget(aux_data,6),bitget(aux_data,5),bitget(aux_data,4),bitget(aux_data,3),bitget(aux_data,2),bitget(aux_data,1)];
clear aux_data;
fprintf(1, 'Completed!\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The original code needs large memory (WI 2016-08-08)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% delete the digital data
% data2((num_amps*4)+1:num_amps*4+1:filesize-67) = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Modified v1. It's slow (WI 2016-08-14)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% fprintf(1, 'start new routine\n');
% data3 = zeros((filesize-67)/(num_amps*4+1)*(num_amps*4),1,'uint8');
% step = num_amps*4 + 1;
% ind2 = 1;
% for ind = 1:step:filesize-67
%     data3(ind2:ind2+step-2) = data2(ind:ind+step-2);
%     ind2 = ind2 + (step - 1);
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Modified v1.1 Need transpose (WI 2016-08-14)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Extracting recording data... ');
data4 = vec2mat(data2, num_amps*4+1); % convert into a matrix with num_amps*4+1 columns
data4(:,num_amps*4+1) = []; % remove the AUX column
data6 = reshape(data4.',[],1); % convert transposed one to one column
data6 = typecast(data6,'single'); % convert 4 bytes binary to single
data = vec2mat(data6, num_amps); % convert into a matrix of single with num_amps columns
fprintf(1, 'Completed!\n');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% % Go back to the beginning of the file...
% frewind(fid);
%
% % ...skip the header this time...
% fread(fid, 3+64, 'uint8');
%
% % ...and read all the data.
% fprintf(1, 'Reading data...  (This may take a while.)\n\n');
% for i=1:t_count
%     for j=1:num_amps
%         data(i,j) = double(fread(fid, 1, 'float32'));
%     end
%
%     aux_byte = fread(fid, 1, 'uint8');
%
%     % Decode auxiliary TTL inputs
%     if aux_byte >= 32
%         aux(i,6) = 1;
%         aux_byte = aux_byte - 32;
%     end
%     if aux_byte >= 16
%         aux(i,5) = 1;
%         aux_byte = aux_byte - 16;
%     end
%     if aux_byte >= 8
%         aux(i,4) = 1;
%         aux_byte = aux_byte - 8;
%     end
%     if aux_byte >= 4
%         aux(i,3) = 1;
%         aux_byte = aux_byte - 4;
%     end
%     if aux_byte >= 2
%         aux(i,2) = 1;
%         aux_byte = aux_byte - 2;
%     end
%     if aux_byte >= 1
%         aux(i,1) = 1;
%         aux_byte = aux_byte - 1;
%     end
% end

% Close file, and we're done.
fclose(fid);

function from_int_file_to_atf_time_trigger_files(intFileNameExt,t,amps,data,aux)
% Sweep length calculation
% Each sweep length is 300 ms (sweep_len). 0.3s is 7500 sampling point at 25kHz.
sweep_len = 0.3 * 25000;
% Each sweep has 100 ms (offset_len) before the trigger.
offset_len = 0.1 * 25000;
% Total sweep length is 400 ms(sample_n).
sample_n = offset_len + sweep_len + 1;

% Call read_intan_data.m to read from ".int" file
% [intFileNameExt,t,amps,data,aux] = read_intan_data;
% plot(t,data(:,ch));
[pathstr,intFileName,ext] = fileparts(intFileNameExt);
% mkdir(intFileName);

% #########################################################################
% # Identify triggers in aux1 and store array of position
% # in trig_t(). Next search begins after sweep_len (0.3 sec).
% #########################################################################
% Read total number of sampling points, d1.
[d1, d2] = size(data);

% Search bits in aux and store the index in trig_t().
% Initialize the indices for the loop
positionAux = [6 5]; % aux(,6) for aux1, aux(,5) for aux2

for j = 1:2
    i = 0; ind = 1;
    while ind < d1
        if aux(ind,positionAux(j)) == 1
            i = i + 1;
            trig_t(j,i) = ind;      % trig_t(i): array of pointer for trigger. 1 < i < sweep_n
            ind = ind + sweep_len;
        end
        ind = ind + 1;
    end
    sweep_n(j) = i;                 % total number of sweep
end

fprintf(1, '\nsweep_n(1)= %d\n', sweep_n(1));
fprintf(1, 'sweep_n(2)= %d\n', sweep_n(2));
if (sweep_n(1) ~= sweep_n(2))
    disp('sweep_n(1) ~= sweep_n(2)');
    %    return;
end

% Memory allocation for output atf files containing chopped sweeps
channel_n = size(amps, 2);
dataSeriseForSweep = zeros(channel_n ,sample_n, sweep_n(1));
timeSeriseForSweep = zeros(channel_n ,sample_n, sweep_n(1));
auxSeriseForSweep = zeros(channel_n ,sample_n, 6, sweep_n(1),'uint8');

% Chop of each sweep and store into output arrays.
% Here channel 1,2 are right side (j=1), 3,4 are left (j=2).
% When recording configuration is right amyhgala #5 #6 and left amygdala #11 #12
% channels = [1 2; 3 4];
% (2017-12-13 wi) When recording configuration is right amyhgala #5 #6 and right PL #8
%                                   left PL #9 and left amygdala #11 #12
channels = [1 2 3; 4 5 6];
%channels = [4 5 6; 1 2 3];

for j = 1:2
    for sweep = 1:sweep_n(j)
        sweep_b = trig_t(j ,sweep) - offset_len;
        sweep_e = trig_t(j ,sweep) + sweep_len;
        if (sweep_b > 0 && sweep_e < d1)
            for channel = channels(j,:)
                dataSeriseForSweep(channel, :, sweep) = data(sweep_b : sweep_e,channel);
                timeSeriseForSweep(channel, :, sweep) = t(sweep_b : sweep_e);
                auxSeriseForSweep(channel, :, :, sweep) = aux(sweep_b : sweep_e, :);
            end
        end
    end
end


% Output each channel file into atf1 format file,
% and move files under the intFileName folder.
for channel = 1:channel_n
    channelName = int2str(amps(channel));
    if (amps(channel) < 10) channelName = ['0' channelName]; end
    
    file_name = [pathstr filesep intFileName '_ch' channelName '.atf'];
    workingStorage = squeeze(dataSeriseForSweep(channel, :, :));
    save(file_name, 'workingStorage', '-tabs', '-ascii');
    
    file_name = [pathstr filesep intFileName '_ch' channelName '_time_aux'];
    timeSerise = squeeze(timeSeriseForSweep(channel, :, :));
    auxSerise = squeeze(auxSeriseForSweep(channel, :, :, :));
    save(file_name, 'timeSerise' ,'auxSerise');
    
    % movefile(file_name,intFileName);
end

% Move the original int file to intFileName folder
% movefile(intFileNameExt, intFileName);
% exit;

function frame_convertor(intFileNameExt,t,aux)

% Read total number of sampling points, d1.
[d1, ~] = size(aux);

% Generating starting time (s) from filename
[pathstr, fileNameNoExt, ~] = fileparts(intFileNameExt);
[~, charLen] = size(fileNameNoExt);
[~, ~, ~, HH, MM, SS] = datevec(fileNameNoExt(charLen - 5 : charLen), 'HHMMSS');
startTime = SS + (MM + HH * 60) * 60;

% Initializing variables
bitNum = 27;
auxCh6 = 1; % pulse trains for timing
auxCh5 = 2; % actual pulse input from master camera

% Start scanning from begining
ind = 1;
pulseEndTs=t(ind);	% Time stamp at the end of a pulse
pulseCount = 0;	% Counting pulses inside a train
frameCount = 1;	% Counting trains (frames)
pulse = 0;		% Bit is high(1) or low(0)

while ind <= d1
    if aux(ind,auxCh6) == 1 % Bit is high
        if pulse==0 % Change from low to high
            pulse=1; % pulse on state
            
            % Examine the detected pulse belongs to the same or previous
            % train
            % Intra-tain pulse
            if t(ind)-pulseEndTs < 0.0002
                % Should be intra train, so that puseCount 1 to 26
                if pulseCount >= bitNum
                    % Error process
                end
            end
            
            % Inter-train pulse
            if t(ind)-pulseEndTs > 0.06
                % Should be inter train
                if pulseCount ~= 0
                    % The last train has less than 27 pulses
                    pulseCount = 0; % reset pulseCount
                end
            end
            
            if pulseCount == 0
                %                timeStamp(frameCount) = t(ind) + startTime;
                timeStamp(frameCount) = t(ind);
                
            end
            
            pulseCount = pulseCount + 1;
            bitCh5(pulseCount) = 0; % initialize bitCh5
            
        elseif pulse == 1 % Continue high
        end
        
        % Check Ch5
        if aux(ind,auxCh5) == 1
            bitCh5(pulseCount) = 1;
        end
        
    elseif aux(ind,auxCh6) == 0 % Bit is low
        if pulse == 1 % Change from high to low. End of one pulse
            pulse = 0;
            pulseEndTs = t(ind);
            if pulseCount == bitNum
                pulseCount = 0;	% reset pulseCount
                % Process Ch5
                frameNum(frameCount) = double(bi2de(fliplr(bitCh5)));
                frameCount = frameCount + 1;
            end
        elseif pulse == 0 % Continue low
        end
    end
    ind = ind + 1;
end

timeFrame = [timeStamp' frameNum'];
file_name = [pathstr filesep fileNameNoExt '_timeFrame'];
save(file_name, 'timeFrame');

