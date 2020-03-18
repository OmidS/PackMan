function pm = prepareTestEnvironment(depList)
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
end
if exist(externalFolderPath, 'dir')
    nonGitExternalFolderPaths = genNonGitPath(externalFolderPath);
    externalFolderPathToRemove = nonGitExternalFolderPaths(isEachMemberASubsetOfAny(currentPathList, nonGitExternalFolderPaths));
    if (~isempty(externalFolderPathToRemove))
        rmpath(externalFolderPathToRemove{:});
    end
    rmdir(externalFolderPath, 's');
end
packageFile = fullfile(currentWorkingDir,'package.json');
if exist(packageFile, 'file')
    delete(packageFile);
end
nonGitPath = genNonGitPath(currentWorkingDir);
toRemoveLater = nonGitPath(isEachMemberASubsetOfAny(currentPathList, nonGitPath));
toRemoveLater = toRemoveLater(~strcmp(toRemoveLater, fullfile(currentWorkingDir,'source','tests')));
pm = installDeps(depList);
pm.install();
rmpath(toRemoveLater{:});

function result = isSubset(superSet, subSet)
result = isempty(setdiff(subSet, superSet));

function result = isSubSetOfAny(superSetSet, subSet)
result = any(cellfun(@(x)isSubset(x, subSet), superSetSet));

function result = isEachMemberASubsetOfAny(superSetSet, subSetSet)
result = cellfun(@(x)isSubSetOfAny(superSetSet, x), subSetSet);