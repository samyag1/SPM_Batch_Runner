function fileLists = getStudyFilenames(prefixes, keepStructureParam)

keepStructure = false;
if nargin > 1
    keepStructure = keepStructureParam;
end

% recursively parse the folders and get the filenames for the current
% top level folder
fileLists = getFolderContents(pwd, prefixes, 1, keepStructure);


function returnList = getFolderContents(path, prefixes, depth, keepStructure)

    % get the current prefix
    curPrefix = char(prefixes(depth));

    % create the current path
    curFolderPath = fullfile(path, curPrefix);
    
    % if this is the last prefix, then the files from this folder should be
    % added to the fileList
    if depth == length(prefixes)
 
        % find all the niftis in the current run folder
        filenames = dir([curFolderPath '*.nii']);
        filenames = {filenames(~[filenames.isdir]).name};
        
        % prepend the path to the filenames
        for i = 1:length(filenames)
            filenames{i} = fullfile(path, filenames{i});
        end
 
        % if the structure is to be kept, return only a cell array of
        % filenames
        if keepStructure
            returnList = filenames;
        % if structure is not to be kept, then return a cell array of size
        % one, which contains the cell array of filenames so that it can be
        % treated just like a subfolder with only level
        else
          
           % store the cell array of filenames as the return list
           returnList = {};
           returnList{end+1} = filenames;
        end
     % otherwise, recurse down
    else

        % find all the session folder names in the current subject folder
        subFolders = dir([curFolderPath '*']);
        subFolders = {subFolders([subFolders.isdir]).name};
    
        % if the strucutre is to be kept, then we know how many items this
        % return list will have, so preallocate
        if keepStructure
            returnList = cell(1, length(subFolders));
        % otherwise we don't, so just create an empty cell array
        else
            returnList = {};
        end
            
        % iterate through all the sessions for the runs
        for i = 1:length(subFolders)

            % get the current subFolder
            subFolder = subFolders{i};
            
            % create the new path for the current subfolder
            newPath = fullfile(path, char(subFolder));
            
            % call this function recursively
            subFolderList = getFolderContents(newPath, prefixes, depth+1, keepStructure);
           
            % if the structure is to be kept, put all the subfolder lists
            % into the return list in order
            if keepStructure
                returnList{i} = subFolderList;
            % otherwise concatonate the return list with the current
            % subfolder list, which will keep the list flat
            else
                returnList = [returnList subFolderList];
            end
        end
    end
    
    
% function fileLists = getStudyFilenames(prefixes, keepStructureParam)
% 
% keepStructure = false;
% if nargin > 1
%     keepStructure = keepStructureParam;
% end
% 
% % iterate through the subjects and create the array of filelists
% fileLists = {};
% 
% % recursively parse the folders and get the filenames for the current
% % top level folder
% fileLists = getFolderContents(pwd, prefixes, 1, fileLists, keepStructure);
% 
% 
%    
% function fileLists = getFolderContents(path, prefixes, depth, fileLists, keepStructure)
% 
%     % get the current prefix
%     curPrefix = char(prefixes(depth));
% 
%     % create the current path
%     curFolderPath = fullfile(path, curPrefix);
%     
%     % if this is the last prefix, then the files from this folder should be
%     % added to the fileList
%     if depth == length(prefixes)
%  
%         % find all the niftis in the current run folder
%         filenames = dir([curFolderPath '*.nii']);
%         filenames = {filenames(~[filenames.isdir]).name};
%         
%         % prepend the path to the filenames
%         for i = 1:length(filenames)
%             filenames{i} = fullfile(path, filenames{i});
%         end
%         
%         % if the strucutre is to be kept, then all that is needed is a cell
%         % array of the actual filenames
%         if keepStructure
%             fileLists = filenames;
%         % but if the structure isn't kept, then the fileLists parameter
%         % passed in is to be populated with cell array's that contain the
%         % filenames, so add it to that cell array
%         else
%             % add the current list of filenames to the list
%             fileLists{end+1} = filenames;
%         end
%     % otherwise, recurse down
%     else
% 
%         % find all the session folder names in the current subject folder
%         subFolders = dir([curFolderPath '*']);
%         subFolders = {subFolders([subFolders.isdir]).name};
%     
%         subFoldersLists = cell(length(subFolders));
%         
%         % iterate through all the sessions for the runs
%         for i = length(subFolders)
% 
%             % get the current subFolder
%             subFolder = subFolders{i};
%             
%             % create the new path for the current subfolder
%             newPath = fullfile(path, char(subFolder));
%             
%             % call this function recursively
%             newFileLists = getFolderContents(newPath, prefixes, depth+1, fileLists, keepStructure);
% 
%             % if the structure is to be kept, then just add the newly
%             % created cell array to the end of the current cell array
%             % which results in a nesting of cell arrays as deep as the
%             % prefixes array
%             if keepStructure
%                 subFoldersLists{i} = newFileLists;
%             % otherwise just store the new file list for return
%             else
%                 fileLists = newFileLists;
%             end
%         end
%         
%         if keepStructure
%             fileLists = subFoldersLists
%         end
%     end
%     
%     
%     
