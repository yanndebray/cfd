folder = "cavity/VTK";   % or "" if current folder

for iter = 0:100:2000
    fname = fullfile(folder, sprintf("cavity_%d.vtk", iter));
    if ~isfile(fname)
        warning("File not found: %s. Skipping.", fname);
        continue
    end

    D = readVTK_vtkPython(fname);

    X = D.points(:,1);
    Y = D.points(:,2);
    Z = D.points(:,3);

    % Example: scalar field "p" (pressure)
    if isfield(D.pointData, "p")
        p = D.pointData.p;
    else
        p = zeros(size(X));  % fallback if p doesn't exist
    end

    scatter3(X, Y, Z, 15, p, 'filled');
    colorbar
    axis equal
    title(sprintf("cavity\\_%d", iter));
    drawnow
end
