% List of open inputs
% Phase and Magnitude Data: Short Echo Phase Image - cfg_files
% Phase and Magnitude Data: Short Echo Magnitude Image - cfg_files
% Phase and Magnitude Data: Long Echo Phase Image - cfg_files
% Phase and Magnitude Data: Long Echo Magnitude Image - cfg_files
% Phase and Magnitude Data: Echo times [short TE long TE] - cfg_entry
% Phase and Magnitude Data: Mask brain - cfg_menu
% Phase and Magnitude Data: Blip direction - cfg_menu
% Phase and Magnitude Data: Total EPI readout time - cfg_entry
% Phase and Magnitude Data: EPI-based field map? - cfg_menu
% Phase and Magnitude Data: EPI Sessions - cfg_repeat
% Phase and Magnitude Data: Match VDM to EPI? - cfg_menu
% Phase and Magnitude Data: Write unwarped EPI? - cfg_menu
% Phase and Magnitude Data: Select anatomical image for comparison - cfg_files
% Phase and Magnitude Data: Match anatomical image to EPI? - cfg_menu
% Realign & Unwarp: Images - cfg_files
% Realign & Unwarp: Images - cfg_files
% Realign & Unwarp: Images - cfg_files
nrun = X; % enter the number of runs here
jobfile = {'/home/bishop/samyag1/Template_Scripts/SPM_Batch_Runner/UnwarpScripts/sessionTester_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(17, nrun);
for crun = 1:nrun
    inputs{1, crun} = MATLAB_CODE_TO_FILL_INPUT; % Phase and Magnitude Data: Short Echo Phase Image - cfg_files
    inputs{2, crun} = MATLAB_CODE_TO_FILL_INPUT; % Phase and Magnitude Data: Short Echo Magnitude Image - cfg_files
    inputs{3, crun} = MATLAB_CODE_TO_FILL_INPUT; % Phase and Magnitude Data: Long Echo Phase Image - cfg_files
    inputs{4, crun} = MATLAB_CODE_TO_FILL_INPUT; % Phase and Magnitude Data: Long Echo Magnitude Image - cfg_files
    inputs{5, crun} = MATLAB_CODE_TO_FILL_INPUT; % Phase and Magnitude Data: Echo times [short TE long TE] - cfg_entry
    inputs{6, crun} = MATLAB_CODE_TO_FILL_INPUT; % Phase and Magnitude Data: Mask brain - cfg_menu
    inputs{7, crun} = MATLAB_CODE_TO_FILL_INPUT; % Phase and Magnitude Data: Blip direction - cfg_menu
    inputs{8, crun} = MATLAB_CODE_TO_FILL_INPUT; % Phase and Magnitude Data: Total EPI readout time - cfg_entry
    inputs{9, crun} = MATLAB_CODE_TO_FILL_INPUT; % Phase and Magnitude Data: EPI-based field map? - cfg_menu
    inputs{10, crun} = MATLAB_CODE_TO_FILL_INPUT; % Phase and Magnitude Data: EPI Sessions - cfg_repeat
    inputs{11, crun} = MATLAB_CODE_TO_FILL_INPUT; % Phase and Magnitude Data: Match VDM to EPI? - cfg_menu
    inputs{12, crun} = MATLAB_CODE_TO_FILL_INPUT; % Phase and Magnitude Data: Write unwarped EPI? - cfg_menu
    inputs{13, crun} = MATLAB_CODE_TO_FILL_INPUT; % Phase and Magnitude Data: Select anatomical image for comparison - cfg_files
    inputs{14, crun} = MATLAB_CODE_TO_FILL_INPUT; % Phase and Magnitude Data: Match anatomical image to EPI? - cfg_menu
    inputs{15, crun} = MATLAB_CODE_TO_FILL_INPUT; % Realign & Unwarp: Images - cfg_files
    inputs{16, crun} = MATLAB_CODE_TO_FILL_INPUT; % Realign & Unwarp: Images - cfg_files
    inputs{17, crun} = MATLAB_CODE_TO_FILL_INPUT; % Realign & Unwarp: Images - cfg_files
end
spm('defaults', 'FMRI');
spm_jobman('serial', jobs, '', inputs{:});
