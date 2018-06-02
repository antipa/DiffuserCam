%impulse_mat_file_name = '~/Documents/randn_psf.mat';
%impulse_mat_file_name = 'Y:\Diffusers''nstuff\miniscope3D\Sims\lenslets_miniscope_zemax_stack.mat';

%impulse_mat_file_name = './example_data/example_psfs.mat';
impulse_mat_file_name = 'Y:\Diffusers''nstuff\3D_Calibration\zstack_dense_pco_good.mat';
%impulse_mat_file_name = 'Y:\Diffusers''nstuff\miniscope3D\hstack.mat';
%impulse_var_name = 'hstack';
impulse_var_name = 'zstack';
%image_file = './example_data/example_raw.png';  %This will have image_bias subtracted, and be resized to the downsampled impulse stack size using a 'box' filter
image_file = 'Y:\Diffusers''nstuff\3d_images_to_process\usaf_tilt_reverse_mono.png';
%image_file = 'Y:\Diffusers''nstuff\miniscope3D\Sims\zebrafish_lenslets_sparsest.png';
%image_file = 'Y:\Diffusers''nstuff\miniscope3D\ZebrafishVideoFramesbckSub\80.png';
%image_file = 'Y:\Diffusers''nstuff\miniscope3D\data\AnimalData\Zebrafish\H14_M13_S32_strong-flash\video_variance.png';
color_to_process = 'mono';  %'red','green','blue', or 'mono'. If raw file is mono, this is ignored
image_bias = 100;   %If camera has bias, subtract from measurement file. 
psf_bias = 108;   %if PSF needs sensor bias removed, put that here.
lateral_downsample = 4;  %factor to downsample impulse stack laterally. Must be multiple of 2 and >= 1.
axial_downsample = 2;  % Axial averageing of impulse stack. Must be multiple of 2 and >= 1.
 
% Allow user to use subset of Z. This is computed BEFORE downsampling by a
% factor of AXIAL_DOWNSAMPLE
start_z = 65;  %First plane to reconstruct. 1 indexed, as is tradition.
end_z =128;   %Last plane to reconstruct. If set to 0, use last plane in file.
 
 
% Populate solver options
 
% Solver parameters
solverSettings.tau = .000800;    %sparsity parameter for TV
solverSettings.tau_n = .00500;     %sparsity param for native sparsity
solverSettings.mu1 = .19;    %Initialize ADMM tuning params. If autotune is on, these will change
solverSettings.mu2 = .6;
solverSettings.mu3 = .4;
 
 
% if set to 1, auto-find mu1, mu2, mu3 every step. If set to 0, use user defined values. If set to N>1, tune for N steps then stop.
solverSettings.autotune = 1;    % default: 1
solverSettings.mu_inc = 1.5; %1.1;  % 
solverSettings.mu_dec = 1.5; %1.1;  %Inrement and decrement values for mu during autotune. Turn to 1 to have no tuning.
solverSettings.resid_tol = 2;   % Primal/dual gap tolerance. Lower means more frequent tuning
solverSettings.maxIter = 5000; % Maximum iteration count  Default: 200
solverSettings.regularizer = 'tv_native';   %'TV' for 3D TV, 'native' for native. Default: TV
solverSettings.cmap = 'gray';
%Figures and user info
solverSettings.disp_percentile = 99.99;   %Percentile of max to set image scaling
solverSettings.save_every = 0;   %Save image stack as .mat every N iterations. Use 0 to never save (except for at the end);
if solverSettings.save_every
    warning(' save_every is not enabled yet. Your result will only be saved at the end of processing.')
end
%Folder for saving state. If it doesn't exist, create it. 
solverSettings.save_dir = '../';
% Strip / from path if used

solverSettings.disp_crop = @(x)gather(x(floor(size(x,1)/4):floor(size(x,1)*3/4),...
    floor(size(x,2)/4):floor(size(x,2)*3/4),:));
solverSettings.disp_func = @(x)x;  %Function handle to modify image before display. No change to data, just for display purposes
solverSettings.disp_figs = 5;   %If set to 0, never display. If set to N>=1, show every N.
solverSettings.print_interval = 5;  %Print cost every N iterations. Default 1. If set to 0, don't print.
fig_num = 2;   %Figure number to display in
save_results = 0;


