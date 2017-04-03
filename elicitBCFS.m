function [ response, rt, tStart, vbl, exitFlag ] = elicitBCFS( window, responseHandler,...
    tex, eyes, keys, mondrians, expParams, constants, answer, maxAlpha )
%collectResponses Show arrow until participant makes response, and collect
%that response
response = {'NO RESPONSE'};
rt = NaN;
exitFlag = {'OK'};

alpha.tex = linspace(0,maxAlpha,maxAlpha);

% prompt = 'Use the arrow keys to say which direction you think the arrow faced.';
prompt = [];
slack = .5;

% KbQueueCreate(constants.device, keys.arrows+keys.escape);
KbQueueCreate(constants.device, keys.arrows+keys.escape);

drawFixation(window);
vbl = Screen('Flip', window.pointer); % Display cue and prompt
for tick = 0:expParams.nTicks-1
    
    % for each tick, pick out one of the mondrians to draw
    drawStimulus(window, prompt, eyes,...
        tex, mondrians(mod(tick,size(mondrians,2))+1).tex, ...
        expParams.alpha.mondrian(mod(tick, size(expParams.alpha.mondrian,2))+1), ...
        alpha.tex(min(length(alpha.tex), tick+1)));
    
    % flip only in synch with mondrian presentation rate
    vbl = Screen('Flip', window.pointer, vbl + (expParams.mondrianHertz-slack)*window.ifi );
    if tick == 0
        tStart = vbl;
        KbQueueStart(constants.device);
    end
    
    if tick >= expParams.respDelay
        [keys_pressed, press_times] = responseHandler(constants.device, answer);
        
        if ~isempty(keys_pressed)
            [response, rt, exitFlag] = ...
                wrapper_keyLogic(keys_pressed, press_times, tStart);
            break;
        end
    end
    
end

KbQueueStop(constants.device);
KbQueueFlush(constants.device);
KbQueueRelease(constants.device);

if ~stcmp(response,'NO RESPONSE') && ...
        ((alpha.tex(min(length(alpha.tex), tick+1)) == 0) || (max(alpha.tex)==0))
    exitFlag = {'CAUGHT'};
end


end

function drawStimulus(window, prompt, eyes, arrowTex, mondrianTex, alpha_mondrian, alpha_arrow)

for eye = 1:2
    Screen('SelectStereoDrawBuffer',window.pointer,eye-1);
    
    % draw Mondrians
    Screen('DrawTexture', window.pointer, mondrianTex,[],[],[],[],alpha_mondrian);
    
    if eyes(eye)
        % draw arrow
        Screen('DrawTexture', window.pointer, arrowTex,[],[],[],[],alpha_arrow);
    end
    
    Screen('FillRect',window.pointer,1,CenterRect([0 0 8 8],window.shifts));
    
    % prompt participant to respond
    DrawFormattedText(window.pointer, prompt, 'center');
end
Screen('DrawingFinished',window.pointer);

end


function [response, rt, exitFlag] = ...
    wrapper_keyLogic(keys_pressed, press_times, tStart)
% There should ideally be only one, keypress ever. If there happens
% to be more than one keypress, only take the first one.
% Add the direction just pressed to the input
% string, and record the timestamp of its keypress.
% For arrow response, this will produce either 'left' or 'right'

if any(keys_pressed == 102)
    key = 39; %RightArrow
    rt = press_times(102) - tStart;
elseif any(keys_pressed == 100)
    key = 37; %LeftArrow
    rt = press_times(100) - tStart;
else
    key = keys_pressed(1);
end
response = {KbName(key)};
if any(keys_pressed==KbName('ESCAPE'))
    exitFlag = {'ESCAPE'};
end
end

