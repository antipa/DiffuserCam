% [xhat,f] = DiffuserCam_main('DiffuserCam_settings_Linda.m',psf);
impulse_mat_file_name = 'D:\Linda\180830_2um beads\calib\2um\lowlight\hstack.mat';
impulse_var_name = 'hstack';

% T: for Schwarz; D: for Lavanhn 
% input_folder='D:\Linda\180814_thermo calib and worm video\res\50um_step\Pos0';
image_file = 'D:\Linda\180814_thermo calib and worm video\live worm\worm1\video3\video3_MMStack_Pos0_layers\video3_MMStack_Pos0.ome00000001.tif';  %This will have image_bias subtracted, and be resized to the downsampled impulse stack size using a 'box' filter

%Folder for saving state. If it doesn't exist, create it. 
solverSettings.save_dir = 'D:\Linda\180828_res tgt\grating\2.5um\processed';
solverSettings.save_every = 0;   %Save image stack as .mat every N iterations. Use 0 to never save (except for at the end);
save_results = 0;  %result will only be saved at the end of processing
save_settings = 0; %save configure file or not

% Strip / from path if used
color_to_process = 'mono';  %'red'xi,'green','blue', or 'mono'. If raw file is mono, this is ignored
psf_bias = 80; %If camera has bias, subtract from measurement file. the value depends on many factors, like exposure time. 
image_bias = 100;   %If PsiTWcamera has bias, subtract from measurement file. 
lateral_downsample = 4;  %factor to downsample impulse stack laterally. Must be multiple of 2 and >= 1.
axial_downsample = 1;  % Axial averageing of impulse stack. Must be multiple of 2 and >= 1.
 
% Allow user to use subset of Z. This is computed BEFORE downsampling by a
% factor of AXIAL_DOWNSAMPLE
start_z = 1;  %First plane to reconstruct. 1 indexed, as is tradition.
end_z = 0;   %Last plane to reconstruct. If set to 0, use last plane in file.
 
 
% Populate solver options
 
% Solver parameters
solverSettings.tau = .001;    %sparsity parameter for TV
% defaults: tau = .0004;
solverSettings.tau_n = 0.005;     %sparsity param for native sparsity
solverSettings.mu1 = .21;    %Initialize ADMM tuning params. If autotune is on, these will change
solverSettings.mu2 = .81;
solverSettings.mu3 = 6.2;
 
 
% if set to 1, auto-find mu1, mu2, mu3 every step. If set to 0, use user defined values. If set to N>1, tune for N steps then stop.
solverSettings.autotune = 1;    % default: 1
solverSettings.mu_inc = 1.1; %1.1;  % 
solverSettings.mu_dec = 1.1; %1.1;  %Inrement and decrement values for mu during autotune. Turn to 1 to have no tuning.
solverSettings.resid_tol = 1.5;   % Primal/dual gap tolerance. Lower means more frequent tuning
solverSettings.maxIter = 300; % Maximum iteration count  Default: 200
solverSettings.regularizer = 'tv';   %'TV' for 3D TV, 'native' for native. Default: TV
solverSettings.cmap = 'parula';%'gray','hot','parula'

%Figures and user info
solverSettings.disp_auto = 1 ; %set 1 to use auto disp_percentile, set 0 to manully set caxis
solverSettings.disp_percentile = 99.99;   %Percentile of max to set image scaling
solverSettings.colormap_axis = [0 2.5e+5]; 

%Display and save
solverSettings.disp_crop = @(x)gather(x(floor(size(x,1)*1/4):floor(size(x,1)*3/4),...
    floor(size(x,2)*1/4):floor(size(x,2)*3/4),:));
solverSettings.disp_func = @(x)x;  %Function handle to modify image before display. No change to data, just for display purposes
solverSettings.disp_figs = 1;   %If set to 0, never display. If set to N>=1, show every N.
solverSettings.xy_draw = 'sum'; % choose from 'sum' or 'max' projection
solverSettings.print_interval = 1;  %Print cost every N iterations. Default 1. If set to 0, don't print.
fig_num = 1;   %Figure number to display in
solverSettings.gpu=1; %set 1 to use only GPU, set 0 to use only CPU, set 0.5 to use both
solverSettings.normalization = 1; % set 1 to normalize each psf
solverSettings.padFracY = 0.5; %set 0 to not use pad/crop, set .5 to use 1x padding
solverSettings.padFracX = 0.5; %set 0 to not use pad/crop
%center matrix size shoule be times of downsampling rate
center = [232,1783,267,1818]; %set (1,2048,1,2048) if use whole sensor. 
solverSettings.crop_circle = 0; %set 1 to crop circle
solverSettings.ci =[770,770,740]/lateral_downsample; %center and radius of circle ([c_row, c_col, r]), axis based on center cropped, downsampled image
solverSettings.update_order = 1; %set 1 to update duals first, then update parameters
%if choose "xhat", [xhat,f] = DiffuserCam_main('DiffuserCam_settings',psf,xhat);
solverSettings.initialization = 'zero'; %set to "zero" or "xhat". 
