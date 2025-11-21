% analyze_drivaer.m
clc; clear; close all;

% Define paths
caseDir = pwd;
geometryDir = fullfile(caseDir, 'constant', 'geometry');

% List of geometry files
geoFiles = {'body.obj.gz', 'frontWheels.obj.gz', 'rearWheels.obj.gz'};
colors = {[0.6 0.8 1], [0.2 0.2 0.2], [0.2 0.2 0.2]}; % Body light blue, wheels dark grey

figure('Name', 'DrivAer Fastback Analysis', 'NumberTitle', 'off');
hold on;
title('DrivAer Fastback Geometry');
xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
axis equal;
grid on;
view(3);
camlight('headlight');
lighting gouraud;

for i = 1:length(geoFiles)
    gzFile = fullfile(geometryDir, geoFiles{i});
    [~, name, ~] = fileparts(geoFiles{i}); % remove .gz
    objFile = fullfile(geometryDir, name);
    
    % Unzip if needed
    if ~isfile(objFile)
        if isfile(gzFile)
            fprintf('Unzipping %s...\n', gzFile);
            gunzip(gzFile);
        else
            fprintf('Warning: File %s not found.\n', gzFile);
            continue;
        end
    end
    
    fprintf('Loading and plotting %s...\n', objFile);
    
    try
        % Try using PDE toolbox
        model = createpde();
        importGeometry(model, objFile);
        h = pdegplot(model, 'FaceAlpha', 1.0);
        
        % pdegplot returns a handle to the patch or group
        if ~isempty(h)
             set(h, 'FaceColor', colors{i}, 'EdgeColor', 'none');
        end
    catch ME
        % fprintf('PDE Toolbox import failed for %s: %s\n', objFile, ME.message);
        % fprintf('Attempting custom OBJ reader...\n');
        
        % Fallback: Custom simple reader
        [V, F] = read_obj_simple(objFile);
        if ~isempty(V) && ~isempty(F)
            patch('Vertices', V, 'Faces', F, 'FaceColor', colors{i}, 'EdgeColor', 'none', 'FaceLighting', 'gouraud');
        end
    end
end

hold off;

% Analyze controlDict
controlDictFile = fullfile(caseDir, 'system', 'controlDict');
if ~isfile(controlDictFile)
    controlDictFile = fullfile(caseDir, 'system', 'controlDict.orig');
end

if isfile(controlDictFile)
    fprintf('\n--- Simulation Settings (%s) ---\n', controlDictFile);
    fid = fopen(controlDictFile);
    while ~feof(fid)
        line = fgetl(fid);
        if isempty(line), continue; end
        line = strtrim(line);
        if startsWith(line, '//') || startsWith(line, '#'), continue; end
        
        % Simple keyword extraction
        tokens = regexp(line, '^\s*([a-zA-Z]+)\s+([^;]+);', 'tokens');
        if ~isempty(tokens)
            key = tokens{1}{1};
            val = tokens{1}{2};
            if ismember(key, {'solver', 'application', 'startTime', 'endTime', 'deltaT', 'writeInterval'})
                fprintf('%-15s : %s\n', key, val);
            end
        end
    end
    fclose(fid);
else
    fprintf('controlDict not found.\n');
end

% Helper function for simple OBJ reading
function [V, F] = read_obj_simple(filename)
    V = [];
    F = [];
    fid = fopen(filename);
    if fid == -1
        return;
    end
    
    % Read file content
    data = textscan(fid, '%s', 'Delimiter', '\n');
    lines = data{1};
    fclose(fid);
    
    numLines = length(lines);
    V = zeros(numLines, 3); % Preallocate max
    F = zeros(numLines, 3); % Preallocate max (triangles)
    v_count = 0;
    f_count = 0;
    
    for k = 1:numLines
        l = lines{k};
        if isempty(l), continue; end
        
        if startsWith(l, 'v ')
            v_count = v_count + 1;
            V(v_count, :) = sscanf(l(3:end), '%f %f %f');
        elseif startsWith(l, 'f ')
            parts = strsplit(strtrim(l(3:end)));
            v_idx = zeros(1, length(parts));
            for j=1:length(parts)
                val = parts{j};
                if contains(val, '/')
                    val = val(1:find(val=='/',1)-1);
                end
                v_idx(j) = str2double(val);
            end
            
            % Triangulate
            if length(v_idx) == 3
                f_count = f_count + 1;
                F(f_count, :) = v_idx;
            elseif length(v_idx) == 4
                f_count = f_count + 1;
                F(f_count, :) = v_idx([1 2 3]);
                f_count = f_count + 1;
                F(f_count, :) = v_idx([1 3 4]);
            end
        end
    end
    
    V = V(1:v_count, :);
    F = F(1:f_count, :);
end
