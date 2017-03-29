function main(varargin)

% Screen('Preference', 'SkipSyncTests', 1);

%% collect input
% use the inputParser class to deal with arguments
ip = inputParser;
%#ok<*NVREPL> dont warn about addParamValue
addParamValue(ip,'subject', 0, @isnumeric);
addParamValue(ip,'dominantEye', 'Right', @(x) sum(strcmp(x, {'Left','Right'}))==1);
addParamValue(ip,'refreshRate', 120, @isnumeric);
addParamValue(ip,'debugLevel',0, @(x) isnumeric(x) && x >= 0);
addParamValue(ip,'responder', 'user', @(x) sum(strcmp(x, {'user','simpleKeypressRobot'}))==1)
parse(ip,varargin{:});
input = ip.Results;


%% setup
[constants, exit_stat] = setupConstants(input, ip);
if exit_stat==1
    windowCleanup(constants);
    return
end
expParams = setupExpParams(input.debugLevel);
stParams = setupStaircaseParams(input.debugLevel);

demographics = getDemographics(constants);

window = setupWindow(input, constants, expParams);

data = setupDataTable(expParams, input, demographics);
keys = setupKeys;
[mondrians, window] = makeMondrianTexes(window);
arrows = makeArrowTexes(window);

responseHandler = makeInputHandlerFcn(input.responder);


%% main experimental loop

giveInstruction(window, keys, responseHandler, constants);

for trial = 1:expParams.nTrials
    
    % function that presents arrow stim and collects response
    [ data.response(trial), data.rt(trial), data.tStart(trial), data.tEnd(trial), exit_flag] = ...
        elicitArrowResponse(window, responseHandler,...
        arrows(data.correctDirection(trial)).tex, data.rightEye(trial),...
        keys, mondrians, expParams, constants, answers{data.correctDirection(trial)},...
        data.bothEyes(trial));
    
    if exit_flag==1
        break;
    end
    
    if mod(trial,10)==0 && trial ~= expParams.nTrials
        showReminder(window, ['You have completed ', num2str(trial), ' out of ', num2str(expParams.nTrials), ' trials'],...
            keys, constants, responseHandler);
        
        showReminder(window, 'Remember to keep your eyes focusd on the center white square',...
            keys, constants, responseHandler);
    end
    
    % inter-trial-interval
    iti(window, expParams.iti);
    
    stParams = staircaseAlgorithm(data.rt, stParams);
    
end

%% save data and exit
writetable(data, [constants.fName, '.csv']);

% end of the experiment
windowCleanup(constants);
end

function [] = giveInstruction(window, keys, responseHandler, constants)

showReminder(window, 'Use the arrow keys to say which direction you think the arrow faced.',...
    keys,constants,responseHandler);
showReminder(window, 'Keep your eyes focused on the center white square',...
    keys,constants,responseHandler);

iti(window, 1);

end

function iti(window, dur)

drawFixation(window);
Screen('Flip', window.pointer);
WaitSecs(dur);
drawFixation(window);
Screen('Flip', window.pointer);

end

function [] = showReminder(window, prompt, keys,constants,responseHandler)

for eye = 0:1
    Screen('SelectStereoDrawBuffer',window.pointer,eye);
    DrawFormattedText(window.pointer,prompt,...
        'center', 'center');
    DrawFormattedText(window.pointer, '[Press Enter to Continue]', ...
        'center', window.winRect(4)*.8);
end
Screen('Flip', window.pointer);
waitForEnter(keys,constants,responseHandler);

end

function [] = waitForEnter(keys,constants,responseHandler)

KbQueueCreate(constants.device, keys.enter);
KbQueueStart(constants.device);

while 1
    
    [keys_pressed, ~] = responseHandler(constants.device, '\ENTER');
    
    if ~isempty(keys_pressed)
        break;
    end
end

KbQueueStop(constants.device);
KbQueueFlush(constants.device);
KbQueueRelease(constants.device);
end

