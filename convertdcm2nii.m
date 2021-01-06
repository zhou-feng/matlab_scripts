function convertdcm2nii(dcmfiledir,outputdir,FuncSeriesDescription,AntSeriesDescription)
% dcmfiledir: raw data directory
% outputdir: output directory
%
% see also scanning PC for FuncSeriesDescription and AntSeriesDescription
% FuncSeriesDescription: Description of the funct, which is stored in dcminfo.SeriesDescription
% e.g. FuncSeriesDescription = {'IAPS_run_01', 'IAPS_run_02','face_run_01'};
% AntSeriesDescription: Description of the ant, which is stored in dcminfo.SeriesDescription
% e.g. AntSeriesDescription = {'3DT1'};
%
% Written by Feng Zhou, 12/27/2020
convertfunc = false;
convertT1w = false;
if nargin > 2 && ~isempty(FuncSeriesDescription)
    convertfunc = true;
    FuncSeriesDescription = lower(FuncSeriesDescription);
end
if nargin > 3 && ~isempty(AntSeriesDescription)
    convertT1w = true;
    AntSeriesDescription = lower(AntSeriesDescription);
end
dcm2niipath = which('dcm2niix.exe');
assert(~isempty(dcm2niipath), 'dcm2niix is needed to convert data!')
dcm2niiexe=['!' dcm2niipath];
subjfolders = dir(dcmfiledir);
isub = [subjfolders(:).isdir];
namesubs = {subjfolders(isub).name}';
namesubs(ismember(namesubs,{'.','..'})) = [];
nsub = length(namesubs);
for ii = 1:nsub
    subname = namesubs{ii,1};
    runfolders = dir(fullfile(dcmfiledir,subname));
    issub = [runfolders(:).isdir];
    datafolders = {runfolders(issub).name}';
    datafolders(ismember(datafolders,{'.','..'})) = [];
    ndatafolder = length(datafolders);
    for jj = 1:ndatafolder
        datafoldername = datafolders{jj,1};
        dcmfiles = dir(fullfile(dcmfiledir, subname, datafoldername, '*.dcm'));
        if ~isempty(dcmfiles)
        dcmfile = fullfile(dcmfiledir, subname, datafoldername, dcmfiles(1,1).name);
        dcminfo = dicominfo(dcmfile);
        SeriesDescription = lower({dcminfo.SeriesDescription});
        if convertfunc && ~isempty(intersect(SeriesDescription, FuncSeriesDescription))
            newsubname = dcminfo.PatientID;
            newsubname = ['sub-', newsubname(isstrprop(newsubname, 'digit'))];
            functpath = fullfile(outputdir, newsubname, 'func');
            if ~exist(functpath, 'dir')
                mkdir(functpath)
            end
            eval([dcm2niiexe, '  -b N -z n -f "%i_%p" ',' -o ',functpath, ' ',dcmfile])
        elseif convertT1w && ~isempty(intersect(SeriesDescription, AntSeriesDescription))
            newsubname = dcminfo.PatientID;
            newsubname = ['sub-', newsubname(isstrprop(newsubname, 'digit'))];
            anatomypath = fullfile(outputdir, newsubname, 'anat');
            if ~exist(anatomypath, 'dir')
                mkdir(anatomypath)
            end
           eval([dcm2niiexe, '  -b N -z n -f "%i_%p" ',' -o ',anatomypath, ' ',dcmfile])
        end
        end
    end
end
end