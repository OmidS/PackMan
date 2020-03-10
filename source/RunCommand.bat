@echo off
REM iex "$args"
REM Remove-Item -Path 'executingSignal'
REM exit

SET subject=%*
%subject%
del "executingSignal"
exit