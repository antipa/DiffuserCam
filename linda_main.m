for layer=1:100
    [xhat,f] = DiffuserCam_main('DiffuserCam_settings_lahvahn.m',hstack(:,:,75:132),layer);
end

