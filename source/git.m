function [status, result] = git(parameterStr)
%GIT Summary of this function goes here
%   Detailed explanation goes here
parametersList = split(parameterStr);
firstParameter = parametersList(1);
gitPlusParameters = ['git ' parameterStr];
switch firstParameter
case 'checkout'
case 'rev-parse'
case '--help'
case 'merge-base'
    [status, result] = system(gitPlusParameters);
otherwise
    name = getRepoName();
    filename = [name 'CommandOutput'];
    fid = fopen(filename , 'wt' );
    fclose(fid);

    [status, ~] = dos([which('RunCommand.bat') ' ' name ' ' gitPlusParameters ' &']);
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
end

function name = getRepoName()
[~, result] = system('git rev-parse --show-toplevel');
result = result(1:end-1); % remove newline.
[~,name,~] = fileparts(result);