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
    jthTrustVector = fnInput.jthTrustVector;
    predictionHorizon = fnInput.predictionHorizon;

    % Placeholder to store weight vector
    weightVector = zeros(predictionHorizon, 1);

    % Iterate through prediction horizon to compute the weight
    for t = 1:predictionHorizon
        weightVector(t,1) = commit*jthTrustVector(t,1);
    end

    % Normalize the weight vector
    weightVector = weightVector/norm(weightVector, 1);

end