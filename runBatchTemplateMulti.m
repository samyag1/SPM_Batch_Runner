function completed = runBatchTemplateMulti(step, id, inputFilenames, batchFilename, logFile, referenceFilename, sourceFilename, matnameFilename)

% assume the batch will be run
completed = true;

% Define constants
TEMP_BATCH_JOB_FILENAME = 'TempJobFile';
FILES_INSERT_MARKER = '$$$INSERT_FILES$$$';
REFERENCE_INSERT_MARKER = '$$$INSERT_REFERENCE$$$';
SOURCE_INSERT_MARKER = '$$$INSERT_SOURCE$$$';
MATNAME_INSERT_MARKER = '$$$INSERT_MATNAME$$$';

% create the name of the done file for this step
doneFilename = sprintf('done_blab_%s', step);

% look through all the files in all the file groups and determine what
% folders (runs/sessions) are being processed here
runFolders = {};
runName = 'Unknown';
sessionName = 'Unknown';
missingFiles = false;
for groupIdx = 1:numel(inputFilenames)
    
    % get the current session's list of filenames
    curGroupFiles = inputFilenames{groupIdx};
                    
    % make sure there are filenames in the current run
    if numel(curGroupFiles) == 0
        missingFiles = true;
    else
    
        for fileIdx = 1:numel(curGroupFiles)
            
            % get the current filename
            curFilename = curGroupFiles{fileIdx};
            
            % split the current filename up into it's folders
            path = fileparts(curFilename);
            folders = regexp(path, '/', 'split');
            
            % store the session name and add the run name to the list
            if ~ismember(path, runFolders)
                runFolders{end+1} = path;
            end
            
            % ASSUME only one session's worth of data every preprocessed here
            runName = folders{end};
            sessionName = folders{end-1};
        end
    end
end

% since some preprocessing steps act on runs, and some on a session's
% worth of runs, determine what to call this grouping of files
if numel(runFolders) > 1
    processingUnit = sessionName;
else
    processingUnit = sprintf('%s-%s',sessionName, runName);
end

% if there are any missing files from the current group, then write that
% out to the log and return
if missingFiles
    % make the log statement
    logStatement = sprintf('Missing files running %s on: %s\n', step, processingUnit);
    
    % write it out to the log file
    fprintf(logFile, logStatement);
    completed = false;
    return;    
end

% verify there's a valid reference file, if one was passed in
if numel(nargin) > 5 && isempty(referenceFilename)
    % make the log statement
    logStatement = sprintf('Missing a reference file running %s on: %s\n', step, processingUnit);
    
    % write it out to the log file
    fprintf(logFile, logStatement);
    completed = false;
    return;    
end

% verify there's a valid reference file, if one was passed in
if numel(nargin) > 6 && isempty(sourceFilename)
    % make the log statement
    logStatement = sprintf('Missing a source file running %s on: %s\n', step, processingUnit);
    
    % write it out to the log file
    fprintf(logFile, logStatement);
    completed = false;
    return;    
end

% verify there's a valid reference file, if one was passed in
if numel(nargin) > 7 && isempty(matnameFilename)
    % make the log statement
    logStatement = sprintf('Missing a matname file running %s on: %s\n', step, processingUnit);
    
    % write it out to the log file
    fprintf(logFile, logStatement);
    completed = false;
    return;    
end

% Check if the done file exists for all run folders in this group
groupDone = false;
for folderIdx = 1:numel(runFolders)
    % get the current folder name
    curFolder = runFolders{folderIdx};
    
    % determine the name of the done file within the current folder
    folderDoneFilename = fullfile(curFolder, doneFilename);
    
    % see if the donefile exists
    groupDone = exist(folderDoneFilename, 'file');
    if ~groupDone
        break;
    end
end

% if all runs for this group are done then log that, and retunr
if groupDone    
    % make the log statement
    logStatement = sprintf('Already ran %s on: %s\n', step, processingUnit);
    
    % write it out to the log file
    fprintf(logFile, logStatement);
    completed = false;
    return;
end    

% create the temp batch filename to use, checking to make sure it isn't
% already in use
notFound = true;
counter = 1;
while notFound
    jobFilename = fullfile(pwd, [TEMP_BATCH_JOB_FILENAME '_' id '_' num2str(counter) '.m']);
    if ~exist(jobFilename, 'file');
        notFound = false;
    end
    counter = counter + 1;
end

% open the batch file template and the new output file
fin = fopen(batchFilename);
if fin == -1
    % make the log statement
    logStatement = sprintf('Failed to open batchFilename %s during step %s on: %s\n', batchFilename, step, processingUnit);
    
    % write it out to the log file
    fprintf(logFile, logStatement);
    completed = false;
    return;
end

% open the job file
fout = fopen(jobFilename, 'w');

try
    % iterate through the locations in the batch file template that require the
    % input filenames
    while true

        % read in the current line from the template file
        data = fgets(fin);

        % if there is no more data in the template file, then break out of this
        % looop
        if data == -1
            break;
        end

        % if the current line contains the file input marker, then replace it
        % with the filenames
        if strfind(data, FILES_INSERT_MARKER)

            % find the part of the current line before the reference marker
            [beforeText, remainingText] = strtok(data, FILES_INSERT_MARKER);
            
            % now find the text after the marker
            afterText = strtok(remainingText, FILES_INSERT_MARKER);

            % print out the before text
            fprintf(fout, beforeText);
            
            if isempty(inputFilenames)
                % write out curly brackets with an empty string inside,
                % indicating no input files are specified 
                fprintf(fout,  ['{' '''' '''' '}' afterText '\n']);
            else
                % iterate through the lists of filenames, each one representing one
                % run's worth of data
                filenamesExist = false;
                for curListIndex = 1:length(inputFilenames)
                    
                    % convert from a cell array to an array of characters
                    runFilenames = inputFilenames{curListIndex};
                    
                    % indicate that at least some filenames exist
                    filenamesExist = true;
                    
                    % write out the open brackets indicating the start of a run's
                    % worth of filenames
                    fprintf(fout, '{\n');
                    
                    % iterate through all the filenames in the current run and
                    % write each one out on a separate line
                    for curFilename = runFilenames
                        
                        % write out the current filename
                        fprintf(fout, '%s\n', ['''' char(curFilename) ',1''']);
                    end
                    
                    % write out the close brackets indicating the end of a run's
                    % worth of filenames
                    fprintf(fout, '}');
                    
                    % add a new line in between lists of filenames, but not on
                    % the last line
                    if curListIndex ~= length(inputFilenames)
                        fprintf(fout, '\n');
                    end
                end
            
                % now write out the after text
                fprintf(fout, [afterText '\n']);

                % make sure there is at least one list with one filename in the list of
                % filename lists, otherwise return since this will cause the
                % job manager to hang forever
                if ~filenamesExist
                    completed = false;
                    return;
                end
            end
            
        elseif strfind(data, REFERENCE_INSERT_MARKER)
            
            % find the part of the current line before the reference marker
            [beforeText, remainingText] = strtok(data, REFERENCE_INSERT_MARKER);
            
            % now find the text after the marker
            afterText = strtok(remainingText, REFERENCE_INSERT_MARKER);
            
            % put the before and after text on either side of the reference
            % filename
            newData = [beforeText '{''' referenceFilename ',1''}' afterText];
            
            % write out the new data with the reference filename in place
            % of the reference marker
            fprintf(fout, newData);
        elseif strfind(data, SOURCE_INSERT_MARKER)
            
            % find the part of the current line before the source marker
            [beforeText, remainingText] = strtok(data, SOURCE_INSERT_MARKER);
            
            % now find the text after the marker
            afterText = strtok(remainingText, SOURCE_INSERT_MARKER);
            
            % put the before and after text on either side of the source
            % filename
            newData = [beforeText '{''' sourceFilename ',1''}' afterText];
            
            % write out the new data with the source filename in place
            % of the reference marker
            fprintf(fout, newData);
        elseif strfind(data, MATNAME_INSERT_MARKER)
            
            % find the part of the current line before the source marker
            [beforeText, remainingText] = strtok(data, MATNAME_INSERT_MARKER);
            
            % now find the text after the marker
            afterText = strtok(remainingText, MATNAME_INSERT_MARKER);
            
            % put the before and after text on either side of the source
            % filename
            newData = [beforeText '{''' matnameFilename '''}' afterText];
            
            % write out the new data with the source filename in place
            % of the reference marker
            fprintf(fout, newData);
        % otherwise just write out the current line to the new file
        else
            fprintf(fout, data);
        end
    end
catch error
    
    % close the files
    fclose(fin);
    fclose(fout);
    
    % now delete the file just created
    delete(jobFilename);
   
    % log that the current run/session has failed and return
    logStatement = sprintf('Failed running %s on: %s\n', step, processingUnit);
    
    % write it out to the log file
    fprintf(logFile, logStatement);
    completed = false;
    return;
end

% close the input and output files to ensure the output file is completely
% written to disk before starting the batch job
fclose(fin);
fclose(fout);

% run the batch
nrun = 1; % enter the number of runs here
jobs = repmat(jobFilename, 1, nrun);
inputs = cell(0, nrun);
spm('defaults', 'FMRI');
try
    spm_jobman('serial', jobs, '', inputs{:});
catch error
    % now delete the file just created
    delete(jobFilename);
      
    % log that the current run/session has failed and return
    logStatement = sprintf('Failed running %s on: %s\n', step, processingUnit);
    
    % write it out to the log file
    fprintf(logFile, logStatement);
    completed = false;
    return;
end

% now delete the file just created
delete(jobFilename);

% ToDo Log that the run/session has finished this step succesfully
logStatement = sprintf('Succesfully ran %s on: %s\n', step, processingUnit);
fprintf(logFile, logStatement);

% write out the done file for the runFolders for this step
for folderIdx = 1:numel(runFolders)
    % get the current folder name
    curFolder = runFolders{folderIdx};
    
    % determine the name of the done file within the current folder
    folderDoneFilename = fullfile(curFolder, doneFilename);
   
    system(sprintf('touch %s', folderDoneFilename));
end