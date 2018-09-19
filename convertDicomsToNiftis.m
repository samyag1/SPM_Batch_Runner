function convertDicomsToNiftis(subject, dicomFolder, niftiFolder, dicomRuns, sessionPrefix, runPrefix, anatomicalPrefix, fieldMapPrefix, dummyScans)

sessionCount = numel(dicomRuns.functionalRuns);
assert(sessionCount == numel(dicomRuns.anatomicalRuns) && sessionCount == numel(dicomRuns.fieldmapRuns));

% find all the folders in the dicom folder that begin with the Session
% prefix
subjectDicomFolder = fullfile(dicomFolder, subject);
sessionsWildcard = fullfile(subjectDicomFolder, [sessionPrefix '*']);
sessionFolderNames = dir(sessionsWildcard);
sessionFolderNames = {sessionFolderNames([sessionFolderNames.isdir]).name};
sessionFolderCount = numel(sessionFolderNames);

sessionPrefixSize = numel(sessionPrefix);

prevSessNo = 0;
prevFunctionalCount = 0;
prevFieldMapCount = 0;
prevAnatomicalCount = 0;

% make this subject's nifti folder if it doesn't already exist
subjectNiftiFolder = fullfile(niftiFolder, subject);
if not(exist(subjectNiftiFolder, 'dir'))
    mkdir(subjectNiftiFolder);
end

% iterate through the sessions
for curSessFolderIdx = 1:sessionFolderCount
    
    % determine what session number this
    curSessDicomFolder = sessionFolderNames{curSessFolderIdx};
    dashIdx = strfind(curSessDicomFolder, '-');
    if isempty(dashIdx)
        curSessNo = str2num(curSessDicomFolder(numel(sessionPrefix)+1));
        curSessName = curSessDicomFolder;
    else
        curSessNo = str2num(curSessDicomFolder(sessionPrefixSize+1:dashIdx-1));
        curSessName = curSessDicomFolder(1:dashIdx-1);
    end
    
    % make the folder for the current session if it doesn't already exist
    curSessNiftiFolder = fullfile(subjectNiftiFolder, curSessName);
    if not(exist(curSessNiftiFolder, 'dir'))
        mkdir(curSessNiftiFolder);
    end
    
    % get the lists of functionals and field maps, and the anatomical run
    % for the current session
    curAnatomicalIdx = dicomRuns.anatomicalRuns(curSessFolderIdx);
    curFunctionalIdxs = dicomRuns.functionalRuns{curSessFolderIdx};
    curFieldMapLists = dicomRuns.fieldmapRuns{curSessFolderIdx};
    curFieldMapIdxs = [];
    for curFieldMapPair = 1:numel(curFieldMapLists)
        curFieldMapIdxs = [curFieldMapIdxs curFieldMapLists{curFieldMapPair}];
    end    

    % reset the previous session counts if this is a new sessions,
    % otherwise they will be used to get the run numbering right for
    % sessions split across multiple days
    if prevSessNo ~= curSessNo
        prevFunctionalCount = 0;
        prevFieldMapCount = 0;
        prevAnatomicalCount = 0;
        prevSessNo = curSessNo;
    end
    
    % read all the run folders in the dicom folder, then iterate through
    % them and convert the necessary ones
    curSessDicomPath = fullfile(subjectDicomFolder, curSessDicomFolder);
    runFolderNames = dir(curSessDicomPath);
    runFolderNames = {runFolderNames([runFolderNames.isdir]).name};
    for curRunIdx = 1:numel(runFolderNames)
        
        % determine what run number this run is
        curDicomRunName = runFolderNames{curRunIdx};
        if strcmp(curDicomRunName, '.') || strcmp(curDicomRunName, '..')
            continue
        end
        curDicomRunPath = fullfile(curSessDicomPath, curDicomRunName);
        underscoreIdxs = strfind(curDicomRunName, '_');
        curRunNo = str2num(curDicomRunName(underscoreIdxs(end)+1:end));
        
        % now determine if this run is a functional, anatomical, field map
        % or something we don't care about
        if ismember(curRunNo,curAnatomicalIdx)
            anatomicalNo = find(curRunNo == curAnatomicalIdx) + prevAnatomicalCount;
            anatomicalNiftiName = sprintf('%s%i', anatomicalPrefix, anatomicalNo);
            anatomicalNiftiPath = fullfile(niftiFolder, subject, curSessName, anatomicalNiftiName);
            convertRun(curDicomRunPath, anatomicalNiftiPath, true, 0);
        elseif ismember(curRunNo, curFunctionalIdxs)
            functionalNo = find(curFunctionalIdxs == curRunNo) + prevFunctionalCount;
            curNiftiRunName = sprintf('%s%02i', runPrefix, functionalNo);            
            curNiftiRunPath = fullfile(niftiFolder, subject, curSessName, curNiftiRunName);
            convertRun(curDicomRunPath, curNiftiRunPath, false, dummyScans);
        elseif ismember(curRunNo, curFieldMapIdxs)
            fieldMapNo = -1;
            fieldMapType = '';
            for curFieldMapPair = 1:numel(curFieldMapLists)
                if ismember(curRunNo, curFieldMapLists{curFieldMapPair})
                    fieldMapNo = curFieldMapPair + prevFieldMapCount;
                    % the first of the two folders is always the magnitude
                    if curFieldMapLists{curFieldMapPair}(1) == curRunNo
                        fieldMapType = 'mag';
                    % and the second is the phase
                    else
                        fieldMapType = 'phase';
                    end
                    break;
                end
            end
            assert(fieldMapNo ~= -1);
            
            curFieldMapRunName = sprintf('%s%02i_%s', fieldMapPrefix, fieldMapNo, fieldMapType);            
            curFieldMapRunPath = fullfile(niftiFolder, subject, curSessName, curFieldMapRunName);
            convertRun(curDicomRunPath, curFieldMapRunPath, true, 0);
        end
    end

    % store the number of runs of each type for this session
    prevFunctionalCount = numel(curFunctionalIdxs);
    prevFieldMapCount = numel(curFieldMapLists);
    prevAnatomicalCount = numel(curAnatomicalIdx);
end

end

function convertRun(dicomFolder, niftiFolder, singleOutput, dummyScans)

    % make sure the output nifti folder exists
    if not(exist(niftiFolder, 'dir'))
        mkdir(niftiFolder);
    else
        % if the folder already contains niftis, then just return
        niftiWildcard = fullfile(niftiFolder, '*.nii');
        niftiFilenames = dir(niftiWildcard);
        if numel(niftiFilenames) > 0
            return;
        end
    end
    
    dummyScansFolder = fullfile(niftiFolder, 'dummy_scans');
    if dummyScans > 0
        if not(exist(dummyScansFolder, 'dir'))
            mkdir(dummyScansFolder);
        end
    end
    
    % store the current workinig folder, so it can be restored later
    oldPWD = pwd();
    
    % read all the dicom filenames into a cell array
    dicomWildcard = fullfile(dicomFolder, '*.dcm');
    dicomFilenames = dir(dicomWildcard);
    dicomFilenames = {dicomFilenames(not([dicomFilenames.isdir])).name};

    if singleOutput
        % change directory to the output
        % nifti directory because SPM is retarded
        cd(niftiFolder);
        
        dicomHeaders = [];
        for filenameIdx= 1:numel(dicomFilenames)
            
            % read in the dicom headers
            curDicomFilename = fullfile(dicomFolder, dicomFilenames{filenameIdx});
            dicomHeaders = [dicomHeaders spm_dicom_headers(curDicomFilename)];
        end
            
        % convert the dicoms
        spm_dicom_convert(dicomHeaders, 'all', 'flat', 'nii');
    else
        for filenameIdx= 1:numel(dicomFilenames)

            % if the current filename is a dummy scan, then move into the
            % dummy scans folder so files are written there
            if filenameIdx <= dummyScans
                cd(dummyScansFolder);
            % otherwise move into the regular nifti folder
            else
                cd(niftiFolder);                
            end
            
            % read in the dicom headers
            curDicomFilename = fullfile(dicomFolder, dicomFilenames{filenameIdx});
            dicomHeader = spm_dicom_headers(curDicomFilename);
            
            % convert the dicoms
            spm_dicom_convert(dicomHeader, 'all', 'flat', 'nii');
        end
    end
    
    % change folder back to the previous directory
    cd(oldPWD);
end