function windowCleanup(constants, tInfo, expParams, input, sa)
rmpath(constants.lib_dir, constants.root_dir);
ListenChar(0);
% Screen('ColorRange', p.window, 255);
Priority(0);
constants.exp_end = GetSecs();
save([constants.fName,'constants.mat'],'constants');
save([constants.fName,'tInfo.mat'],'tInfo');
save([constants.fName,'expParams.mat'],'expParams');
save([constants.fName,'input.mat'],'input');
save([constants.fName,'sa.mat'],'sa');
sca; % alias for screen('CloseAll')
end
