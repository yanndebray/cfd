% plot_run_1.m
clc; clear; close all;

% Define the file path
% Assuming the script is run from the workspace root c:\Users\ydebray\Downloads\cfd
filename = fullfile('drivaer_data', 'run_1', 'force_mom_1.csv');

% Check if file exists
if ~isfile(filename)
    error('File not found: %s', filename);
end

% Read the data
data = readtable(filename);

% Extract variable names and values
varNames = data.Properties.VariableNames;
values = table2array(data);

% Create a bar chart
figure('Name', 'Run 1 Force Coefficients', 'NumberTitle', 'off');
b = bar(values);

% Customize the plot
set(gca, 'XTickLabel', varNames);
title('Force Coefficients for Run 1');
ylabel('Coefficient Value');
grid on;

% Add value labels on top of bars
xtips1 = b.XEndPoints;
ytips1 = b.YEndPoints;
labels1 = string(b.YData);
text(xtips1, ytips1, labels1, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'bottom');

fprintf('Plot created for %s\n', filename);
disp(data);

%% Plot Geometry
stlFilename = fullfile('drivaer_data', 'run_1', 'drivaer_1.stl');

if isfile(stlFilename)
    fprintf('Loading STL file: %s\n', stlFilename);
    TR = stlread(stlFilename);
    
    figure('Name', 'Run 1 Geometry', 'NumberTitle', 'off');
    
    if isa(TR, 'triangulation')
        p = patch('Faces', TR.ConnectivityList, 'Vertices', TR.Points, ...
                  'FaceColor', [0.8 0.8 1.0], ...
                  'EdgeColor', 'none', ...
                  'FaceLighting', 'gouraud', ...
                  'AmbientStrength', 0.15);
    elseif isstruct(TR)
        % Handle structure output from older or custom stlread
        if isfield(TR, 'faces') && isfield(TR, 'vertices')
             p = patch('Faces', TR.faces, 'Vertices', TR.vertices, ...
                  'FaceColor', [0.8 0.8 1.0], ...
                  'EdgeColor', 'none', ...
                  'FaceLighting', 'gouraud', ...
                  'AmbientStrength', 0.15);
        else
             error('Unknown structure format from stlread');
        end
    else
        error('Unknown output from stlread');
    end
    
    % Add a light source
    camlight('headlight');
    material('dull');
    
    % Fix the axes scaling
    axis('image');
    view([-135 35]);
    xlabel('X'); ylabel('Y'); zlabel('Z');
    title('DrivAer Geometry - Run 1');
    grid on;
else
    fprintf('Warning: STL file not found: %s\n', stlFilename);
end
