% post_process_pitzDailySteady.m
% Lightweight MATLAB post-processing for OpenFOAM pitzDaily steady case.
% Computes time evolution of domain-averaged velocity magnitude and pressure
% and produces basic diagnostic plots from available time directories.

function post_process_pitzDailySteady(caseDir)
    % Allow running without arguments (assume script location parent)
    if nargin == 0
        caseDir = fileparts(mfilename('fullpath')); % directory containing this script
    end

    fprintf('Case directory: %s\n', caseDir);

    timeDirs = listTimeDirectories(caseDir);
    if isempty(timeDirs)
        error('No numeric time directories found in %s', caseDir);
    end

    fprintf('Found %d time directories: %s\n', numel(timeDirs), strjoin(string(timeDirs), ', '));

    meanUMag = zeros(numel(timeDirs),1);
    meanP    = zeros(numel(timeDirs),1);

    for i = 1:numel(timeDirs)
        tStr = num2str(timeDirs(i));
        Ufile = fullfile(caseDir, tStr, 'U');
        pfile = fullfile(caseDir, tStr, 'p');
        if ~isfile(Ufile) || ~isfile(pfile)
            warning('Skipping time %s (missing U or p)', tStr);
            meanUMag(i) = NaN; %#ok<*AGROW>
            meanP(i)    = NaN;
            continue;
        end
        U = readOpenFoamInternalField(Ufile); % Nx3
        p = readOpenFoamInternalField(pfile); % Nx1
        if size(U,2) ~= 3
            error('U field at time %s is not vector data.', tStr);
        end
        if size(p,2) ~= 1 || size(p,1) ~= size(U,1)
            warning('Size mismatch U(%d) vs p(%d) at time %s', size(U,1), size(p,1), tStr);
        end
        magU = sqrt(sum(U.^2,2));
        meanUMag(i) = mean(magU);
        meanP(i)    = mean(p(:));
    end

    % Plot time evolution
    figure('Name','Mean Quantities vs Time');
    yyaxis left; plot(timeDirs, meanUMag, '-o','DisplayName','Mean |U|'); ylabel('Mean Velocity Magnitude');
    yyaxis right; plot(timeDirs, meanP, '-s','DisplayName','Mean p'); ylabel('Mean Pressure');
    xlabel('Time'); title('Domain-Averaged Quantities'); grid on;
    legend('Location','best');

    % Histogram & distribution at final time
    finalIdx = find(~isnan(meanUMag),1,'last');
    if ~isempty(finalIdx)
        finalTime = num2str(timeDirs(finalIdx));
        Ufinal = readOpenFoamInternalField(fullfile(caseDir, finalTime, 'U'));
        magUfinal = sqrt(sum(Ufinal.^2,2));
        figure('Name','Velocity Magnitude Distribution (final)');
        histogram(magUfinal, 60); xlabel('|U|'); ylabel('Count'); title(['Velocity Magnitude Distribution at t = ', finalTime]); grid on;
    end

    fprintf('Post-processing complete.\n');
end

function data = readOpenFoamInternalField(fieldFile)
    % Reads scalar or vector internalField from an OpenFOAM volField file.
    % Returns Nx1 for scalar, Nx3 for vector.
    fid = fopen(fieldFile,'r');
    if fid < 0
        error('Cannot open %s', fieldFile);
    end
    C = onCleanup(@() fclose(fid));
    lines = {}; %#ok<NASGU>
    raw = fread(fid,'*char')';
    % Locate 'internalField'
    idxIF = strfind(raw, 'internalField');
    if isempty(idxIF)
        error('internalField not found in %s', fieldFile);
    end
    % Extract from internalField onward
    tail = raw(idxIF(1):end);
    % Determine uniform vs nonuniform
    if ~isempty(regexp(tail, 'internalField\s+uniform\s', 'once'))
        % Robust uniform field parsing (vector or scalar)
        uniformMatch = regexp(tail, 'internalField\s+uniform\s+([^;]+);', 'tokens', 'once');
        if isempty(uniformMatch)
            error('Uniform internalField declaration not found in %s', fieldFile);
        end
        valStr = strtrim(uniformMatch{1});
        if startsWith(valStr,'(') && endsWith(valStr,')')
            nums = regexp(valStr(2:end-1), '[-+eE0-9\.]+', 'match');
            data = str2double(nums(:))';
            if numel(data) == 3
                % Return 1x3 vector
            elseif numel(data) == 1
                data = data(:); % scalar disguised in parentheses
            else
                error('Unexpected number of components for uniform field in %s', fieldFile);
            end
        else
            % Scalar uniform
            data = str2double(valStr);
        end
        return;
    end
    % Nonuniform list parsing
    % Find size line: number preceding '(' that begins list
    sizeMatch = regexp(tail, 'internalField\s+nonuniform\s+List<.*?>\s+(\d+)','tokens','once');
    if isempty(sizeMatch)
        error('Failed to find nonuniform list size in %s', fieldFile);
    end
    nVals = str2double(sizeMatch{1});
    % Extract block between first '(' after size and matching ')'
    blockStart = regexp(tail, '\n\(', 'start', 'once');
    if isempty(blockStart)
        error('Opening parenthesis for data block not found in %s', fieldFile);
    end
    % Find closing ')\n;' pattern (end of list)
    blockEnd = regexp(tail(blockStart+1:end), '\)\s*;','start','once');
    if isempty(blockEnd)
        % Fallback: just last ')' before ';'
        blockEnd = regexp(tail(blockStart+1:end), '\)','start','last');
    end
    dataBlock = tail(blockStart+1:blockStart+blockEnd-1);
    if contains(tail,'List<vector>')
        % Parse vectors
        vecTokens = regexp(dataBlock, '\(\s*([-+eE0-9\.]+)\s+([-+eE0-9\.]+)\s+([-+eE0-9\.]+)\s*\)', 'tokens');
        if numel(vecTokens) ~= nVals
            warning('Vector count %d mismatch declared %d in %s', numel(vecTokens), nVals, fieldFile);
        end
        data = zeros(numel(vecTokens),3);
        for i = 1:numel(vecTokens)
            data(i,:) = str2double(vecTokens{i});
        end
    else
        % Parse scalars
        scaTokens = regexp(dataBlock, '([-+eE0-9\.]+)', 'tokens');
        if numel(scaTokens) ~= nVals
            warning('Scalar count %d mismatch declared %d in %s', numel(scaTokens), nVals, fieldFile);
        end
        data = zeros(numel(scaTokens),1);
        for i = 1:numel(scaTokens)
            data(i) = str2double(scaTokens{i}{1});
        end
    end
end

function timeDirs = listTimeDirectories(caseDir)
    d = dir(caseDir);
    nums = [];
    for i = 1:numel(d)
        if d(i).isdir && ~startsWith(d(i).name,'.')
            val = str2double(d(i).name);
            if ~isnan(val)
                nums(end+1) = val; %#ok<AGROW>
            end
        end
    end
    timeDirs = sort(nums);
end