
function [filename,t,amps,data,aux] = readIntan(filename)
%% readIntan - IO to read Intan int file
%
%  Read Intan int file
%
%  USAGE
%    >> [filename,t,amps,data,aux] = readIntan(filename)
%
%  INPUTS
%
%  OUTPUTS
%    filename = full path file name in ascii
%    t = time vector (in seconds)
%    amps = vector listing active amplifier channels
%    data = matrix of electrode-referred amplifier signals (in microvolts)
%    aux = matrix of six auxiliary TTL input signals
%
%  Examples
%
%    >> [filename,t,amps,data,aux] = read_intan_data;
%    >> plot(t,data(:,1));
%
%  NOTES
%
%  TODO
%
%  BUG FIX
%
%% Example headder
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
%
%  NOTES
%
%  TODO
%
%  BUG FIX
%
%    2017-12-13
%    When total 6 channel recording, 5th and 6th extracting data is 0.
%    Define the belonging either right/left in from_int_file_to_atf_time_trigger_files
%    for the additional recording channels.
%%

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
if num_amps == 1
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
% Replace code below with much faster code CDP 06-24-10
% Go back to the beginning of the file...
frewind(fid);

% ...skip the header this time...
fread(fid, 3+64, 'uint8');

% allocate space to read the entire file
data2 = zeros((filesize-67),1,'uint8');
% read the entire file
fprintf(1, 'Reading int file... ');
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
fprintf(1, 'Extracting recording data... ');
data4 = vec2mat(data2, num_amps*4+1); % convert into a matrix with num_amps*4+1 columns
data4(:,num_amps*4+1) = []; % remove the AUX column
data6 = reshape(data4.',[],1); % transpose and convert to one column
data6 = typecast(data6,'single'); % convert 4 bytes binary to single
data = vec2mat(data6, num_amps); % convert to a matrix with num_amps columns
fprintf(1, 'Completed!\n');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Close file, and we're done.
fclose(fid);
end