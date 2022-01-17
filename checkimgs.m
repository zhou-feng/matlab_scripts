function subinfo = checkimgs(datadir)
subdirs = dir(fullfile(datadir, 'sub*'));
nsub = size(subdirs, 1);
subID = cell(nsub, 1);
nAnat = cell(nsub, 1);
nFunc = cell(nsub, 1);
nFmap = cell(nsub, 1);
for i = 1:nsub
    subname = subdirs(i).name;
    funcimgs = dir(fullfile(datadir, subname, 'func','*.nii*'));
    anatimgs = dir(fullfile(datadir, subname, 'anat','*.nii*'));
    fmapimgs = dir(fullfile(datadir, subname, 'fmap','*.nii*')); 
    subID{i,1} = subname;
    nAnat{i,1} = size(anatimgs, 1);
    nFunc{i,1} = size(funcimgs, 1);
    nFmap{i,1} = size(fmapimgs, 1);
end
subinfo = struct('subID',subID,'nAnat',nAnat,'nFunc',nFunc, 'nFmap', nFmap);
end