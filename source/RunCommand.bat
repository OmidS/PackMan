@echo off

for /f "tokens=1,* delims= " %%a in ("%*") do set ALL_BUT_FIRST=%%b
SET cmdToRun=%ALL_BUT_FIRST%

echo Executing git command on %~1 repository: %cmdToRun%

for /f %%i in ('%cmdToRun%') do set result=%%i
@echo %result% > %~1CommandOutput

exit