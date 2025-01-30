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
function graphOutput = generateGraph(N)
    % Generate an Erdos-Renyi graph and ensure it has a spanning tree
    % Inputs:
    %   N - Number of nodes
    
    if N < 2
        error('Number of nodes N must be at least 2.');
    end

    % Set probability of edge creation (0 < p <= 1)
    p = 0.1;
    
    % Step 1: Generate a random Erdős–Rényi graph
    A = rand(N, N) < p; % Generate random adjacency matrix
    A = triu(A, 1); % Keep upper triangle to avoid duplicate edges
    A = A + A'; % Make it symmetric (undirected graph)
    
    % Step 2: Ensure the graph is connected (has a spanning tree)
    % Check if the graph is connected using BFS or DFS
    G = graph(A);
    while ~isConnected(G)
        % Find connected components
        bins = conncomp(G);
        unique_bins = unique(bins);
        
        % Connect different components by adding edges
        for i = 1:length(unique_bins)-1
            % Find one node in the current component and one in the next
            node1 = find(bins == unique_bins(i), 1);
            node2 = find(bins == unique_bins(i+1), 1);
            
            % Add an edge between these nodes
            A(node1, node2) = 1;
            A(node2, node1) = 1;
        end
        
        % Update graph
        G = graph(A);
    end
    
    % Step 3: Compute degree and Laplacian matrices
    D = diag(sum(A, 2)); % Degree matrix
    L = D - A; % Laplacian matrix
    % Simple Weight Matrix for building prediction data 
    simpleWeights = D \ A;

    % Return the following outputStruct
    graphOutput.graph = G;
    graphOutput.adjMatrix = A;
    graphOutput.degMatrix = D;
    graphOutput.simpleWeights = simpleWeights;
    graphOutput.x0 = randn(N, 1);
    
end

% Helper function to check graph connectivity
function connected = isConnected(G)
    bins = conncomp(G); % Get connected components
    connected = (max(bins) == 1); % Only one component means connected
end