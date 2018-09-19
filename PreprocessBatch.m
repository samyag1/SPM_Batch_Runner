function PreprocessBatch(subjects, options)

% TODO
% 1. Add Dicom Conversion
% 5. Update the runBatchTemplateMulti method so it knows where to insert
% files by reading the parameter names instead of needing to have
% INSERT_MARKERS
% 6. Update the runBatchTemplateMulti so it reads the file prefix used at
% each step instead of needing to declare it in the options
% 7. Make it work on single or multi session experiments, excluding the
% session level folders if single
% 8. Make error handling robust and useful
% 9. Parallelize the code to run on multiple cores
% 10. FIgure out how to load the TSDiffAna configuration file into the
% batch editor automatically
% 11. Add Anwar's plotmovparams script as a part of realignment
% 12. Fix the bug in coregistration when the first session is split into
% two. The part 2 folders don't get coregistered
% 13. Add the mean image from run 1 to be coregistered and resliced to the
% first anatomical in 2 step coregistration.

oldPWD = pwd;
if not(exist(options.rootFolder, 'dir'))
    mkdir(options.rootFolder);
end
cd(options.rootFolder);
% spm_defaults();
% spm();

% Iterate through all the subjects passed in
for i = 1:numel(subjects)

    % store the prefix of the nifti files to use for the next processing step
    curFunctionalsPrefix = options.rawNiftiPrefix;
    curAnatomicalPrefix = options.anatomicalNiftiPrefix;

    % get the current subject
    curSubject = subjects{i};
    curSubjectFolder = fullfile(options.rootFolder, curSubject);
    if not(exist(curSubjectFolder, 'dir'))
        mkdir(curSubjectFolder);
    end
    
    % ToDo Open the log file
    logFilename = fullfile(curSubject, options.logFilename);
    logFile = fopen(logFilename, 'a');
    
    % ToDO Log the subject started processing
    logStatement = sprintf('%s\nSubject: %s\n%s\n\n', options.logSubjectSeparator, curSubject, options.logSubjectSeparator);
    fprintf(logFile, logStatement);
    
    %%%%%%%%%%%%%%%%%%%% Dicom Conversion %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if options.runConvertDicoms
        
        % Log the start of this step
        logStatement = sprintf('%s\nSTEP STARTING: %s\n\n', options.logStepSeparator, options.stepConvertDicoms);
        fprintf(logFile, logStatement);

        % do the conversion
        convertDicomsToNiftis(curSubject, ...
                              options.dicomFolder, ...
                              options.rootFolder, ...
                              options.dicomRuns{i}, ...
                              options.sessionPrefix, ...
                              options.runPrefix, ...
                              options.anatomicalRunPrefix, ...
                              options.fieldMapPrefix, ...
                              options.dummyScans);
    
        % Log the stop of this step
        logStatement = sprintf('\n\nSTEP FINISHED: %s\n%s\n\n', options.stepConvertDicoms, options.logStepSeparator);
        fprintf(logFile, logStatement);
    end
    
    %%%%%%%%%%%%%%%%%%%% 4D to 3D conversion %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if options.runConvert4Dto3D
        
        % Log the start of this step
        logStatement = sprintf('%s\nSTEP STARTING: %s\n\n', options.logStepSeparator, options.stepConvert4Dto3D);
        fprintf(logFile, logStatement);

        % do the conversion
        batch4Dto3DNifti(curSubject, options.sessionPrefix, options.runPrefix, '*.nii*', [options.rawNiftiPrefix, options.studyName]);
    
        % Log the stop of this step
        logStatement = sprintf('\n\nSTEP FINISHED: %s\n%s\n\n', options.stepConvert4Dto3D, options.logStepSeparator);
        fprintf(logFile, logStatement);
    end
    
    % NOTE: You must open the SPM batch editor and click file->"Add
    % Application" and select the cfg_tsdiffana.m file to be able to run
    % TSDiffAna through the batch editor like this script does.
    %%%%%%%%%%%%%%%%%%%% TSDiffAna %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if options.runTSDiffAna
        
        % Log the start of this step
        logStatement = sprintf('%s\nSTEP STARTING: %s\n\n', options.logStepSeparator, options.stepTSDiffAna);
        fprintf(logFile, logStatement);
        
        % get the cell array of filename lists, broken down by run
        filenamePrefixesTSDiffAna = {curSubject, options.sessionPrefix, options.runPrefix, curFunctionalsPrefix};
        fileListsTSDiffAna = getStudyFilenames(filenamePrefixesTSDiffAna);
        
        % apply the TSDiffAna batch template to one run's worth of data at a time.
        % because of the way the batch was written for TSDiffAna
        % This will create a
        % new batch file based on the template file passed in with all the files
        % added to it, then run the batch script
        for fileList = fileListsTSDiffAna
            runBatchTemplateMulti(options.stepTSDiffAna, curSubject, fileList, options.batchFilenameTSDiffAna, logFile);
        end
    
        % Log the stop of this step
        logStatement = sprintf('\n\nSTEP FINISHED: %s\n%s\n\n', options.stepTSDiffAna, options.logStepSeparator);
        fprintf(logFile, logStatement);
    end
    
    %%%%%%%%%%%%%%%%%%%% Despike %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if options.runDespike
        
        % Log the start of this step
        logStatement = sprintf('%s\nSTEP STARTING: %s\n\n', options.logStepSeparator, options.stepDespike);
        fprintf(logFile, logStatement);

        % get the cell array of folder names of all runs
        folderPrefixesDespike = {curSubject, options.sessionPrefix, options.runPrefix};
        folders = getStudyFolders(folderPrefixesDespike);
        
        % the despiker assumes the current folder is the one being
        % searched in for spikes, so store the current folder and move
        % into the folder to despike
        preDespikerFolder = pwd;
        
        % despike all the folders over which TSDiffAna was run
        for folder = folders
            folderName = folder{1};
            
            % split up the path into folders and find the run and session
            % name
            folders = regexp(folderName, '/', 'split');
            runName = folders{end};
            sessionName = folders{end-1};
            
            % check whether despiking was already run, and if so, move to
            % the next run
            doneFilenameDespike = fullfile(folderName, sprintf('done_blab_%s', options.stepDespike));
            if exist(doneFilenameDespike, 'file')
                logStatement = sprintf('Already ran %s on: %s-%s\n', options.stepDespike, sessionName, runName);
                fprintf(logFile, logStatement);
                continue;
            end
            
            try
                % change to the folder where spikes are being searched
                cd(folder{1});
                
                [volumes regressors] = run_despiker(folderName, options.totDespikerLimit, options.sliceDespikerLimit);
                
                % write out to the log that despiking was done succesfully
                logStatement = sprintf('Successfully ran %s on: %s-%s\n', options.stepDespike, sessionName, runName);
                fprintf(logFile, logStatement);
                
                % write out the done file
                system(sprintf('touch %s', doneFilenameDespike));
            catch error
                % write the error out to the log file and continue
                logStatement = sprintf('Failed running %s on: %s-%s\n\t Error type: %s\n\tError message: %s\n', options.stepDespike, sessionName, runName, error.identifier, error.message);
                fprintf(logFile, logStatement);
            end
        end
        
        % return to the folder before despiking
        cd(preDespikerFolder);
        
        % Log the stop of this step
        logStatement = sprintf('\n\nSTEP FINISHED: %s\n%s\n\n', options.stepDespike, options.logStepSeparator);
        fprintf(logFile, logStatement);
    end
    
    %%%%%%%%%%%%%%%%%%%% Realignment and Unwarping %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if options.runRealignmentAndUnwarp
        
        % Log the start of this step
        logStatement = sprintf('%s\nSTEP STARTING: %s\n\n', options.logStepSeparator, options.stepRealignmentAndUnwarp);
        fprintf(logFile, logStatement);
        
        % TEMP - since my code can't support modifying a unwarp batch file
        % that uses multiple field maps I just run a premade batch file
        % here. Remove this once I add support for multiple field maps
        if options.realignAndUnwarpFromBatch
            curUnwarpBatchFile = options.realignAndUnwarpBatchFiles{i};
 %           run(curUnwarpBatchFile);
        else
            % get the cell array of filename lists, broken down by run
            filenamePrefixesRealignment = {curSubject, options.sessionPrefix, options.runPrefix, curFunctionalsPrefix};
            fileListsRealignmentAndUnwarp = getStudyFilenames(filenamePrefixesRealignment, true);
            
            % the getStudyFilenames assumes all prefixes are just that, prefixes,
            % so looks for all folders/files with that prefix. Since the first
            % folder, the subject, is a real folder, the fileLists returns a list
            % of 1, for that subject. So trim it down to a list of session lists
            fileListsRealignmentAndUnwarp = fileListsRealignmentAndUnwarp{1};
            
            % put all the sessions data together into one if the flag says to
            if options.realignAllSessionsTogether
                % realign by session
                singleSessionFileLists = {};
                for curSession = 1:length(fileListsRealignmentAndUnwarp)
                    
                    % get the current epi files lists for this session
                    sessionFileLists = fileListsRealignmentAndUnwarp{curSession};
                    singleSessionFileLists = [singleSessionFileLists sessionFileLists];
                end
                
                % run the batch script that will do realignment on all the
                % files from the current session. This will first realign all
                % the volumes within a run to the first volume of that run,
                % then it will realign the first volume of runs 2-N with the
                % mean EPI of run1
                runBatchTemplateMulti(options.stepRealignmentAndUnwarp, curSubject, singleSessionFileLists, options.batchFilenameRealignmentAndUnwarp, logFile);
            else
                
                % realign by session
                for curSession = 1:length(fileListsRealignmentAndUnwarp)
                    
                    % get the current epi files lists for this session
                    sessionFileLists = fileListsRealignmentAndUnwarp{curSession};
                    
                    % run the batch script that will do realignment on all the
                    % files from the current session. This will first realign all
                    % the volumes within a run to the first volume of that run,
                    % then it will realign the first volume of runs 2-N with the
                    % mean EPI of run1
                    runBatchTemplateMulti(options.stepRealignmentAndUnwarp, curSubject, sessionFileLists, options.batchFilenameRealignmentAndUnwarp, logFile);
                end
            end
        end
        
        % update the current prefix to be the one just used
        curFunctionalsPrefix = [options.realignmentAndUnwarpNiftiPrefix curFunctionalsPrefix];
    
        % Log the stop of this step
        logStatement = sprintf('\n\nSTEP FINISHED: %s\n%s\n\n', options.stepRealignmentAndUnwarp, options.logStepSeparator);
        fprintf(logFile, logStatement);
    end
    
    %%%%%%%%%%%%%%%%%%%% Realignment %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if options.runRealignment
        
        % Log the start of this step
        logStatement = sprintf('%s\nSTEP STARTING: %s\n\n', options.logStepSeparator, options.stepRealignment);
        fprintf(logFile, logStatement);
        
        % get the cell array of filename lists, broken down by run
        filenamePrefixesRealignment = {curSubject, options.sessionPrefix, options.runPrefix, curFunctionalsPrefix};
        fileListsRealignment = getStudyFilenames(filenamePrefixesRealignment, true);
        
        % the getStudyFilenames assumes all prefixes are just that, prefixes,
        % so looks for all folders/files with that prefix. Since the first
        % folder, the subject, is a real folder, the fileLists returns a list
        % of 1, for that subject. So trim it down to a list of session lists
        fileListsRealignment = fileListsRealignment{1};
        
        % put all the sessions data together into one if the flag says to
        if options.realignAllSessionsTogether 
            % realign by session
            singleSessionFileLists = {};
            for curSession = 1:length(fileListsRealignment)
                
                % get the current epi files lists for this session
                sessionFileLists = fileListsRealignment{curSession};
                singleSessionFileLists = [singleSessionFileLists sessionFileLists];
            end
                
            % run the batch script that will do realignment on all the
            % files from the current session. This will first realign all
            % the volumes within a run to the first volume of that run,
            % then it will realign the first volume of runs 2-N with the
            % mean EPI of run1
            runBatchTemplateMulti(options.stepRealignment, curSubject, singleSessionFileLists, options.batchFilenameRealignment, logFile);            
        else
            
            % realign by session
            for curSession = 1:length(fileListsRealignment)
                
                % get the current epi files lists for this session
                sessionFileLists = fileListsRealignment{curSession};
                
                % run the batch script that will do realignment on all the
                % files from the current session. This will first realign all
                % the volumes within a run to the first volume of that run,
                % then it will realign the first volume of runs 2-N with the
                % mean EPI of run1
                runBatchTemplateMulti(options.stepRealignment, curSubject, sessionFileLists, options.batchFilenameRealignment, logFile);
            end
        end
                
        % update the current prefix to be the one just used
        curFunctionalsPrefix = [options.realignmentNiftiPrefix curFunctionalsPrefix];
    
        % Log the stop of this step
        logStatement = sprintf('\n\nSTEP FINISHED: %s\n%s\n\n', options.stepRealignment, options.logStepSeparator);
        fprintf(logFile, logStatement);
    end
    
    %%%%%%%%%%%%%%%%%%%% Slice Timing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if options.runSliceTiming
        
        % Log the start of this step
        logStatement = sprintf('%s\nSTEP STARTING: %s\n\n', options.logStepSeparator, options.stepSliceTiming);
        fprintf(logFile, logStatement);

        % get the cell array of filename lists, broken down by run
        filenamePrefixesSliceTiming= {curSubject, options.sessionPrefix, options.runPrefix, curFunctionalsPrefix};
        fileListsSliceTiming = getStudyFilenames(filenamePrefixesSliceTiming);
        
        % get the list of mean epi images for the first run of each session
        filenamePrefixesMeanEPIs = {curSubject, options.sessionPrefix, options.runPrefix, options.meanEPINiftiPrefix};
        fileListsMeanEPI = getStudyFilenames(filenamePrefixesMeanEPIs);
        
        % run slice timing
        for fileListIdx = 1:numel(fileListsSliceTiming)
            fileList = {[fileListsSliceTiming{fileListIdx} fileListsMeanEPI{fileListIdx}]};
            runBatchTemplateMulti(options.stepSliceTiming, curSubject, fileList, options.batchFilenameSliceTiming, logFile);
        end
                
        % update the current prefix to be the one just used
        curFunctionalsPrefix = [options.sliceTimingNiftiPrefix curFunctionalsPrefix];
    
        % Log the stop of this step
        logStatement = sprintf('\n\nSTEP FINISHED: %s\n%s\n\n', options.stepSliceTiming, options.logStepSeparator);
        fprintf(logFile, logStatement);
    end
    
    %%%%%%%%%%%%%%%%%%%% Coregistration %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if options.runCoregistration
        
        % Log the start of this step
        logStatement = sprintf('%s\nSTEP STARTING: %s\n\n', options.logStepSeparator, options.stepCoregistration);
        fprintf(logFile, logStatement);
        
        % get the filenames for the slice timed files preserving the structure of
        % subjects, sessions and runs
        filenamePrefixesCoregistration = {curSubject, options.sessionPrefix, options.runPrefix, curFunctionalsPrefix};
        fileListsCoregistration = getStudyFilenames(filenamePrefixesCoregistration, true);
        
        % get the list of anatomical files for each subject and session
        filenamePrefixesAnatomicals = {curSubject, options.sessionPrefix, options.anatomicalRunPrefix, curAnatomicalPrefix};
        fileListsanatomical = getStudyFilenames(filenamePrefixesAnatomicals, true);
        
        % get the list of mean epi images for the first run of each session
        filenamePrefixesMeanEPIs = {curSubject, options.sessionPrefix, options.runPrefix, options.meanEPINiftiPrefix};
        fileListsmeanEPI = getStudyFilenames(filenamePrefixesMeanEPIs, true);
       
        % the getStudyFilenames assumes all prefixes are just that, prefixes,
        % so looks for all folders/files with that prefix. Since the first
        % folder, the subject, is a real folder, the fileLists returns a list
        % of 1, for that subject. So trim it down to a list of session lists
        fileListsCoregistration = fileListsCoregistration{1};
        fileListsanatomical = fileListsanatomical{1};
        fileListsmeanEPI = fileListsmeanEPI{1};
            
        % get the anatmoical for the first session of this subject
        firstAnatomical = fileListsanatomical{1}{1}{1};
        
        % get the mean EPI for the first session of this subject
        firstMeanEPI = fileListsmeanEPI{1}{1}{1};
        
        % iterate through each session
        for curSession = 1:length(fileListsCoregistration)

            % if the realignment failed to produce a mean EPI in the first
            % folder, then write the error to log and move on
            if isempty(fileListsmeanEPI{curSession}{1})

                % make the log statement
                logStatement = sprintf('Missing the mean EPI running %s on session: %i\n', options.stepCoregistration, curSession);

                % write it out to the log file
                fprintf(logFile, logStatement);
                continue;    
            end
            % get the current mean epi for the first run of this session
            % take the first element of the array, as only the first run
            % will have a mean EPI image
            curMeanEPI = fileListsmeanEPI{curSession}{1}{1};
            
            % get the current epi files lists for this session
            curFileList = fileListsCoregistration{curSession};
            
            % since coregistration requires one list of files, and doesn't
            % take sets of images like other steps, concatonate all the
            % filename lists (runs) into one list
            newFileList = {};
            for i = 1:length(curFileList)
                curList = curFileList{i};
                newFileList = [newFileList curList];
            end
            curFileList = {newFileList};
            
            % 1 step registration is done when there is only anatomical for all
            % the sessions of a subject. Here, the mean EPI is registered
            % to the single anatomical
            if options.doFunctionalToFunctionalCoregistration
                
                if curSession ~= 1
                    % only reslice if user wants to
                    if options.resliceCoregisteredImages
                        % coregister the mean EPI to the one and only anatomical
                        % for this run
                        runBatchTemplateMulti(options.stepCoregistration, curSubject, curFileList, options.batchFilenameCoregistration, logFile, firstMeanEPI, curMeanEPI);
                    else
                        % coregister the mean EPI to the one and only anatomical
                        % for this run
                        runBatchTemplateMulti(options.stepCoregistrationEstimate, curSubject, curFileList, options.batchFilenameCoregistrationEstimate, logFile, firstMeanEPI, curMeanEPI);
                    end
                end
            elseif options.coregisterAnatomicalToFunctional
                % coregister the anatomical into functional space and
                % reslice it
                runBatchTemplateMulti(options.stepCoregistration, curSubject, {{firstAnatomical}}, options.batchFilenameCoregistration, logFile, curMeanEPI, firstAnatomical);
            elseif options.do1StepCoregistration
                
                % only reslice if user wants to
                if options.resliceCoregisteredImages
                    % coregister the mean EPI to the one and only anatomical
                    % for this run
                    runBatchTemplateMulti(options.stepCoregistration, curSubject, curFileList, options.batchFilenameCoregistration, logFile, firstAnatomical, curMeanEPI);
                else                
                    % coregister the mean EPI to the one and only anatomical
                    % for this run
                    runBatchTemplateMulti(options.stepCoregistrationEstimate, curSubject, curFileList, options.batchFilenameCoregistrationEstimate, logFile, firstAnatomical, curMeanEPI);
                end
            else
                
                % get the current anatomical file for this session
                % take the first element of the array, as there SHOULD only be
                % one anatomical in this list
                curAnatomical = fileListsanatomical{curSession}{1}{1};
                
                % coregister the mean epi to the mprage for this session,
                % only estimating the parameters
                runBatchTemplateMulti(options.stepCoregistrationEstimateFirst, curSubject, curFileList, options.batchFilenameCoregistrationEstimate, logFile, curAnatomical, curMeanEPI);
                
                % Add the mean epi to the list of files that should be
                % coregistered the second time
                curFileList{1}{end+1} = curMeanEPI;
                
                % if this isn't the first session then do the second
                % registration step. The first session doesn't need it
                % because it's already registered to the T1 of the first
                % session
                if curSession ~= 1
                    % coregister the mprage for this session to the mprage from
                    % the first session
                    runBatchTemplateMulti(options.stepCoregistrationEstimate, curSubject, curFileList, options.batchFilenameCoregistrationEstimate, logFile, firstAnatomical, curAnatomical);
                end
                
                % only reslice if user wants to
                if options.resliceCoregisteredImages
                    % coregister the mprage for this session to the mprage from
                    % the first session
                    runBatchTemplateMulti(options.stepCoregistrationReslice, curSubject, curFileList, options.batchFilenameCoregistrationReslice, logFile, curMeanEPI);
                end
            end
        end
        
        % update the current prefix to be the one just used
        curFunctionalsPrefix = [options.coregisterNiftiPrefix curFunctionalsPrefix];
%         curAnatomicalPrefix = [options.coregisterNiftiPrefix curAnatomicalPrefix];
        
        % Log the stop of this step
        logStatement = sprintf('\n\nSTEP FINISHED: %s\n%s\n\n', options.stepCoregistration, options.logStepSeparator);
        fprintf(logFile, logStatement);
    end
    
    %%%%%%%%%%%%%%%%%%%% Normalization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if options.runNormalization
        
        % Log the start of this step
        logStatement = sprintf('%s\nSTEP STARTING: %s\n\n', options.logStepSeparator, options.stepNormalization);
        fprintf(logFile, logStatement);
        
        % get the cell array of filename lists, broken down by run
        filenamePrefixesNormalization = {curSubject, options.sessionPrefix, options.runPrefix, curFunctionalsPrefix};
        fileListsNormalization = getStudyFilenames(filenamePrefixesNormalization, true);
        
        % get the list of anatomical files for each subject and session
        filenamePrefixesAnatomicals = {curSubject, options.sessionPrefix, options.anatomicalRunPrefix, curAnatomicalPrefix};
        fileListsAnatomical = getStudyFilenames(filenamePrefixesAnatomicals, true);
       
        % the getStudyFilenames assumes all prefixes are just that, prefixes,
        % so looks for all folders/files with that prefix. Since the first
        % folder, the subject, is a real folder, the fileLists returns a list
        % of 1, for that subject. So trim it down to a list of session lists
        fileListsNormalization = fileListsNormalization{1};
        fileListsAnatomical = fileListsAnatomical{1};
         
        % get the anatomical file for the first session
        % take the first element of the array, as there SHOULD only be
        % one anatomical in this list
        curAnatomical = fileListsAnatomical{1}{1}{1};
        
        for curSession = 1:length(fileListsNormalization)
            
            % get the current epi files lists for this session
            curFileList = fileListsNormalization{curSession};
            
            % since normalization requires one list of files, and doesn't
            % take sets of images like other steps, concatonate all the
            % filename lists into one if functionals are to be resliced
            newFileList = {};
            if options.normalizeFunctionals
                for i = 1:length(curFileList)
                    curList = curFileList{i};
                    newFileList = [newFileList curList];
                end
            end
            % and the anatomical if that is to be resliced
            if options.normalizeAnatomical
                newFileList(end+1) = {curAnatomical};
            end
            
            % since the runBatch function takes a cell array of cell arrays,
            % put the cell array containing all the filenames for the current
            % subject into another cell array
            curFileListNormalization = {newFileList};
            
            % run the batch script that will do segmentation, then use the
            % transformation matrix from that segmentation to do
            % normalization of the EPIs
            runBatchTemplateMulti(options.stepNormalization, curSubject, curFileListNormalization, options.batchFilenameNormalization, logFile, curAnatomical);
        end
     
        % update the current prefix to be the one just used
        curFunctionalsPrefix = [options.normalizationNiftiPrefix curFunctionalsPrefix];
        curAnatomicalPrefix = [options.normalizationNiftiPrefix curAnatomicalPrefix];
    
        % Log the stop of this step
        logStatement = sprintf('\n\nSTEP FINISHED: %s\n%s\n\n', options.stepNormalization, options.logStepSeparator);
        fprintf(logFile, logStatement);
    end
    
    %%%%%%%%%%%%%%%%%%%% Smoothing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if options.runSmoothing
        
        % Log the start of this step
        logStatement = sprintf('%s\nSTEP STARTING: %s\n\n', options.logStepSeparator, options.stepSmoothing);
        fprintf(logFile, logStatement);
        
        % get the cell array of filename lists, broken down by run
        filenamePrefixesNormalized = {curSubject, options.sessionPrefix, options.runPrefix, curFunctionalsPrefix};
        normalizedFileLists = getStudyFilenames(filenamePrefixesNormalized);
        
        % This will create a
        % new batch file based on the template file passed in with all the files
        % added to it, then run the batch script
        for fileList = normalizedFileLists
            runBatchTemplateMulti(options.stepSmoothing, curSubject, fileList, options.batchFilenameSmoothing, logFile);
        end
        
        % update the current prefix to be the one just used
        curFunctionalsPrefix = [options.smoothingNiftiPrefix curFunctionalsPrefix];
    
        % Log the stop of this step
        logStatement = sprintf('\n\nSTEP FINISHED: %s\n%s\n\n', options.stepSmoothing, options.logStepSeparator);
        fprintf(logFile, logStatement);
    end
    
    % close the log file
    fclose(logFile);
end

% return to the folder where the script was run
cd(oldPWD);