function result = git(varargin)
    %GIT Summary of this function goes here
    %   Detailed explanation goes here
    if (nargin == 0)
       ME = MException('Packman:gitError', ...
                       'Not enough input args');
       throw(ME);
    end
    splitCells = cellfun(@split, varargin, 'UniformOutput', false);
    parametersList = vertcat(splitCells{:});
    firstParameter = parametersList{1};
    gitPlusParametersList = [{'git'}, parametersList{:}];
    spaceSeparatedGitPlusParametersList = join(gitPlusParametersList, ' ');
    commandString = spaceSeparatedGitPlusParametersList{1};
    switch firstParameter
    case 'remote'
    case 'pull'
    case 'fetch'
    case 'push'
    otherwise
        [status, result] = system(commandString);
        if status
            ME = MException('Git:couldntExecuteGitCommand', ...
            'git command %s resulted in a failure!', commandString);
            throw(ME);   
        end        
        return;
    end
    name = getRepoName();
    filename = [name 'CommandOutput'];
    fid = fopen(filename , 'wt' );
    fclose(fid);
    
    [status, ~] = dos([which('RunCommand.bat') ' ' name ' ' commandString ' &']);
    if status
        ME = MException('Git:couldntExecuteGitCommand', ...
        'git command %s resulted in failure!', commandString);
        throw(ME);  
    end
    v = ver;
    isRoboticsToolboxAvailable = any(strcmp('Robotics System Toolbox', {v.Name}));
    desiredRate = 5;
    if (isRoboticsToolboxAvailable)
        r = robotics.Rate(desiredRate);
        reset(r);
    end        
    while(true)
        fid = fopen(filename, 'rt' );
        contents = textscan(fid,'%s','Delimiter','\n');
        contents = contents{1};
        fclose(fid);
        if ~isempty(contents)
            delete(filename)
            break;
        end
        if (isRoboticsToolboxAvailable)
            waitfor(r);
        else
            pause(1/desiredRate);
        end
    end
    result = contents;
    
    function name = getRepoName()
    commandString = 'git rev-parse --show-toplevel';
    [status, result] = system(commandString);
    if status
        ME = MException('Git:couldntExecuteGitCommand', ...
        'git command %s resulted in failure!', commandString);
        throw(ME);  
    end    
    result = result(1:end-1); % remove newline.
    [~,name,~] = fileparts(result);