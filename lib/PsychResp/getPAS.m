function [ response, rt, exitFlag ] = getPAS( window, keys, answer )
% getPAS: prompt and receive PAS response
response = {'NO RESPONSE'};
rt = NaN;
exitFlag = {'OK'};


KbQueueCreate(constants.device, keys);
KbQueueStart(constants.device);

Screen('Flip', window.pointer); % Display cue and prompt
for eye = 0:1
    Screen('SelectStereoDrawBuffer',window.pointer, eye);
    
    DrawFormattedText(window.pointer,'no image detected - 0',...
        'center', window.winRect(4)*.2);
    DrawFormattedText(window.pointer,'possibly saw, couldn''t name - 1',...
        'center', window.winRect(4)*.3);
    DrawFormattedText(window.pointer,'definitely saw, but unsure what it was (could possibly guess) - 2',...
        'center', window.winRect(4)*.4);
    DrawFormattedText(window.pointer,'definitely saw, could name - 3',...
        'center', window.winRect(4)*.5);
    
    DrawFormattedText(window.pointer, '[Press Enter to Continue]', ...
        'center', window.winRect(4)*.8);
end
tStart = Screen('Flip', window.pointer);

while 1
    [keys_pressed, press_times] = responseHandler(constants.device, answer);
    if ~isempty(keys_pressed)
        [response, rt, exitFlag] = ...
            wrapper_keyLogic(keys_pressed, press_times, tStart);
        break;
    end
end

KbQueueStop(constants.device);
KbQueueFlush(constants.device);
KbQueueRelease(constants.device);

end

