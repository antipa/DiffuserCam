for layer=208:400
    layer
    [xhat,f] = DiffuserCam_main('DiffuserCam_settings_azul.m',hstack(:,:,75:132),layer);
end

