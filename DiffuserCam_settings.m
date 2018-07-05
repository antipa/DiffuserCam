%impulse_mat_file_name = '~/Documents/randn_psf.mat';
%impulse_mat_file_name = 'Y:\Diffusers''nstuff\miniscope3D\Sims\lenslets_miniscope_zemax_stack.mat';

impulse_mat_file_name = './example_data/zstack_270_320_44_4github.mat';
%impulse_mat_file_name = 'Y:\Diffusers''nstuff\3D_Calibration\zstack_270_320_44_4github.mat';
%impulse_mat_file_name = 'C:\Users\nick\Documents\MATLAB\DiffuserCam-Dev\example_data\example_psfs.mat';
%impulse_mat_file_name = 'Y:\Diffusers''nstuff\3D_Calibration\pco_dense_corrected_mono_2xds.mat';
%impulse_mat_file_name = 'Y:\Diffusers''nstuff\miniscope3D\hstack.mat';
%impulse_var_name = 'hstack';
impulse_var_name = 'psf';
%image_file = './example_data/example_raw.png';  %This will have image_bias subtracted, and be resized to the downsampled impulse stack size using a 'box' filter
%image_file = 'Y:\Diffusers''nstuff\3D_Calibration\usaf_tilt_4github.png';
image_file = 'Y:\Diffusers''nstuff\3d_images_to_process\flowers_near_top_halfds_mono.png';
image_file = './example_data/usaf_tilt_4github.png';
%image_file = 'Y:\Diffusers''nstuff\miniscope3D\Sims\zebrafish_lenslets_sparsest.png';
%image_file = 'Y:\Diffusers''nstuff\miniscope3D\ZebrafishVideoFramesbckSub\80.png';
%image_file = 'Y:\Diffusers''nstuff\miniscope3D\data\AnimalData\Zebrafish\H14_M13_S32_strong-flash\video_variance.png';
color_to_process = 'mono';  %'red','green','blue', or 'mono'. If raw file is mono, this is ignored
image_bias = 100;   %If camera has bias, subtract from measurement file. 
psf_bias = 102;   %if PSF needs sensor bias removed, put that here.
lateral_downsample = 1;  %factor to downsample impulse stack laterally. Must be multiple of 2 and >= 1.
axial_downsample = 1;  % Axial averageing of impulse stack. Must be multiple of 2 and >= 1.
 
% Allow user to use subset of Z. This is computed BEFORE downsampling by a
% factor of AXIAL_DOWNSAMPLE
start_z = 1;  %First plane to reconstruct. 1 indexed, as is tradition.
end_z = 0;   %Last plane to reconstruct. If set to 0, use last plane in file.
 
 
% Populate solver options
 
% Solver parameters
solverSettings.tau = .00200;    %sparsity parameter for TV
% defaults: tau = .0004;
solverSettings.tau_n = .0400;     %sparsity param for native sparsity
solverSettings.mu1 = .21;    %Initialize ADMM tuning params. If autotune is on, these will change
solverSettings.mu2 = .5;
solverSettings.mu3 = 6;

%solverSettings.mu1 = .21;    %Initialize ADMM tuning params. If autotune is on, these will change
%solverSettings.mu2 = 3;
%solverSettings.mu3 = 6;
 
% if set to 1, auto-find mu1, mu2, mu3 every step. If set to 0, use user defined values. If set to N>1, tune for N steps then stop.
solverSettings.autotune = 1;    % default: 1
solverSettings.mu_inc = 1.01; %1.1;  % 
solverSettings.mu_dec = 1.01; %1.1;  %Inrement and decrement values for mu during autotune. Turn to 1 to have no tuning.
solverSettings.resid_tol = 1.1;   % Primal/dual gap tolerance. Lower means more frequent tuning
solverSettings.maxIter = 5000; % Maximum iteration count  Default: 200
solverSettings.regularizer = 'tv';   %'TV' for 3D TV, 'native' for native. Default: TV
solverSettings.cmap = 'gray';
%Figures and user info
solverSettings.disp_percentile = 100;   %Percentile of max to set image scaling
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
solverSettings.disp_figs = 20;   %If set to 0, never display. If set to N>=1, show every N.
solverSettings.print_interval = 20;  %Print cost every N iterations. Default 1. If set to 0, don't print.
fig_num = 1;   %Figure number to display in
save_results = 0;


