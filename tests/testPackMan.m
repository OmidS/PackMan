%testPackMan Tests the PackMan class

%% Main function to generate tests
function tests = testPackMan
tests = functiontests(localfunctions);
end

%% Test Functions
function testThatPackManConstructorWorks(testCase)
    % Test specific code
    pm = PackMan();
    verifyEqual(testCase,class(pm),'PackMan');
end

function testThatPackManRelativePathsWork(testCase)
    % Test specific code
    wDir = pwd;
    pm = PackMan();
    
    expectedDepDirPath = fullfile(wDir, './external');
    verifyEqual(testCase,pm.depDirPath, expectedDepDirPath);
    
    expectedPackagePath = fullfile(wDir, './package.mat');
    verifyEqual(testCase,pm.packageFilePath, expectedPackagePath);
end

function testThatPackManGeneratesPackageFile(testCase)
    % Test specific code
    pm = PackMan();
    verifyTrue(testCase, exist(pm.packageFilePath, 'file')~=false );
end

function testThatPackManFetchesRepos(testCase)
    % Test specific code
    depList        = DepMatRepo('DepMat', 'master', 'https://github.com/OmidS/depmat.git', 'depmat', '', true);
    pm = PackMan( depList );
    depDir = fullfile(pm.depDirPath, depList.FolderName);
    verifyTrue(testCase, exist(depDir, 'dir')~=false );
    
    depListOnFile = PackMan.loadFromPackageFile( pm.packageFilePath );
    
    verifyEqual(testCase,length(depList), length(depListOnFile));
    for i = 1:length(depList)
        rId = find( strcmp( {depListOnFile.Name}, depList(i).Name) );
        verifyEqual(testCase, depList(i).Url, depListOnFile(rId).Url);
    end
end

function testThatPackManCanFetcheSpecificCommits(testCase)
    % Test specific code
    depList           = DepMatRepo('DepMat1', 'master', 'https://github.com/OmidS/depmat.git', 'depmat1', 'f3810b050186a2e1e5e3fbdb64dd7cd8f3bc8528', false);
    depList(end+1, 1) = DepMatRepo('DepMat2', 'master', 'https://github.com/OmidS/depmat.git', 'depmat2', '95fe15dc04406846857e1601f5954a1b4997313b', false);
    
    pm = PackMan( depList );
    depDir1 = fullfile(pm.depDirPath, depList(1).FolderName);
    depDir2 = fullfile(pm.depDirPath, depList(2).FolderName);
    addedFile = 'TestRepoList.m'; % This is a file we expect to exist in commit 2 but not in commit 1
    
    verifyTrue(testCase, exist( fullfile(depDir1, addedFile) , 'file')==false );
    verifyTrue(testCase, exist( fullfile(depDir2, addedFile) , 'file')~=false );
    
    % Check commit ids in package file
    depListOnFile = PackMan.loadFromPackageFile( pm.packageFilePath );
    for i = 1:length(depList)
        rId = find( strcmp( {depListOnFile.Name}, depList(i).Name) );
        verifyEqual(testCase, depListOnFile(rId).Commit, depList(i).Commit );
    end
end

function testThatPackManRejectsInvalidDepLists(testCase)
    % Test specific code
    depList           = DepMatRepo('DepMat', 'master', 'https://github.com/OmidS/depmat.git', 'depmat1', 'f3810b050186a2e1e5e3fbdb64dd7cd8f3bc8528', false);
    depList(end+1, 1) = DepMatRepo('DepMat', 'master', 'https://github.com/OmidS/depmat.git', 'depmat2', '95fe15dc04406846857e1601f5954a1b4997313b', false);
    verifyError(testCase, @()( PackMan(depList) ), 'PackMan:DepListError' );
end


%% Helper functions
function [depDir, packageFile] = getPaths()
    
p = fileparts( mfilename('fullpath') );
depDir = fullfile(p, 'external');
packageFile = fullfile(p, 'package.mat');

end

%% Optional file fixtures  
function setupOnce(testCase)  % do not change function name
% set a new path, for example
addpath('../');

end

function teardownOnce(testCase)  % do not change function name
% change back to original path, for example

end

%% Optional fresh fixtures  
function setup(testCase)  % do not change function name
% open a figure, for example

[depDir, packageFile] = getPaths();
if exist(depDir, 'dir'), delete(depDir); end
if exist(packageFile, 'file'), delete(packageFile); end

end

function teardown(testCase)  % do not change function name
% close figure, for example

[depDir, packageFile] = getPaths();
if exist(depDir, 'dir'), rmdir(depDir, 's'); end
if exist(packageFile, 'file'), delete(packageFile); end

end