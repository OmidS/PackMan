classdef DepMat
    % DepMat A class used to update git repositories
    %
    %
    %
    %     Licence
    %     -------
    %     Part of DepMat. https://github.com/tomdoel/depmat
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %

    
    properties (SetAccess = private)
        RepoList
        RootSourceDir
        RepoUpdaterList
        RepoDirList
        RepoNameList
        dispHandler = @(x)(disp(x))
    end
    
    methods
        function obj = DepMat(repoList, rootSourceDir)
            obj.RepoList = repoList;
            obj.RootSourceDir = rootSourceDir;
            DepMat.fixCurlPath;
            
            obj.RepoDirList = cell(1, numel(obj.RepoList));
            obj.RepoNameList = cell(1, numel(obj.RepoList));
            obj.RepoUpdaterList = DepMatRepositoryUpdater.empty;
            
            for repoIndex = 1 : numel(obj.RepoList)
                repo = obj.RepoList(repoIndex);
                repoCombinedName = repo.FolderName;
                repoSourceDir = fullfile(obj.RootSourceDir, repoCombinedName);
                repo = DepMatRepositoryUpdater(repoSourceDir, repo);
                repo.setDispHandler(obj.dispHandler);
                obj.RepoUpdaterList(repoIndex) = repo;
                obj.RepoDirList{repoIndex} = repoSourceDir;
                obj.RepoNameList{repoIndex} = repoCombinedName;
            end
        end
        
        function [statusList, varargout] = getAllStatus(obj)
            statusList = DepMatStatus.empty;
            local_commit_ids = cell(size(obj.RepoList));
            for repoIndex = 1 : numel(obj.RepoList)
                repo = obj.RepoUpdaterList(repoIndex);
                [statusList(repoIndex), local_commit_ids{repoIndex}] = repo.getStatus;
            end
            if nargout > 1, varargout{1} = local_commit_ids; end
        end
        
        function success = updateAll(obj)
            success = true;
            for repoIndex = 1 : numel(obj.RepoList)
                repo = obj.RepoUpdaterList(repoIndex);
                success = success && repo.updateRepo;
            end
        end
        
        function anyChanged = cloneOrUpdateAll(obj)
            anyChanged = false;
            
            for repoIndex = 1 : numel(obj.RepoList)
                repo = obj.RepoUpdaterList(repoIndex);
                [~, changed] = repo.cloneOrUpdate;
                anyChanged = anyChanged || changed;
            end

        end
        
        function setDispHandler(obj, funcHandle)
            obj.dispHandler = funcHandle;
            for repoIndex = 1:length(obj.RepoUpdaterList)
                obj.RepoUpdaterList(repoIndex).setDispHandler(obj.dispHandler);
            end
        end
    end
    
    methods (Static)
        function [success, output] = execute(command)
            [return_value, output] = system(command);
            success = return_value == 0;
            if ~success
                if contains(output, 'Protocol https not supported or disabled in libcurl')
                    obj.dispHandler('! You need to modify the the DYLD_LIBRARY_PATH environment variable to point to a newer version of libcurl. The version installed with Matlab does not support using https with git.');
                end
            end
        end

        function installed = isGitInstalled
            installed = true;
            try
                git('--help');
            catch
                installed = false;
            end
        end
        
        function fixCurlPath
            % Matlab's curl configuration doesn't include https so git will not work.
            % We need to add the system curl configuration directory earlier in the
            % path so that it picks up this one instead of Matlab's
            
            try
                if ismac
                    pathName = 'PATH';
                    binDir = '/usr/lib';
                elseif isunix
                    pathName = 'LD_LIBRARY_PATH';
                    binDir = '/usr/lib';
                else
                    pathName = [];
                    binDir = [];
                end
                
                if ~isempty(pathName)
                    currentLibPath = getenv(pathName);
                    if (7 == exist(binDir, 'dir')) && ~strcmp(currentLibPath(1:length(binDir) + 1), [binDir ':'])
                        setenv(pathName, [binDir ':' currentLibPath]);
                    end
                end
            catch exception
                obj.dispHandler(['DepMat:fixCurlPath error: ' exception.message]);
            end
        end
    end
    
end

