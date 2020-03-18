%testPackMan Tests the PackMan class
% To run the tests:
% 	runtests('testPackMan');

%% Main function to generate tests
function tests = testPackMan
tests = functiontests(localfunctions);
end

%% Test Functions
% function testThatPackManConstructorWorks(testCase)
%     % Test specific code
%     pm = PackMan();
%     pm.install();
%     verifyEqual(testCase,class(pm),'PackMan');
% end

% function testThatPackManRelativePathsWork(testCase)
%     % Test specific code
%     wDir = pwd;
%     pm = PackMan();
%     pm.install();
%     
%     expectedDepDirPath = fullfile(wDir, './external');
%     verifyEqual(testCase,pm.depDirPath, expectedDepDirPath);
%     
%     expectedPackagePath = fullfile(wDir, './package.json');
%     verifyEqual(testCase,pm.packageFilePath, expectedPackagePath);
% end
% 
% function testThatPackManGeneratesPackageFile(testCase)
%     % Test specific code
%     pm = PackMan(getDepList);
%     if exist(pm.packageFilePath, 'file')
%         delete(pm.packageFilePath)
%     end
%     verifyTrue(testCase, ~exist(pm.packageFilePath, 'file'))
%     
%     pm.install();
%     
%     verifyTrue(testCase, exist(pm.packageFilePath, 'file')~=false );
% end
% 
function testThatPackManFetchesRepos(testCase)
    % Test specific code
    depList        = [
        {'PackMan', 'release', 'https://github.com/DanielAtKrypton/PackMan.git', 'PackMan', '', true};
        {'DepMat', 'master', 'https://github.com/OmidS/depmat.git', 'depmat', '', true};
    ];
    depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);    

    pm = prepareTestEnvironment(depList);
    
    for i=1:length(depList)
        depDir = fullfile(pm.depDirPath, depList(i).FolderName);
        verifyTrue(testCase, exist(depDir, 'dir')~=false );
    end
    
    depListOnFile = PackMan.loadFromPackageFile( pm.packageFilePath );
    
    verifyEqual(testCase,length(depList), length(depListOnFile));
    for i = 1:length(depList)
        rId = find( strcmp( {depListOnFile.Name}, depList(i).Name) );
        verifyEqual(testCase, depList(i).Url, depListOnFile(rId).Url);
    end
end
% 
% function testThatPackManCanFetchesSpecificCommits(testCase)
%     % Test specific code
%     depList           = [
%         {'DepMat1', 'master', 'https://github.com/OmidS/depmat.git', 'depmat1', 'f3810b050186a2e1e5e3fbdb64dd7cd8f3bc8528', false};
%         {'DepMat2', 'master', 'https://github.com/OmidS/depmat.git', 'depmat2', '95fe15dc04406846857e1601f5954a1b4997313b', false};
%     ];
%     depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);
%     
%     pm = prepareTestEnvironment(depList);
%     
%     depDir1 = fullfile(pm.depDirPath, depList(1).FolderName);
%     depDir2 = fullfile(pm.depDirPath, depList(2).FolderName);
%     addedFile = 'TestRepoList.m'; % This is a file we expect to exist in commit 2 but not in commit 1
%     
%     verifyTrue(testCase, exist( fullfile(depDir1, addedFile) , 'file')==false );
%     verifyTrue(testCase, exist( fullfile(depDir2, addedFile) , 'file')~=false );
%     
%     % Check commit ids in package file
%     depListOnFile = PackMan.loadFromPackageFile( pm.packageFilePath );
%     for i = 1:length(depList)
%         rId = find( strcmp( {depListOnFile.Name}, depList(i).Name) );
%         verifyEqual(testCase, depListOnFile(rId).Commit, depList(i).Commit );
%     end
% end
% 
% function testThatPackManAutoInstallsOnlyWhenItHasNoOutput(testCase)
%     % Test specific code
%     depList           = {'DepMat1', 'master', 'https://github.com/OmidS/depmat.git', 'depmat1', '', false};
%     depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);
%     
%     packageDir = fullfile('./external', depList(1).FolderName); 
%     verifyTrue(testCase, exist( packageDir , 'dir')==false );
%     
%     pm = PackMan( depList );
%     verifyTrue(testCase, exist( packageDir , 'dir')==false );
%     
%     pm.install();
%     verifyTrue(testCase, exist( packageDir , 'dir')~=false );
%     
%     depList           = [
%         {'DepMat1', 'master', 'https://github.com/OmidS/depmat.git', 'depmat1', '', false};
%         {'DepMat2', 'master', 'https://github.com/OmidS/depmat.git', 'depmat2', '', false};
%     ];
%     depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);
%     packageDir = fullfile('./external', depList(2).FolderName); 
%     verifyTrue(testCase, exist( packageDir , 'dir')==false );
%     PackMan( depList );
%     verifyTrue(testCase, exist( packageDir , 'dir')~=false );
% end
% 
% function testThatPackManRejectsInvalidDepLists(testCase)
%     % Test specific code
%     depList           = [
%         {'DepMat', 'master', 'https://github.com/OmidS/depmat.git', 'depmat1', 'f3810b050186a2e1e5e3fbdb64dd7cd8f3bc8528', false};
%         {'DepMat', 'master', 'https://github.com/OmidS/depmat.git', 'depmat2', '95fe15dc04406846857e1601f5954a1b4997313b', false};
%     ];
%     depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);
%     verifyError(testCase, @()( PackMan(depList) ), 'PackMan:DepListError' );
% end
% 
% function testThatPackManReturnsDepPaths(testCase)
%     % Test specific code
%     depList        = {'DepMat', 'master', 'https://github.com/OmidS/depmat.git', 'depmat', '', true};
%     depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);
%     pm = PackMan( depList );
%     pm.install();
%     paths = pm.genPath();
%     expectedPaths = [fullfile(pm.parentDir, './external/depmat/tests'),';', ...
%                      fullfile(pm.parentDir, './external/depmat'),';', ...
%                      pm.parentDir,';'];
%     verifyEqual(testCase, paths, expectedPaths);
% end
% 
% function testThatPackManRecursiveWorks(testCase)
%     % Test specific code
%     depList        = {'matlabPackManRecursiveSample', 'master', 'https://github.com/OmidS/matlabPackManRecursiveSample.git', 'matlabPackManRecursiveSample', '', true};
%     depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);
%     pm = PackMan( depList );
%     pm.install();
%     paths = pm.genPath();
%     expectedPaths = [fullfile(pm.parentDir, './external/matlabPackManRecursiveSample/external/depmat/tests'),';', ...
%                      fullfile(pm.parentDir, './external/matlabPackManRecursiveSample/external/depmat'),';', ...
%                      fullfile(pm.parentDir, './external/matlabPackManRecursiveSample/external/matlabPackManSample/external/depmat/tests'),';', ...
%                      fullfile(pm.parentDir, './external/matlabPackManRecursiveSample/external/matlabPackManSample/external/depmat'),';', ...
%                      fullfile(pm.parentDir, './external/matlabPackManRecursiveSample/external/matlabPackManSample'),';', ...
%                      fullfile(pm.parentDir, './external/matlabPackManRecursiveSample'),';', ...
%                      pm.parentDir,';'];
%     verifyEqual(testCase, paths, expectedPaths);
% end
% 
% %% Helper functions
% function [depDir, packageFile] = getPaths()
%     
% p = fileparts( mfilename('fullpath') );
% depDir = fullfile(p, 'external');
% packageFile = fullfile(p, 'package.mat');
% 
% end
% 
% %% Optional file fixtures  
% function setupOnce(testCase)  % do not change function name
% % set a new path, for example
% addpath('../');
% 
% end
% 
% function teardownOnce(testCase)  % do not change function name
% % change back to original path, for example
% 
% end
% 
% %% Optional fresh fixtures  
% function setup(testCase)  % do not change function name
% % open a figure, for example
% 
% [depDir, packageFile] = getPaths();
% if exist(depDir, 'dir'), delete(depDir); end
% if exist(packageFile, 'file'), delete(packageFile); end
% 
% end
% 
% function teardown(testCase)  % do not change function name
% % close figure, for example
% 
% [depDir, packageFile] = getPaths();
% if exist(depDir, 'dir'), rmdir(depDir, 's'); end
% if exist(packageFile, 'file'), delete(packageFile); end
% 
% end