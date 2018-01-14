disp(['The working folder: ' pwd])
fileList = dir([pwd filesep '*.int']); % Get file list of *.int
[filesNum, ~] = size(fileList);

%        delta      [0 4]
%        theta      [4 10]
%        spindles   [10 20]
%        alphabeta  [10 30]
%        gamma      [30 80]
%        ripples    [100 250]
fqName = {'gamma','alphabeta','theta','delta','specg','specg1'};
foi = {[30 80],[10 30],[4 10],[0 4],[1:0.5:100],[100:20.0:1250]};
width      = 5;
toi        = 0.0:0.008:3600.0;

% rmFields = {'amp','phase'};
rmFields = {'no'};

for k = 1:filesNum
    [~, fileNameNoExt, ~] = fileparts(fileList(k).name);
    
    fprintf(1, ['### Start ' num2str(k) '/' num2str(filesNum) ' ###\n']);
    t_start = cputime;
    
    for i = 1:6
        [d1, ~] = size(dir([pwd filesep fileNameNoExt '*' fqName{i} '.mat']));
        
        if d1 == 0
            if exist('lfp','var') == 0
                [d1, ~] = size(dir([pwd filesep fileNameNoExt '*' 'lfp' '.mat']));
                if d1 == 0
                    % Generate filtered lfp from scrach
                    [intFileNameExt,t,amps,data,aux] = ...
                        readIntan([pwd filesep fileList(k).name]);
                    
                    % Create Bzcode lfp data stracture
                    intan.Filename = intFileNameExt;
                    intan.data = cast(data, 'int16');
                    intan.channels = [0 1 2 3 4 5];
                    intan.samplingRate = 25000;
                    intan.duration = 3600.0000;
                    intan.interval = [0,3600.0000];
                    intan.timestamps = t;
                    clear t data amps data aux;
                    
                    % Low pass filter
                    disp('Low pass filter');
                    [ filtered ] = bz_FilterLFP(intan,'passband', [0 1250]);
                    clear intan;
                    
                    % Downsample from 25000 to 1250
                    disp('Downsampling');
                    [ lfp ] = bz_DownsampleLFP(filtered, 20);
                    clear filtered;
                    
                    lfp = rmfield(lfp,{'amp','phase'});
                                        
                    fprintf(1,['Saving filtered lfp ...']);
                    save([pwd filesep fileNameNoExt '_lfp'], 'lfp', '-v7.3');
                    fprintf(1,'Done\n');
                else
                    load([pwd filesep fileNameNoExt '_lfp.mat']);
                end
            end
            
            if i < 5
                fprintf(1,['Bandpass for ' fqName{i} '...']);
                eval([fqName{i} ' = bz_FilterLFP(lfp,''passband'',foi{i});']);
                % [ gamma ] = bz_FilterLFP(lfp,'passband','gamma');
                fprintf(1,'Done\n');
                
                if rmFields{1} ~='no'
                    eval([fqName{i} ' = rmfield(' fqName{i} ',rmFields);']);
                end
            else
                fprintf(1,['Wavelet convolution for ' fqName{i} '...']);
                eval([fqName{i} ' = wc(lfp,width,foi{i},toi);']);
                fprintf(1,'Done\n');
            end
            
            fprintf(1,['Saving file for ' fqName{i} '...']);
            save([pwd filesep fileNameNoExt '_' fqName{i}], fqName{i}, '-v7.3');
            fprintf(1,'Done\n');
            
            clear(fqName{i});
        end
        
        %         % Plot
        %         plot(lfpdown.timestamps,[theta.data(:,1),lfpdown.data(:,1),gamma.data(:,1)]);
        %
        %         % Output file for Neuroscope
        %         j=1;
        %         for i=1:6
        %             out.data(:,j) = lfpdown.data(:,i);
        %             out.data(:,j+1) = gamma.data(:,i);
        %             out.data(:,j+2) = theta.data(:,i);
        %             j=j+3;
        %         end
        %
        %         out.data = out.data';
        %         filename = 'out.lfp';
        %         f = fopen(filename,'w');
        %         fwrite(f,out.data,'int16');
        %         fclose(f);
        
    end
    clear lfp;
    
    % End of each .int file
    fprintf(1, ['### Completed ' num2str(k) '/' num2str(filesNum)...
        ' ### elasped time = ' num2str(cputime - t_start) '\n']);
end
