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
% Date last updated: 29 January, 2025.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [weightVector] = calculateWeight(fnInput)

    % Extract the input
    commit = fnInput.commit;
    iStates = fnInput.iStates;
    jStates = fnInput.jStates;
    epsilon = fnInput.epsilon;
    jthTrustVector = fnInput.jthTrustVector;
    predictionHorizon = fnInput.predictionHorizon;

    % Placeholder to store weight vector
    weightVector = zeros(predictionHorizon, 1);

    % Iterate through prediction horizon to compute the weight
    for t = 1:predictionHorizon
        stateDiff = norm(iStates(1,t) - (commit)*jStates(1,t));
        weightVector(t,1) = jthTrustVector(t,1)/(epsilon + stateDiff);
    end

    % Normalize the weight vector
    weightVector = weightVector/norm(weightVector, 1);

end