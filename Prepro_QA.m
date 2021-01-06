function Prepro_QA(datadir, threshold, task)
% datadir: preprocessed data
% threshold: define outliers based on FD (default:0.5)
% task: name of the task fMRI data you would like to preprocess, if
% not specified, use all of the data in the func folder
%
% the Carpet plot (Power 2016) is adapted from Stephan Heunis's script
% https://github.com/jsheunis/matlab-spm-scripts-jsh/blob/master/thePlotSpm.m
% By default this script uses the realigned (unwarped) and slice timing corrected data for the
% plot
% you can also plot e.g. the smoothed raw data (see corresponding commented part for an example)


% Written by Feng Zhou, 12/27/2020
if nargin <2 || isempty(threshold)
    threshold = 0.5; % very arbitary threshold
end
if nargin < 3
    task = [];
end
MNI152 = which('MNI152_T1_2mm.nii');
subjfolders = dir(fullfile(datadir,'*'));
issub = [subjfolders(:).isdir]; 
namesubs = {subjfolders(issub).name}';
namesubs(ismember(namesubs,{'.','..'})) = [];
nsub = length(namesubs);
QAdir = fullfile(datadir, 'PicForQA');
if ~exist(QAdir,'dir')
    mkdir(QAdir)
end
funcimgs = cell(0,1);
maxtrans = [];
maxrot = [];
nFD_outliers = [];
intensity_scale = [-6 6];
for ii=1:nsub
    subname=namesubs{ii,1};
    subdir = fullfile(datadir, subname);
    subfuncdir = fullfile(subdir, 'func');
    subantdir = fullfile(subdir, 'anat');
    unprepro = spm_select('List',subfuncdir,['^sub-.*',task, '.*nii$']);
    subfuncimgs = cellstr(unprepro(:, 1:end-9));
    funcimgs = [funcimgs; subfuncimgs];
    normalized_anatomy = fullfile(subdir, 'anat','wt_Brain.nii');
    wimages = spm_select('List',subfuncdir,['^wt.*', task, '.*nii$']);
    rpfiles = spm_select('FPList',subfuncdir,['^rp.*',task,'.*txt$']);
    nRuns = size(wimages, 1);
    
    %% coregister segments to functional space
    clear matlabbatch
    meanimg = spm_select('FPList',subfuncdir,'^mean.*nii$');
    T1wimg = spm_select('FPList',subantdir,'^sub.*T1w.nii$');
    matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {meanimg};
    matlabbatch{1}.spm.spatial.coreg.estwrite.source = {T1wimg};
    matlabbatch{1}.spm.spatial.coreg.estwrite.other = cellstr(spm_select('FPList',subantdir,'^c[123].*nii$'));
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask = 0;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';
    spm_jobman('run', matlabbatch);
    
    subTPM = spm_select('FPList',subantdir,'^rc[123].*nii$');
    [GM_img_bin, WM_img_bin, CSF_img_bin] = createBinarySegments(subTPM(1,:), subTPM(2,:), subTPM(3,:), 0.1);
    I_GM = find(GM_img_bin);
    I_WM = find(WM_img_bin);
    I_CSF = find(CSF_img_bin);
    mask_reshaped = GM_img_bin | WM_img_bin | CSF_img_bin;
    I_mask = find(mask_reshaped);  

    for jj = 1:nRuns
       %% plot normalization
        wimage = spm_select('ExtFPList', subfuncdir, ['^',wimages(jj,:)]);
        nwimage = size(wimage,1);
        normalized_EPI = wimage(ceil(nwimage/2),:);
        spm_check_registration(normalized_EPI,normalized_anatomy,MNI152);
        spm_ov_contour('display',1,NaN)
        spm_orthviews('reposition', [0 0 0]);
        print(gcf, '-dtiff', '-r200',fullfile(QAdir, ['Norm_',subfuncimgs{jj}]))
        close all
        
       %% plot head movement
        rpfile = rpfiles(jj,:);
        printfig = figure;
        RP = load(rpfile);
        headmovement = [];
        headmovement(:,1:3) = RP(:,1:3);
        headmovement(:,4:6) = RP(:,4:6)*180/pi;
        
        maxtrans = [maxtrans; max(max(abs(headmovement(:,1:3))))];
        maxrot = [maxrot; max(max(abs(headmovement(:, 4:6))))];
        
        subplot(2,1,1);
        plot(headmovement(:,1:3));
        ylim([min(min(headmovement(:,1:3))), max(max(headmovement(:,1:3)))])
        xlim([0, size(RP, 1)])
        grid on;
        title('Motion: shifts (top, in mm), rotations (middle, in degree) and FD (bottom)', 'interpreter', 'none');
        subplot(2,1,2);
        plot(headmovement(:,4:6));
        ylim([min(min(headmovement(:,4:6))), max(max(headmovement(:,4:6)))])
        xlim([0, size(RP, 1)])
        grid on;
        print(printfig, '-dtiff', '-r200',fullfile(QAdir, ['RP_',subfuncimgs{jj}]));
        close all
        
       %% (smooth,) detrend and calculate PSC
%         clear matlabbatch
%         matlabbatch{1}.spm.spatial.smooth.data = cellstr(spm_select('ExtFPList', subfuncdir, ['^',unprepro(kk,:)]));
%         matlabbatch{1}.spm.spatial.smooth.fwhm = [6 6 6];
%         matlabbatch{1}.spm.spatial.smooth.dtype = 0;
%         matlabbatch{1}.spm.spatial.smooth.im = 0;
%         matlabbatch{1}.spm.spatial.smooth.prefix = 'plot_';
%         spm_jobman('run', matlabbatch);
%         datatoplot = spm_read_vols(spm_vol(spm_select('ExtFPList', subfuncdir,['plot_',unprepro(kk,:)])));
        
        datatoplot = spm_read_vols(spm_vol(spm_select('ExtFPList', subfuncdir,['^u_a_',unprepro(jj,:)])));
        [Ni,Nj,Nk, Nt] = size(datatoplot);
        F_2D = reshape(datatoplot, Ni*Nj*Nk, Nt);
        mean_2D = repmat(mean(F_2D), Ni*Nj*Nk, 1);
%         F_detrended = spm_detrend(F_2D, 1)+mean_2D;% remove linear and quadratic trends only 
        F_detrended = spm_detrend(F_2D, 2); %remove mean, linear and quadratic trends

        % Mask, mean and PSC
        F_masked = F_detrended(I_mask, :);
        F_mean = mean(F_masked, 2);
        F_masked_psc = 100*(F_masked./repmat(F_mean, 1, Nt)) - 100;
        F_masked_psc(isnan(F_masked_psc))=0;
        F_psc_img = zeros(Ni, Nj, Nk, Nt);
        F_2D_psc = reshape(F_psc_img, Ni*Nj*Nk, Nt);
        F_2D_psc(I_mask, :) = F_masked_psc;
        
       %% plot FD        
        printfig = figure;
        FDplot = subplot(5,1,1);
        head = 50; % default in Power paper 
        RP(:,4:6) = head*RP(:,4:6);
        % differentiate movement parameters
        delta_mov = [zeros(1,size(RP,2));diff(RP)];
        FD = sum(abs(delta_mov),2);
        FD_outliers = find(FD>threshold);
        noutlier = length(FD_outliers);
        nFD_outliers = [nFD_outliers;noutlier];
        plot(FD);
        hold on
        grid on;
        min_FD = min(FD);
        max_FD = max(FD);
        if noutlier>0
            for nn = 1:noutlier
                plot([FD_outliers(nn), FD_outliers(nn)], [min_FD, max_FD], 'r-');
            end
        end
        ylim([min_FD, max_FD])
        xlim([0, size(RP, 1)])
        title('FD')
        ylabel('mm')
        set(FDplot,'Xticklabel',[]);
        %% Power the plot
        % Create image to plot by concatenation
        GM_img = F_2D_psc(I_GM, :);
        WM_img = F_2D_psc(I_WM, :);
        CSF_img = F_2D_psc(I_CSF, :);
        all_img = [GM_img; WM_img; CSF_img];
        % Identif limits between the different tissue compartments
        line1_pos = numel(I_GM);
        line2_pos = numel(I_GM) + numel(I_WM);
        
        subplot(5,1,2:5);
        imagesc(all_img);
        colormap(gray);
        caxis(intensity_scale);
        title('Carpet Plot')
        ylabel('Voxels')
        xlabel('fMRI volumes')
        hold on;
        line([1 Nt],[line1_pos line1_pos],  'Color', 'b', 'LineWidth', 2 )
        line([1 Nt],[line2_pos line2_pos],  'Color', 'r', 'LineWidth', 2 )
        xlim([0, size(RP, 1)])
        hold off;
        print(printfig, '-dtiff', '-r200',fullfile(QAdir, ['Power_',subfuncimgs{jj}]));
        close all
    end
end

save(fullfile(QAdir, 'MaxMotion.mat'),'-mat','maxtrans', 'maxrot','funcimgs','nFD_outliers')

header = {'func_img', 'MaxShift','MaxRotation', 'FDoutliers'};
xlswrite(fullfile(QAdir,'Motion.xlsx'), header, 1, 'A1')
xlswrite(fullfile(QAdir,'Motion.xlsx'), funcimgs, 1, 'A2')
xlswrite(fullfile(QAdir,'Motion.xlsx'),maxtrans, 1, 'B2')
xlswrite(fullfile(QAdir,'Motion.xlsx'),maxrot, 1, 'C2')
xlswrite(fullfile(QAdir,'Motion.xlsx'),nFD_outliers, 1, 'D2')
end

