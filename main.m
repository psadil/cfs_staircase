function main(varargin)


%% collect input
% use the inputParser class to deal with arguments
ip = inputParser;
%#ok<*NVREPL> dont warn about addParamValue
addParamValue(ip,'subject', 0, @isnumeric);
addParamValue(ip,'dominantEye', 'Right', @(x) sum(strcmp(x, {'Left','Right'}))==1);
addParamValue(ip,'refreshRate', 120, @isnumeric);
addParamValue(ip,'debugLevel', 0, @(x) isnumeric(x) && x >= 0);
addParamValue(ip,'responder', 'user', @(x) sum(strcmp(x, {'user','simpleKeypressRobot'}))==1)
parse(ip,varargin{:});
input = ip.Results;


%% setup
PsychDefaultSetup(2);
[constants, input, exit_stat] = setupConstants(input, ip);
if exit_stat==1
    windowCleanup(constants);
    return
end
expParams = setupExpParams(input.refreshRate, input.debugLevel);
tInfo = setupTInfo(expParams, input.debugLevel);
sa = setupSAParams(input.debugLevel);

demographics = getDemographics(constants);

window = setupWindow(input, constants, expParams);

data = setupDataTable(expParams, input, demographics);
keys = setupKeys;
[mondrians, window] = makeMondrianTexes(window);

responseHandler = makeInputHandlerFcn(input.responder);
%% main experimental loop
try
    ListenChar(-1);
    HideCursor;
    giveInstruction(window, keys, responseHandler, constants);
    
    trial_SA = 1;
    for trial = 1:expParams.nTrials
        
        [data.transparency(trial), trial_SA] = wrapper_SA(data, trial, sa, trial_SA, expParams);
        [data.RoboRT(trial), data.meanRoboRT(trial)] = ...
            setupRobotResponses(data.transparency(trial),...
            sa, expParams, data.jitter(trial), data.tType{trial});
        
        % make texture for this trial (function is setup to hopefully handle
        % creation of many textures if graphics card could handle that
        stims = makeTexs(data.item(trial), window);
        
        % function that presents stim and collects response
        [data.response(trial), data.rt(trial),...
            data.tStart(trial), data.tEnd(trial),...
            tInfo.vbl(tInfo.trial==trial), tInfo.missed(tInfo.trial==trial),...
            data.exitFlag(trial)] = ...
            elicitBCFS(window, responseHandler,...
            stims.tex, data.eyes{trial},...
            keys, mondrians, expParams, constants, data.RoboRT(trial),...
            data.transparency(trial), data.jitter(trial));
        Screen('Close', stims.tex);
        % handle exitFlag, based on responses given
        switch data.exitFlag{trial}
            case 'ESCAPE'
                break;
            case 'CAUGHT'
                showPromptAndWaitForResp(window, 'Please only hit ENTER when an image is present!',...
                    keys, constants, responseHandler);
            case 'SPACE'
                if strcmp(data.tType{trial},'NULL')
                    showPromptAndWaitForResp(window, 'Correct! No object was going to appear.',...
                        keys, constants, responseHandler);
                elseif strcmp(data.tType{trial},'CFS')
                    showPromptAndWaitForResp(window, 'Incorrect! An object was appearing.',...
                        keys, constants, responseHandler);
                end
            case 'OK'
                if strcmp(data.response{trial},'Return')
                    [data.pas(trial),~,~] = getPAS(window, keys.pas, '2', constants, responseHandler);
                end
        end
        
        % show reminder on each block of trials. Breaks up the expt a bit
        if mod(trial,10)==0 && trial ~= expParams.nTrials
            showPromptAndWaitForResp(window, ['You have completed ', num2str(trial), ' out of ', num2str(expParams.nTrials), ' trials'],...
                keys, constants, responseHandler);
            showPromptAndWaitForResp(window, 'Remember to keep your eyes focusd on the center cross',...
                keys, constants, responseHandler);
        end
        
        % inter-trial-interval
        iti(window, expParams.iti);
    end
    
    %% save data and exit
    writetable(data, [constants.fName, '.csv']);
    
    % end of the experiment
    windowCleanup(constants, tInfo, expParams, input, sa);
    
catch
    psychrethrow(psychlasterror);
    windowCleanup(constants, tInfo, expParams, input, sa)
end

end

%%
function [] = giveInstruction(window, keys, responseHandler, constants)

showPromptAndWaitForResp(window, 'In this experiment, you will see hidden objects emerge from flashing squares',...
    keys,constants,responseHandler);
showPromptAndWaitForResp(window, ['When you are certain that an object has emerged, press the Enter key.\n',...
    'Please press the key as soon as you are certain that an object has appeared.\n',...
    'But, do NOT wait until you can identify the object.'],...
    keys,constants,responseHandler);
showPromptAndWaitForResp(window, ['After each trial, you will be asked about how well you could see the object.\n\n',...
    'no image detected - 0\n',...
    'possibly saw, couldn''t name - 1\n',...
    'definitely saw, but unsure what it was (could possibly guess) - 2\n',...
    'definitely saw, could name - 3\n',...
    '\nYou should wait until you can give a response of 2\n',...
    'but respond before you would give a response of 3\n', ...
    '\nUse the keypad to indicate your response\n'],...
    keys,constants,responseHandler);
showPromptAndWaitForResp(window, ['On some trials, there will be no object\n',...
    'If you think that there is no object, press SPACE'],...
    keys,constants,responseHandler);
showPromptAndWaitForResp(window, 'Finally, always keep your eyes focused on the center white cross',...
    keys,constants,responseHandler);

iti(window, 1);

end

%%
function iti(window, dur, varargin)

if nargin > 2
    vbl = varargin{1};
else
    vbl = Screen('Flip', window.pointer);
end

drawFixation(window);
vbl = Screen('Flip', window.pointer, vbl + window.ifi/2 );
WaitSecs(dur);
drawFixation(window);
Screen('Flip', window.pointer, vbl + window.ifi/2);

end

%%
function [] = showPromptAndWaitForResp(window, prompt, keys,constants,responseHandler, varargin)

if nargin > 5
    vbl = varargin{1};
else
    vbl = Screen('Flip', window.pointer);
end

for eye = 0:1
    Screen('SelectStereoDrawBuffer',window.pointer,eye);
    DrawFormattedText(window.pointer,prompt,...
        'center', 'center');
    DrawFormattedText(window.pointer, '[Press Enter to Continue]', ...
        'center', window.winRect(4)*.8);
end
Screen('DrawingFinished',window.pointer);
Screen('Flip', window.pointer, vbl + window.ifi/2 );
waitForEnter(keys,constants,responseHandler);

end

%%
function [exitFlag] = waitForEnter(keys,constants,responseHandler)

KbQueueCreate(constants.device, keys.enter);
KbQueueStart(constants.device);

while 1
    
    [keys_pressed, ~] = responseHandler(constants.device, '\ENTER');
    
    if ~isempty(keys_pressed)
        exitFlag = {'OK'};
        break;
    end
    
end

KbQueueStop(constants.device);
KbQueueFlush(constants.device);
KbQueueRelease(constants.device);
end

%%
function stims = makeTexs(item, window)
%genBlockTexs generates textures for 1 study/text cycle (block)

stims = struct('id', item);

% grab all images
[im, ~, alpha] = arrayfun(@(x) imread(fullfile(pwd,...
    'stims', 'expt', 'whole', ['object', num2str(x.id), '_noBkgrd']), 'png'), ...
    stims, 'UniformOutput', 0);
stims.image = cellfun(@(x, y) cat(3,x,y), im, alpha, 'UniformOutput', false);

% make textures of images
stims.tex = arrayfun(@(x) Screen('MakeTexture',window.pointer,x.image{:}), stims);

end

%% wrapper for SA algorithm
function [transparency, trial_SA] = wrapper_SA(data, trial, sa, trial_SA, expParams)

% This function helps implement two pieces of experimental logic.
% First, the transparency on null trials is automatically set to 0.
% Second, the overall data table is filtered so that we're only
% dealing with non-null trials. The SA algorithm doesn't need to
% see those trials for which participants weren't supposed to
% respond!

if strcmp(data.tType{trial},'NULL')
    transparency = 0;
elseif strcmp(data.tType{trial},'CFS')
    data_SA = data(~strcmp(data.tType,'NULL'),:);
    if trial_SA == 1
        transparency_log = sa.params.x1;
    else
        transparency_log = ...
            SA(log(data_SA.transparency(trial_SA-1)),...
            trial_SA, data_SA.rt(trial_SA-1), sa);
    end
    trial_SA = trial_SA + 1;
    % need to convert transparency scale
    transparency = exp(transparency_log);
    % but, we can't have transparency greater than 1
    transparency = min(1, transparency);
    % to keep the rate constant, we need to alter the resolution of
    % the value chosen
%     transparency = transparency + mod(1/expParams.mondrianHertz,transparency);
    % finally can't have value less than 1/mondrianHertz
    transparency = max(transparency, 1/expParams.mondrianHertz);
end

end

