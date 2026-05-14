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
% Date last updated: October 06, 2025.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make a fresh start
clear; close all; clc;

% set properties for plotting
%set(groot,'defaultAxesTickLabelInterpreter','latex');  
%set(groot,'defaulttextinterpreter','latex');
%set(groot,'defaultLegendInterpreter','latex');
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
trustRadius = 3; % Trust Radius for Coordination - 3
discountFactor = 0.99; % Discount Factor for Trust Estimation
predictionHorizon = 15; % Prediction Horizon

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
    save('networkData.mat');
    disp('Finished saving the generated network data');
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

% Choose similation scenario
% simScenario = 1 - Single malicious agent, 
% simScenario = 2 - multiple malicious agents
% simScenario = 3 - multiple malicious leaders
simScenario = 1;

% Set the simulation scenario
if(simScenario == 1)
    % Make a random agent to become malicious throughout all time steps
    maliciousIndex = 5; % randperm(numAgents, 1);
    % Choose a uncompromised node for recording its neighbors trusts for plotting
    while 1
        goodIndex = randperm(numAgents, 1);
        % If agent is good and has malicious neighbor, then break
        if(goodIndex ~= maliciousIndex && adjMatrix(goodIndex, maliciousIndex) == 1)
            break
        end
    end
else
    % Set number of malicious agents
    numMaliciousAgents = ceil(numAgents/4);
    % Choose malicious agent indices
    maliciousIndices = randperm(numAgents, numMaliciousAgents);
    % Choose a uncompromised node for recording its neighbors trusts for plotting
    while 1
        goodIndex = randperm(numAgents, 1);
        % If agent is good and has malicious neighbor, then break
        if(goodIndex ~= any(maliciousIndices) && any(adjMatrix(goodIndex, maliciousIndices) == 1))
            break
        end
    end
end

% % Identify neighbors of agent atgood Index
% goodNodeNeighborsCount = size(find(adjMatrix(goodIndex, :) > 0), 2);
% 
% % Placeholder for recording the trusts of goodNodeNeighbors
% trustRecord = zeros(goodNodeNeighborsCount, numSteps-1);

% Set flag for recording trust
trustRecord = 1;

% Choose the attack time interval
if(simScenario < 3)
    attackStart = 15;
    attackEnd = 100;
else
    attackStart = 10;
    attackEnd = 100;
end

% Placeholder to store the commitment data of neighbors over time
agentNeighborsCommitments = cell(numAgents, 1);

% Prepare for storing the neighbor's commitment data 
for i = 1:numAgents
    % Identify neighbors of agent i
    iNeighbors = find(adjMatrix(i, :) > 0);

    % Count the number of neighbors of agent i
    iNeighborsCount = size(iNeighbors, 2);

    % Initialise the neighbor's commitment data for each agent
    agentNeighborsCommitments{i} = zeros(iNeighborsCount, numSteps);
end

% ADC Protocol Iteration
disp('Starting ADC Protocol Iteration');
for k = 2:numSteps-1
    
    % Iterate through all agents
    for i = 1:numAgents

        % Simulate the attack only during the attack duration
        if(k >= attackStart && k <= attackEnd)
            if(simScenario == 1)
                % Update single malicious agent
                if(i == maliciousIndex)
                    x(i, k+1:k+1+predictionHorizon-1) = 1 + randn*x(i, k:k+predictionHorizon-1);
                    % x(i, k+1:k+1+predictionHorizon-1) = -0.1 + x(i, k:k+predictionHorizon-1);
                    continue;
                end 
            elseif(simScenario == 2)
                % Update multiple malicious agents (one per every for loop iteration)
                if(any(maliciousIndices(:) == i))
                    x(i, k+1:k+1+predictionHorizon-1) = 0.1 + randn*x(i, k:k+predictionHorizon-1);
                    continue;
                end 
            else
                % Update leader malicious agent (one per every for loop iteration)
                if(any(maliciousIndices(:) == i))
                    x(i, k+1:k+1+predictionHorizon-1) = x(i, k:k+predictionHorizon-1);
                    continue;
                end 
            end

        end

        % Identify neighbors of agent i
        iNeighbors = find(adjMatrix(i, :) > 0);

        % Count the number of neighbors of agent i
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
            trustEstimationInput.iPredictedStates = iPredictedStates;
            trustEstimationInput.currentPrediction = jthFriendPrediction;
            trustEstimationInput.previousPrediction = jthFriendOldPrediction;

            % Estimate trust of jth neighbor at time k via their prediction
            jthTrustVector = estimateTrust(trustEstimationInput);

            % if((i == 10 || i == 20) && (iNeighbors(j) == maliciousIndex))
            %     jthTrustVector
            % end

            % When for loop runs for selected good index node, record its trust
            % computations for all neighbors using a placeholder
            if(trustRecord == 1 && any(jthTrustVector > 0) && k >= attackStart && k <= attackEnd)
                plotNeighborTrust = jthTrustVector;
                trustRecord = 0;
            end

            % Store average trust of jth neighbor for commitment calculation
            iNeighborsCommitments(j,k) = mean(jthTrustVector); 
            if(k == 1)
                agentNeighborsCommitments{i}(j,k) = iNeighborsCommitments(j,k);
            else
                agentNeighborsCommitments{i}(j,k) = iNeighborsCommitments(j,k) + sum(iNeighborsCommitments(j,1:k-1),2); 
            end
            
            % Prepare a struct input for weight calculation
            weightCalculationInput.commit = agentNeighborsCommitments{i}(j,k);
            weightCalculationInput.jthTrustVector = jthTrustVector;
            weightCalculationInput.predictionHorizon = predictionHorizon;
            
            % Calculate the weight to be associated for jth neighbor
            adcProtocolWeights(:,j) = calculateWeight(weightCalculationInput);

            % % Deliberately make 0 weight for mal neighbors
            % if (iNeighbors(j) == maliciousIndex)
            %     adcProtocolWeights(:,j) = zeros(predictionHorizon, 1);
            % end

            % Form difference of opinion of agent i w.r.t neighbor j
            jthFriendOpinionDifference = jthFriendPrediction' - iPredictedStates';

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
nwPlot = plot(G, 'Layout', 'force', 'NodeColor','k','EdgeAlpha',0.99, 'NodeCData', degree(G));
nwPlot.NodeFontSize = 40;
nwPlot.MarkerSize = 20;
a = findobj(gcf, 'type', 'axes');
h = findobj(gcf, 'type', 'line');
set(h, 'linewidth', 20);
set(a, 'linewidth', 6);
set(a, 'FontSize', 75);
% Convert matlab figs to tikz for pgfplots in latex document.
% matlab2tikz('figurehandle',figure1,'filename','networkPlot.tex' ,'standalone', true, 'showInfo', false);

% Plot the evolution of states
figure2 = figure('Color',[1 1 1]);
plot(0:numSteps-1, x(:,1:numSteps)', 'LineWidth', 1.5);
axis tight;
xlabel('Time', 'FontWeight', 'bold');
ylabel('States', 'FontWeight', 'bold');
a = findobj(gcf, 'type', 'axes');
h = findobj(gcf, 'type', 'line');
set(h, 'linewidth', 5);
set(a, 'linewidth', 5);
set(a, 'FontSize', 80);
set(gca,'fontweight','bold');
% Convert matlab figs to tikz for pgfplots in latex document.
matlab2tikz('figurehandle',figure2,'filename','statesPlot.tex' ,'standalone', true, 'showInfo', false);

% Plot the trusts of neighbors of good agent 
figure3 = figure('Color',[1 1 1]);
plot(0:numSteps-1, agentNeighborsCommitments{2}(5,:), 'LineWidth', 1.5, 'MarkerSize',20, 'Marker','+', 'Color',"b");
xlabel('Time', 'FontWeight', 'bold');
ylabel('Commitment', 'FontWeight', 'bold');
xlim([0, numSteps-1]);
a = findobj(gcf, 'type', 'axes');
h = findobj(gcf, 'type', 'line');
set(h, 'linewidth', 5);
set(a, 'linewidth', 5);
set(a, 'FontSize', 80);
set(gca,'fontweight','bold');
% Convert matlab figs to tikz for pgfplots in latex document.
matlab2tikz('figurehandle',figure3,'filename','trustPlot.tex' ,'standalone', true, 'showInfo', false);
