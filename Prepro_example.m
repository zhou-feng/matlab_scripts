% 10/03/2021
clear, clc

% task description, e.g. IAPS for sub-xxx_task-IAPS... this is not necessary
% if you omit this all func data will be preprocessed
task = '*';
datadir = 'F:\DynamicFearBIDS';% where you put your BIDS data

%% for fieldmap correction
% % we need phasediff and magnitude files in the fmap folder
% preproParam.echotimes = [4.92 7.38]; % short and long TE in ms, you can find these in the phasediff json file or magnitude json files
% 
% % according to https://www.jiscmail.ac.uk/cgi-bin/wa-jisc.exe?A2=ind1506&L=SPM&P=R11500
% % tblip should be set based on the Phase enc. dir of EPI images,  -1 for A-->P and 1 for P--A?
% % in this case I should use 1
% % according to https://lcni.uoregon.edu/kb-articles/kb-0003
% % Polarity of the blips depends not only on your acquisition but also on how your data was converted to NIFTI
% % so it could be either + or - ve. The easiest thing to do is to try it both ways. Once these parameters are set, load an EPI image. 
% % After a moment, you'll see the fieldmap, warped EPI, and unwarped EPI in the graphics window.
% % see also https://cbs.fas.harvard.edu/science/core-facilities/neuroimaging/information-investigators/MRphysicsfaq
% % which one should I use??
% preproParam.blip = 1; 
% 
% 
% preproParam.readouttime = 29.9698; 
% % total EPI readout time in ms, this is very complicated, however, dcm2niix reports this
% % readout time = (ReconMatrixPE - 1) * EffectiveEchoSpacing 
% % it seems that EffectiveEchoSpacing tasks account for parallel imaging already
% % see also https://lcni.uoregon.edu/kb-articles/kb-0003
%% for slice timing
preproParam.TR = 2;%TR
preproParam.nslices = 39;
preproParam.so = [1:2:39 2:2:39];% slice order (see your json file)
preproParam.refslice = 39; % reference slice
% preproParam.nslices = 62;% number of slices
% preproParam.so = [957.500000000000,0,1022.50000000000,65,1085,127.500000000000,1150,192.500000000000,1215,255,1277.50000000000,...
%     320,1342.50000000000,382.500000000000,1405,447.500000000000,1470,512.500000000000,1532.50000000000,575,1597.50000000000,640,...
%     1660,702.500000000000,1725,767.500000000000,1787.50000000000,830,1852.50000000000,895,1917.50000000000,957.500000000000,0,...
%     1022.50000000000,65,1085,127.500000000000,1150,192.500000000000,1215,255,1277.50000000000,320,1342.50000000000,382.500000000000,...
%     1405,447.500000000000,1470,512.500000000000,1532.50000000000,575,1597.50000000000,640,1660,702.500000000000,1725,767.500000000000,...
%     1787.50000000000,830,1852.50000000000,895,1917.50000000000];% slice order in ms
% preproParam.refslice = 1022.5;% reference slice in ms
preproParam.TA = preproParam.TR - (preproParam.TR/preproParam.nslices); % if the slice order and reference slice are defined in ms, this can be defined as 0 (won't be used)

%% for normalization
% the larger bounding box (MNI152)is [-90 -126 -72;90 90 108]
preproParam.bb = [-78 -112 -70;78 76 85];% SPM's default bounding box (to save some space)
preproParam.vox = [2 2 2];%The voxel sizes (x, y & z, in mm) of the written normalised images

%% for smooth
preproParam.fwhm = [6 6 6];% 6mm FWHM 

%% the steps and orders can be easily changed, see below for examples
% preproOrder = {'FieldMap', 'STC', 'realignunwarp', 'T1norm', 'smooth'};%STC for slice timing correction
preproOrder = {'STC', 'realignunwarp', 'T1norm', 'smooth'};
% preproOrder = {'realignunwarp', 'SliceTiming', 'T1norm', 'smooth'};
% preproOrder = {'realignunwarp', 'EPInorm', 'smooth'};

%% run preprocessing
% Prepro_SPM_BIDS(datadir, preproOrder, preproParam, task);
Prepro_SPM_BIDS(datadir, preproOrder, preproParam);% run all func data

%% QA
% Prepro_QA_simple(datadir);