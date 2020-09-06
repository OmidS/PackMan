function toRemoveLater = prepareTestEnvironment()
%PREPARETESTENVIRONMENT Summary of this function goes here
%   Detailed explanation goes here
currentWorkingDir = pwd;
externalFolderPath = fullfile(currentWorkingDir,'source','external');
currentPath = path;
currentPathList = split(currentPath, ';');
currentPathList = rmmissing(currentPathList);
sourceFolderPath =fullfile(currentWorkingDir,'source');
toAddBefore = currentPathList(strcmp(currentPathList, sourceFolderPath));
if (isempty(toAddBefore))
    addpath(sourceFolderPath);
    currentPathList = [currentPathList; {sourceFolderPath}];
end
if exist(externalFolderPath, 'dir')
    nonGitExternalFolderPaths = genNonGitPath(externalFolderPath);
    externalFolderPathsToRemove = nonGitExternalFolderPaths(isTheres(currentPathList, nonGitExternalFolderPaths));
    if (~isempty(externalFolderPathsToRemove))
        rmpath(externalFolderPathsToRemove{:});
    end
    rmdir(externalFolderPath, 's');
end
packageFile = fullfile(currentWorkingDir,'package.json');
if exist(packageFile, 'file')
    delete(packageFile);
end
nonGitPath = genNonGitPath(currentWorkingDir);
toRemoveLater = nonGitPath(isTheres(currentPathList, nonGitPath));
toRemoveLater = toRemoveLater(~strcmp(toRemoveLater, fullfile(currentWorkingDir,'source','tests')));

function result = isThere(setOfElements, element)
result = ~isempty(setOfElements(strcmp(setOfElements, element)));

function result = isTheres(superSet, subSet)
result = cellfun(@(x)isThere(superSet, x), subSet);