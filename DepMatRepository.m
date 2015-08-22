classdef DepMatRepository < handle
    % DepMatRepository. Query, clone and update a git repository
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
        SourceDir
        RepoDef
    end
    
    properties (Constant, Access = private)
        FetchFailureFileName = 'depmat_fetch_failure' 
    end
    
    methods
        function obj = DepMatRepository(sourceDir, repoDef)
            % Creates a DepMatRepository object for checking the status of
            % and updating a git repository
 
            obj.SourceDir = sourceDir;
            obj.RepoDef = repoDef;
        end
        
        function status = getStatus(obj)
            % Returns the current git status of this repository, as one of
            % the enumerations in DepMatStatus
            
            if ~(exist(obj.SourceDir, 'dir') == 7)
                status = DepMatStatus.DirectoryNotFound;
                return;
            end
            
            lastDir = pwd;
            try
                cd(obj.SourceDir);
                status = obj.internalGetStatus;
                cd(lastDir);
            catch ex
                cd(lastDir);
                status = DepMatStatus.GitFailure;
            end
        end
        
        function success = cloneRepo(obj)
            % Attempts to clone the repository. Only do this if the status
            % is DepMatStatus.DirectoryNotFound, NotUnderSourceControl or FetchFailure

            if ~(exist(obj.SourceDir, 'dir') == 7)
                mkdir(obj.SourceDir);
            end
            
            lastDir = pwd;
            try
                cd(obj.SourceDir);
                success = obj.internalCloneRepo;
                cd(lastDir);
            catch ex
                cd(lastDir);
                success = false;
            end            
        end
        
        function success = updateRepo(obj)
            % Attempts to update the repository. Only do this if the status
            % is DepMatStatus.UpdateAvailable
            
            lastDir = pwd;
            try
                cd(obj.SourceDir);
                success = obj.internalUpdateRepo;
                cd(lastDir);
            catch ex
                cd(lastDir);
                success = false;
            end
        end
        
        function [success, changed] = cloneOrUpdate(obj)
            % Checks the current status of the repository and only updates
            % if this is in a suitable state to do so
            
            changed = false;
            
            try
                status = obj.getStatus;
            catch ex
                success = false;
                disp(['! ' obj.RepoDef.Name ' unable to check for updates']);
                return;
            end
            
            switch status
                case {DepMatStatus.DirectoryNotFound, ...
                        DepMatStatus.NotUnderSourceControl, ...
                        DepMatStatus.FetchFailure}
                    success = obj.cloneRepo(fetch_failure);
                    if success
                        disp([obj.RepoDef.Name ' added']);
                        changed = true;
                    else
                        disp(['! ' obj.RepoDef.Name ' could not be added']);
                    end
                    
                case DepMatStatus.UpToDate
                    success = true;
                    disp([obj.RepoDef.Name ' up to date']);
                    
                case DepMatStatus.UpdateAvailable
                    success = obj.updateRepo;
                    if success
                        disp([obj.RepoDef.Name ' updated']);
                        changed = true;
                    else
                        disp(['! ' obj.RepoDef.Name ' could not be updated']);
                    end
                    
                case DepMatStatus.LocalChanges
                    success = false;
                    disp(['! ' obj.RepoDef.Name ' could not be updated as there are local changes']);
                    
                case DepMatStatus.GitNotFound
                    success = false;
                    disp(['! ' obj.RepoDef.Name ' could not be updated as git is not installed or not in the path']);
                    
                case DepMatStatus.GitFailure
                    success = false;
                    disp(['! ' obj.RepoDef.Name ' could not be updated as the git commands returned a failure']);
                    
                otherwise
                    disp(['! ' obj.RepoDef.Name ' could not be updated']);
            end
        end
        
    end
    
    methods (Access = private)
        function status = internalGetStatus(obj)
            if ~(exist(obj.SourceDir, 'dir') == 7)
                status = DepMatStatus.DirectoryNotFound;
                return;
            end
            
            if ~(7 == exist(fullfile(obj.SourceDir, '.git'), 'dir'))
                status = DepMatStatus.NotUnderSourceControl;
                return;
            end
            
            if ~DepMatRepository.isGitInstalled
                status = DepMatStatus.GitNotFound;
                return;
            end
            
            if obj.checkForFetchFailure
                status = DepMatStatus.FetchFailure;
                return;
            end
            
            [success, local_id] = DepMatRepository.execute('git rev-parse @{0}');
            if ~success
                status = DepMatStatus.GitFailure;
                return;
            end
            [success, remote_id] = DepMatRepository.execute('git rev-parse @{u}');
            if ~success
                status = DepMatStatus.GitFailure;
                return;
            end
            [success, base] = DepMatRepository.execute('git merge-base @{0} @{u}');
            if ~success
                status = DepMatStatus.GitFailure;
                return;
            end
            
            if strcmp(local_id, remote_id)
                status = DepMatStatus.UpToDate;
            elseif strcmp(local_id, base)
                status = DepMatStatus.UpdateAvailable;
            elseif strcmp(remote_id, base)
                status = DepMatStatus.LocalChanges;
            else
                status = DepMatStatus.Conflict;
            end
        end
        
        function success = internalUpdateRepo(obj)
            pullResult = DepMatRepository.execute('git pull');
            success = ~isempty(pullResult);
        end
        
        function success = internalCloneRepo(obj)
            
            % Avoid initialisation if it has already been done, to avoid errors
            fetchFailure = obj.checkForFetchFailure;
            if ~fetchFailure
                if ~DepMatRepository.execute('git init')
                    success = false;
                    disp(['! ' obj.RepoDef.Name ' could not be cloned']);
                    return;
                end
                
                if ~DepMatRepository.execute(['git remote add -t ' obj.RepoDef.Branch ' origin ' obj.RepoDef.Url])
                    success = false;
                    disp(['! ' obj.RepoDef.Name ' could not be cloned']);
                    return;
                end
            end
            
            if ~DepMatRepository.execute('git fetch')
                obj.setFetchFailure;
                
                success = false;
                disp(['! ' obj.RepoDef.Name ' could not be cloned']);
                return;
            end
            
            if ~DepMatRepository.execute(['git checkout ' obj.RepoDef.Branch])
                success = false;
                disp(['! ' obj.RepoDef.Name ' could not be cloned']);
                return;
            end
            
            disp([obj.RepoDef.Name ' added' ]);
            success = true;
            if fetchFailure
                obj.clearFetchFailure
                delete(fetch_failure_filename);
            end
        end
        
        function setFetchFailure(obj)
            fetchFailureFilename = fullfile(obj.SourceDir, obj.FetchFailureFileName);
            fileHandle = fopen(fetchFailureFilename, 'w');
            fclose(fileHandle);
        end
        
        function fetchFailure = checkForFetchFailure(obj)
           fetchFailureFilename = fullfile(obj.SourceDir, obj.FetchFailureFileName);
           fetchFailure = (2 == exist(fetchFailureFilename, 'file'));
        end
        
        function clearFetchFailure(obj)
            fetchFailureFilename = fullfile(obj.SourceDir, obj.FetchFailureFileName);
            delete(fetchFailureFilename);
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
            installed = ~isempty(execute('which git'));
        end
        
    end
end

