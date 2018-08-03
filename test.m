tic

            v5=gpuArray(nukp - xi/mu1);
            v6=mu1*Hadj(v5); %3 item
            clear v5
            v0=mu3*gpuArray(wkp-rho/mu3); %1 item
            v1=gpuArray(uk1 - eta_1/mu2);v2=gpuArray(uk2 - eta_2/mu2);v3=gpuArray(uk3 - eta_3/mu2);
            v4=mu2*PsiT(v1,v2,v3); %2 item
            clear v1 v2 v3
            vkp_numerator = gather(v0+v4+v6);
            clear v0 v4 v6
toc