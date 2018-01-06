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
            readIntan([pwd filesep dataSeriseFiles(k).name]);
        
        extractFrameNum(intFileNameExt,t,aux);
        
        from_int_file_to_atf_time_trigger_files(intFileNameExt,t,amps,data,aux);
    end
    disp(['completed ', num2str(k), '/', num2str(dataSeriseFilesNumber)]);
end


