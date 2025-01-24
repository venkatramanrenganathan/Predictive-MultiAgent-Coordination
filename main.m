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
% Date last updated: 24 January, 2025.
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
numSteps = 30; % Number of time steps
numAgents = 10; % Number of agents

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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simulate the Network
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

alpha = 0.1; % Step size (weight for updates)
epsilon = 1e-3; % Constant for numerical stability in weights calculation
trustRadius = 0.5; % Trust Radius for Coordination
discountFactor = 0.99; % Discount Factor for Trust Estimation
predictionHorizon = 5; % Prediction Horizon

% Placeholder to store the data for all nodes
x = zeros(numAgents, numSteps);

% Initialize random data for all nodes across the prediction horizon
x(:, 1:predictionHorizon) = randn(numAgents, predictionHorizon);

% ADC Protocol Iteration
for k = 1:numSteps-1

    % Break the loop predictionHorizon #times steps for plotting
    if(k > numSteps-predictionHorizon)
        break;
    end
    
    if(k == 1)
        % Update using simple protocol for time k = 1
        simpleWeights = degMatrix \ adjMatrix;
        % Update neighbors with initial weights
        x(:, k+1) = simpleWeights * x(:, k); 
    else
        % Update using ADC protocol
        % Iterate through all agents
        for i = 1:numAgents
    
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
    
                % Get the index of neighbor j of agent i
                jthNeighborIndex = iNeighbors(1,j);
    
                % Get prediction data of neighbor j of agent i at time k
                jthFriendPrediction = iNeighborsPredictions(jthNeighborIndex, :);

                % Get old prediction data of neighbor j at time k-1
                jthFriendOldPrediction = iNeighborsOldPredictions(jthNeighborIndex, :);
    
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
                weightCalculationInput.timeStep = k;
                weightCalculationInput.epsilon = epsilon;
                weightCalculationInput.iStates = iPredictedStates;
                weightCalculationInput.jStates = jthFriendPrediction;
                weightCalculationInput.jthTrustVector = jthTrustVector;
                weightCalculationInput.predictionHorizon = predictionHorizon;
                
                % Calculate the weight to be associated for jth neighbor
                adcProtocolWeights(:,j) = calculateWeight(weightCalculationInput);

                % Form the committed states of jth neighbof agent i
                jthFriendCommittedStates = iNeighborsCommitments(j,k) * jthFriendPrediction;

                % Form difference of opinion of agent i w.r.t neighbor j
                jthFriendOpinionDifference = jthFriendCommittedStates' - iPredictedStates';

                % Compute jth neighbor's contribution for agent i's update
                neighborsContribution(:,j) = adcProtocolWeights(:,j).*jthFriendOpinionDifference;

            end
            
                % Update neighbors with ADC Protocol Update rule
                x(i, k+1:k+1+predictionHorizon-1) = x(i, k:k+predictionHorizon-1) + sum(neighborsContribution, 2); 
    
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