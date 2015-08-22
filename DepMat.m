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
    end
    
    methods
        function obj = DepMat(repoList, rootSourceDir)
            obj.RepoList = repoList;
            obj.RootSourceDir = rootSourceDir;
            DepMat.fixCurlPath;
        end
        
        function [anyChanged, repoDirList, repoNameList] = cloneOrUpdateAll(obj)
            anyChanged = false;
            repoDirList = cell(1, numel(obj.RepoList));
            repoNameList = cell(1, numel(obj.RepoList));
            
            for repoIndex = 1 : numel(obj.RepoList)
                repo = obj.RepoList(repoIndex);
                repoCombinedName = [repo.Name '_' repo.Branch];
                repoSourceDir = fullfile(obj.RootSourceDir, repoCombinedName);
                [~, changed] = DepMatCloneOrUpdate(repoSourceDir, repo);
                anyChanged = anyChanged || changed;
                repoDirList{repoIndex} = repoSourceDir;
                repoNameList{repoIndex} = repoCombinedName;
            end

        end
    end
    
    methods (Static)
        function [success, output] = execute(command)
            [return_value, output] = system(command);
            success = return_value == 0;
            if ~success
                if strfind(output, 'Protocol https not supported or disabled in libcurl')
                    disp('! You need to modify the the DYLD_LIBRARY_PATH environment variable to point to a newer version of libcurl. The version installed with Matlab does not support using https with git.');
                end
            end
        end

        function installed = isGitInstalled
            installed = ~isempty(DepMat.execute('which git'));
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
    end
    
end

