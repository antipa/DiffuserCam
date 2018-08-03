% xhat = DiffuserCam_main('DiffuserCam_settings_Linda.m',psf);
% impulse_mat_file_name = 'T:\Linda\180718_calib and worm\1um_calib\1um_sub0.75bg\1um_sub0.75bg.mat';
% impulse_var_name = 'hstack_sub';

% T: for Schwarz; D: for Lavanhn 
image_file = 'T:\Linda\180718_calib and worm\worm\20um_step\20um\Pos0\img_000000000_Default_016.tif';  %This will have image_bias subtracted, and be resized to the downsampled impulse stack size using a 'box' filter

%Folder for saving state. If it doesn't exist, create it. 
solverSettings.save_dir = 'T:\Linda\180718_calib and worm\worm\processed';

% Strip / from path if used
color_to_process = 'mono';  %'red'xi,'green','blue', or 'mono'. If raw file is mono, this is ignored
psf_bias = 0; %If camera has bias, subtract from measurement file.
image_bias = 100;   %If PsiTWcamera has bias, subtract from measurement file. 
lateral_downsample = 1;  %factor to downsample impulse stack laterally. Must be multiple of 2 and >= 1.
axial_downsample = 1;  % Axial averageing of impulse stack. Must be multiple of 2 and >= 1.
 
% Allow user to use subset of Z. This is computed BEFORE downsampling by a
% factor of AXIAL_DOWNSAMPLE
start_z = 1;  %First plane to reconstruct. 1 indexed, as is tradition.
end_z = 0;   %Last plane to reconstruct. If set to 0, use last plane in file.
 
 
% Populate solver options
 
% Solver parameters
solverSettings.tau = .005;    %sparsity parameter for TV
% defaults: tau = .0004;
solverSettings.tau_n = 0.0005;     %sparsity param for native sparsity
solverSettings.mu1 = .23;    %Initialize ADMM tuning params. If autotune is on, these will change
solverSettings.mu2 = .81;
solverSettings.mu3 = 3;
 
 
% if set to 1, auto-find mu1, mu2, mu3 every step. If set to 0, use user defined values. If set to N>1, tune for N steps then stop.
solverSettings.autotune = 1;    % default: 1
solverSettings.mu_inc = 1.1; %1.1;  % 
solverSettings.mu_dec = 1.1; %1.1;  %Inrement and decrement values for mu during autotune. Turn to 1 to have no tuning.
solverSettings.resid_tol = 1.5;   % Primal/dual gap tolerance. Lower means more frequent tuning
solverSettings.maxIter = 1000; % Maximum iteration count  Default: 200
solverSettings.regularizer = 'TV';   %'TV' for 3D TV, 'native' for native. Default: TV
solverSettings.cmap = 'gray';

%Figures and user info
solverSettings.disp_percentile = 99.99;   %Percentile of max to set image scaling
solverSettings.save_every = 0;   %Save image stack as .mat every N iterations. Use 0 to never save (except for at the end);
if solverSettings.save_every
    warning(' save_every is not enabled yet. Your result will only be saved at the end of processing.')
end

%Display and save
solverSettings.disp_crop = @(x)gather(x(floor(size(x,1)/4):floor(size(x,1)*3/4),...
    floor(size(x,2)/4):floor(size(x,2)*3/4),:));
solverSettings.disp_func = @(x)x;  %Function handle to modify image before display. No change to data, just for display purposes
solverSettings.disp_figs = 10;   %If set to 0, never display. If set to N>=1, show every N.
solverSettings.print_interval = 1;  %Print cost every N iterations. Default 1. If set to 0, don't print.
fig_num = 1;   %Figure number to display in
save_results = 1;

solverSettings.pad=0; %set 1 to use pad/crop
solverSettings.gpu=0.5; %set 1 to use only GPU, set 0 to use only CPU, set 0.5 to use both
solverSettings.normalization = 1; % set 1 to normalize each psf
solverSettings.center = [230,1781,265,1816]; %set (1,2048,1,2048) if use whole sensor