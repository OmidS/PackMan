function DepMatUpdate(repoList, varargin)
    % DepMatUpdate. Clones or updates all repositories in a DepMatRepo list 
    %
    %
    %
    %     Licence
    %     -------
    %     Part of DepMat. https://github.com/tomdoel/depmat
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
   
    if ~init
        return;
    end
    
    forcePathUpdate = nargin > 1 && strcmp(varargin{1}, 'force');
    
    rootSourceDir = fullfile(getUserDirectory, 'depmat', 'Source');
    repoDirList = cell(1, numel(repoList));
    repoNameList = cell(1, numel(repoList));
    
    for repoIndex = 1 : numel(repoList)
        repo = repoList(repoIndex);
        repoCombinedName = [repo.Name '_' repo.Branch];
        repoSourceDir = fullfile(rootSourceDir, repoCombinedName);
        [~, changed] = DepMatCloneOrUpdate(repoSourceDir, repo);
        forcePathUpdate = forcePathUpdate || changed;
        repoDirList{repoIndex} = repoSourceDir;
        repoNameList{repoIndex} = repoCombinedName;
    end
    
    DepMatAddPaths(repoDirList, repoNameList, forcePathUpdate);
end

function success = init
    if ~isGitInstalled
        success = false;
        msgbox('Cannot find git');
        return;
    end
    
    fixCurlPath;
    success = true;
   
end

function installed = isGitInstalled
    installed = ~isempty(execute('which git'));
end

function output = execute(command)
    [return_value, output] = system(command);
    if (return_value ~= 0)
        output = [];
    end
end

function home_directory = getUserDirectory
    % Returns a path to the user's home folder
    if (ispc)
        home_directory = getenv('USERPROFILE');
    else
        home_directory = getenv('HOME');
    end
end

function fixCurlPath
    % Matlab's curl configuration doesn't include https so git will not work.
    % We need to add the system curl configuration directory earlier in the
    % path so that it picks up this one instead of Matlab's
    currentLibPath = getenv('DYLD_LIBRARY_PATH');
    binDir = '/usr/lib';
    if (7 == exist(binDir, 'dir')) && ~strcmp(currentLibPath(1:length(binDir) + 1), [binDir ':'])
        setenv('DYLD_LIBRARY_PATH', [binDir ':' currentLibPath]);
    end
end
