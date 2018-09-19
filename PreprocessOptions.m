function options = PreprocessOptions()

% TODO - a cludge for now using just a matrix with fields. Eventually make
% this object oriented
options = [];

% define the session and run folder prefixes
%subjects = 'IAPS_01';
options.rootFolder = '';
options.studyName = '';
options.sessionPrefix = 'Session';
options.runPrefix = 'run';
options.anatomicalRunPrefix = 't1_mprage';
options.fieldMapPrefix = 'fieldMap';
options.rawNiftiPrefix = 'f';
options.realignmentNiftiPrefix = 'r';
options.realignmentAndUnwarpNiftiPrefix = 'u';
options.sliceTimingNiftiPrefix = 'a';
options.coregisterNiftiPrefix = 'c';
options.normalizationNiftiPrefix = 'w';
options.smoothingNiftiPrefix = 's';
options.anatomicalNiftiPrefix = 's';
options.meanEPINiftiPrefix = 'meanf';

% define the steps to take during processing
options.runConvertDicoms = true;
options.runConvert4Dto3D = false;
options.runTSDiffAna = true;
options.runDespike = false;
options.runRealignment = true;
options.runRealignmentAndUnwarp = false;
options.runSliceTiming = true;
options.runCoregistration = true;
options.runNormalization = true;
options.runSmoothing = true;

% the number of dummy scans to put in a separate dummy_scans subfolder for
% functional runs.
options.dummyScans = 0;

% THese are the thresholds the despiker uses to determine if a given volume
% is a spike. The original limits from Matthews code were 10 and 20, but I
% found on the IAPS data those were too high
options.totDespikerLimit = 4;
options.sliceDespikerLimit = 15;

% whether to group all EPIs from all sessions into one realignment step,
% which would put them all in the same space, or to realign each session
% differently, resulting in all EPIs within a session aligned, but not
% across sessions
options.realignAllSessionsTogether = true;

% options for converting dicoms to niftis
options.dicomFolder = '';
options.dicomRuns = {};

%%%%%%%%%%%%%%%%%%% Coregistration Options%%%%%%%%%%%%%%%%%%%%
% These three are mutually exclusive (TODO - make into one var with 3
% levels)

% coregisters all epis to the anatomical of the first session when true,
% when false coregisters all EPIs to the anatomical for that session, 
% then coregisters anatomicals from all sessions to the first session 
options.do1StepCoregistration = true; 
% coregister the mean of session 1's EPIs to the mean of subsequent
% session's EPIs
options.doFunctionalToFunctionalCoregistration = false;
% coregister the anatomical of each session to the mean EPI of that
% session.
options.coregisterAnatomicalToFunctional = false;
%%%%%%%%%%%%%%%%%%% Coregistration Options%%%%%%%%%%%%%%%%%%%%

% this will reslice the coregistered image regardless of 1 or 2 step
% or functional to functional coregistration.
options.resliceCoregisteredImages = false;

% whether to reslice functionals and/or anatomicals during normalization
options.normalizeAnatomical = true;
options.normalizeFunctionals = true;

% Default batch templates to use
options.batchFilenameTSDiffAna = 'BatchTemplate_TSDiffAna.m';
options.batchFilenameRealignment= 'BatchTemplate_Realignment.m';
options.batchFilenameRealignmentAndUnwarp= 'BatchTemplate_RealignmentAndUnwarp.m';
options.batchFilenameSliceTiming = 'BatchTemplate_SliceTiming.m';
options.batchFilenameCoregistration = 'BatchTemplate_Coregistration.m';
options.batchFilenameCoregistrationReslice = 'BatchTemplate_CoregistrationReslice.m';
options.batchFilenameCoregistrationEstimate = 'BatchTemplate_CoregistrationEstimate.m';
options.batchFilenameNormalization = 'BatchTemplate_SegmentNormalize.m';
options.batchFilenameSmoothing = 'BatchTemplate_Smoothing.m';

% TODO - put these into a constants file - not really options
options.stepConvertDicoms = 'ConvertDicoms';
options.stepConvert4Dto3D = 'Convert4Dto3D';
options.stepTSDiffAna = 'TSDiffAna';
options.stepDespike = 'Despiking';
options.stepRealignment = 'Realignment';
options.stepRealignmentAndUnwarp = 'RealignmentAndUnwarp';
options.stepSliceTiming = 'SliceTiming';
options.stepCoregistration = 'CoregistrationEstimateAndReslice';
options.stepCoregistrationReslice = 'CoregistrationReslice';
options.stepCoregistrationEstimate = 'CoregistrationEstimateFinal';
options.stepCoregistrationEstimateFirst = 'CoregistrationEstimateFirst';
options.stepNormalization = 'Normalization';
options.stepSmoothing = 'Smoothing';

options.logFilename = 'BLab_Preprocessing_Log.txt';
options.logSubjectSeparator = '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@';
options.logStepSeparator =    '#############################################################################';

end