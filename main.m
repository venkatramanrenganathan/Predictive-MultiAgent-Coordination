%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This code simulates Anticipatory Distributed Coordination (ADC) algorithm 
% for multi-agent systems.
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

% Make a fresh start
clear; close all; clc;

% set properties for plotting
set(groot,'defaultAxesTickLabelInterpreter','latex');  
set(groot,'defaulttextinterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');
addpath(genpath('src'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up Network Data for Simulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Network Parameters
numSteps = 500; % Number of time steps
numAgents = 20; % Number of agents

% ADC protocol parameters
epsilon = 1e-3; % Constant for numerical stability in weights calculation
trustRadius = 0.75; % Trust Radius for Coordination
discountFactor = 0.80; % Discount Factor for Trust Estimation
predictionHorizon = 20; % Prediction Horizon

% Flag deciding whether to generate new data or load existing data
% dataPrepFlag = 1: Generates new network data
% dataPrepFlag = 0: Loads existing network data
dataPrepFlag = 0;

% When dataPrepFlag = 1: Generate new data for network
if(dataPrepFlag)
    
    disp('Generating new network structure');
    % Generate a connected random graph with a spanning tree
    graphOutput = generateGraph(numAgents);
    
    % Extract the graph output
    x0 = graphOutput.x0;
    G = graphOutput.graph;    
    adjMatrix = graphOutput.adjMatrix;
    degMatrix = graphOutput.degMatrix;
    simpleWeights = graphOutput.simpleWeights;
    
    % Save the generated network data into mat file.
    disp('Saving the generated network data');
    save('networkData.mat');
else
    disp('Loading existing data for network');
    load('networkData.mat');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simulate the Network
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Placeholder to store the data for all nodes
x = zeros(numAgents, numSteps);

% Initialize random data for all nodes across the prediction horizon
x(:,1) = x0;

% Update using simple weights till prediction horizon to build data
for k = 2:predictionHorizon-1
    % Update neighbors with initial weights
    x(:, k) = simpleWeights * x(:, k-1); 
end

disp('Starting ADC Protocol Iteration');

% ADC Protocol Iteration
for k = 2:numSteps-1
    
    % Iterate through all agents
    for i = 1:numAgents

        % % Make an agent malicious
        % maliciousIndex = 5;
        % 
        % if(i == maliciousIndex)
        %     x(i, k+1:k+1+predictionHorizon-1) = randn*x(i, k:k+predictionHorizon-1);
        %     break;
        % end

        % Identify neighbors of agent i
        iNeighbors = find(adjMatrix(i, :) > 0);

        % Count the number of agent i
        iNeighborsCount = size(iNeighbors, 2);

        % Extract state values of agent i
        iStates = x(i,:);

        % Extract agent i's prediction from time k
        iPredictedStates = x(i, k:k+predictionHorizon-1);

        % Extract state values of neighbors of agent i
        iNeighborsStates = x(iNeighbors, :);

        % Extract prediction data out of data for neighbors of agent i
        iNeighborsPredictions = iNeighborsStates(:, k:k+predictionHorizon-1);

        % % Extract old prediction data out of data for neighbors of agent i
        iNeighborsOldPredictions = iNeighborsStates(:, k-1:k-1+predictionHorizon-1);

        % Placeholder to store commitment factor of neighbors
        iNeighborsCommitments = zeros(iNeighborsCount, numSteps);

        % Placeholder to store ADC protocol weights of all neighbors 
        adcProtocolWeights = zeros(predictionHorizon, iNeighborsCount);

        % Placeholder to store neighbors contribution via ADC protocol
        neighborsContribution = zeros(predictionHorizon, iNeighborsCount);
    
        % Iterate through all neighbors of agent i
        for j = 1:iNeighborsCount

            % Get prediction data of neighbor j of agent i at time k
            jthFriendPrediction = iNeighborsPredictions(j, :);

            % Get old prediction data of neighbor j at time k-1
            jthFriendOldPrediction = iNeighborsOldPredictions(j, :);

            % Prepare a struct input for trust estimation
            trustEstimationInput.trustRadius = trustRadius;
            trustEstimationInput.discountFactor = discountFactor;
            trustEstimationInput.predictionHorizon = predictionHorizon;
            trustEstimationInput.currentPrediction = jthFriendPrediction;
            trustEstimationInput.previousPrediction = jthFriendOldPrediction;

            % Estimate trust of jth neighbor at time k via their prediction
            jthTrustVector = estimateTrust(trustEstimationInput);

            % Store average trust of jth neighbor for commitment calculation
            iNeighborsCommitments(j,k) = mean(jthTrustVector); 
            iNeighborsCommitments(j,k) = sum(iNeighborsCommitments(j,1:k),2)/k;
            
            % Prepare a struct input for weight calculation
            weightCalculationInput.commit = iNeighborsCommitments(j,k);
            weightCalculationInput.epsilon = epsilon;
            weightCalculationInput.iStates = iPredictedStates;
            weightCalculationInput.jStates = jthFriendPrediction;
            weightCalculationInput.jthTrustVector = jthTrustVector;
            weightCalculationInput.predictionHorizon = predictionHorizon;
            
            % Calculate the weight to be associated for jth neighbor
            adcProtocolWeights(:,j) = calculateWeight(weightCalculationInput);

            % Form the committed states of jth neighbof agent i
            % jthFriendCommittedStates = iNeighborsCommitments(j,k) * jthFriendPrediction;
            jthFriendCommittedStates = jthFriendPrediction;

            % Form difference of opinion of agent i w.r.t neighbor j
            jthFriendOpinionDifference = jthFriendCommittedStates' - iPredictedStates';

            % Compute jth neighbor's contribution for agent i's update
            neighborsContribution(:,j) = adcProtocolWeights(:,j).*jthFriendOpinionDifference;

        end
        
            % Update neighbors with ADC Protocol Update rule
            x(i, k+1:k+1+predictionHorizon-1) = x(i, k:k+predictionHorizon-1) + sum(neighborsContribution, 2)'; 

    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plotting the network and the states
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Plotting results');

% Plot the network structure
figure1 = figure('Color',[1 1 1]);
plot(G, 'Layout', 'force');
title('Network Structure');
a = findobj(gcf, 'type', 'axes');
h = findobj(gcf, 'type', 'line');
set(h, 'linewidth', 6);
set(a, 'linewidth', 6);
set(a, 'FontSize', 50);
% Convert matlab figs to tikz for pgfplots in latex document.
% matlab2tikz('figurehandle',figure1,'filename','networkPlot.tex' ,'standalone', true, 'showInfo', false);

% Plot the evolution of states
figure2 = figure('Color',[1 1 1]);
plot(0:numSteps-1, x(:,1:numSteps)', 'LineWidth', 1.5);
xlabel('Time Step');
ylabel('State Value');
a = findobj(gcf, 'type', 'axes');
h = findobj(gcf, 'type', 'line');
set(h, 'linewidth', 3);
set(a, 'linewidth', 3);
set(a, 'FontSize', 50);
% Convert matlab figs to tikz for pgfplots in latex document.
matlab2tikz('figurehandle',figure2,'filename','statesPlot.tex' ,'standalone', true, 'showInfo', false);