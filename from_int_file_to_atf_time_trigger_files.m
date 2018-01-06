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
