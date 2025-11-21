% Enhanced OpenFOAM cavity visualization inspired by simple 2D fluid demo
% Features added:
%  - Velocity magnitude contour (2D projection)
%  - Streamlines computed from interpolated velocity field
%  - Quiver overlay (subsampled vectors)
%  - Pressure scatter fallback if velocity unavailable
%  - Optional video export

folder = "cavity/VTK";          % Folder containing VTK files
timesteps = 0:100:2000;          % Available iteration numbers
makeVideo = true;                % Enable video recording
videoName = "cavity_postprocess.mp4";
quiverStride = 4;                % Subsampling for quiver plot
gridResolution = 60;             % Target grid for interpolation

if makeVideo
    try
        vidObj = VideoWriter(videoName, "MPEG-4");
        vidObj.FrameRate = 10;
        open(vidObj);
    catch ME
        warning('Video writer init failed: %s', ME.message);
        makeVideo = false;
    end
end

fig = figure('Name','Cavity Postprocess','Position',[100 100 900 650]);
colormap(fig,'jet');

for iter = timesteps
    fname = fullfile(folder, sprintf("cavity_%d.vtk", iter));
    if ~isfile(fname)
        warning("File not found: %s. Skipping.", fname);
        continue
    end

    D = readVTK_vtkPython(fname);
    X = D.points(:,1);
    Y = D.points(:,2);
    Z = D.points(:,3);

    haveVelocity = isfield(D.pointData,'U');
    havePressure = isfield(D.pointData,'p');

    if haveVelocity
        Uvec = D.pointData.U;        % [N x 3]
        Umag = sqrt(sum(Uvec.^2,2));

        % Build 2D grid (assuming near-2D cavity, use X-Y plane)
        xmin = min(X); xmax = max(X);
        ymin = min(Y); ymax = max(Y);
        gx = linspace(xmin,xmax,gridResolution);
        gy = linspace(ymin,ymax,gridResolution);
        [GX,GY] = meshgrid(gx,gy);

        % Interpolate velocity components & magnitude
        Fx = scatteredInterpolant(X,Y,Uvec(:,1),'natural','none');
        Fy = scatteredInterpolant(X,Y,Uvec(:,2),'natural','none');
        Fm = scatteredInterpolant(X,Y,Umag,'natural','none');
        UX = Fx(GX,GY); UY = Fy(GX,GY); UM = Fm(GX,GY);

        % Clear and plot
        clf(fig);
        % Velocity magnitude contour
        contourf(GX,GY,UM,20,'LineColor','none'); hold on;
        colorbar; title(sprintf('Cavity Velocity Magnitude & Flow (iter %d)',iter));
        xlabel('x'); ylabel('y'); axis equal tight;

        % Streamlines: seed a set of start points along left boundary
        sx = xmin * ones(1,15);
        sy = linspace(ymin,ymax,15);
        % Replace NaNs by zero for streamline safety
        UXn = UX; UYn = UY; UXn(isnan(UXn))=0; UYn(isnan(UYn))=0;
        % Streamline requires vector field gridded, use streamslice for robustness
        streamslice(GX,GY,UXn,UYn,3);  % density factor

        % Quiver (subsample)
        qs = quiverStride;
        quiver(GX(1:qs:end,1:qs:end),GY(1:qs:end,1:qs:end),UXn(1:qs:end,1:qs:end),UYn(1:qs:end,1:qs:end),'k');
        hold off;
    else
        % Fallback scatter plot colored by pressure (or zeros)
        if havePressure
            p = D.pointData.p;
        else
            p = zeros(size(X));
        end
        clf(fig);
        scatter3(X,Y,Z,15,p,'filled');
        colorbar; axis equal; xlabel('x'); ylabel('y'); zlabel('z');
        title(sprintf('Cavity Pressure Scatter (iter %d)',iter));
    end

    drawnow;
    if makeVideo
        frame = getframe(fig);
        writeVideo(vidObj,frame);
    end
end

if makeVideo
    close(vidObj);
    fprintf('Video written: %s\n', videoName);
end
