function windowCleanup(constants)
rmpath(constants.lib_dir,constants.root_dir);
ListenChar(0);
% Screen('ColorRange', p.window, 255);
Priority(0);
constants.exp_end = GetSecs();
save(constants.fName,'constants');
sca; % alias for screen('CloseAll')
end
