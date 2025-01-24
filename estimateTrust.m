%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This code estimates the trust of a neighbor given its prediction data.
%
% Copyrights Authors: 1) Venkatraman Renganathan - Cranfield University, UK.
%                     2) Sabyasachi Mondal - Cranfield University, UK.
%
% Emails: v.renganathan@cranfield.ac.uk
%         sabyasachi.mondal@cranfield.ac.uk
%
% Date last updated: 23 January, 2025.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [trustVector] = estimateTrust(fnInput)

    % Extract all the input
    trustRadius = fnInput.trustRadius;
    discountFactor = fnInput.discountFactor;
    predictionHorizon = fnInput.predictionHorizon;
    jthFriendPrediction = fnInput.currentPrediction;
    jthFriendOldPrediction = fnInput.previousPrediction;

    % Place holder for trust vector
    trustVector = zeros(predictionHorizon-1, 1);

    % Iterate through prediction horizon except the last step
    for t = 2:predictionHorizon
        maxVal = jthFriendOldPrediction(1,t) + trustRadius;
        minVal = jthFriendOldPrediction(1,t) - trustRadius;
        if(jthFriendPrediction(1,t-1) <= maxVal && jthFriendPrediction(1,t-1) >= minVal)
            trustVector(t,1) = discountFactor^(t-1)*1;
        else
            trustVector(t,1) = 0;
        end

    end

end