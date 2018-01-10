function [specg] = wc(lfp)
% perform wavelet-convolution by fieldtrip
% import lfpdown into fieldtrip format
data = [];
data.time = {lfp.timestamps'};
data.label{1,1} = '1';
data.label{2,1} = '2';
data.label{3,1} = '3';
data.label{4,1} = '4';
data.label{5,1} = '5';
data.label{6,1} = '6';
data.fsample = 1250;
data.trial = {lfp.data'};
data.sampleinfo = [1,size(lfp.data,1)];

% create cgf for wavelet-convolution
cfg = [];
% cfg.channel = '1';
cfg.method     = 'wavelet';
cfg.width      = 3;
cfg.output     = 'pow';
cfg.foi        = 1:0.2:20;
cfg.toi        = 0.0:0.008:3600.0;
% execute
specg = ft_freqanalysis(cfg, data);

% % plot
% cfg = [];
% % cfg.baseline     = [-0.5 -0.1];
% % cfg.baselinetype = 'absolute';  
% % cfg.maskstyle    = 'saturation';	
% % cfg.zlim         = [0 2e6];	
% % cfg.xlim = [880,960];
% cfg.colormap ='jet';
% cfg.channel      = '1';
% figure;
% ft_singleplotTFR(cfg, TFRwave);
% 
% colormapeditor;
% 
end


