function fileLists = getStudyFolders(prefixes)

% iterate through the subjects and create the array of filelists
folderNames = {};

% recursively parse the folders and get the filenames for the current
% top level folder
fileLists = getFolderContents(pwd, prefixes, 1, folderNames);


function folderNames = getFolderContents(path, prefixes, depth, folderNames)

    % get the current prefix
    curPrefix = char(prefixes(depth));

    % create the current path
    curFolderPath = fullfile(path, curPrefix);
    
    % find all the session folder names in the current subject folder
    subFolders = dir([curFolderPath '*']);
    subFolders = {subFolders([subFolders.isdir]).name};
    
    % iterate through all the sessions for the runs
    for subFolder = subFolders

        % create the new path for the current subfolder
        newPath = fullfile(path, char(subFolder));
            
        % if this is the last prefix, then add the cur folder to the list
        if depth == length(prefixes)
 
            % add the current list of filenames to the list
            folderNames{end+1} = newPath;
            
        % otherwise, recurse down
        else

            % call this function recursively
            folderNames = getFolderContents(newPath, prefixes, depth+1, folderNames);
        end
    end
    
    
    
