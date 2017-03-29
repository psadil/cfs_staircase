function stParams = setupStaircaseParams( debugLevel )

% defaults regardless of debug level
stParams.crit = 3; % Desired level of accuracy
stParams.N_width = 10; % Width of interval for moving average
stParams.N_int = 8; % Number of intervals to assess
stParams.interval = zeros( 1, stParams.N_width );
stParams.count = 1; % Initialize count variable
stParams.inc = 1;

% Define window within which no changes should occur
% Need to define mode! or, median?!
stParams.stable_win =...
    icdf('InverseGaussian', [.6,.75], stParams.crit, 1);

% Size of change to log of target alpha during each interval
stParams.x_change = linspace( .5, .1, stParams.N_width );

% Initial starting value for target alpha
stParams.x_cur = .8;


end
