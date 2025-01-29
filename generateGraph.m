%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This code generates a graph when specified with a number of agents.
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
function [graphOutput] = generateGraph(numAgents)

    % Create a spanning tree first
    spanningTree = graph();
    spanningTree = addnode(spanningTree, numAgents);
    for i = 2:numAgents
        parent = randi(i-1); % Randomly connect to a previous node
        spanningTree = addedge(spanningTree, parent, i, rand);
    end
    
    % Add additional random edges to make it a connected graph
    p = 0.5; % Probability of adding extra edges
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
    adjMatrix = adjacency(spanningTree);
    adjMatrix = max(adjMatrix, adjMatrix');
    G = graph(adjMatrix);
    
    % Normalize the adjacency matrix to make the weight matrix stochastic
    degMatrix = diag(sum(adjMatrix, 2));
    % Simple Weight Matrix for building prediction data 
    simpleWeights = degMatrix \ adjMatrix;

    % Return the following outputStruct
    graphOutput.graph = G;
    graphOutput.adjMatrix = adjMatrix;
    graphOutput.degMatrix = degMatrix;
    graphOutput.simpleWeights = simpleWeights;

end