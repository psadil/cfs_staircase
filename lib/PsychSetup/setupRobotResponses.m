function roboResps = setupRobotResponses( debugLevel, expParams )
%setupRobotResponses Summary of this function goes here

switch debugLevel
    
    case 1
    roboResps.latencies = repelem(3, expParams.nTrials);
end


end

