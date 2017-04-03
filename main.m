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

for trial = 1:expParams.nTrials
    
    if trial > 1
       data.transparency(trial) = saParams.x1;
    else
       data.transparency(trial) = ...
          SA(data.transparency(trial-1), trial, data.rt(trial-1), sa); 
    end
    
    stims = makeBlockTexs(data, mod(trial,10)+1, window);
    
    % function that presents arrow stim and collects response
    [ data.response(trial), data.rt(trial), data.tStart(trial), data.tEnd(trial), exit_flag] = ...
        elicitBCFS(window, responseHandler,...
        stims(trial).tex, data.rightEye(trial),...
        keys, mondrians, expParams, constants, roboResps.latencies(trial),...
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

function stims = makeBlockTexs(data, block, window)
%genBlockTexs generates textures for 1 study/text cycle (block)

stimTab = data(data.block == block,:);
    
stims = struct('id', stimTab.item);

% grab all images
[im, ~, alpha] = arrayfun(@(x) imread(fullfile(pwd,...
    'stims', 'expt', 'whole', ['object', num2str(x.name), '_noBkgrd'], 'png')), ...
    stims, 'UniformOutput', 0);
stim_wAlpha = cellfun(@(x, n) cat(3,x,x,x,n), im, alpha, 'UniformOutput', 0);

% make textures of images
cellTestAp1 = num2cell(cellfun(@(x) Screen('MakeTexture',window.pointer,x), stim_wAlpha));

% name textures of each stim
[stims(1:size(stims,1)).image] = deal(cellTestAp1{:});

stims(slide).tex = arrayfun(@(x) ...
    drawToOffScreenWindow(x.image,window), stims, 'UniformOutput', false);
    

    function tex = drawToOffScreenWindow(image, window)
        
        tex = Screen('OpenOffScreenWindow', window.screenNumber, window.bgColor);
        
        % final bracket could include alpha
        Screen('MakeTexture',window.pointer,image,[],[],[],[],[]);
        Screen('DrawTexture',window.pointer,image,[],[],[],[],[]);
    end

end
