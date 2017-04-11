function sa = setupSAParams( debugLevel )

% Almost all of the following comes from Hsu and Chen (2009)

% defaults regardless of debug level
sa.params.quant = .9; % desired percentile of responses
sa.params.tau = 3000;
sa.params.x1 = -.5; % initial maximum transparency (scaled: actual alpha is exp(x1))
sa.params.ratio = 0.22; % ratio of mean to sd in weibull
sa.params.R = 500;  % location of weibull
sa.params.K = 1500; 
sa.params.beta = 0.3;

sa.params.delta = 5; % initial amount by which to change maximum transparency

sa.values.nShifts = NaN(100,1);
sa.values.Yn = NaN(100,1);

end
