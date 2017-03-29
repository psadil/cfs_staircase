function arrows = makeArrowTexes(window, expParams)
% draw arrow to offScreenWindow so that it can be used as regular texture.
% Return those textures. Arrow texture direction and sizes are hard coded.


% amount by which the arrow tips will be offset
offset = 10;

fromH = window.yCenter;
toH = window.yCenter;
penWidth = 5;
rampRate = .1; % how often (in s) should the ramp increase

arrows(1:2) = struct('tex',NaN([window.res.width, window.res.height]));
for tex = 1:2
    
    if tex == 1 % right-facing
        fromV = window.width/3;
        toV = 2*(window.width/3);
    else % left-facing
        fromV = 2*(window.width/3);
        toV = window.width/3;
    end
        
    % starting from background color (gray), decrease every rampRate down
    % to 0
    intensityArrow = linspace(window.bgColor, 0, expParams.arrowDur/rampRate);
    % starting from background color (gray), increase every rampRate up
    % to 1
    intensityBG = linspace(window.bgColor, 1, expParams.arrowDur/rampRate);
    for i = 1:expParams.arrowDur/rampRate
        arrows(tex).tex = Screen('OpenOffScreenWindow', window.screenNumber, ...
            intensityBG(i));
 
        % horizontal part
        Screen('DrawLine', arrows(tex).tex, intensityArrow(i),...
            fromH, fromV, ...
            toH, toV, penWidth);
        
        % upper head
        Screen('DrawLine', arrows(tex).tex, intensityArrow(i), ...
            toH + offset, toV - offset, ...
            toH, toV, penWidth);
        
        % lower head
        Screen('DrawLine', arrows(tex).tex, intensityArrow(i), ...
            toH + offset, toV + offset, ...
            toH, toV, penWidth);
    end
end

end
