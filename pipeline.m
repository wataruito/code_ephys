disp(['The working folder: ' pwd])
fileList = dir([pwd filesep '*.int']); % Get file list of *.int
[filesNum, ~] = size(fileList);

for k = 1:filesNum
    [~, fileNameNoExt, ~] = fileparts(fileList(k).name);
    [d1, ~] = size(dir([pwd filesep fileNameNoExt '*lfp.mat']));
    [d2, ~] = size(dir([pwd filesep fileNameNoExt '*gamma.mat']));
    [d3, ~] = size(dir([pwd filesep fileNameNoExt '*theta.mat']));
    [d4, ~] = size(dir([pwd filesep fileNameNoExt '*delta.mat']));
    
    d1 = d1 && d2 && d3 && d4;
    
    fprintf(1, ['### Start ' num2str(k) '/' num2str(filesNum) ' ###\n']);
    t_start = cputime;
    
    if d1 == 0
        
        
        [intFileNameExt,t,amps,data,aux] = ...
            readIntan([pwd filesep fileList(k).name]);
        
        % Create Bzcode lfp data stracture
        % filename = 'RIG01_171222_130723.int';
        %[intFileNameExt,t,amps,data,aux] = readIntan(filename);
        
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
        fields = {'amp','phase'};
        lfp = rmfield(lfp,fields);
        
        % Band pass at gamma, theta
        %        delta      [0 4]
        %        theta      [4 10]
        %        spindles   [10 20]
        %        gamma      [30 80]
        %        ripples    [100 250]
        disp('Bandpass for gamma');
        [ gamma ] = bz_FilterLFP(lfp,'passband','gamma');
        fields = {'amp','phase'};
        gamma = rmfield(gamma,fields);
        
        disp('Bandpass for theta');
        [ theta ] = bz_FilterLFP(lfp,'passband','theta');
        fields = {'amp','phase'};
        theta = rmfield(theta,fields);
        
        disp('Bandpass for delta');
        [ delta ] = bz_FilterLFP(lfp,'passband','delta');
        fields = {'amp','phase'};
        delta = rmfield(delta,fields);
        
        disp('Saving files');
        save([pwd filesep fileNameNoExt '_lfp'], 'lfp', '-v7.3');
        save([pwd filesep fileNameNoExt '_gamma'], 'gamma', '-v7.3');
        save([pwd filesep fileNameNoExt '_theta'], 'theta', '-v7.3');
        save([pwd filesep fileNameNoExt '_delta'], 'delta', '-v7.3');
        clear gamma theta delta;
        
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
    
    [d1, ~] = size(dir([pwd filesep fileNameNoExt '*specg.mat']));
    if d1 == 0
        if exist('lfp','var') == 0
            disp('Reading lfp files');
            load([pwd filesep fileNameNoExt '_lfp.mat']);
        end
        disp('Wavelet convolution');
        [specg] = wc(lfp);
        disp('Saving specg files');
        save([pwd filesep fileNameNoExt '_specg'], 'specg', '-v7.3');
        clear lfp specg;
    end
    fprintf(1, ['### Completed ' num2str(k) '/' num2str(filesNum)...
        ' ### elasped time = ' num2str(cputime - t_start) '\n']);
    
end








