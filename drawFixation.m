function [  ] = drawFixation( window )

for eye = 0:1
    Screen('SelectStereoDrawBuffer',window.pointer,eye);
    Screen('FillRect',window.pointer,1,CenterRect([0 0 8 8],window.shifts));
end

end

