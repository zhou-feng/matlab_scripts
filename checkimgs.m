function subinfo = checkimgs(datadir)
subdirs = dir(fullfile(datadir, 'sub*'));
nsub = size(subdirs, 1);
subID = cell(nsub, 1);
nT1w = cell(nsub, 1);
nFunc = cell(nsub, 1);
for i = 1:nsub
    subname = subdirs(i).name;
    funcimgs = dir(fullfile(datadir, subname, 'func','*.nii*'));
    T1wimgs = dir(fullfile(datadir, subname, 'anat','*.nii*'));
    subID{i,1} = subname;
    nT1w{i,1} = size(T1wimgs, 1);
    nFunc{i,1} = size(funcimgs, 1);
end
subinfo = struct('subID',subID,'nT1w',nT1w,'nFunc',nFunc);
end