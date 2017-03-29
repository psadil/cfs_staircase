function [ keys ] = setupKeys(  )
%setupKeys setup different kinds of useful key patterns


codes = zeros(1,256);

keys.arrows = codes;
keys.arrows(KbName({'4','6'})) = 1;
keys.escape = codes;
keys.escape(KbName('ESCAPE')) = 1;
keys.enter = codes;
keys.enter(KbName({'Return'})) = 1;

end

