[sample_n, sweep_n] = size(LTP);

% downsampling from 25kHz to 5kHz
sample_n_5kHz = (sample_n - rem(sample_n, 5))/5;
atf_5kHz = zeros(sample_n_5kHz, sweep_n);

for sample = 1:sample_n_5kHz
  atf_5kHz(sample,:) = mean(LTP((sample*5-4):sample*5,:));
end

% averaging 10 sweeps
sweep_n_10 = (sweep_n - rem(sweep_n, 10))/10;
atf_5kHz_10 = zeros(sample_n_5kHz, sweep_n_10);

for sweep = 1:sweep_n_10
      atf_5kHz_10(:, sweep) = mean(atf_5kHz(:,(sweep*10-9):sweep*10),2);
end

save 5kHz_10sweep.atf atf_5kHz_10 -tabs -ascii
save 5kHz.atf atf_5kHz -tabs -ascii








