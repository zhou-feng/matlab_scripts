function renameBIDS(datadir, funcnames, anatname, fmapnames)
% I'm using unzipped files, you might want to change nii to nii.gz
renameFunc = true;
renameT1w = true;
renameFmap = true;

if isempty(funcnames)
    renameFunc = false;
end

if nargin < 3 || isempty(anatname)
    renameT1w = false;
end

if nargin < 4 || isempty(fmapnames)
    renameFmap = false;
end

subjfolders = dir(fullfile(datadir,'*'));
isfolder = [subjfolders(:).isdir]; 
subjfolders = {subjfolders(isfolder).name}';
subjfolders(ismember(subjfolders,{'.','..'})) = [];
nsub = length(subjfolders);

for ii = 1:nsub
    subname = subjfolders{ii,1};
    
    %% func
    if renameFunc
        nfunc = size(funcnames, 1);
        funcdir = fullfile(datadir, subname, 'func');
        for jj = 1:nfunc
            img = dir(fullfile(funcdir,[funcnames{jj,1}, '.nii']));
            if ~isempty(img)
                movefile(fullfile(funcdir, img.name), fullfile(funcdir, [subname, '_task-', funcnames{jj, 2}, '_bold.nii']));
            end
            json = dir(fullfile(funcdir,[funcnames{jj,1}, '.json']));
            if ~isempty(json)
                movefile(fullfile(funcdir, json.name), fullfile(funcdir, [subname, '_task-', funcnames{jj, 2}, '_bold.json']));
                jsonfile = spm_jsonread(fullfile(funcdir, [subname, '_task-', funcnames{jj, 2}, '_bold.json']));
                splits = strsplit(funcnames{jj,2}, '_run');
                jsonfile.TaskName = splits{1};
                spm_jsonwrite(fullfile(funcdir, [subname, '_task-', funcnames{jj, 2}, '_bold.json']), jsonfile, struct('indent', ' '));
            end
        end
    end
    %% ant
    if renameT1w
        antdir = fullfile(datadir, subname, 'anat');
        img = dir(fullfile(antdir, [anatname{1,1}, '.nii']));
        if ~isempty(img)
            movefile(fullfile(antdir, img.name), fullfile(antdir,[subname, '_', anatname{1,2}, '.nii']));
        end
        json = dir(fullfile(antdir,[anatname{1,1}, '.json']));
        if ~isempty(json)
            movefile(fullfile(antdir, json.name), fullfile(antdir,[subname, '_', anatname{1,2}, '.json']));
        end
    end
    %% field map (SWU-specific)
    if renameFmap
        nfmap = size(fmapnames, 1);
        fmapdir = fullfile(datadir, subname, 'fmap');
        functdir = fullfile(datadir, subname, 'func');
        funcimgs = spm_select('List',functdir,'^sub.*task.*.nii');
        nfunc = size(funcimgs, 1);
        IntendedFor = cell(nfunc, 1);
        for nn = 1:nfunc
            IntendedFor{nn} =['func/', funcimgs(nn,:)];
        end
        
        for jj = 1:nfmap
            img = dir(fullfile(fmapdir,[fmapnames{jj,1}, 'nii']));
            if ~isempty(img)
                movefile(fullfile(fmapdir, img.name), fullfile(fmapdir, [subname, '_', fmapnames{jj, 2}, '.nii']));
            end
            json = dir(fullfile(fmapdir,[fmapnames{jj,1}, 'json']));
            if ~isempty(json)
                movefile(fullfile(fmapdir, json.name), fullfile(fmapdir, [subname, '_', fmapnames{jj, 2}, '.json']));
                jsonfile = spm_jsonread(fullfile(fmapdir, [subname, '_', fmapnames{jj, 2}, '.json']));
                jsonfile.IntendedFor = IntendedFor;
                spm_jsonwrite(fullfile(fmapdir, [subname, '_', fmapnames{jj, 2}, '.json']), jsonfile, struct('indent', ' '));
            end
        end
    end
end
end