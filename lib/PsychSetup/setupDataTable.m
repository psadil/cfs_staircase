function [ data ] = setupDataTable( expParams, input, demographics )
%setupDataTable setup data table for this participant. 

rng('shuffle');
scurr = rng; % set up and seed the randon number generator

data = table;
data.subject = repelem(input.subject, expParams.nTrials)';
data.seed = repelem(scurr.Seed, expParams.nTrials)';
data.dominantEye = repelem({input.dominantEye}, expParams.nTrials)';
data.sex = repelem(demographics(1), expParams.nTrials)';
data.ethnicity = repelem(demographics(2), expParams.nTrials)';
data.race = repelem(demographics(3), expParams.nTrials)';
data.trial = (1:expParams.nTrials)';
data.item = randi(expParams.nTrials,[expParams.nTrials,1]);
data.block = repelem(1:10, expParams.nTrials/10)';
data.tStart = NaN(expParams.nTrials,1);
data.tEnd = NaN(expParams.nTrials,1);

% trial type key:
% 0 => Catch trial (no stimulus)
% 1 => CFS (present image only to non-dominant eye)
data.tType = Shuffle([repelem({'CFS'},expParams.nTrials*(1/5)),...
    repelem({'NULL'},expParams.nTrials*(1/5))])';

data.eyes = repelem({[1,0]},expParams.nTrials);

% arrow points right and left on half of all trials each
data.response = cell(expParams.nTrials,1);
data.rt = NaN(expParams.nTrials,1);

end

