clear, clc
%% STEP 1, convert dcm to nifti (4D NII)
dcmfiledir = 'H:\DCM2BIDS\MRI_data'; % this is the origial MRI_data folder, you don't need to do anything
outputdir = 'H:\DCM2BIDS\BIDS_dataset'; % where you want to put the converted data

% the func and ant descriptions are that you used in the scanning protocals
FuncSeriesDescription = {'face_run_01', 'face_run_02', 'face_run_03', 'IAPS_run_01', 'IAPS_run_02', 'IAPS_run_03', 'IAPS_run_04'};
AntSeriesDescription = {'3DT1'};
convertdcm2nii(dcmfiledir,outputdir,FuncSeriesDescription,AntSeriesDescription);

%% STEP 2, check numbers of T1w and funct images for each subject
% Of note, some subjects might have more imgs (e.g. due to re-scanning), which should be removed
% make sure you have the same numbers of nT1w AND nFunct
subinfo = checkimgs(outputdir);


%% STEP 3, discard initial N volumes
nVols = 5; % initial 5 volumes
discard_init_vols(outputdir,nVols);

%% STEP 4, rename nii imgs to fit BIDS
% left ones are part of the old names, 
% right ones are the modified names (will automatically includes subID)
functnames = {'*face_run_01*', 'face_run-01';...
'*face_run_02*','face_run-02';...
'*face_run_03*', 'face_run-03';...
'*IAPS_run_01*', 'IAPS_run-01';...
'*IAPS_run_02*', 'IAPS_run-02';...
'*IAPS_run_03*', 'IAPS_run-03';...
'*IAPS_run_04*', 'IAPS_run-04'};
T1wname = {'*3DT1*', 'T1w'};
renameBIDS(outputdir, functnames, T1wname);

%% json files for each task (can obtain an initial one using dcm2niix)
% the new version of dcm2niix can generate slice order for our GE scanner
% but I think you have to include the TaskName

dcmfile = spm_select; % select a dicom file for e.g. a task
dcm2niipath = which('dcm2niix.exe');
dcm2niiexe=['!' dcm2niipath];
eval([dcm2niiexe, '  -b Y -z n -f "%i_%p" ',' -o ',datadir, ' ',dcmfile]);
% you will find a json file in your datadir, rename it to fit your task
% e.g. task-face_bold.json
% includes TaskName
face_json = spm_jsonread('task-face_bold.json');
face_json.TaskName = 'face';
spm_jsonwrite('task-face_bold.json', face_json, struct('indent', ' '));

% in case you want to include slice timing info
% timeperslice = 2/36;
% order = 0:timeperslice:2;
% slicetiming = zeros(36, 1);
% slicetiming(1:2:end) = order(1:18);
% slicetiming(2:2:end) = order(19:end-1);
% face_json.SliceTiming = slicetiming;
%% dataset description
dd_json.Name = 'Zara Fear Dataset';
dd_json.BIDSVersion = '1.0.2';
dd_json.Authors = {'Weihua Zhao', 'Feng Zhou'};
json_options.indent = '  ';
jsonwrite('dataset_description.json', dd_json, json_options);
 
%% participant.tsv
subID{1,1} = '120'; subID{1,2} = '130';
sex{1,1} = 'M'; sex{1,2} = 'F';
age = [20, 22];
sub = struct('participant_id', {subID}, 'sex', {sex}, 'age', age);
spm_save('participants.tsv', sub);