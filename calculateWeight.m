%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This code calculates the weight for a neighbor given its prediction data.
%
% Copyrights Authors: 1) Venkatraman Renganathan - Cranfield University, UK.
%                     2) Sabyasachi Mondal - Cranfield University, UK.
%
% Emails: v.renganathan@cranfield.ac.uk
%         sabyasachi.mondal@cranfield.ac.uk
%
% Date last updated: 24 January, 2025.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [weightVector] = calculateWeight(fnInput)

    % Extract the input
    jthTrustVector = fnInput.jthTrustVector;
    predictionHorizon = fnInput.predictionHorizon;
    jStates = fnInput.jStates;
    iStates = fnInput.iStates;
    epsilon = fnInput.epsilon;

    % Placeholder to store weight vector
    weightVector = zeros(predictionHorizon, 1);

    % Iterate through prediction horizon to compute the weight
    for t = 1:predictionHorizon
        stateDiff = norm(iStates(1,t) - jStates(1,t));
        newStateDiff = epsilon + stateDiff;
        weightVector(t,1) = jthTrustVector(t,1)/newStateDiff;
    end

end