%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This code simulates predictive consensus algorithm for multi-agent systems.
% Journal Paper submitted to IEEE Letters to Control Systems Society.
%
% Copyrights Authors: 1) Venkatraman Renganathan - Cranfield University, UK.
%                     2) Sabyasachi Mondal - Cranfield University, UK.
%                     3) Saurabh Upadhyay - Cranfield University, UK.
%
% Emails: v.renganathan@cranfield.ac.uk
%         sabyasachi.mondal@cranfield.ac.uk
%         saurabh.upadhyay@cranfield.ac.uk 
%
% Date last updated: May 14, 2026.
% 
% Notation:
%   L           : graph Laplacian
%   calL        : lifted Laplacian; here d = 1, so calL = L
%   x[k]        : stacked network state
%   xhat[k+1]   : predicted estimate
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
rng(10); % reproducibility

%% Parameters
numAgents = 20;
timeSteps = 300;

%% Generate connected undirected weighted graph with lambdaN(L) < 1

trial = 0; % trail number       
p_extra = 0.08; % extra edge probability
maxTrials = 10000; % maximum number of allowed trials
foundGraph = false; % flag to raise when a connected graph is generated
connectThreshold = 1e-10; % Eigenvalue threshold to check for connectivity

% Loop till you generate a connected graph
while ~foundGraph

    % Increment the trial number
    trial = trial + 1;
    
    % If the trial number exceeds the maxTrials, exit with failure error
    if trial > maxTrials
        error('Could not generate a connected graph with lambda_N(L)<1 within maxTrials.');
    end
    
    % Set Adjacency matrix as zero matrix
    AdjacencyMatrix = zeros(numAgents, numAgents);
    
    % Create random spanning tree first to guarantee connectedness
    for i = 2:numAgents
        parent = randi(i-1);
        % Small weights help keep lambda_N(L)<1
        weight = 0.005 + 0.015*rand; 
        AdjacencyMatrix(i,parent) = weight;
        AdjacencyMatrix(parent,i) = weight;
    end
    
    % Add sparse extra random edges with small weights
    for i = 1:numAgents
        for j = i+1:numAgents
            if AdjacencyMatrix(i,j) == 0 && rand < p_extra
                weight = 0.005 + 0.015*rand;
                AdjacencyMatrix(i,j) = weight;
                AdjacencyMatrix(j,i) = weight;
            end
        end
    end
    
    % Get the degree matrix
    DegreeMatrix = diag(sum(AdjacencyMatrix,2));
    
    % Form the Laplacian matrix
    LaplacianMatrix = DegreeMatrix - AdjacencyMatrix;
    
    % Get the eigenvalues of Laplacian matrix
    eigenLaplacian = sort(eig(LaplacianMatrix));
    
    % Record the 2nd eigenvalue of Laplacian matrix
    lambda2 = eigenLaplacian(2);
    
    % Record the largest eigenvalue of Laplacian matrix
    lambdaN = eigenLaplacian(end);

    % Store all the non-zero Eigenvalues of Laplacian matrix
    nonZeroLambdas = eigenLaplacian(2:end);

    % Connected & lambda_N less than 1, you have found the connected graph
    if lambda2 > connectThreshold && lambdaN < 1
        foundGraph = true;
    end
end

% Print the lambda2 and lambdaN
fprintf('Found connected graph after %d trials.\n', trial);
fprintf('lambda2 = %.6f, lambdaN = %.6f\n', lambda2, lambdaN);

% Disagreement projection matrix
Pi_perp = eye(numAgents) - (1/numAgents)*ones(numAgents,numAgents);

% Set the initial condition for all agents
x0 = -5 + 10*rand(numAgents,1);

%% ================================================================
% Gain selection for nominal comparison
% ================================================================

% Standard consensus gain
alphaStandard = 2/(lambda2 + lambdaN);

% Predictive consensus Protocol
% x[k+1] = (I - gamma L + beta L^2)x[k], where gamma = alpha + beta

betaGrid = linspace(0, 1.5, 400);
bestRho = inf;
bestBeta = 0;
bestGamma = alphaStandard;
gammaTolerance = 1e-8;

for beta = betaGrid

    % Need |1 - gamma*lambda_i + beta*lambda_i^2| < 1
    % Equivalent: 0 < gamma - beta*lambda_i < 2/lambda_i
    gammaLower = max(beta*nonZeroLambdas) + gammaTolerance;
    gammaUpper = min(beta*nonZeroLambdas + 2./nonZeroLambdas) - gammaTolerance;

    % If bounds of gamma hold, continue
    if gammaUpper <= gammaLower
        continue;
    end

    % Form a grid over gamma space
    gammaGrid = linspace(gammaLower, gammaUpper, 600);

    % Loop over gamma grid
    for gamma = gammaGrid

        % Compute the rho
        rho = max(abs(1 - gamma*nonZeroLambdas + beta*nonZeroLambdas.^2));

        % If newly computed rho is < bestrho, update rho with bestrho.
        if rho < bestRho
            bestRho = rho;
            bestBeta = beta;
            bestGamma = gamma;
        end
    end
end

% Set the alpha, beta, gamma for predictive consensus protocol
betaPredictive = bestBeta;
gammaPredictive = bestGamma;
alphaPredictive = gammaPredictive - betaPredictive;

% Print the results
fprintf('Nominal gains:\n');
fprintf('alpha_std  = %.6f\n', alphaStandard);
fprintf('alpha_pred = %.6f, beta_pred = %.6f, gamma_pred = %.6f, rho_pred = %.6f\n', ...
    alphaPredictive, betaPredictive, gammaPredictive, bestRho);
% Give warning if the calculated alpha <= 0. 
if alphaPredictive <= 0
    warning('alpha_pred is non-positive. Consider changing beta grid.');
end

%% ================================================================
% Compare standard vs predictive nominal convergence 
% ================================================================

% Placeholders to store the states under standard and predictive protocols
xStandard = zeros(numAgents,timeSteps+1);
xPredictive = zeros(numAgents,timeSteps+1);

% Populate the first entries of the placeholders
xStandard(:,1) = x0;
xPredictive(:,1) = x0;

% Placeholders to store the errors under standard and predictive protocols
disagreeStandard = zeros(timeSteps+1,1);
disagreePredictive = zeros(timeSteps+1,1);

% Populate the first entries of the placeholders
disagreeStandard(1) = norm(Pi_perp*xStandard(:,1),2);
disagreePredictive(1) = norm(Pi_perp*xPredictive(:,1),2);

A_standard = eye(numAgents) - alphaStandard*LaplacianMatrix;
A_predictive = eye(numAgents) - gammaPredictive*LaplacianMatrix + betaPredictive*(LaplacianMatrix^2);

% Loop through time to record both states & errors under both protocols
for k = 1:timeSteps

    % Update state under standard consensus protocol
    xStandard(:,k+1) = A_standard*xStandard(:,k);
    
    % Update state under predictive consensus protocol
    xPredictive(:,k+1) = A_predictive*xPredictive(:,k);
    
    % Update error under standard consensus protocol
    disagreeStandard(k+1) = norm(Pi_perp*xStandard(:,k+1),2);
    
    % Update error under predictive consensus protocol
    disagreePredictive(k+1) = norm(Pi_perp*xPredictive(:,k+1),2);
end


%% ================================================================
% Figure 2: Delay / packet-drop resilience comparison
% ================================================================

Dmax = 4; % maximum allowable age of stale prediction
etaDrop = 0.40; % reduction factor
dropProbability = 0.25; % probability of a packet-dropping
epsilon_w = 0.5; % Persistent bounded prediction disturbance

% Conservative gains for delayed/drop setting
alphaStandardWithDelay = etaDrop*alphaStandard;
alphaPredictiveWithDelay = etaDrop*alphaPredictive;
betaPredictiveWithDelay  = etaDrop*betaPredictive;
gammaPredictiveWithDelay = alphaPredictiveWithDelay + betaPredictiveWithDelay;

% Compute the rho
rhoDelay = max(abs(1 - gammaPredictiveWithDelay*nonZeroLambdas + betaPredictiveWithDelay*nonZeroLambdas.^2));

fprintf('Delay/drop gains:\n');
fprintf('alpha_std_d = %.6f\n', alphaStandardWithDelay);
fprintf('alpha_pred_d = %.6f, beta_pred_d = %.6f, gamma_pred_d = %.6f, rho_delay = %.6f\n', ...
    alphaPredictiveWithDelay, betaPredictiveWithDelay, gammaPredictiveWithDelay, rhoDelay);
if rhoDelay >= 1
    error('Predictive gains under packet drops are not nominally stable.');
end

% Placeholders for states under standard & predictive protocols with Delay
xStandardDelay = zeros(numAgents,timeSteps+1);
xPredictiveDelay = zeros(numAgents,timeSteps+1);

% Populate the first entries of the placeholders
xStandardDelay(:,1) = x0;
xPredictiveDelay(:,1) = x0;

% Placeholders for errors under standard & predictive protocols with Delay
disagreeStandardDelay = zeros(timeSteps+1,1);
disagreePredictiveDelay = zeros(timeSteps+1,1);

% Populate the first entries of the placeholders
disagreeStandardDelay(1) = norm(Pi_perp*xStandardDelay(:,1),2);
disagreePredictiveDelay(1) = norm(Pi_perp*xPredictiveDelay(:,1),2);

% Set the age of stale prediction to be zero
age = 0;

% Loop through the time steps 
for k = 1:timeSteps

    % Bounded stale-age process
    if rand < dropProbability
        age = min(age + 1, Dmax);
    else
        age = 0;
    end

    % Infer the stale prediction time index
    indexStale = max(1, k - age);

    % Standard consensus with stale state information
    % Standard consensus with stale and disturbed state information
    xStaleStandard = xStandardDelay(:,indexStale);
    
    wStandard = randn(numAgents,1);
    if norm(wStandard,2) > 0
        wStandard = rand*epsilon_w*wStandard/norm(wStandard,2);
    end
    
    xStaleStandardUsed = xStaleStandard + wStandard;
    
    xStandardDelay(:,k+1) = xStandardDelay(:,k) ...
        - alphaStandardWithDelay*LaplacianMatrix*xStaleStandardUsed;

    % Predictive consensus with stored stale prediction
    xStalePredictive = xPredictiveDelay(:,indexStale);
    
    % Create a bounded noise - ensure norm of noise <= epsilon_w
    w = randn(numAgents,1); 
    if(norm(w,2) > 0)
        w = epsilon_w * w / norm(w,2);
    end

    % One-step prediction map: F(x) = (I - L)x
    % Persistent bounded prediction disturbance
    wPredictive = randn(numAgents,1);
    if norm(wPredictive,2) > 0
        wPredictive = rand*epsilon_w*wPredictive/norm(wPredictive,2);
    end
    
    % Stored multi-step prediction map
    PredictionMatrix = eye(numAgents) - LaplacianMatrix;
    
    xhatUsed = (PredictionMatrix^(age+1))*xStalePredictive + wPredictive;

    % Update using the predictive protocol with delay
    xPredictiveDelay(:,k+1) = xPredictiveDelay(:,k) ...
                   - alphaPredictiveWithDelay*LaplacianMatrix*xPredictiveDelay(:,k) ...
                   - betaPredictiveWithDelay*LaplacianMatrix*xhatUsed;
    
    % Update the errors of both standard and predictive protocols
    disagreeStandardDelay(k+1) = norm(Pi_perp*xStandardDelay(:,k+1),2);
    disagreePredictiveDelay(k+1) = norm(Pi_perp*xPredictiveDelay(:,k+1),2);
end

%% Compute theoretical disagreement tube bound

PredictionMatrix = eye(numAgents) - LaplacianMatrix;
ellF = norm(PredictionMatrix,2);

% Estimate one-step variation bound from predictive trajectory
stateDiffs = vecnorm(diff(xPredictiveDelay,1,2),2,1);
nuBound = max(stateDiffs);

tubeBound = (betaPredictiveWithDelay*lambdaN/(1-rhoDelay)) ...
            * (ellF*Dmax*nuBound + epsilon_w);

fprintf('ellF = %.6f\n', ellF);
fprintf('nuBound = %.6f\n', nuBound);
fprintf('Tube bound = %.6f\n', tubeBound);

%% Plotting Results

% Set the plotting parameters
fontSize = 40;
lineWidth = 5;

% Figure 1 - Predictive vs Standard Protocol Disagreement Comparison
figure('Color','w','Position',[100 100 1500 1000]);
semilogy(0:timeSteps, disagreeStandard, '-', 'LineWidth', lineWidth); 
hold on;
semilogy(0:timeSteps, disagreePredictive, '-', 'LineWidth', lineWidth);
grid on; box on;
xlabel('$k$', 'Interpreter','latex', 'FontSize', fontSize);
ylabel('$\|\Pi^\perp \mathbf{x}[k]\|_2$', ...
    'Interpreter','latex', 'FontSize', fontSize);
legend({'Standard consensus','Predictive consensus'}, ...
    'Interpreter','latex', ...
    'FontSize', fontSize, ...
    'Location','northeast');
set(gca, ...
    'TickLabelInterpreter','latex', ...
    'FontSize', fontSize, ...
    'LineWidth', 2);
%exportgraphics(gcf, 'fig1_nominal_disagreement.pdf', 'ContentType','vector');

% Figure 2 - Predictive vs Standard Protocol States Plot
figure('Color','w','Position',[100 100 1500 1000]);
%semilogy(0:timeSteps, xStandard, '-', 'LineWidth', lineWidth); 
hold on;
semilogy(0:timeSteps, xPredictive, '-', 'LineWidth', lineWidth);
grid on; box on;
xlabel('$k$', 'Interpreter','latex', 'FontSize', fontSize);
ylabel('$\mathbf{x}[k]$', ...
    'Interpreter','latex', 'FontSize', fontSize);
% legend({'Standard consensus','Predictive consensus'}, ...
%     'Interpreter','latex', ...
%     'FontSize', fontSize, ...
%     'Location','northeast');
legend({'Predictive consensus'}, ...
    'Interpreter','latex', ...
    'FontSize', fontSize, ...
    'Location','northeast');
set(gca, ...
    'TickLabelInterpreter','latex', ...
    'FontSize', fontSize, ...
    'LineWidth', 2);
%exportgraphics(gcf, 'fig2_states_convergence.pdf', 'ContentType','vector');

% Figure 3 - Delay Resilience - Disagreement Comparison
figure('Color','w','Position',[100 100 1500 1000]);
semilogy(0:timeSteps, disagreeStandardDelay, '-', 'LineWidth', lineWidth); 
hold on;
semilogy(0:timeSteps, disagreePredictiveDelay, '-', 'LineWidth', lineWidth);
grid on; box on;
yline(tubeBound, ':', ...
    'LineWidth', lineWidth, ...
    'Color', [0.3 0.3 0.3]);
xlabel('$k$', 'Interpreter','latex', 'FontSize', fontSize);
ylabel('$\|\Pi^\perp \mathbf{x}[k]\|_2$', ...
    'Interpreter','latex', 'FontSize', fontSize);
legend({'Standard consensus', ...
        'Predictive consensus', ...
        'Theoretical tube bound'}, ...
        'Interpreter','latex', ...
        'FontSize', fontSize, ...
        'Location','southwest');
set(gca, ...
    'TickLabelInterpreter','latex', ...
    'FontSize', fontSize, ...
    'LineWidth', 2);
%exportgraphics(gcf, 'fig3_packet_drop_resilience_disagreement.pdf', 'ContentType','vector');

% Figure 4 - Delay Resilience - States Plot
figure('Color','w','Position',[100 100 1500 1000]);
%semilogy(0:timeSteps, xStandardDelay, '-', 'LineWidth', lineWidth); 
hold on;
semilogy(0:timeSteps, xPredictiveDelay, '-', 'LineWidth', lineWidth);
grid on; box on;
xlabel('$k$', 'Interpreter','latex', 'FontSize', fontSize);
ylabel('$\mathbf{x}[k]$', ...
    'Interpreter','latex', 'FontSize', fontSize);
% legend({'Standard consensus with drops', ...
%         'Predictive consensus with stored predictions'}, ...
%     'Interpreter','latex', ...
%     'FontSize', fontSize, ...
%     'Location','northeast');
legend({'Predictive consensus with stored predictions'}, ...
    'Interpreter','latex', ...
    'FontSize', fontSize, ...
    'Location','northeast');
set(gca, ...
    'TickLabelInterpreter','latex', ...
    'FontSize', fontSize, ...
    'LineWidth', 2);
%exportgraphics(gcf, 'fig4_packet_drop_resilience_states.pdf', 'ContentType','vector');