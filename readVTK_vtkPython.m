function data = readVTK_vtkPython(filename)
%READVTK_VTKPYTHON Read a legacy .vtk file using the Python VTK package.
%
%   data = readVTK_vtkPython("cavity_0.vtk")
%
% Returns:
%   data.points        : [N x 3] double, coordinates
%   data.pointData.*   : struct fields for each point data array
%   (you can extend to cell data, connectivity, etc.)

    % Import Python modules (only expensive the first time)
    vtk            = py.importlib.import_module('vtk');
    numpy_support  = py.importlib.import_module('vtk.util.numpy_support');

    % Create and configure the reader
    reader = vtk.vtkDataSetReader();
    reader.SetFileName(char(filename));
    reader.Update();

    output = reader.GetOutput();

    % --- Points -----------------------------------------------------------
    pts_vtk = output.GetPoints().GetData();
    pts_np  = numpy_support.vtk_to_numpy(pts_vtk);
    data.points = double(pts_np);   % [N x 3]

    % --- Point data (scalars, vectors, etc.) ------------------------------
    pd = output.GetPointData();
    nArrays = int32(pd.GetNumberOfArrays());

    data.pointData = struct();
    for i = 0:(nArrays-1)
        % Get array name
        name_py = pd.GetArrayName(int32(i));
        if isempty(name_py)
            continue
        end
        name = char(name_py);

        % Get VTK array and convert to NumPy → MATLAB
        arr_vtk = pd.GetArray(int32(i));
        arr_np  = numpy_support.vtk_to_numpy(arr_vtk);
        data.pointData.(name) = double(arr_np);
    end
end
