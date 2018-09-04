function [xhat, f] = DiffuserCam_main(config,psf,init)
% Solve for image from DiffuserCam. First rev: 3D ADMM only. 
% CONFIG: String with path to settings file. See DiffuserCam_settings.m for
% details.

% Read in settings
run(config); %This should be a string path to a .m script that populates a bunch of variables in your workspace
%image_file = [input_folder,'\video3_MMStack_Pos0.ome00000',num2str(layer,'%03d'),'.tif'] ;
% out_file = [solverSettings.save_dir,'\layer_',num2str(layer)];


%Make figure handle
if solverSettings.disp_figs ~= 0
    solverSettings.fighandle = figure(fig_num);
    clf
end

if (lateral_downsample < 1)
    error('lateral_downsample must be >= 1')
end
if (axial_downsample < 1 )
    error('axial_downsample must be >= 1')
end

%% Load and prepare impulse stack
if ~exist('psf')
    psf = load(impulse_mat_file_name,impulse_var_name);
    psf = psf.(impulse_var_name);
end

% Get impulse dimensions
[~,~, Nz_in] = size(psf);

if end_z == 0 || end_z > Nz_in
    end_z = Nz_in;
end
psf = psf(:,:,start_z:end_z);

%crop the center, subtract bias
psf = psf(center(1):center(2),center(3):center(4),:);   %use half sensor
psf = psf -psf_bias;

% non-uniform axial downsampling
% cut=30;
% psf1 = psf(:,:,5:cut-1);
% psf2 = psf(:,:,cut:4:136);
% psf=cat(3,psf1,psf2);
% clear psf1 psf2


% Do downsampling
for n = 1:log2(lateral_downsample)
    psf = 1/4*(psf(1:2:end,1:2:end,:)+psf(1:2:end,2:2:end,:) + ...
        psf(2:2:end,1:2:end,:) + psf(2:2:end,2:2:end,:));
end

for n = 1:log2(axial_downsample)
    psf = 1/2*(psf(:,:,1:2:end)+psf(:,:,2:2:end));
end

[Ny, Nx, Nz] = size(psf);

% Normalize each slice
psfn = zeros(Nz,1); %record norm of each slice, multiply each slice in the end
if solverSettings.normalization
    psf = single(psf);
    for n = 1:Nz
        psfn(n) = norm(psf(:,:,n),'fro');
        psf(:,:,n) = psf(:,:,n)/psfn(n);
    end
end
solverSettings.psfn=psfn;
clear psfn

%% initialization
switch lower(solverSettings.initialization) 
    case('zero')
        vk = 0*psf;
    case('xhat')
        vk = init;
end

%% Load image file and adjust to impulse size.
raw_in = imread(image_file);
raw_in = raw_in - image_bias;
switch color_to_process
    case 'red'; colind = 1;
    case 'green'; colind = 2;
    case 'blue'; colind = 3;
end


if numel(size(image_file)) == 3
    if strcmpi(color_to_process,'mono')
        imc = mean(double(raw_in),3);
    else
        imc = double(raw_in(:,:,colind));
    end
else
    imc = double(raw_in);
end

b = imc(center(1):center(2),center(3):center(4)); %use sensor centor
clear imc raw_in
b = imresize(b,[Ny, Nx],'box');
b = b/max(b(:));  %Normalize to 16-bit range

%% Solver stuff
switch solverSettings.regularizer
    case('native')
        out_file = [solverSettings.save_dir,'\state_',num2str(solverSettings.maxIter),'soft_tau_',num2str(solverSettings.tau_n)];
    case('tv')
        out_file = [solverSettings.save_dir,'\state_',num2str(solverSettings.maxIter),'tv_tau_',num2str(solverSettings.tau)];
end
dtstamp = datestr(datetime('now'),'YYYYmmDD_hhMMss');
if exist([out_file,'.mat'],'file')
    fprintf('file already exists. Adding datetime stamp to avoid overwriting. \n');
    out_file = [out_file,'_',dtstamp];
end
if solverSettings.save_dir(end) == '/'
    solverSettings.save_dir = solverSettings.save_dir(1:end-1);
end
if ~exist(solverSettings.save_dir,'dir')
    mkdir(solverSettings.save_dir);
end
    
if solverSettings.gpu==1
    [xhat, f] = ADMM3D_solver(gpuArray(single(psf)),gpuArray(single(b)),gpuArray(single(vk)),solverSettings);
elseif solverSettings.gpu==0
    [xhat, f] = ADMM3D_solver(single(psf),single(b),single(vk),solverSettings);
elseif solverSettings.gpu==0.5 && solverSettings.update_order==1
    [xhat, f] = ADMM3D_solver_huge(single(psf),single(b),single(vk),solverSettings);
elseif solverSettings.gpu==0.5 && solverSettings.update_order==0
    [xhat, f] = ADMM3D_solver_huge2(single(psf),single(b),single(vk),solverSettings);
end


if save_results==1 && solverSettings.save_every==0
    %Setup output folder
    xhat_out = gather(xhat);
    if solverSettings.normalization  %multiply normalization back
        xhat_out = bsxfun(@times,xhat_out,reshape(solverSettings.psfn,1,1,[]));
    end
    save([out_file,'.mat'],'xhat_out','b','f');   %Save result
    saveas(gcf,[out_file,'.png']);
    saveas(gcf,[out_file,'.fig']);
end
if save_settings
    slashes = strfind(config,'/');
    if ~isempty(slashes)
        config_fname = config(slashes(end)+1:end-2);
    else
        config_fname = config(1:end-2);
    end
    switch solverSettings.regularizer
    case('native')
        copyfile(config,[solverSettings.save_dir,'\',config_fname,'_','state_',num2str(solverSettings.maxIter),'soft_tau_',num2str(solverSettings.tau_n),'.m'])
    case('tv')
        copyfile(config,[solverSettings.save_dir,'\',config_fname,'_','state_',num2str(solverSettings.maxIter),'tv_tau_',num2str(solverSettings.tau),'.m'])
    end
end