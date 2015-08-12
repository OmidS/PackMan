function [success, changed] = DepMatCloneOrUpdate(sourceDir, repoDef)
    % DepMatCloneOrUpdate. Performs a clone or update of a git repository
    %
    %
    %
    %     Licence
    %     -------
    %     Part of DepMat. https://github.com/tomdoel/depmat
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    if ~(exist(sourceDir, 'dir') == 7)
        mkdir(sourceDir);
    end
    
    lastDir = pwd;
    try    
        cd(sourceDir);
    
        % The fetch failure file indicates that the repo was initialised
        % but the fetch did not work. So we want to fetch again but not to
        % reinitialise
        fetch_failure_filename = fullfile(sourceDir, 'depmat_fetch_failure');
        fetch_failure = 2 == exist(fetch_failure_filename, 'file');
        if 7 == exist(fullfile(sourceDir, '.git'), 'dir') && ~fetch_failure
            [success, changed] = updateGitRepo(repoDef);
        else
            success = cloneGitRepo(repoDef, fetch_failure);
            changed = true;
        end
        
        if fetch_failure
            delete(fetch_failure_filename);
        end
        cd(lastDir);
        
    catch ex
        cd(lastDir);
        success = false;
        changed = false;
    end
end

function success = cloneGitRepo(repoDef, skipInit)
    
    % Avoid initialisation if it has already been done, to avoid errors
    if ~skipInit
        if ~execute('git init')
            success = false;
            disp(['! ' repoDef.Name ' could not be cloned']);
            return;
        end
    
        if ~execute(['git remote add -t ' repoDef.Branch ' origin ' repoDef.Url])
            success = false;
            disp(['! ' repoDef.Name ' could not be cloned']);
            return;
        end
    end
    
    if ~execute('git fetch')
        fileHandle = fopen('depmat_fetch_failure', 'w');
        fclose(fileHandle);

        success = false;
        disp(['! ' repoDef.Name ' could not be cloned']);
        return;
    end
    
    if ~execute(['git checkout ' repoDef.Branch])
        success = false;
        disp(['! ' repoDef.Name ' could not be cloned']);
        return;
    end
    
    disp([repoDef.Name ' added' ]);
    success = true;
end

function [success, changed] = updateGitRepo(repoDef)
    changed = false;
    
    [success, local_id] = execute('git rev-parse @{0}');
    if ~success
        disp(['! ' repoDef.Name ' unable to check for updates']);
        return
    end
    
    [success, remote_id] = execute('git rev-parse @{u}');
    if ~success
        disp(['! ' repoDef.Name ' unable to check for updates']);
        return
    end
    
    [success, base] = execute('git merge-base @{0} @{u}');
    if ~success
        disp(['! ' repoDef.Name ' unable to check for updates']);
        return
    end

    if strcmp(local_id, remote_id)
        success = true;
        disp([repoDef.Name ' up to date']);
        return;

    elseif strcmp(local_id, base)
        pullResult = execute('git pull');
        if isempty(pullResult)
            success = false;
            disp(['! ' repoDef.Name ' could not be updated']);
            return;
        else
            success = true;
            changed = true;
            disp([repoDef.Name ' updated']);
            return;
        end
       
    elseif strcmp(remote_id, base)
        success = false;
        disp(['! ' repoDef.Name ' could not be updated as there are local changes']);
        return;
        
    else
        disp(['! ' repoDef.Name ' could not be updated']);
    end
end

function [success, output] = execute(command)
    [return_value, output] = system(command);
    success = return_value == 0;
    if ~success
        if strfind(output, 'Protocol https not supported or disabled in libcurl')
            disp('! You need to modify the the DYLD_LIBRARY_PATH environment variable to point to a newer version of libcurl. The version installed with Matlab does not support using https with git.');
        end
    end
end

