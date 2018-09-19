function batch4Dto3DNifti(subjectPrefix, sessionPrefix, runPrefix, fileFilter4D, filePrefix3D)    

% find all the subject folder names in the current folder
subjects = dir([subjectPrefix '*']);
subjects = {subjects([subjects.isdir]).name};
    
% iterate through the subjects and create the array of filelists
for subject = subjects
    
    % convert the subject folder into a string
    subject = char(subject);
    
    % create the subject path
    subjectPath = fullfile(subject, sessionPrefix);
    
    % find all the session folder names in the current subject folder
    sessions = dir([subjectPath '*']);
    sessions = {sessions([sessions.isdir]).name};
    
    % iterate through all the sessions for the runs
    for session = sessions
        
        session = char(session);
        
        % make the current session path
        sessionPath = fullfile(subject, session, runPrefix);
        
        % find all the run folder names in the current session folder
        runs = dir([sessionPath '*']);
        runs = {runs([runs.isdir]).name};
        
        % iterate through all the runs
        for run = runs
            
            run = char(run);
            
            % make the current run path
            runPath = fullfile(subject, session, run);
            
            % check if 3D files with the given file prefix already exist,
            % if so, move on to the next run
            files3D = dir(fullfile(runPath, [filePrefix3D '*']));
            if length(files3D) > 0
                continue;
            end
            
            filenames4D = dir([runPath fileFilter4D]);
            filenames4D = {filenames4D([filenames4D.isdir]).name};
          
            if numel(filenames4D) == 0
                error(['Folder: ' runPath ' contains no 4D nifti to convert']);
            elseif numel(filenames4D) > 1
                error(['Folder: ' runPath ' contains multiple 4D niftis to convert']);
            end
            
            filename4D = filenames4D{1};
            filePath4D = fullfile(runPath, filename4D);
            
            % make sure the 4D file is there
            if ~exist(filePath4D, 'file')
                out = ['Trying to convert 4D file which does not exist: ' filePath4D]
                continue;
            end
            
            oldPwd = pwd;
            cd(runPath);
            
            try
                % use the fslsplit command to turn into 3D files
                splitText = ['fslsplit ' filename4D ' ' filePrefix3D];
                system(splitText);

                % now unzip all the 3D files 
                filenames3D = dir([filePrefix3D '*']);
                filenames3D = {filenames3D(~[filenames3D.isdir]).name};
                for filename3D = filenames3D
                    filename3D = char(filename3D);
                    system(['fslchfiletype NIFTI ' filename3D]);
                end
            catch error
                cd(oldPwd);
                rethrow(error)
            end
            
            cd(oldPwd);
        end
    end
end
