function arrows = makeArrowTexes(window)
% draw arrow to offScreenWindow so that it can be used as regular texture.
% Return those textures. Arrow texture direction and sizes are hard coded.


% amount by which the arrow tips will be offset
offset_tip = 10;
offset_inner = 100;
window.shifts([1,3]) = window.shifts([1,3]) + [offset_inner, - offset_inner];


fromY = window.yCenter;
toY = window.yCenter;
penWidth = 10;

arrows(1:2) = struct('tex',NaN([window.res.width, window.res.height]));
for tex = 1:2
    
    if tex == 1 % right-facing
        fromX = window.shifts(1);
        toX = window.shifts(3);
        tipTopX = toX - offset_tip;
    else % left-facing
        fromX = window.shifts(3);
        toX = window.shifts(1);
        tipTopX = toX + offset_tip;
    end
    
    
    arrows(tex).tex = Screen('OpenOffScreenWindow', window.screenNumber, ...
        window.bgColor);
    
    % horizontal part
    Screen('DrawLine', arrows(tex).tex, BlackIndex(window.screenNumber),...
        fromX, fromY, ...
        toX, toY, penWidth);
    
    % upper head
    Screen('DrawLine', arrows(tex).tex, BlackIndex(window.screenNumber), ...
        tipTopX, toY - offset_tip, ...
        toX, toY, penWidth);
    
    % lower head
    Screen('DrawLine', arrows(tex).tex, BlackIndex(window.screenNumber), ...
        tipTopX, toY + offset_tip, ...
        toX, toY, penWidth);
end

end
