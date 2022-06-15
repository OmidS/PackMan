%testPackMan Tests the PackMan class
% To run the tests:
% 	runtests('testPackMan');

%% Main function to generate tests
function tests = testPackMan
tests = functiontests(localfunctions);
disp tests
end

%% Test Functions
function testThatPackManConstructorWorks(testCase)
    % Test specific code
    depList        = {'PackMan', 'release', 'https://github.com/DanielAtKrypton/PackMan.git', 'PackMan', '', true};
    depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);    

    pm = prepareTestEnvironmentAndInstall(depList);
    verifyEqual(testCase,class(pm),'PackMan');
end

function testThatPackManRelativePathsWork(testCase)
    % Test specific code
    depList        = {'PackMan', 'release', 'https://github.com/DanielAtKrypton/PackMan.git', 'PackMan', '', true};
    depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);    

    pm = prepareTestEnvironmentAndInstall(depList);
    currentWorkingDir = pwd;
    expectedDepDirPath = fullfile(currentWorkingDir, 'source', 'external');
    verifyEqual(testCase,pm.depDirPath, expectedDepDirPath);
    
    expectedPackagePath = fullfile(currentWorkingDir, './package.json');
    verifyEqual(testCase,pm.packageFilePath, expectedPackagePath);
end
 
function testThatPackManGeneratesPackageFile(testCase)
    % Test specific code
    depList        = [
        {'PackMan', 'release', 'https://github.com/DanielAtKrypton/PackMan.git', 'PackMan', '', true};
        {'DepMat', 'master', 'https://github.com/OmidS/depmat.git', 'depmat', '', true};
    ];
    depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);    
    
    prepareTestEnvironment();
    pm = installDeps(depList);
    
    verifyTrue(testCase, ~exist(pm.packageFilePath, 'file'))
    
    pm.install();
    
    verifyTrue(testCase, exist(pm.packageFilePath, 'file')~=false );
end

function testThatPackManFetchesRepos(testCase)
    % Test specific code
    depList        = [
        {'PackMan', 'release', 'https://github.com/DanielAtKrypton/PackMan.git', 'PackMan', '', true};
        {'DepMat', 'master', 'https://github.com/OmidS/depmat.git', 'depmat', '', true};
    ];
    depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);    

    pm = prepareTestEnvironmentAndInstall(depList);
    
    for i=1:length(depList)
        depDir = fullfile(pm.depDirPath, depList(i).FolderName);
        verifyTrue(testCase, exist(depDir, 'dir')~=false );
    end
    
    depListOnFile = PackMan.loadFromPackageFile( pm.packageFilePath );
    
    verifyEqual(testCase,length(depList), length(depListOnFile));
    for i = 1:length(depList)
        rId =  strcmp( {depListOnFile.Name}, depList(i).Name) ;
        verifyEqual(testCase, depList(i).Url, depListOnFile(rId).Url);
    end
end

function testThatPackManCanFetchesSpecificCommits(testCase)
    % Test specific code
    depList           = [
        {'PackMan', 'release', 'https://github.com/DanielAtKrypton/PackMan.git', 'PackMan', '', true};
        {'DepMat1', 'master', 'https://github.com/OmidS/depmat.git', 'depmat1', 'f3810b050186a2e1e5e3fbdb64dd7cd8f3bc8528', false};
        {'DepMat2', 'master', 'https://github.com/OmidS/depmat.git', 'depmat2', '95fe15dc04406846857e1601f5954a1b4997313b', false};
    ];
    depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);
    
    pm = prepareTestEnvironmentAndInstall(depList);
    
    depDir2 = fullfile(pm.depDirPath, depList(2).FolderName);
    depDir3 = fullfile(pm.depDirPath, depList(3).FolderName);
    addedFile = 'TestRepoList.m'; % This is a file we expect to exist in commit 2 but not in commit 1
    
    verifyTrue(testCase, exist( fullfile(depDir2, addedFile) , 'file')==false );
    verifyTrue(testCase, exist( fullfile(depDir3, addedFile) , 'file')~=false );
    
    % Check commit ids in package file
    depListOnFile = PackMan.loadFromPackageFile( pm.packageFilePath );
    for i = 2:length(depList)
        rId =  strcmp( {depListOnFile.Name}, depList(i).Name) ;
        verifyEqual(testCase, depListOnFile(rId).Commit, depList(i).Commit );
    end
end

function testThatPackManAutoInstallsOnlyWhenItHasNoOutput(testCase)
    % Test specific code
    depList           = [
        {'PackMan', 'release', 'https://github.com/DanielAtKrypton/PackMan.git', 'PackMan', '', true};    
        {'DepMat1', 'master', 'https://github.com/OmidS/depmat.git', 'depmat1', '', false};
    ];
        
    depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);
    
    prepareTestEnvironment();
    externalFolder = fullfile(pwd, 'source', 'external');
    packageDir = fullfile(externalFolder, depList(2).FolderName); 
    verifyTrue(testCase, exist( packageDir , 'dir')==false );
    
    pm = installDeps(depList);
    verifyTrue(testCase, exist( packageDir , 'dir')==false );
    
    pm.install();
    verifyTrue(testCase, exist( packageDir , 'dir')~=false );
    
    depList           = [
        {'PackMan', 'release', 'https://github.com/DanielAtKrypton/PackMan.git', 'PackMan', '', true};
        {'DepMat1', 'master', 'https://github.com/OmidS/depmat.git', 'depmat1', '', false};
        {'DepMat2', 'master', 'https://github.com/OmidS/depmat.git', 'depmat2', '', false};
    ];
    depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);
    
    prepareTestEnvironment();
    packageDir = fullfile(externalFolder, depList(3).FolderName); 
    verifyTrue(testCase, exist( packageDir , 'dir')==false );
    installDeps(depList);
    verifyTrue(testCase, exist( packageDir , 'dir')~=false );
end

function testThatPackManRejectsInvalidDepLists(testCase)
    % Test specific code
    depList           = [
        {'PackMan', 'release', 'https://github.com/DanielAtKrypton/PackMan.git', 'PackMan', '', true};
        {'DepMat', 'master', 'https://github.com/OmidS/depmat.git', 'depmat1', 'f3810b050186a2e1e5e3fbdb64dd7cd8f3bc8528', false};
        {'DepMat', 'master', 'https://github.com/OmidS/depmat.git', 'depmat2', '95fe15dc04406846857e1601f5954a1b4997313b', false};
    ];
    depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);
    prepareTestEnvironment();
    verifyError(testCase, @()( installDeps(depList) ), 'PackMan:DepListError' );
end

function testThatPackManReturnsDepPaths(testCase)
    % Test specific code
    depList        = [
        {'PackMan', 'release', 'https://github.com/DanielAtKrypton/PackMan.git', 'PackMan', '', true};    
        {'DepMat', 'master', 'https://github.com/OmidS/depmat.git', 'depmat', '', true};
    ];
    depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);
    pm = prepareTestEnvironmentAndInstall(depList);
    paths = pm.genPath();
    expectedPaths = [
        {pm.parentDir                                                       }
        {fullfile(pm.parentDir, 'source')                                   }
        {fullfile(pm.parentDir, 'source', 'external')                       }
        {fullfile(pm.parentDir, 'source', 'external', 'PackMan')            }
        {fullfile(pm.parentDir, 'source', 'external', 'PackMan', 'source')  }
        {fullfile(pm.parentDir, 'source', 'external', 'depmat')             }
        {fullfile(pm.parentDir, 'source', 'external', 'depmat', 'tests')    }
        {fullfile(pm.parentDir, 'source', 'tests')                          }
    ];
    verifyEqual(testCase, paths, expectedPaths);
end

function testThatPackManRecursiveWorks(testCase)
    % Test specific code
    depList        = [
        {'PackMan', 'release', 'https://github.com/DanielAtKrypton/PackMan.git', 'PackMan', '', true};        
        {'PackManRecursiveSample', 'master', 'https://github.com/DanielAtKrypton/PackManRecursiveSample.git', 'PackManRecursiveSample', '', true};
    ];
        
    depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);
    pm = prepareTestEnvironmentAndInstall(depList);
    paths = pm.genPath();
    expectedPaths = [
        {pm.parentDir                                                           }
        {fullfile(pm.parentDir, 'source')                                       }
        {fullfile(pm.parentDir, 'source', 'external')                           }
        {fullfile(pm.parentDir, 'source', 'external', 'PackMan')                }
        {fullfile(pm.parentDir, 'source', 'external', 'PackManRecursiveSample') }
        {fullfile(pm.parentDir, 'source', 'external', 'PackMan', 'source')      }
        {fullfile(pm.parentDir, 'source', 'tests')                              }        
    ];
    verifyEqual(testCase, paths, expectedPaths);
end
