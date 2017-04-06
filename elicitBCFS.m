function [ response, rt, tStart, vbl, exitFlag ] = elicitBCFS( window, responseHandler,...
    tex, eyes, keys, mondrians, expParams, constants, roboRT, maxAlpha, jitter )
%collectResponses Show arrow until participant makes response, and collect
%that response
response = {'NO RESPONSE'};
rt = NaN;
exitFlag = {'OK'};

% transparency of texture increases at constant rate, up to a given trial's
% maximum value
alpha.tex = [repelem(0,jitter), linspace(0,maxAlpha,(maxAlpha*10)+1)];
% transparency of mondrians is typically locked at 1
alpha.mondrian = [repelem(1,jitter), expParams.alpha.mondrian];
% both transparencies needed to have additional jitter added to beginning

% prompt = 'Use the arrow keys to say which direction you think the arrow faced.';
prompt = [];
slack = .5;
goRobo = 0;

% KbQueueCreate(constants.device, keys.arrows+keys.escape);
KbQueueCreate(constants.device, keys.enter+keys.escape);

drawFixation(window);
Screen('PreloadTextures',window.pointer,tex);
vbl = Screen('Flip', window.pointer); % Display cue and prompt
for tick = 0:expParams.nTicks-1
    
    % for each tick, pick out one of the mondrians to draw
    drawStimulus(window, prompt, eyes,...
        tex, mondrians(mod(tick,size(mondrians,2))+1).tex, ...
        alpha.mondrian(mod(tick, size(expParams.alpha.mondrian,2))+1), ...
        alpha.tex(min(length(alpha.tex), tick+1)));
    
    % flip only in sync with mondrian presentation rate
    vbl = Screen('Flip', window.pointer, vbl + (expParams.mondrianHertz-slack)*window.ifi );
    if tick == 0
        tStart = vbl;
        KbQueueStart(constants.device);
    elseif tick >= roboRT
        goRobo = 1;
    end
    
    [keys_pressed, press_times] = responseHandler(constants.device, '\ENTER', goRobo);
    if ~isempty(keys_pressed)
        [response, rt, exitFlag] = ...
            wrapper_keyLogic(keys_pressed, press_times, tStart);
        break;
    end
end

KbQueueStop(constants.device);
KbQueueFlush(constants.device);
KbQueueRelease(constants.device);

if ~strcmp(response,'NO RESPONSE') && ...
        ((alpha.tex(min(length(alpha.tex), tick+1)) == 0) || (max(alpha.tex)==0))
    exitFlag = {'CAUGHT'};
end

end

function drawStimulus(window, prompt, eyes, imageTex, mondrianTex, alpha_mondrian, alpha_tex)

for eye = 1:2
    Screen('SelectStereoDrawBuffer',window.pointer,eye-1);
    
    % draw Mondrians
    Screen('DrawTexture', window.pointer, mondrianTex,[],[],[],[],alpha_mondrian);
    
    if eyes(eye)
%         Screen('DrawTexture', window.pointer, imageTex,[],[],[],alpha_tex);
        Screen('DrawTexture', window.pointer, imageTex,[],window.imagePlace,[],[],alpha_tex);
    end
    
    % small white fixation square
    Screen('FillRect',window.pointer,1,CenterRect([0 0 8 8],window.shifts));
    
    % prompt participant to respond
    DrawFormattedText(window.pointer, prompt, 'center');
end
Screen('DrawingFinished',window.pointer);

end
