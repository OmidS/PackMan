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
        dispHandler = @(x)(disp(x))
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
            catch
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
            catch
                cd(lastDir);
                success = false;
            end            
        end
        
        function [success, output] = updateRepo(obj)
            % Attempts to update the repository. Only do this if the status
            % is DepMatStatus.UpdateAvailable
            
            lastDir = pwd;
            try
                cd(obj.SourceDir);
                [success, output] = obj.internalUpdateRepo;
            catch
                success = false;
                output = '';
            end
            cd(lastDir);
        end
        
        function [success, changed] = cloneOrUpdate(obj)
            % Checks the current status of the repository and only updates
            % if this is in a suitable state to do so
            
            changed = false;
            
            try
                status = obj.getStatus;
            catch
                success = false;
                obj.dispHandler(['! ' obj.RepoDef.Name ' unable to check for updates']);
                return;
            end
            
            switch status
                case {DepMatStatus.DirectoryNotFound, ...
                        DepMatStatus.NotUnderSourceControl, ...
                        DepMatStatus.FetchFailure}
                    success = obj.cloneRepo;
                    if success
                        obj.dispHandler(sprintf('%s added (%s)', obj.RepoDef.Name, obj.RepoDef.getVersionStr()));
                        changed = true;
                    else
                        obj.dispHandler(['! ' obj.RepoDef.Name ' could not be added']);
                    end
                    
                case DepMatStatus.UpToDate
                    success = true;
                    obj.dispHandler(sprintf('%s up to date (%s)', obj.RepoDef.Name, obj.RepoDef.getVersionStr()));
                    
                case DepMatStatus.UpToDateButWrongHead
                    obj.dispHandler([obj.RepoDef.Name ' up to date but at wrong head']);
                    [success, changed, headCommitId] = obj.checkoutCommit;
                    if success
                        obj.dispHandler([obj.RepoDef.Name ' checked out specified commit: ', headCommitId]);
                        changed = true;
                    else
                        obj.dispHandler(['! ' obj.RepoDef.Name ' could not check out ', obj.RepoDef.Commit]);
                    end
                    
                case DepMatStatus.UpdateAvailable
                    [success, output] = obj.updateRepo;
                    if success
                        obj.dispHandler(sprintf('%s updated (%s)', obj.RepoDef.Name, obj.RepoDef.getVersionStr()));
                        changed = true;
                    else
                        obj.dispHandler(['! ' obj.RepoDef.Name ' (located in "' obj.SourceDir '") could not be updated.' sprintf(' %s', output)]);
                    end
                    
                case DepMatStatus.LocalChanges
                    success = false;
                    obj.dispHandler(['! ' obj.RepoDef.Name ' could not be updated as there are local changes']);
                    
                case DepMatStatus.GitNotFound
                    success = false;
                    obj.dispHandler(['! ' obj.RepoDef.Name ' could not be updated as git is not installed or not in the path']);
                    
                case DepMatStatus.GitFailure
                    success = false;
                    obj.dispHandler(['! ' obj.RepoDef.Name ' could not be updated as the git commands returned a failure']);
                    
                otherwise
                    obj.dispHandler(['! ' obj.RepoDef.Name ' could not be updated']);
            end
        end
        
        function [success, changed, headCommitId] = checkoutCommit(obj)
            lastDir = pwd;
            try
                cd(obj.SourceDir);
                [success, changed, headCommitId] = obj.internalCheckoutCommit;
                if (~success)
                    obj.dispHandler(['! ' obj.RepoDef.Name ' could not check out specified commit (',obj.RepoDef.Commit,')']);
                end                
                cd(lastDir);
            catch
                cd(lastDir);
                success = false;
            end
        end
        
        function setDispHandler(obj, funcHandle)
            obj.dispHandler = funcHandle;
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
            
            try
                git('remote update');
                local_id_head = git('rev-parse @{0}'); % current head commit
            catch
                status = DepMatStatus.GitFailure;
                return;
            end
            
            local_id_head = strrep(local_id_head,newline,''); 
            
            if ~obj.RepoDef.GetLatest
                if strcmp(local_id_head, obj.RepoDef.Commit)
                    status = DepMatStatus.UpToDate;
                else
                    status = DepMatStatus.UpToDateButWrongHead;
                end
            else % Get the latest commit
                try
                    local_id = git(['rev-parse ',obj.RepoDef.Branch,'@{0}']); % Latest local commit
                    remote_id = git(['rev-parse ',obj.RepoDef.Branch,'@{u}']); % Latest remote commit
                    base = git(['merge-base ',obj.RepoDef.Branch,'@{0} ',obj.RepoDef.Branch,'@{u}']);
                catch
                    status = DepMatStatus.GitFailure;
                    return;
                end

                local_id = strrep(local_id,newline,''); 
                remote_id = strrep(remote_id,newline,''); 
                base = strrep(base,newline,''); 

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
        end
        
        function [success, output] = internalUpdateRepo(obj)
            try
                output = git(['checkout ', obj.RepoDef.Branch]); % Checkout the branch
                output = git('pull');
            catch
                success = false;
                return;
            end
            success = true;
        end
        
        function success = internalCloneRepo(obj)
            
            % Avoid initialisation if it has already been done, to avoid errors
            fetchFailure = obj.checkForFetchFailure;
            if ~fetchFailure
                try
                    git('init');
                    git(['remote add -t ' obj.RepoDef.Branch ' origin ' obj.RepoDef.Url]);
                catch
                    success = false;
                    return;
                end
            end
            
            try
                git('fetch');
            catch
                obj.setFetchFailure;
                success = false;
                return;            
            end

            if ~isempty(obj.RepoDef.Commit)&&~obj.RepoDef.GetLatest
                checkoutCmd = ['checkout ' obj.RepoDef.Commit];
            else
                checkoutCmd = ['checkout ' obj.RepoDef.Branch];
            end
            
            try
                git(checkoutCmd)
            catch
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
            changed = false;
            try
                local_id_head = git('rev-parse @{0}'); % current head commit
                local_id_head = strrep(local_id_head,newline,''); 
                local_id_latest = git(['rev-parse ',obj.RepoDef.Branch,'@{0}']); % Latest local commit
                local_id_latest = strrep(local_id_latest,newline,''); 
                headCommitId = local_id_head;
                toCheckoutHash = '';
                if ( obj.RepoDef.GetLatest) && ~strcmp(local_id_head, local_id_latest)
                    toCheckoutHash = local_id_latest;
                elseif ~( obj.RepoDef.GetLatest ) && ~strcmp(local_id_head, obj.RepoDef.Commit)
                    toCheckoutHash = obj.RepoDef.Commit;
                end
                if ~isempty(toCheckoutHash)
                    git(['checkout ' toCheckoutHash])
                    changed = true;
                    headCommitId = toCheckoutHash;
                end
                success = true;                
            catch
                success = false;
                return;
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
    methods(Static)
        function getHeadCommitId
        end
        
        function [status, commitHash] = internalGetHeadHash
            status = true;
            try
                commitHash = git('rev-parse HEAD');
            catch
                status = DepMatStatus.GitFailure;
                return;
            end
            commitHash = strrep(commitHash,newline,''); 
        end
    end
end

