function smooth_fmriprep(datadir, FWHM, delete_gunzipped_files, task)
% datadir: 
% where the fmriprep dir is, e.g., C:\data_outputs\fmriprep
%
% FWHM: 
% full width at hafl maximum of the Gaussian smoothing keinel. e.g., FWHM = 6.
%
% delete_gunzipped_files:
% whether or not to delete the gunzipped (unsmoothed) files. 1: delete (default).
% 
% task:
% which task's data to smooth. If not specified all of the tasks will be smoothed (default).

if nargin < 4
    task = [];
end

if nargin < 3 || isempty(delete_gunzipped_files)
    delete_gunzipped_files = 1;
end

subdirs = dir(fullfile(datadir,'sub*'));
issub = [subdirs(:).isdir]; 
subIDs = {subdirs(issub).name}';
subIDs(ismember(subIDs,{'.','..'})) = [];
nsub = length(subIDs);
for ii=1:nsub
    subID = subIDs{ii,1};
    fprintf('Running smooth (%smm FWHM) for %s \n', num2str(FWHM), subID)
    subdir = fullfile(datadir, subID, 'func');
    fmriprep_output = spm_select('FPList', subdir, ['.*', task, '.*preproc_bold.nii.gz$']);
    nfiles = size(fmriprep_output, 1);
    for jj = 1:nfiles
        gunzip(fmriprep_output(jj,:))
    end
    
    fmriprep_gunzipped_FP = spm_select('FPList', subdir, ['.*', task, '.*preproc_bold.nii$']);
    fmriprep_gunzipped = spm_select('List', subdir, ['.*', task, '.*preproc_bold.nii$']);
    
    % run smooth for each run separately to save memory
    for jj = 1:nfiles
        clear matlabbatch
        fmriprep_file_4d = spm_select('ExtFPList', subdir, fmriprep_gunzipped(jj, :));
        matlabbatch{1}.spm.spatial.smooth.data = cellstr(fmriprep_file_4d);
        matlabbatch{1}.spm.spatial.smooth.fwhm = FWHM.*ones(1, 3);
        matlabbatch{1}.spm.spatial.smooth.dtype = 0;
        matlabbatch{1}.spm.spatial.smooth.im = 0;
        matlabbatch{1}.spm.spatial.smooth.prefix = ['s', num2str(FWHM), '_'];
        spm_jobman('run', matlabbatch);
    end
    
    if delete_gunzipped_files == 1
        for jj = 1:nfiles
            delete(fmriprep_gunzipped_FP(jj,:))
        end
    end
end
