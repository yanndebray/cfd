% plot_vtp_slices.m
% Load .mat slice files exported by parse_vtp_slices.py and plot mean
% velocity magnitude and pressure versus x-location.

function plot_vtp_slices(dataDir)
    if nargin == 0
        dataDir = fullfile(fileparts(mfilename('fullpath')), '..', 'output', 'slices_mat');
    end
    dataDir = char(dataDir);
    if ~isfolder(dataDir)
        error('Data directory %s not found. Run parse_vtp_slices.py first.', dataDir);
    end
    mats = dir(fullfile(dataDir,'xNormal_*.mat'));
    if isempty(mats)
        error('No slice .mat files found in %s', dataDir);
    end
    xVals = [];
    meanUmag = [];
    meanP = [];
    for k = 1:numel(mats)
        S = load(fullfile(dataDir, mats(k).name));
        if isfield(S,'slice_x')
            xVals(end+1) = S.slice_x; %#ok<AGROW>
        else
            xVals(end+1) = NaN; %#ok<AGROW>
        end
        if isfield(S,'Umag')
            meanUmag(end+1) = mean(S.Umag); %#ok<AGROW>
        else
            meanUmag(end+1) = NaN; %#ok<AGROW>
        end
        if isfield(S,'p')
            meanP(end+1) = mean(S.p); %#ok<AGROW>
        else
            meanP(end+1) = NaN; %#ok<AGROW>
        end
    end
    [xValsSorted, idx] = sort(xVals);
    meanUmag = meanUmag(idx);
    meanP = meanP(idx);

    figure('Name','Slice Means');
    yyaxis left; plot(xValsSorted, meanUmag,'-o'); ylabel('Mean |U|');
    yyaxis right; plot(xValsSorted, meanP,'-s'); ylabel('Mean p');
    xlabel('x location'); title('Slice Mean Velocity Magnitude & Pressure'); grid on;
end
