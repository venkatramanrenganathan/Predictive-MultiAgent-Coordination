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
% Date last updated: 23 January, 2025.
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
numAgents = 10; % Number of agents
numSteps = 20; % Number of time steps
alpha = 0.1; % Step size (weight for updates)

% Generate a connected random graph with a spanning tree
% Create a spanning tree first
spanningTree = graph();
spanningTree = addnode(spanningTree, numAgents);
for i = 2:numAgents
    parent = randi(i-1); % Randomly connect to a previous node
    spanningTree = addedge(spanningTree, parent, i, rand);
end

% Add additional random edges to make it a connected graph
p = 0.05; % Probability of adding extra edges
adjMatrix = adjacency(spanningTree);
for i = 1:numAgents
    for j = i+1:numAgents
        if rand < p && adjMatrix(i, j) == 0
            adjMatrix(i, j) = rand;
            adjMatrix(j, i) = adjMatrix(i, j);
        end
    end
end

% Symmetric adjacency matrix
adjMatrix = max(adjMatrix, adjMatrix');
G = graph(adjMatrix);

% Normalize the adjacency matrix to make the weight matrix stochastic
degMatrix = diag(sum(adjMatrix, 2));
initialWeights = degMatrix \ adjMatrix;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simulate the Network
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

epsilon = 1e-3; % Constant for numerical stability in weights calculation
predictionHorizon = 5; % Prediction Horizon
trustRadius = 0.5; % Trust Radius for Coordination
discountFactor = 0.99; % Discount Factor for Trust Estimation

% Placeholder to store the data for all nodes
x = zeros(numAgents, numSteps);

% Initialize random data for all nodes across the prediction horizon
x(:, 1:predictionHorizon) = randn(numAgents, predictionHorizon);

% ADC Protocol Iteration
for k = 1:numSteps-1

    % Iterate through all agents
    for i = 1:numAgents

        % Identify neighbors of agent i
        iNeighbors = find(adjMatrix(i, :) > 0);

        % Count the number of agent i
        iNeighborsCount = size(iNeighbors, 2);

        % Extract state values of agent i
        iStates = x(i,:);

        % Extract state values of neighbors of agent i
        iNeighborsStates = x(iNeighbors, :);

        % Extract prediction data out of all data for neighbors of agent i
        iNeighborsPredictions = iNeighborsStates(:, k:k+predictionHorizon-1);

        if(k > 1)
            iNeighborsOldPredictions = iNeighborsStates(:, k-1:k-1+predictionHorizon-1);
        end
    
        % Iterate through all neighbors of agent i
        for j = 1:iNeighborsCount

            % Get the index of neighbor j of agent i
            jthNeighborIndex = iNeighbors(1,j);

            % Get prediction data of neighbor j of agent i at time k
            jthFriendPrediction = iNeighborsPredictions(jthNeighborIndex, :);

            % Prepare a struct input for trust estimation
            trustEstimationInput.trustRadius = trustRadius;
            trustEstimationInput.discountFactor = discountFactor;
            trustEstimationInput.predictionHorizon = predictionHorizon;
            trustEstimationInput.currentPrediction = jthFriendPrediction;
            trustEstimationInput.previousPrediction = jthFriendOldPrediction;

            % Estimate trust of jth neighbor at time k via their prediction
            jthTrustVector = estimateTrust(trustEstimationInput);

            % Compute average trust for jth neighbor
            jthMeanTrust = mean(jthTrustVector);
            
            % Prepare a struct input for weight calculation
            weightCalculationInput.jthTrustVector = jthTrustVector;
            weightCalculationInput.predictionHorizon = predictionHorizon;
            weightCalculationInput.jStates = jthFriendPrediction;
            weightCalculationInput.iStates = iStates;
            weightCalculationInput.epsilon = epsilon;
            
            % Calculate the weight to be associated for jth neighbor
            jthNeighborWeightVector = calculateWeight(weightCalculationInput);
        
            % START FROM HERE
            % Update the states for the prediction horizon
            if(k == 1) 
                x(:, k+1) = initialWeights * x(:, k); % Update via initial weights
            else
                x(:, k+1) = smartWeights * x(:, k); % Update rule
            end



        end

    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plotting the network and the states
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Plot the network structure
figure;
plot(G, 'Layout', 'force');
title('Network Structure');
a = findobj(gcf, 'type', 'axes');
h = findobj(gcf, 'type', 'line');
set(h, 'linewidth', 6);
set(a, 'linewidth', 6);
set(a, 'FontSize', 50);

% Plot the evolution of states
figure;
plot(0:numSteps-1, x', 'LineWidth', 1.5);
xlabel('Time Step');
ylabel('State Value');
grid on;
a = findobj(gcf, 'type', 'axes');
h = findobj(gcf, 'type', 'line');
set(h, 'linewidth', 3);
set(a, 'linewidth', 3);
set(a, 'FontSize', 50);