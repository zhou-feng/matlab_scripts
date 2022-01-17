function Prepro_QA_simple(datadir, threshold, task)
% datadir: preprocessed data
% threshold: define outliers based on FD (default:0.5)
% task: name of the task fMRI data you would like to preprocess, if
% not specified, use all of the data in the func folder
%
%
% Written by Feng Zhou, 12/27/2020
if nargin <2 || isempty(threshold)
    threshold = 0.5; % very arbitary FD threshold
end
if nargin < 3
    task = [];
end
MNI152 = which('MNI152_T1_2mm_brain.nii');
subjfolders = dir(fullfile(datadir,'*'));
issub = [subjfolders(:).isdir]; 
namesubs = {subjfolders(issub).name}';
namesubs(ismember(namesubs,{'.','..'})) = [];
QAdir = fullfile(datadir, 'PicForQA');
[lia, locb] = ismember('PicForQA', namesubs);
if lia
    namesubs(locb) = [];
else
    mkdir(QAdir)
end
nsub = length(namesubs);
funcimgs = cell(0,1);
maxtrans = [];
maxrot = [];
noutlier_FD = [];
for ii=1:nsub
    subname=namesubs{ii,1};
    subdir = fullfile(datadir, subname);
    subfuncdir = fullfile(subdir, 'func');
    imgs = spm_select('List',subfuncdir,['^sub-.*',task, '.*nii$']);
    subfuncimgs = cell(size(imgs,1), 1);
    for kk = 1:size(imgs, 1)
        imgname = imgs(kk,:);
        imgname = strsplit(imgname, '_bold');
        subfuncimgs(kk) = imgname(1);
    end
    funcimgs = [funcimgs; subfuncimgs];
    normalized_anatomy = fullfile(subdir, 'anat','wBrain.nii');
    wimages = spm_select('List',subfuncdir,'^wua.*nii$');
    rpfiles = spm_select('FPList',subfuncdir,'^rp.*txt$');
    nRuns = size(wimages, 1);

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
        
        % derivative 24
        derivative = [zeros(1, 6); diff(headmovement)];
        derivative24 = [headmovement, derivative, headmovement.^2, derivative.^2];
        
        % FD Power
        head = 50; % default in Power paper 
        RP(:,4:6) = head*RP(:,4:6);
        % differentiate movement parameters
        delta_mov = [
            zeros(1,size(RP,2));
            diff(RP);
            ];
        FD = sum(abs(delta_mov),2);
        FD_outliers = find(FD>threshold);
        noutliers = length(FD_outliers);  
        spikes = zeros(size(RP, 1),noutliers);
         if noutliers>0
             for kk = 1:noutliers
                 spikes(FD_outliers(kk), kk) = 1;
             end
         end
        
        derivative24_spikes = [derivative24, spikes];
        save(fullfile(subfuncdir, ['Derivative24_spike_',subfuncimgs{jj},'.txt']), 'derivative24_spikes', '-ascii');
      
        noutlier_FD = [noutlier_FD;noutliers];
        maxtrans = [maxtrans; max(max(abs(headmovement(:,1:3))))];
        maxrot = [maxrot; max(max(abs(headmovement(:, 4:6))))];
        
        subplot(3,1,1);
        plot(headmovement(:,1:3));
        ylim([min(min(headmovement(:,1:3))), max(max(headmovement(:,1:3)))])
        xlim([0, size(RP, 1)])
        grid on;
        title('Motion: shifts (top, in mm), rotations (middle, in degree) and FD (bottom)', 'interpreter', 'none');
        subplot(3,1,2);
        plot(headmovement(:,4:6));
        ylim([min(min(headmovement(:,4:6))), max(max(headmovement(:,4:6)))])
        xlim([0, size(RP, 1)])
        grid on;
        
        subplot(3,1,3);
        plot(FD);
        hold on
        grid on;
        min_FD = min(FD);
        max_FD = max(FD);
        if noutliers>0
            for nn = 1:noutliers
                plot([FD_outliers(nn), FD_outliers(nn)], [min_FD, max_FD], 'r-');
            end
        end
        ylim([min_FD, max_FD])
        xlim([0, size(RP, 1)])
        print(printfig, '-dtiff', '-r200',fullfile(QAdir, ['RP_',subfuncimgs{jj}]));
        close all
        end
end

Motions = table(funcimgs,maxtrans,maxrot, noutlier_FD);
save(fullfile(QAdir, 'MaxMotion.mat'),'-mat','Motions')

header = {'func_img', 'MaxShift','MaxRotation', 'FDoutliers'};
xlswrite(fullfile(QAdir,'Motion.xlsx'), header, 1, 'A1')
xlswrite(fullfile(QAdir,'Motion.xlsx'), funcimgs, 1, 'A2')
xlswrite(fullfile(QAdir,'Motion.xlsx'),maxtrans, 1, 'B2')
xlswrite(fullfile(QAdir,'Motion.xlsx'),maxrot, 1, 'C2')
xlswrite(fullfile(QAdir,'Motion.xlsx'),noutlier_FD, 1, 'D2')
end

