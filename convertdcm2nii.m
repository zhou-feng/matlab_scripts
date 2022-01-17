function convertdcm2nii(dcmfiledir,outputdir,FuncProtocol,AntProtocol, FieldMapProtocol)
% This script is used to convert dcm to nii for the dynamic fear study (Prisma fit)

% dcmfiledir: raw data directory
% outputdir: output directory
%
% see also scanning PC for Protocol names
%
% FuncProtocol: ProtocolName of the funct, which is stored in dcminfo.ProtocolName
% e.g. FuncProtocol = {'fear_run01', 'fear_run02', 'fear_run03'};
%
% AntProtocol: ProtocolName of the ant, which is stored in dcminfo.ProtocolName
% e.g. AntProtocol = {'t1_mprage_sag_iso'};
%
% FieldMapProtocol: ProtocolName of the field map, which is stored in dcminfo.ProtocolName
% % e.g. FieldMapProtocol = {'gre_field_mapping_2mm'};

% Written by Feng Zhou, 10/01/2021
convertfunc = false;
convertT1w = false;
convertFmap = false;
if nargin > 2 && ~isempty(FuncProtocol)
    convertfunc = true;
    FuncProtocol = lower(FuncProtocol);
end
if nargin > 3 && ~isempty(AntProtocol)
    convertT1w = true;
    AntProtocol = lower(AntProtocol);
end
if nargin > 4 && ~isempty(FieldMapProtocol)
    convertFmap = true;
    FieldMapProtocol = lower(FieldMapProtocol);
end

dcm2niipath = which('dcm2niix.exe');
assert(~isempty(dcm2niipath), 'dcm2niix is needed to convert data!')
dcm2niiexe=['!' dcm2niipath];

subjfolders = dir(dcmfiledir);
isfolder = [subjfolders(:).isdir];
subjfolders = {subjfolders(isfolder).name}';
subjfolders(ismember(subjfolders,{'.','..'})) = [];
nsub = length(subjfolders);

for ii = 1:nsub
    subj = subjfolders{ii,1};
    
    % subj folder --> another one folder --> dcm folders
    datafolder = dir(fullfile(dcmfiledir,subj));
    isfolder = [datafolder(:).isdir];
    datafolder = {datafolder(isfolder).name}';
    datafolder(ismember(datafolder,{'.','..'})) = [];
    
    dcmfolders = dir(fullfile(dcmfiledir,subj, datafolder{1,1}));
    isfolder = [dcmfolders(:).isdir];
    dcmfolders = {dcmfolders(isfolder).name}';
    dcmfolders(ismember(dcmfolders,{'.','..'})) = [];
    ndcmfolder = length(dcmfolders);
    
    for jj = 1:ndcmfolder
        dcmfoldername = dcmfolders{jj,1};
        dcmfiles = dir(fullfile(dcmfiledir, subj, datafolder{1,1}, dcmfoldername, '*.IMA'));
        if ~isempty(dcmfiles)
        dcmfile = fullfile(dcmfiledir, subj, datafolder{1,1}, dcmfoldername, dcmfiles(1,1).name);
        dcminfo = dicominfo(dcmfile);
        ProtocolName = lower({dcminfo.ProtocolName});
        if convertfunc && ~isempty(intersect(ProtocolName, FuncProtocol))
            newsubname = dcminfo.PatientID;
            newsubname = ['sub-', newsubname(isstrprop(newsubname, 'digit'))];
            functpath = fullfile(outputdir, newsubname, 'func');
            if ~exist(functpath, 'dir')
                mkdir(functpath)
            end
            eval([dcm2niiexe, '  -b Y -z n -f "%i_%p" ',' -o ',functpath, ' ',dcmfile])
        elseif convertT1w && ~isempty(intersect(ProtocolName, AntProtocol))
            newsubname = dcminfo.PatientID;
            newsubname = ['sub-', newsubname(isstrprop(newsubname, 'digit'))];
            anatomypath = fullfile(outputdir, newsubname, 'anat');
            if ~exist(anatomypath, 'dir')
                mkdir(anatomypath)
            end
           eval([dcm2niiexe, '  -b Y -z n -f "%i_%p" ',' -o ',anatomypath, ' ',dcmfile])
           
        elseif convertFmap && ~isempty(intersect(ProtocolName, FieldMapProtocol))
            newsubname = dcminfo.PatientID;
            newsubname = ['sub-', newsubname(isstrprop(newsubname, 'digit'))];
            anatomypath = fullfile(outputdir, newsubname, 'fmap');
            if ~exist(anatomypath, 'dir')
                mkdir(anatomypath)
            end
           eval([dcm2niiexe, '  -b Y -z n -f "%i_%p" ',' -o ',anatomypath, ' ',dcmfile])
        end
        end
    end
end
end