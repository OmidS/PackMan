classdef DepMatRepositoryUpdater < handle
    % DepMatRepositoryUpdater. Query, clone and update a git repository
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
        function obj = DepMatRepositoryUpdater(sourceDir, repoDef)
            % Creates a DepMatRepositoryUpdater object for checking the status of
            % and updating a git repository
 
            obj.SourceDir = sourceDir;
            obj.RepoDef = repoDef;
        end
        
        function [status, varargout] = getStatus(obj)
            % Returns the current git status of this repository, as one of
            % the enumerations in DepMatStatus
            if nargout > 1, varargout{1} = ''; end
            
            if ~(exist(obj.SourceDir, 'dir') == 7)
                status = DepMatStatus.DirectoryNotFound;
                return;
            end
            
            lastDir = pwd;
            try
                cd(obj.SourceDir);
                [status, varargout{1}] = obj.internalGetStatus;
                if isempty(varargout{1}), [~, varargout{1}] = obj.internalGetHeadHash(); end
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
                    success = obj.cloneRepo;
                    if success
                        disp([obj.RepoDef.Name ' added']);
                        changed = true;
                    else
                        disp(['! ' obj.RepoDef.Name ' could not be added']);
                    end
                    
                case DepMatStatus.UpToDate
                    success = true;
                    disp([obj.RepoDef.Name ' up to date']);
                    
                case DepMatStatus.UpToDateButWrongHead
                    disp([obj.RepoDef.Name ' up to date but at wrong head']);
                    [success, changed, headCommitId] = obj.checkoutCommit;
                    if success
                        disp([obj.RepoDef.Name ' checked out specified commit: ', headCommitId]);
                        changed = true;
                    else
                        disp(['! ' obj.RepoDef.Name ' could not check out ', obj.RepoDef.Commit]);
                    end
                    
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
        
        function [success, changed, headCommitId] = checkoutCommit(obj)
            lastDir = pwd;
            try
                cd(obj.SourceDir);
                [success, changed, headCommitId] = obj.internalCheckoutCommit;
                if (~success)
                    disp(['! ' obj.RepoDef.Name ' could not check out specified commit (',obj.RepoDef.Commit,')']);
                end                
                cd(lastDir);
            catch ex
                cd(lastDir);
                success = false;
            end
        end
        
    end
    
    methods (Access = private)
        function [status, varargout] = internalGetStatus(obj)
            if nargout > 1, varargout{1} = ''; end
            if ~(exist(obj.SourceDir, 'dir') == 7)
                status = DepMatStatus.DirectoryNotFound;
                return;
            end
            
            if ~(7 == exist(fullfile(obj.SourceDir, '.git'), 'dir'))
                status = DepMatStatus.NotUnderSourceControl;
                return;
            end
            
            if ~DepMat.isGitInstalled
                status = DepMatStatus.GitNotFound;
                return;
            end
            
            if obj.checkForFetchFailure
                status = DepMatStatus.FetchFailure;
                return;
            end
            
            [success, local_id] = DepMat.execute('git remote update');
            if ~success
                status = DepMatStatus.GitFailure;
                return;
            end
            
            [success, local_id_head] = DepMat.execute(['git rev-parse @{0}']); % current head commit
            if ~success
                status = DepMatStatus.GitFailure;
                return;
            end
            
            [success, local_id] = DepMat.execute(['git rev-parse ',obj.RepoDef.Branch,'@{0}']); % Latest local commit
            if ~success
                status = DepMatStatus.GitFailure;
                return;
            end
            [success, remote_id] = DepMat.execute(['git rev-parse ',obj.RepoDef.Branch,'@{u}']); % Latest remote commit
            if ~success
                status = DepMatStatus.GitFailure;
                return;
            end
            [success, base] = DepMat.execute(['git merge-base ',obj.RepoDef.Branch,'@{0} ',obj.RepoDef.Branch,'@{u}']);
            if ~success
                status = DepMatStatus.GitFailure;
                return;
            end
            
            local_id_head = strrep(local_id_head,sprintf('\n'),''); 
            local_id = strrep(local_id,sprintf('\n'),''); 
            remote_id = strrep(remote_id,sprintf('\n'),''); 
            base = strrep(base,sprintf('\n'),''); 
            
            if strcmp(local_id, remote_id)
                if (~obj.RepoDef.GetLatest && strcmp(obj.RepoDef.Commit, local_id_head) ) || ...
                   ( obj.RepoDef.GetLatest && strcmp(local_id, local_id_head) )
                    status = DepMatStatus.UpToDate;
                    if nargout > 1, varargout{1} = local_id_head; end
                else
                    status = DepMatStatus.UpToDateButWrongHead;
                end
            elseif strcmp(local_id, base)
                status = DepMatStatus.UpdateAvailable;
            elseif strcmp(remote_id, base)
                status = DepMatStatus.LocalChanges;
            else
                status = DepMatStatus.Conflict;
            end
        end
        
        function [status, commitHash] = internalGetHeadHash(obj)
            status = true;
            [success, commitHash] = DepMat.execute('git rev-parse HEAD');
            if ~success
                status = DepMatStatus.GitFailure;
                return;
            end
            commitHash = strrep(commitHash,sprintf('\n'),''); 
        end
        
        function success = internalUpdateRepo(obj)
            pullResult = DepMat.execute('git pull');
            success = ~isempty(pullResult);
        end
        
        function success = internalCloneRepo(obj)
            
            % Avoid initialisation if it has already been done, to avoid errors
            fetchFailure = obj.checkForFetchFailure;
            if ~fetchFailure
                if ~DepMat.execute('git init')
                    success = false;
                    return;
                end
                
                if ~DepMat.execute(['git remote add -t ' obj.RepoDef.Branch ' origin ' obj.RepoDef.Url])
                    success = false;
                    return;
                end
            end
            
            if ~DepMat.execute('git fetch')
                obj.setFetchFailure;
                
                success = false;
                return;
            end
            
            if ~isempty(obj.RepoDef.Commit)&&~obj.RepoDef.GetLatest
                checkoutCmd = ['git checkout ' obj.RepoDef.Commit];
            else
                checkoutCmd = ['git checkout ' obj.RepoDef.Branch];
            end
            
            if ~DepMat.execute(checkoutCmd)
                success = false;
                return;
            end
            
            success = true;
            if fetchFailure
                obj.clearFetchFailure
                delete(fetch_failure_filename);
            end
        end
        
        function [success, changed, headCommitId] = internalCheckoutCommit(obj)
            [success, local_id_head] = DepMat.execute(['git rev-parse @{0}']); % current head commit
            local_id_head = strrep(local_id_head,sprintf('\n'),''); 
            [success, local_id_latest] = DepMat.execute(['git rev-parse ',obj.RepoDef.Branch,'@{0}']); % Latest local commit
            local_id_latest = strrep(local_id_latest,sprintf('\n'),''); 
            
            headCommitId = local_id_head;
            changed = false;
            toCheckoutHash = '';
            if ( obj.RepoDef.GetLatest) && ~strcmp(local_id_head, local_id_latest)
                toCheckoutHash = local_id_latest;
            elseif ~( obj.RepoDef.GetLatest ) && ~strcmp(local_id_head, obj.RepoDef.Commit)
                toCheckoutHash = obj.RepoDef.Commit;
            end
            if ~isempty(toCheckoutHash)
                if ~DepMat.execute(['git checkout ' toCheckoutHash])
                    success = false;
                    % changed = true;
                    return;
                end
                changed = true;
                headCommitId = toCheckoutHash;
            end
            success = true;
        end
        
        function getHeadCommitId()
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
end

