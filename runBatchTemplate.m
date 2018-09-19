function completed = runBatchTemplate(inputFilenames, batchFilename, referenceFilename, sourceFilename)

% assume the batch will be run
completed = true;

% Define constants
TEMP_BATCH_JOB_FILENAME = 'TempJobFile.m';
FILENAME_INSERT_MARKER = '$$$INSERT_FILES$$$';
REFERENCE_INSERT_MARKER = '$$$INSERT_REFERENCE$$$';
SOURCE_INSERT_MARKER = '$$$INSERT_SOURCE$$$';

% open the batch file template and the new output file
fin = fopen(batchFilename);
fout = fopen(TEMP_BATCH_JOB_FILENAME , 'w');

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
        if strfind(data, FILENAME_INSERT_MARKER)

            % find the part of the current line before the reference marker
            [beforeText remainingText] = strtok(data, FILENAME_INSERT_MARKER);
            
            % now find the text after the marker
            afterText = strtok(remainingText, FILENAME_INSERT_MARKER);

            % print out the before text
            fprintf(fout, beforeText);
            
            % iterate through the lists of filenames, each one representing one
            % run's worth of data
            filenamesExist = false;
            for runFilenames = inputFilenames

                % convert from a cell array to an array of characters
                runFilenames = runFilenames{1};
                
                % make sure there are filenames in the current run
                if length(runFilenames) == 0
                    'Encountered a run without any files'
                    continue
                end
                
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
            
        elseif strfind(data, REFERENCE_INSERT_MARKER)
            
            % find the part of the current line before the reference marker
            [beforeText remainingText] = strtok(data, REFERENCE_INSERT_MARKER);
            
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
            [beforeText remainingText] = strtok(data, SOURCE_INSERT_MARKER);
            
            % now find the text after the marker
            afterText = strtok(remainingText, SOURCE_INSERT_MARKER);
            
            % put the before and after text on either side of the source
            % filename
            newData = [beforeText '{''' sourceFilename ',1''}' afterText];
            
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
    
    % TODO - rethrow the error up
    rethrow(error);
end

% close the input and output files to ensure the output file is completely
% written to disk before starting the batch job
fclose(fin);
fclose(fout);

% just to make sure there is no workspace name conflicts, clear all the
% variables in the current workspace
%clear;

% run the batch
nrun = 1; % enter the number of runs here
jobfile = fullfile(pwd, TEMP_BATCH_JOB_FILENAME);
jobs = repmat(jobfile, 1, nrun);
inputs = cell(0, nrun);
spm('defaults', 'FMRI');
spm_jobman('serial', jobs, '', inputs{:});