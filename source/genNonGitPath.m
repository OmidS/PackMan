function pathList = genNonGitPath(folderName)
    %genPath - Description
    %
    % Syntax: output = genPath(input)
    %
    % Long description
        
    paths = genpath(folderName);            
    pathList = split(paths, ';');
    pathList = rmmissing(pathList);
    pathList = pathList(~contains(pathList, '\.git'));