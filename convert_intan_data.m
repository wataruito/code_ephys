%#########################################################################
% Convert Intan .int file to 
Axon format
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


function convert_intan_data
% Get the working directory
folder_name = uigetdir;
% Generate directory file list by 'dir *.int
dataSeriseFiles = dir([folder_name '\*.int']);
[dataSeriseFilesNumber, d2] = size(dataSeriseFiles);

for k = 1:dataSeriseFilesNumber
    [pathstr,fileNameNoExt,ext] = fileparts(dataSeriseFiles(k).name);
    [d1, d2] = size(dir([folder_name '\' fileNameNoExt '*.atf']));
    if d1 == 0
        [intFileNameExt,t,amps,data,aux] = ...
            read_intan_data_2([folder_name '\' dataSeriseFiles(k).name]);
        from_int_file_to_atf_time_trigger_files(intFileNameExt,t,amps,data,aux);
    end
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
fprintf(1, 'Extracting recording data... ');
data4 = vec2mat(data2, num_amps*4+1);
data4(:,num_amps*4+1) =[];
data5 = transpose(data4);
data6 = reshape(data5,[(filesize-67)/(num_amps*4+1)*(num_amps*4),1]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% convert the remaining data from bytes to single
% data3 = typecast(data3,'single');
data6 = typecast(data6,'single');
data = vec2mat(data6, num_amps);

% data = zeros(t_count,num_amps);
% % de-mux the channels
% for ind = 1:num_amps
%     data(:,ind) = data3(ind:num_amps:length(data3));
% end
fprintf(1, ' Completed!\n');

%---------------------------------------

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
    
    file_name = [pathstr '\' intFileName '_ch' channelName '.atf'];
    workingStorage = squeeze(dataSeriseForSweep(channel, :, :));
    save(file_name, 'workingStorage', '-tabs', '-ascii');
    
    file_name = [pathstr '\' intFileName '_ch' channelName '_time_aux'];
    timeSerise = squeeze(timeSeriseForSweep(channel, :, :));
    auxSerise = squeeze(auxSeriseForSweep(channel, :, :, :));
    save(file_name, 'timeSerise' ,'auxSerise');
    
    % movefile(file_name,intFileName);
end

% Move the original int file to intFileName folder
% movefile(intFileNameExt, intFileName);
% exit;
