clear, clc
%% STEP 1, convert dcm to nifti (4D NII)
dcmfiledir = 'G:\DynamicFearRaw'; % put everyone's MRI data under this folder
outputdir = 'G:\DynamicFearBIDS'; % where you want to put the converted data

% the func and ant descriptions are that you used in the scanning protocals
FuncProtocol = {'fear_run01', 'fear_run02', 'fear_run03', 'fear_run04', 'movie'};
AntProtocol = {'t1_mprage_sag_iso_mww64CH'};
convertdcm2nii(dcmfiledir,outputdir,FuncProtocol,AntProtocol);
% if you only want to convert func data
% convertdcm2nii(dcmfiledir,outputdir,FuncProtocol)
% if you only want to convert ant data
% convertdcm2nii(dcmfiledir,outputdir, [], AntProtocol)

%% STEP 2, check numbers of T1w and funct images for each subject
% Of note, some subjects might have more imgs (e.g. due to re-scanning), which should be removed
% make sure you have the same numbers of nT1w AND nFunct
subinfo = checkimgs(outputdir);

%% STEP 3, discard initial N volumes of func images
% It seems that the Prisma Fit at SWU scans 10s without saving the images before it sends the trigger
% Therefor this step might be unnecessary. But I'm removing the first 4 scans anyway
nVols = 4; % initial 4 volumes
discard_init_vols(outputdir,nVols);

%% STEP 4, rename nii imgs to fit BIDS
% left ones are part of the old names, 
% right ones are the modified names (will automatically includes subID)
funcnames = {'*fear_run01*', 'fear_run-01';...
'*fear_run02*', 'fear_run-02';...
'*fear_run03*', 'fear_run-03';...
'*fear_run04*', 'fear_run-04';...
'*movie*', 'movie';};

anatname = {'*t1_mprage_sag_iso_mww64CH*', 'T1w'};


renameBIDS(outputdir, funcnames, anatname);

% if you want to rename T1w only
% renameBIDS(outputdir, [], anatname);

% if you want to rename func only
% renameBIDS(outputdir, funcnames, []);


%% dataset description
dd_json.Name = 'Dynamic Fear Dataset';
dd_json.BIDSVersion = '1.8.4';
dd_json.Authors = {'Feng Zhou', 'Benjamin Becker'};
dd_json.License = 'TBD';
json_options.indent = '  ';
jsonwrite(fullfile(outputdir, 'dataset_description.json'), dd_json, json_options);
% %  
% % %% participant.tsv
% % % % subID{1,1} = '120'; subID{1,2} = '130';
% % % % sex{1,1} = 'M'; sex{1,2} = 'F';
% % % % age = [20, 22];
% % % % sub = struct('participant_id', {subID}, 'sex', {sex}, 'age', age);
% % % % spm_save('participants.tsv', sub);
