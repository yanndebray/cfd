% Simple 2D Fluid Dynamics Example: Lid-Driven Cavity Flow
% Solves the incompressible Navier-Stokes equations using a 
% Streamfunction-Vorticity formulation.
%
% The top lid moves to the right with velocity u = 1.
% Reynolds number (Re) controls the fluid viscosity.

clear; clc; close all;

% --- Parameters ---
Nx = 41;                % Grid points in x
Ny = 41;                % Grid points in y
L = 1.0;                % Domain size
Re = 100;               % Reynolds number
dt = 0.001;             % Time step
T_final = 2.0;          % Simulation duration
plot_interval = 50;     % Plot every N steps

% --- Grid Generation ---
x = linspace(0, L, Nx);
y = linspace(0, L, Ny);
[X, Y] = meshgrid(x, y);
dx = x(2) - x(1);
dy = y(2) - y(1);

% --- Initialize Fields ---
psi = zeros(Ny, Nx);    % Streamfunction
omega = zeros(Ny, Nx);  % Vorticity
u = zeros(Ny, Nx);      % x-velocity
v = zeros(Ny, Nx);      % y-velocity

% --- Video Writer ---
vidObj = VideoWriter('lid_driven_cavity.mp4','MPEG-4');
vidObj.FrameRate = 10;
open(vidObj);

% Create figure with fixed size to ensure consistent frame size
figure('Position', [100, 100, 800, 600]);

fprintf('Starting simulation (Re = %d)...\n', Re);

% --- Main Loop ---
steps = floor(T_final / dt);
for n = 1:steps
    
    % 1. Solve Poisson Equation for Streamfunction: del^2 psi = -omega
    % Using SOR (Successive Over-Relaxation) for faster convergence
    beta = 1.5; % Relaxation parameter
    for k = 1:100
        psi_old = psi;
        for i = 2:Nx-1
            for j = 2:Ny-1
                psi(j,i) = (1-beta)*psi(j,i) + beta * 0.25 * ...
                    (psi(j,i+1) + psi(j,i-1) + psi(j+1,i) + psi(j-1,i) + dx^2 * omega(j,i));
            end
        end
        % Check convergence
        if max(abs(psi(:) - psi_old(:))) < 1e-6
            break; 
        end
    end
    
    % 2. Compute Velocity from Streamfunction
    % u = d(psi)/dy, v = -d(psi)/dx
    % Central differences for interior points
    u(2:end-1, 2:end-1) = (psi(3:end, 2:end-1) - psi(1:end-2, 2:end-1)) / (2*dy);
    v(2:end-1, 2:end-1) = -(psi(2:end-1, 3:end) - psi(2:end-1, 1:end-2)) / (2*dx);
    
    % 3. Boundary Conditions for Vorticity
    % Wall boundaries (no-slip): psi = 0
    % Relation: omega_wall = -2 * (psi_inside - psi_wall + h*u_wall) / h^2
    
    % Bottom Wall (y=0, u=0)
    omega(1, :) = -2 * psi(2, :) / dy^2;
    
    % Top Wall (y=L, u=1 -> Moving Lid)
    % psi_inside is psi(end-1, :), u_wall = 1
    omega(end, :) = -2 * (psi(end-1, :) + dy * 1) / dy^2; 
    
    % Left Wall (x=0, v=0)
    omega(:, 1) = -2 * psi(:, 2) / dx^2;
    
    % Right Wall (x=L, v=0)
    omega(:, end) = -2 * psi(:, end-1) / dx^2;
    
    % 4. Solve Vorticity Transport Equation
    % d(omega)/dt + u*d(omega)/dx + v*d(omega)/dy = (1/Re) * del^2 omega
    
    % Compute derivatives (Central difference)
    omega_mid = omega(2:end-1, 2:end-1);
    
    domega_dx = (omega(2:end-1, 3:end) - omega(2:end-1, 1:end-2)) / (2*dx);
    domega_dy = (omega(3:end, 2:end-1) - omega(1:end-2, 2:end-1)) / (2*dy);
    
    lap_omega = (omega(2:end-1, 3:end) - 2*omega_mid + omega(2:end-1, 1:end-2)) / dx^2 + ...
                (omega(3:end, 2:end-1) - 2*omega_mid + omega(1:end-2, 2:end-1)) / dy^2;
            
    % Update interior vorticity (Explicit Euler)
    omega(2:end-1, 2:end-1) = omega_mid + dt * ( ...
        -(u(2:end-1, 2:end-1) .* domega_dx + v(2:end-1, 2:end-1) .* domega_dy) + ...
        (1/Re) * lap_omega );
    
    % --- Visualization ---
    if mod(n, plot_interval) == 0
        % Calculate velocity magnitude
        vel_mag = sqrt(u.^2 + v.^2);
        
        clf;
        contourf(X, Y, vel_mag, 20, 'LineColor', 'none');
        hold on;
        % Plot streamlines
        contour(X, Y, psi, 20, 'k');
        % Plot velocity vectors (subsampled)
        quiver(X(1:2:end, 1:2:end), Y(1:2:end, 1:2:end), ...
               u(1:2:end, 1:2:end), v(1:2:end, 1:2:end), 'w');
        hold off;
        
        colormap('jet');
        colorbar;
        title(sprintf('Lid Driven Cavity (Re=%d), Time=%.2f', Re, n*dt));
        xlabel('x'); ylabel('y');
        axis equal; axis([0 L 0 L]);
        drawnow;

        % Capture frame for video
        frame = getframe(gcf);
        writeVideo(vidObj, frame);
    end
end

close(vidObj);
fprintf('Simulation complete.\n');
