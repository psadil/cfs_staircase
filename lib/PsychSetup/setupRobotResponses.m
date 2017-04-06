function roboRT = setupRobotResponses(transparency, debugLevel, sa, expParams, jitter, tType )
%setupRobotResponses Summary of this function goes here
% NOTE: best resolution of roboResps will be in mondrianHertz.


switch debugLevel
    case 0
        roboRT = 0;
    otherwise
        switch tType
            case 'NULL'
                roboRT = 0;
            case 'CFS'
                meanRT = getMeanRT(transparency, sa.params.R, sa.params.K, sa.params.beta);
                wblParams = weibullParams(meanRT, 1);
                
                % sample a value for the robot
                roboRT_raw = wblrnd(wblParams.scale, wblParams.shape) + sa.params.R;
                roboRT = (roboRT_raw/(expParams.mondrianHertz^-1 * 120)) + jitter;
 
        end
end
end

function params = weibullParams(mu, sd)

params.shape = (sd/mu) ^ 1.086;
params.scale = mu/(gamma(1+(1/params.shape)));

end

function meanRT = getMeanRT(intensity, R, K, beta)

meanRT = R + K*(exp(intensity)^-beta);

end
