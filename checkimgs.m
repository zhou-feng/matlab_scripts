function nImgs = checkimgs(datadir)
subdirs = dir(fullfile(datadir, 'sub*'));
nsub = size(subdirs, 1);
nImgs = cell(nsub, 3);
for i = 1:nsub
    subname = subdirs(i).name;
    funcimgs = dir(fullfile(datadir, subname, 'func','*.nii*'));
    T1wimgs = dir(fullfile(datadir, subname, 'anat','*.nii*'));
    nImgs{i,1} = subname;
    nImgs{i,2} = size(T1wimgs, 1);
    nImgs{i,3} = size(funcimgs, 1);
end