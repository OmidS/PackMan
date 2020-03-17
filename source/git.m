function [status, result] = git(varargin)
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
        return;
    end
    name = getRepoName();
    filename = [name 'CommandOutput'];
    fid = fopen(filename , 'wt' );
    fclose(fid);
    
    [status, ~] = dos([which('RunCommand.bat') ' ' name ' ' commandString ' &']);
    while(true)
        fid = fopen(filename, 'rt' );
        contents = fscanf(fid, '%s\n');
        fclose(fid);
        if ~isempty(contents)
            delete(filename)
            break;
        end
        pause(0.2);
    end
    result = contents;
    
    function name = getRepoName()
    [~, result] = system('git rev-parse --show-toplevel');
    result = result(1:end-1); % remove newline.
    [~,name,~] = fileparts(result);