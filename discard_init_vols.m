function discard_init_vols(datadir,nVols)
% datadir
% nVols: number of initial volumes deleted from output
dcm2niipath = fileparts(which('dcm2nii.exe'));
dcm2niiexe=['!' dcm2niipath '\dcm2nii.exe' ' '];
subjfolders = dir(fullfile(datadir,'*'));
isub = [subjfolders(:).isdir]; % returns logical vector
namesubs = {subjfolders(isub).name}';
namesubs(ismember(namesubs,{'.','..'})) = [];
nsub = length(namesubs);
for ii = 1:nsub
    subname = namesubs{ii,1};
    funcdir = fullfile(datadir, subname, 'func');
    funimages = dir(fullfile(funcdir,'*.nii'));
    nimg = length(funimages);
    for jj = 1:nimg
        funimg = fullfile(funcdir, funimages(jj).name);
        eval([dcm2niiexe ' -o ', funcdir ' -k ' num2str(nVols) ' ' funimg])
        delete(funimg)
    end
end
end

