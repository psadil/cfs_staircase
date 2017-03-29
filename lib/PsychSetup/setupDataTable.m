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
data.tStart = NaN(expParams.nTrials,1);
data.tEnd = NaN(expParams.nTrials,1);

data.trialCode = Shuffle(repelem(1:5,expParams.nTrials/5))';

% arrow points left(1) and right(2) on half of all trials each
data.correctDirection = (data.trialCode==1 | data.trialCode==2)+1;

% Half of trials present arrow to left(0), half to right(1) eye
data.rightEye = (data.trialCode==3 | data.trialCode==4);

% on one third of trials, draw to both eyes
data.bothEyes = (data.trialCode==5);

% arrow points right and left on half of all trials each
data.response = cell(expParams.nTrials,1);
data.rt = NaN(expParams.nTrials,1);

end

