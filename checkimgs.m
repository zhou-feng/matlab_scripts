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
field1 = 'subID'; value1 = subID;
field2 = 'nT1w'; value2 = nT1w;
field3 = 'nFunc'; value3 = nFunc;
subinfo = struct(field1,value1,field2,value2,field3,value3);
end