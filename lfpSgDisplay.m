% lfpSgDisplay.m
%   To display spectrogram with LFP
%   specify channels to be displayed
%       ch = [...];

ch = [1];
cfs = squeeze(specg.powspctrm(1,:,:));
t = squeeze(specg.time(1,:));
t1 = lfp.timestamps';
pfreq = squeeze(specg.freq(1,:));
data=lfp.data(:,1);
data1=theta.data(:,1);

tw_max = size(cfs,2);
tw_step = 2500;                % duration 20s
tw_start = 1;
tw_end = tw_start + tw_step - 1;

sample_size = size(ch,2);

figure;
colormap 'jet';
colormapeditor;
while 1
    for i = 1:sample_size
        channel_n = ch(i);
        
        subplot(sample_size*3,1,i*3-2);

%         cfg = [];
%         % cfg.baseline     = [-0.5 -0.1];
%         % cfg.baselinetype = 'absolute';
%         % cfg.maskstyle    = 'saturation';
%         % cfg.zlim         = [0 2e6];
%         cfg.xlim = [t(tw_start),t(tw_end)];
%         cfg.colormap ='jet';
%         cfg.channel      = '1';
%         cfg.colorbar = 'no';
%         ft_singleplotTFR(cfg, TFRwave);
         
        imagesc(t(tw_start:tw_end),pfreq,cfs(:,tw_start:tw_end,channel_n)); axis xy;
         %       imagesc(t(tw_start:tw_end),pfreq,abs(cfs(:,tw_start:tw_end,channel_n)).^2); axis xy;
        %colorbar; title('Spectrogram');
        % contourf(t(tw_start:tw_end),pfreq,abs(cfs(:,tw_start:tw_end,channel_n)).^2); axis xy;
        
        subplot(sample_size*3,1,i*3-1);
        plot(t1(tw_start*10:tw_end*10),data(tw_start*10:tw_end*10,channel_n));
        subplot(sample_size*3,1,i*3);
        plot(t1(tw_start*10:tw_end*10),data1(tw_start*10:tw_end*10,channel_n));
        
    end
    
    prompt = 'Left or Right? ';
    x = input(prompt,'s');
    if x == 'r'
        if tw_end + tw_step < tw_max
            tw_start = tw_start + tw_step;
            tw_end = tw_start + tw_step;
        end
    elseif x == 'l'
        if tw_start - tw_step >= 0
            tw_start = tw_start - tw_step;
            tw_end = tw_start + tw_step;
        end
    elseif x == 'E'
        break;
    end
end

