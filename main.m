function main(varargin)


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
sa = setupSAParams(input.debugLevel);

demographics = getDemographics(constants);

window = setupWindow(input, constants, expParams);

data = setupDataTable(expParams, input, demographics);
keys = setupKeys;
[mondrians, window] = makeMondrianTexes(window);

responseHandler = makeInputHandlerFcn(input.responder);

roboResps = setupRobotResponses(input.debugLevel, expParams);
%% main experimental loop

giveInstruction(window, keys, responseHandler, constants);

trial_SA = 1;
for trial = 1:expParams.nTrials
    
    data.transparency(trial) = wrapper_SA(data, trial, sa);
    
    % make texture for this trial (function is setup to hopefully handle
    % creation of many textures if graphics card could handle that
    stims = makeTexs(data, trial, data.transparency(trial), window);
    
    % function that presents arrow stim and collects response
    [ data.response(trial), data.rt(trial), data.tStart(trial), data.tEnd(trial), exitFlag] = ...
        elicitBCFS(window, responseHandler,...
        stims.tex, data.eyes(trial),...
        keys, mondrians, expParams, constants, roboResps.latencies(trial),...
        data.transparency(trial));
    
    switch exitFlag
        case 'ESCAPE'
            break;
        case 'CAUGHT'
            showReminder(window, 'Please, only respond when an image is present!',...
                keys, constants, responseHandler);
    end
    
    % get PAS response
    data.pas(trial) = getPAS();
    
    % show reminder on each block of trials. Breaks up the expt a bit
    if mod(trial,10)==0 && trial ~= expParams.nTrials
        showReminder(window, ['You have completed ', num2str(trial), ' out of ', num2str(expParams.nTrials), ' trials'],...
            keys, constants, responseHandler);
        
        showReminder(window, 'Remember to keep your eyes focusd on the center white square',...
            keys, constants, responseHandler);
    end
    
    % inter-trial-interval
    iti(window, expParams.iti);
    
end

%% save data and exit
writetable(data, [constants.fName, '.csv']);

% end of the experiment
windowCleanup(constants);

%% wrapper for SA algorithm
    function transparency = wrapper_SA(data, trial, sa)
        
        % This function helps implement two pieces of experimental logic.
        % First, the transparency on null trials is automatically set to 0.
        % Second, the overall data table is filtered so that we're only
        % dealing with non-null trials. The SA algorithm doesn't need to
        % see those trials for which participants weren't supposed to
        % respond!
        
        if strcmp(data.tType,'NULL')
            data.transparency(trial) = 0;
        elseif strcmp(data.tType,'CFS')
            data_SA = data(~strcmp(data.tType,'NULL'),:);
            if trial_SA == 1
                transparency = sa.params.x1;
            else
                transparency = ...
                    SA(data_SA.transparency(trial_SA-1),...
                    trial_SA, data_SA.rt(trial_SA-1), sa);
            end
            trial_SA = trial_SA + 1;
        end
    end

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

function stims = makeTexs(data, whichItems, window)
%genBlockTexs generates textures for 1 study/text cycle (block)

stimTab = data(whichItems,:);

stims = struct('id', stimTab.item);

% grab all images
[im, ~, alpha] = arrayfun(@(x) imread(fullfile(pwd,...
    'stims', 'expt', 'whole', ['object', num2str(x.name), '_noBkgrd'], 'png')), ...
    stims, 'UniformOutput', 0);
stims.image = cellfun(@(x, n) cat(3,x,x,x,n), im, alpha, 'UniformOutput', 0);

stims.tex = arrayfun(@(x) ...
    drawToOffScreenWindow(x.image,window,slideAlpha), stims, 'UniformOutput', false);

    function tex = drawToOffScreenWindow(image, window)
        
        tex = Screen('OpenOffScreenWindow', window.screenNumber, window.bgColor);
        
        Screen('MakeTexture',tex,image);
        Screen('DrawTexture',tex,image);
    end
end


