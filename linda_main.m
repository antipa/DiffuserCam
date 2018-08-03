xhat_out = uint16(65535*(xhat/max(xhat(:))));
for layer=7:16
    imout = xhat_out(:,:,layer);
    imwrite(imout,['\\WALLER-PHANTOM\PhantomData\Diffusers''nstuff\Big_DiffuserMicroscope\180606_worm\1worm',...
        '\-20\-20\processed\img_000000008_layer',num2str(layer),'.tif'])
end
