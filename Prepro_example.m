% 12/27/2020
clear, clc

% task description, e.g. IAPS for sub-xxx_task-IAPS... this is not necessary
% if you omit this all func data will be preprocessed
task = 'IAPS';
datadir = 'E:\Prepro_test\dataset';% where you put your BIDS data
%% for slice timing
preproParam.TR = 2;%TR
preproParam.nslices = 36;% number of slices
preproParam.so = [1:2:35 2:2:36];% slice order
preproParam.refslice = 35;%reference slice
preproParam.TA = preproParam.TR - (preproParam.TR/preproParam.nslices); % do not change

%% for normalization
% the larger bounding box (MNI152)is [-90 -126 -72;90 90 108]
preproParam.bb = [-78 -112 -70;78 76 85];% SPM's default bounding box (to save some space)
preproParam.vox = [2 2 2];%The voxel sizes (x, y & z, in mm) of the written normalised images

%% for smooth
preproParam.fwhm = [8 8 8];% 8mm FWHM 

%% the steps and orders can be easily changed, see below for examples
preproOrder = {'STC','realignunwarp', 'T1norm', 'smooth'};%STC for slice timing correction
% preproOrder = {'realignunwarp', 'SliceTiming', 'T1norm', 'smooth'};
% preproOrder = {'realignunwarp', 'EPInorm', 'smooth'};

%% run preprocessing
Prepro_SPM_BIDS(datadir, preproOrder, preproParam, task);
% Prepro_SPM_BIDS(datadir, preproOrder, preproParam);% run all func data

%% QA
Prepro_QA(datadir, [], task);