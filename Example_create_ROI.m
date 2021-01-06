
coordinate = [0 20 30]'; % center coordinate
sphere = 6; % radius, in mm
vol = spm_vol('func.nii,1'); % need a image to define the image space
[Y, XYZ] = spm_read_vols(vol);
maskvol = spm_vol('mask.nii'); % better to use a mask
mask = spm_read_vols(maskvol);
maskidx = mask(:)>0;
XYZmasked = XYZ(:, maskidx);
Q = ones(1,size(XYZmasked,2));
% 'sphere'
idx = find(sum((XYZmasked - coordinate*Q).^2) <= sphere^2);

% 'box'
% idx  = find(all(abs(XYZmasked - coordinates*Q) <= sphere(:)*Q/2));

ROI = zeros(1, size(XYZmasked, 2));
ROI(idx) = 1;

%% write out the ROI image
% Y = Y.*0;
% Y(maskidx) = ROI;
% maskvol.fname = 'ROI.nii';
% spm_write_vol(maskvol, Y);

    
    