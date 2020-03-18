%installDeps Installs/updates dependencies of the project
%   Inputs:
%     - (1) depList (optional, default: call getDepList): An array of 
%               DepMatRepo objects containing info about each dependency.
%     - (2) depSubDir (optional, default: 'external'): Name of subdirectory 
%               for dependencies. If you use something other than the
%               default, don't forget to add it to .gitignore so that git
%               doesn't track it. 
%     - (3 and later): will be passed to PackMan as the 3rd and later inputs.
%   Outputs:
%     - (1) pm (optional): the package manager object. This object can be
%               used to manually install deps by calling:
%                   pm.install(); 
%               It can also be used for adding dep paths to path by calling
%                   addpath(pm.genPath())
% 
%   Usage example:
%       % Modify getDepList.m to return the list of all dependencies.
%       % Then simply call this any time you want to install/update:
%       installDeps

function varargout = installDeps()

    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Directory of dependencies
    folderName = pwd;  
    paths = genpath(folderName);            
    pathList = split(paths, ';');
    pathList = rmmissing(pathList);
    nonGitPaths = pathList(~contains(pathList, '\.git'));
    
    oldPath = path;
    if (all(cellfun(@exist, nonGitPaths)== 7))
        addpath(nonGitPaths{:});
        s = which('installDeps.m', '-ALL');
        if length(s) >= 1
            installDepsPath = s{1};
            depSubDir = fullfile(fileparts(installDepsPath),'external');
            installPackMan( depSubDir );
            dpDirPth = fileparts(installDepsPath);
            getDepListFunction = fullfile(dpDirPth, 'getDepList.m');
            run(getDepListFunction);
            depList = ans;
        end
    else    
        depSubDir = fullfile('.', 'external');
        depSubDir = getDepDirPath( depSubDir );
        installPackMan( depSubDir );
    end
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get the list of dependencies
    if isempty(depList)
        depList = getDepList();
    end
    
    pm = PackMan(depList, depSubDir); % Install other dependencies
    
    if nargout < 1
        pm.install();
    else
        varargout{1} = pm;
    end
    
    path(oldPath);
    
    function depDirPath = getDepDirPath( depSubDir )
    % Generates path to dependency directory based on the path of the current
    % file
    % Inputs: 
    % (1) depSubDir: relative path of the dependency directory
    % Outputs:
    % (1) full path of the dependency subdir
    
    thisFilePath = mfilename('fullpath');
    [thisFileDir, ~, ~] = fileparts(thisFilePath);
    depDirPath = fullfile(thisFileDir, depSubDir);
    
    function installPackMan( depDirPath )
    % Makes sure DepMat is available and in the path, so that PackMan can
    % install other dependencies
    % Inputs: 
    % (1) depDirPath: path to dependency directory
    % Outputs: 
    % (none)
    % Usage example:
    % installPackMan( depDirPath );
    
    packManDir = fullfile(depDirPath, 'PackMan');
    try
        repoUrl = 'https://github.com/DanielAtKrypton/PackMan.git';
        command = ['git clone ', repoUrl, ' "',packManDir,'"'];
        [status, cmdout] = system(command);
        if (~status), fprintf('%s', cmdout); end
    catch
        
    end
    
    packManSourceDir = fullfile(packManDir,'source');
    
    addpath(genpath(packManSourceDir));