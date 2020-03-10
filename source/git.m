function [status, result] = git(parameterStr)
%GIT Summary of this function goes here
%   Detailed explanation goes here
fid = fopen( 'executingSignal', 'wt' );
fclose(fid);

[status, result] = dos(['RunCommand.bat git ' parameterStr ' &']);
% [status, result] = system(['pwsh -Command .\RunCommand.ps1 git ' parameterStr ' &']);
while(isfile('executingSignal'))
    pause(0.2);
end