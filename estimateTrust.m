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
% Date last updated: 29 January, 2025.
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
    trustVector = zeros(predictionHorizon, 1);

    % Iterate through prediction horizon except the last step
    % Check if old prediction at time t lies inside ball around current
    % prediction value at time t
    for t = 2:predictionHorizon
        maxVal = jthFriendPrediction(1,t-1) + trustRadius;
        minVal = jthFriendPrediction(1,t-1) - trustRadius;
        if(jthFriendOldPrediction(1,t) <= maxVal && jthFriendOldPrediction(1,t) >= minVal)
            trustVector(t-1,1) = discountFactor^(t-1)*1;
        else
            trustVector(t-1,1) = 0;
        end

    end
    % Use average of all trust for last time step
    trustVector(end,1) = mean(trustVector(1:predictionHorizon-1,1));

end