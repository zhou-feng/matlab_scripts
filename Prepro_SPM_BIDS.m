function Prepro_SPM_BIDS(datadir, preproOrder, preproParam, task)
% datadir: where your data is
% preproOrder: the order of preprocessing, 
% e.g. preproOrder = {'STC', 'RealignUnwarp','T1norm', 'Smooth'};
% preproParam: some necessary parameters, e.g. slice order for STC,
% bounding box and voxel size for Normalization
% task: name of the task fMRI data you would like to preprocess, if
% not specified, use all of the data in the func folder
%
% if you want to perform normalization without realignment, make sure that you
% have mean*.nii in the funct folder
%
%
% Written by Feng Zhou, 12/27/2020
if nargin < 4
    task = '^sub.*nii';
else
    task = ['^sub.*', task, '.*nii']; 
end
subjfolders = dir(datadir);
isub = [subjfolders(:).isdir];
namesubs = {subjfolders(isub).name}';
namesubs(ismember(namesubs,{'.','..'})) = [];
nsub = length(namesubs);
nprepro = length(preproOrder);
parfor ii = 1:nsub
    subname = namesubs{ii,1};
    fprintf('Running preprocessing for %s \n \n', subname)
    funcdir = fullfile(datadir, subname, 'func');
    anatdir = fullfile(datadir, subname, 'anat');
    if exist(funcdir, 'dir')
        taskfiles = spm_select('List', funcdir, task);
        EPItoUnwarp = spm_select('FPList', funcdir, task);
        EPItoUnwarp = cellstr(EPItoUnwarp);
        nRuns = size(taskfiles, 1);
        funct = cell(nRuns,1);
        for nn = 1:nprepro
             matlabbatch = [];
            for jj = 1:nRuns
                funct{jj,1} = cellstr(spm_select('ExtFPList', funcdir, ['^', taskfiles(jj, :)])); % fieldmap generates wfmag* files, we will use ^sub* files for further preprocessing
            end
            fn = vertcat(funct{:});
            function_name = preproOrder{nn};
            if strcmpi(function_name, 'FieldMap') || strcmpi(function_name, 'FieldMapCorrection')
                phasefile = spm_select('FPList', fullfile(datadir, subname, 'fmap'), '.*phasediff.nii');
                magnitudefile = spm_select('FPList', fullfile(datadir, subname, 'fmap'), '.*magnitude.*nii');
                magnitudefile = magnitudefile(1, :); % we just need one magnitude file, the shorter echo time one is better?
                matlabbatch = FieldMapCorrection(phasefile, magnitudefile, EPItoUnwarp, preproParam);
                dataprefix = [];
                parsave(fullfile(funcdir,'FieldMap_Batch.mat'), matlabbatch);
            elseif strcmpi(function_name, 'STC') || strcmpi(function_name, 'SliceTiming')
                [dataprefix, matlabbatch] = STC(funct, preproParam);
                parsave(fullfile(funcdir,'SliceTiming_Batch.mat'), matlabbatch);
            elseif strcmpi(function_name, 'RealignUnwarp')
                vdmfiles = spm_select('FPList', fullfile(datadir, subname, 'fmap'), 'vdm.*session.*nii');
                if ~isempty(vdmfiles)
                    vdmfiles = cellstr(vdmfiles);
                    [dataprefix, matlabbatch] = RealignUnwarp(funct, vdmfiles);
                else [dataprefix, matlabbatch] = RealignUnwarp(funct);
                end
                parsave(fullfile(funcdir,'RealignUnwarp_Batch.mat'), matlabbatch);
            elseif strcmpi(function_name, 'Realign')
                [dataprefix, matlabbatch] = Realign(funct);
                parsave(fullfile(funcdir,'Realign_Batch.mat'), matlabbatch);
            elseif strcmpi(function_name, 'EPInorm')
                meanImgs = cellstr(spm_select('ExtFPListRec',funcdir,'^mean.*.nii$'));
                if ~isempty(meanImgs) %mean image required
                    meanImg = meanImgs{1};
                    % in case the mean image is selected? I don't remember.
                    % but it shouldn't be. I wll leave this anyway since it looks funny...
                    for mm = 1:length(meanImgs) 
                        idx = strcmp(fn, meanImgs{mm});
                        fn(idx) = [];
                    end
                    [dataprefix, matlabbatch] = EPInorm(meanImg, fn, preproParam);
                    parsave(fullfile(funcdir,'EPInorm_Batch.mat'), matlabbatch);
                else
                    error('Couldn''t find mean image! You might consider to get a mean image via ImCalc')
                end
            elseif strcmpi(function_name, 'T1norm')
                T1Img = spm_select('FPList',anatdir,'.*T1w.*.nii$');
                meanImgs = cellstr(spm_select('ExtFPListRec',funcdir,'^mean.*.nii$'));
                if ~isempty(meanImgs) && ~isempty(T1Img) %mean image and T1 image required
                    T1Img = T1Img(1,:);
                    meanImg = meanImgs{1};
                    for mm = 1:length(meanImgs)
                        idx = strcmp(fn, meanImgs{mm});
                        fn(idx) = [];
                    end
                    [dataprefix, matlabbatch] = T1norm(T1Img, meanImg, fn, preproParam);
                    parsave(fullfile(funcdir,'T1norm_Batch.mat'), matlabbatch);
                else
                    error('couldn''t find mean image or anatomy image! You might consider to get a mean image via ImCalc or/and use EPInorm instead')
                end
            elseif strcmpi(function_name, 'T1ReNorm')
                [dataprefix, matlabbatch] = T1ReNorm(fn, anatdir, preproParam);
                parsave(fullfile(funcdir,'T1ReNorm_Batch.mat'), matlabbatch);
            elseif strcmpi(function_name, 'Smooth')
                [dataprefix, matlabbatch] = smoothImg(fn, preproParam);
                parsave(fullfile(funcdir,'Smooth_Batch.mat'), matlabbatch);
            else 
                error('unknown preprocessing step');
            end
            spm_jobman('run', matlabbatch)
            dataprefix = repmat(dataprefix, nRuns, 1);
            taskfiles = [dataprefix, taskfiles];
        end
        fprintf('%s Done! \n \n',subname)
    end
end
end

%% save batch file
function parsave(fname, matlabbatch)
  save(fname, 'matlabbatch')
end
%% fieldmap correction
function matlabbatch = FieldMapCorrection(phasefile, magnitudefile, EPItoUnwarp, pm_fmriprepro)
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.phase = {phasefile};
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.magnitude = {magnitudefile};
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.et = pm_fmriprepro.echotimes;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.maskbrain = 0;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.blipdir = pm_fmriprepro.blip;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.tert = pm_fmriprepro.readouttime;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.epifm = 0;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.ajm = 0;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.method = 'Mark3D';
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.fwhm = 10;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.pad = 0;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.ws = 1;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.template = {fullfile(spm('dir'), 'toolbox', 'FieldMap', 'T1.nii')};
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.fwhm = 5;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.nerode = 2;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.ndilate = 4;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.thresh = 0.5;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.reg = 0.02;
ntasks = size(EPItoUnwarp, 1);
for t = 1:ntasks
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.session(t).epi = {EPItoUnwarp{t, 1}};
end
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchvdm = 1;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.sessname = 'session';
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.writeunwarped = 0;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.anat = {''};
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchanat = 0;
end

%% slice timing correction
function [prefix, matlabbatch] = STC(fn, pm_fmriprepro)
prefix = 'a';
matlabbatch{1}.spm.temporal.st.scans = fn';
matlabbatch{1}.spm.temporal.st.nslices = pm_fmriprepro.nslices;
matlabbatch{1}.spm.temporal.st.tr = pm_fmriprepro.TR;
matlabbatch{1}.spm.temporal.st.ta = pm_fmriprepro.TA;
matlabbatch{1}.spm.temporal.st.so = pm_fmriprepro.so;
matlabbatch{1}.spm.temporal.st.refslice = pm_fmriprepro.refslice;
matlabbatch{1}.spm.temporal.st.prefix = prefix;
end

%% realign & unwarp
function [prefix, matlabbatch] = RealignUnwarp(fn, vdmfiles)
prefix = 'u';
nruns = length(fn);
for nn = 1:nruns
    matlabbatch{1}.spm.spatial.realignunwarp.data(nn).scans = fn{nn,1};
    if nargin < 2
        matlabbatch{1}.spm.spatial.realignunwarp.data(nn).pmscan = '';
    else
        matlabbatch{1}.spm.spatial.realignunwarp.data(nn).pmscan = {vdmfiles{nn,1}};
    end
end
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.quality = 0.9;
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.sep = 4;
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.fwhm = 5;
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.rtm = 0;
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.einterp = 4;
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.ewrap = [0 0 0];
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.weight = '';
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.basfcn = [12 12];
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.regorder = 1;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.lambda = 100000;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.jm = 0;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.fot = [4 5];
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.sot = [];
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.uwfwhm = 4;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.rem = 1;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.noi = 5;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.expround = 'Average';
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.uwwhich = [2 1];
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.rinterp = 4;
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.mask = 1;
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.prefix = prefix;
end

%% realign
function [prefix, matlabbatch] = Realign(fn)
prefix = 'r';
matlabbatch{1}.spm.spatial.realign.estwrite.data = fn';
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.sep = 4;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm = 0;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.interp = 4;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight = '';
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which = [2 1];
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.interp = 4;
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask = 1;
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix = prefix;
end

%% normalization by mean EPI
function [prefix, matlabbatch] = EPInorm(meanImg, fn, pm_fmriprepro)
prefix = 'w';
matlabbatch{1}.spm.spatial.preproc.channel.vols = {meanImg};
matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
matlabbatch{1}.spm.spatial.preproc.channel.write = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,1')};
matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,2')};
matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,3')};
matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,4')};
matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,5')};
matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,6')};
matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
matlabbatch{1}.spm.spatial.preproc.warp.write = [0 1];
matlabbatch{2}.spm.spatial.normalise.write.subj.def(1) = cfg_dep('Segment: Forward Deformations', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','fordef', '()',{':'}));
matlabbatch{2}.spm.spatial.normalise.write.subj.resample = fn;
matlabbatch{2}.spm.spatial.normalise.write.woptions.bb = pm_fmriprepro.bb;
matlabbatch{2}.spm.spatial.normalise.write.woptions.vox = pm_fmriprepro.vox;
matlabbatch{2}.spm.spatial.normalise.write.woptions.interp = 4;
matlabbatch{2}.spm.spatial.normalise.write.woptions.prefix = prefix;
end

%% normalization by T1
function [prefix, matlabbatch] = T1norm(T1Img, meanImg, fn, pm_fmriprepro)
prefix = 'w';
matlabbatch{1}.spm.spatial.preproc.channel.vols = {T1Img};
matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
matlabbatch{1}.spm.spatial.preproc.channel.write = [0 1];
matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,1')};
matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,2')};
matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,3')};
matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,4')};
matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,5')};
matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,6')};
matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
matlabbatch{1}.spm.spatial.preproc.warp.write = [1 1];
matlabbatch{2}.cfg_basicio.file_dir.cfg_fileparts.files(1) = cfg_dep('Segment: Bias Corrected (1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','channel', '()',{1}, '.','biascorr', '()',{':'}));
matlabbatch{3}.spm.util.imcalc.input(1) = cfg_dep('Segment: c1 Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{1}, '.','c', '()',{':'}));
matlabbatch{3}.spm.util.imcalc.input(2) = cfg_dep('Segment: c2 Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{2}, '.','c', '()',{':'}));
matlabbatch{3}.spm.util.imcalc.input(3) = cfg_dep('Segment: c3 Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{3}, '.','c', '()',{':'}));
matlabbatch{3}.spm.util.imcalc.input(4) = cfg_dep('Segment: Bias Corrected (1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','channel', '()',{1}, '.','biascorr', '()',{':'}));
matlabbatch{3}.spm.util.imcalc.output = 'Brain';
matlabbatch{3}.spm.util.imcalc.outdir(1) = cfg_dep('Get Pathnames: Directories (unique)', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','up'));
matlabbatch{3}.spm.util.imcalc.expression = '(i1 + i2 + i3) .* i4';
matlabbatch{3}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{3}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{3}.spm.util.imcalc.options.mask = 0;
matlabbatch{3}.spm.util.imcalc.options.interp = 1;
matlabbatch{3}.spm.util.imcalc.options.dtype = 4;
matlabbatch{4}.spm.spatial.coreg.estimate.ref(1) = cfg_dep('Image Calculator: Imcalc Computed Image', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
matlabbatch{4}.spm.spatial.coreg.estimate.source = {meanImg};
matlabbatch{4}.spm.spatial.coreg.estimate.other = fn;
matlabbatch{4}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
matlabbatch{4}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
matlabbatch{4}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{4}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
matlabbatch{5}.spm.spatial.normalise.write.subj.def(1) = cfg_dep('Segment: Forward Deformations', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','fordef', '()',{':'}));
matlabbatch{5}.spm.spatial.normalise.write.subj.resample = fn;
matlabbatch{5}.spm.spatial.normalise.write.woptions.bb = pm_fmriprepro.bb;
matlabbatch{5}.spm.spatial.normalise.write.woptions.vox = pm_fmriprepro.vox;
matlabbatch{5}.spm.spatial.normalise.write.woptions.interp = 4;
matlabbatch{5}.spm.spatial.normalise.write.woptions.prefix = prefix;
matlabbatch{6}.spm.spatial.normalise.write.subj.def(1) = cfg_dep('Segment: Forward Deformations', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','fordef', '()',{':'}));
matlabbatch{6}.spm.spatial.normalise.write.subj.resample(1) = cfg_dep('Image Calculator: Imcalc Computed Image', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
matlabbatch{6}.spm.spatial.normalise.write.woptions.bb = pm_fmriprepro.bb;
matlabbatch{6}.spm.spatial.normalise.write.woptions.vox = [1 1 1];
matlabbatch{6}.spm.spatial.normalise.write.woptions.interp = 4;
matlabbatch{6}.spm.spatial.normalise.write.woptions.prefix = prefix;
end

%% T1 re-norm
function [prefix, matlabbatch] = T1ReNorm(fn, T1dir, pm_fmriprepro)
prefix = 'w';
matlabbatch{1}.spm.spatial.normalise.write.subj.def = cellstr(spm_select('FPListRec',T1dir,'^y_.*\.nii$'));
matlabbatch{1}.spm.spatial.normalise.write.subj.resample = fn;
matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = pm_fmriprepro.bb;
matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = pm_fmriprepro.vox;
matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = prefix;
end
%% smooth
function [prefix, matlabbatch] = smoothImg(fn, pm_fmriprepro)
prefix = 's';
matlabbatch{1}.spm.spatial.smooth.data = fn;
matlabbatch{1}.spm.spatial.smooth.fwhm = pm_fmriprepro.fwhm;
matlabbatch{1}.spm.spatial.smooth.dtype = 0;
matlabbatch{1}.spm.spatial.smooth.im = 0;
matlabbatch{1}.spm.spatial.smooth.prefix = prefix;
end
%%