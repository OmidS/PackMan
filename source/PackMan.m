classdef PackMan < handle & matlab.mixin.Copyable
    %PackMan Package manager class
    %   Uses DepMat tp provide dependency management
    
    properties
        depList          % List of dependencies
        parentDir        % Path to main directory of the package
        depDirPath       % Path to subdirectory for dependencies
        packageFilePath  % Path to package info file
        dispHandler = @(x)(disp(x))
    end
    
    methods
        function obj = PackMan( depList, depDirPath, packageFilePath, parDir )
            % Inputs:
            % (1) depList (default): a structure or DepMat array of the
            %             dependencies.
            % (2) depDirPath (default: './external'): path to the 
            %             directory to install dependencies
            % (3) packageFilePath (default: './package.mat'): path to package
            %             info file
            % (4) parDir (default: pwd): path to main directory of the
            %             package. By default, will be the current
            %             directory when calling PackMan
            % Outputs:
            % (1) PackMan object
            % Usage sample:
            % 
            
            if nargin < 4 || isempty(parDir), parDir = pwd; end
            obj.parentDir = parDir;
            
            if nargin < 1 || isempty(depList)
                depList = DepMat.empty; 
            else                
                depListLenght = length(depList);
                f_names = fieldnames(depList);
                f_namesLength = length(f_names);
                
                constructorParams = cell(f_namesLength, depListLenght);
                depObjList = repmat(DepMatRepo(),1,depListLenght);
                for i = 1:depListLenght
                    constructorParams(:, i) = cellfun(@(x)(depList(i).(x)),f_names,'UniformOutput',false);
                    depObjList(i) = DepMatRepo(constructorParams{:,i});
                end                
                depList = depObjList;
            end
            if nargin < 2 || isempty(depDirPath), depDirPath = fullfile(obj.parentDir, '/external'); end
            if nargin < 3 || isempty(packageFilePath)
                if exist('jsonencode', 'builtin')
                    packageFilePath = fullfile(obj.parentDir, '/package.json'); 
                else
                    packageFilePath = fullfile(obj.parentDir, '/package.mat'); 
                end
            end
            
            [depListOk, message] = PackMan.isDepListValid(depList);
            if ~depListOk, error('PackMan:DepListError', 'Problem in depList:%s\n', message); end
            
            obj.depList = depList;
            obj.depDirPath = depDirPath;
            obj.packageFilePath = packageFilePath;
            
            obj.addPackageFileDeps();
            if nargout < 1
                obj.install();
            end
            
            try
                % Attempt to update "installDeps.m" if needed
                [ST] = dbstack();
                if length(ST) == 2 && strcmp(ST(2).file, 'installDeps.m')
                    [ST] = dbstack('-completenames');
                    % Called from "installDeps.m". Check for its updates
                    oldFilePath = ST(2).file;
                    newFileDir = fullfile(fileparts(ST(1).file), 'installDeps.m');
                    fileO = javaObject('java.io.File', oldFilePath);
                    fileN = javaObject('java.io.File', newFileDir);
                    if ~javaMethod('contentEquals','org.apache.commons.io.FileUtils', fileO, fileN)
                        fprintf('=====\n');
                        fprintf('A new version of "installDeps.m" seems to be available.\n');
                        fprintf('PackMan will now replace your "installDeps.m" with the new file by runnig:\n');
                        cmdStr = sprintf('copyfile(''%s'', ''%s'');', newFileDir, oldFilePath);
                        fprintf('>> %s\n', cmdStr);
                        copyfile(newFileDir, oldFilePath);
                        fprintf('Done. "installDeps.m" was updated from "%s".\n', newFileDir);
                        fprintf('=====\n');
                    end
                end
            catch
            end
        end
        
        function obj = addPackageFileDeps( obj )
            % Incorporates dependecies from the package file
            % Inputs: 
            % (none)
            % Outputs
            % (none)
            % Usage sample: 
            %   pm = PackMan();
            
            depListF = PackMan.loadFromPackageFile(obj.packageFilePath);
            
            [depListOk, message] = PackMan.isDepListValid(depListF);
            if depListOk
                obj.depList = PackMan.mergeDepList(depListF, obj.depList);
            else
                fprintf('WARNING: Problem in dependencies listed in file %s:%s\n', obj.packageFilePath, message);
                fprintf('Discarding package file info!\n'); 
            end
            
        end
        
        function install(obj, alreadyInstalled, depth)
            % Installs/update dependecies in the dep directory
            % Inputs: 
            % (1) alreadyInstalled (default: []): a list of dependecies
            %       that are already installed (perhaps by other
            %       dependecies and thus do not need to be installed.
            % (2) depth (default: 0): depth of recursion
            % Outputs:
            % (none)
            % Usage sample: 
            %   pm = PackMan();
            %   obj.install();
            
            if isempty(obj.depList), return; end
            
            if nargin < 2, alreadyInstalled = []; end
            if nargin < 3, depth = 0; end
            
            depListLength = length(obj.depList);
            if depListLength > 0
                obj.dispHandler(sprintf('Installing dependencies for %s...', obj.parentDir));
            end
            
            for i = 1:depListLength
                thisDep = obj.depList(i);
                if ~isempty(alreadyInstalled) && ( ...
                        ismember(thisDep, alreadyInstalled) || ...
                        (~isempty(thisDep.Commit) && any(strcmp(thisDep.Commit, {alreadyInstalled.Commit}))) ... % Assumes identical commid id means identical code
                    ) 
                    obj.dispHandler(sprintf('- %s already installed (%s...)', thisDep.Name, thisDep.getVersionStr()));
                else
                    conflict = false;
                    for j = 1:length(alreadyInstalled)
                        if (isequal(thisDep.Url, alreadyInstalled(j).Url) || ...
                            isequal(strrep(thisDep.Url, '.git', ''), strrep(alreadyInstalled(j).Url, '.git', ''))) && ...
                            isequal(thisDep.Commit, alreadyInstalled(j).Commit) && ...
                            isequal(thisDep.FolderName, alreadyInstalled(j).FolderName)
                            conflict = true;
                        end
                    end
                    if ~conflict
                        depMat = DepMat(thisDep, obj.depDirPath);
                        depMat.setDispHandler( @(x)(obj.dispHandler(sprintf('- %s', x))) );
                        depMat.cloneOrUpdateAll;
                        alreadyInstalled = cat(1, alreadyInstalled, thisDep);
                    else
                        pm = obj.createDepPackMan( thisDep );
                        warning('PackMan:install:versionConflict', 'Two different versions of %s were listed as dependencies! Aborted installation of the following version:  (%s, to be installed in in "%s")!\n', thisDep.Url, thisDep.getVersionStr(), pm.parentDir);
                    end
                end
            end
            
            obj.saveToFile();
            obj.recurse( alreadyInstalled, depth );
        end
        
        function recurse( obj, alreadyInstalled, depth )
            % Goes over the list of dependecies and installs their
            % dependencies
            % Inputs: 
            % (1) alreadyInstalled (default: []): a list of dependecies
            %       that are already installed (perhaps by other
            %       dependecies and thus do not need to be installed.
            % (2) depth (default: 0): depth of recursion
            % Outputs:
            % (none)
            % Usage sample: 
            %   pm = PackMan();
            %   obj.recurse();
            
            if nargin < 2, alreadyInstalled = []; end
            if nargin < 3, depth = 0; end

            for di = 1:length( obj.depList )
                pm = obj.createDepPackMan( obj.depList(di) );
                preS = repmat('  ', [depth, 1]);
                pm.dispHandler = @(x)( fprintf('%s  %s\n', preS, x) );
                if ~obj.depList(di).GetLatest 
                    % Dependencies should inherit the getLatest of their 
                    % parent if it is false
                    for cdi = 1:length(pm.depList)
                        pm.depList(cdi).GetLatest = false;
                    end
                end
                pm.install( alreadyInstalled, 1 + depth );
            end
        end
        
        function [paths, varargout] = genPath( obj, alreadyAdded, selfPaths )
            % Generates a string of dependency directories
            % Inputs: 
            % - (1) alreadyAdded (default: []): a list of dependecies
            %       that are already added to the path list (perhaps by other
            %       dependecies and thus do not need to be added again.
            % - (2) selfPaths (default: true): If true, will also add self
            %       paths (will be set to false in recursive calls)
            % Outputs: 
            % - (1) paths: string of dependencies and recursively of their
            %           dependencies
            % - (2) alreadyAdded: updated list of deps that are added to
            %           the path list
            % Usage sample: 
            %   pm = PackMan(); 
            %   pm.install(); 
            %   paths = pm.genPath(); 
            %   addpath(paths); 
            if nargin < 2, alreadyAdded = {}; end
            if nargin < 3, selfPaths = true; end
            
            paths = {};
            if selfPaths
                % Add subpaths of this package
                paths = [paths; obj.getSelfPaths()];
            end
            % Add parent paths of deps
            [depSelfPaths, alreadyAdded, nowAdded ] = obj.getDepSelfPaths( alreadyAdded );
            paths = [paths; depSelfPaths];
            % Recurse to deps of the added deps
            for di = 1:length(nowAdded)
                thisDep = nowAdded(di);
                pm = obj.createDepPackMan( thisDep );
                [depPaths, alreadyAdded] = pm.genPath( alreadyAdded, false );
                paths = [paths; depPaths];
            end
            
            paths = unique(paths);
            if nargout > 1, varargout{1} = alreadyAdded; end
        end
        
        function [paths, varargout] = getDepSelfPaths(obj, alreadyAdded)
            % Generates a string of dependency directories
            % Inputs: 
            % - (1) alreadyAdded (default: []): a list of dependecies
            %       that are already added to the path list (perhaps by other
            %       dependecies and thus do not need to be added again.
            % Outputs: 
            % - (1) paths: string of dependencies and recursively of their
            %           dependencies
            % - (2) alreadyAdded: updated list of deps that are added to
            %           the path list
            % - (3) nowAdded: list of deps that were added in this call
            % Usage sample: 
            %   pm.getDepSelfPaths(); 

            if nargin < 2, alreadyAdded = {}; end
            
            nowAdded = {};
            paths = {};
            for di = 1:length( obj.depList )
                thisDep = obj.depList(di);
                % obj.dispHandler(sprintf('Considering dep %s (%s)', thisDep.Name, thisDep.Commit));
                if ~isempty(alreadyAdded) && (ismember(thisDep, alreadyAdded) || any(strcmp(thisDep.Commit, {alreadyAdded.Commit}))) % Assumes identical commid id means identical code
                    obj.dispHandler(sprintf('- %s already added to path list (%s...)', thisDep.Name, thisDep.getVersionStr()));
                else
                    conflict = false;
                    for j = 1:length(alreadyAdded)
                        if (isequal(thisDep.Url, alreadyAdded(j).Url) || ...
                            isequal(strrep(thisDep.Url, '.git', ''), strrep(alreadyAdded(j).Url, '.git', ''))) && ...
                           ~isequal(thisDep.Commit, alreadyAdded(j).Commit)
                            conflict = true;
                        end
                    end
                    pm = obj.createDepPackMan( thisDep );
                    if ~conflict
                        alreadyAdded = cat(1, alreadyAdded, thisDep);
                        nowAdded = cat(1, nowAdded, thisDep);
                        depPaths = pm.getSelfPaths();
                        paths = [paths; depPaths];
                    else
                        warning('PackMan:genpath:versionConflict', 'Two different versions of %s were listed as dependencies! Aborted adding of the following version  to the path:  (%s, located in "%s")!\n', thisDep.Url, thisDep.getVersionStr(), pm.parentDir);
                    end
                end
            end
            if nargout > 1, varargout{1} = alreadyAdded; end
            if nargout > 2, varargout{2} = nowAdded; end
        end
        
        function paths = getSelfPaths(obj)
            paths = {};
            % Add subpaths of this package
            files = dir(obj.parentDir);
            files(~[files.isdir]) = [];
            files(ismember({files.name}, {'.','..','.git',obj.depDirPath})) = [];
            for fi = 1:length(files)
                subDirPath = fullfile(files(fi).folder, files(fi).name);
                if strcmp(subDirPath, obj.depDirPath), continue; end
                paths = [paths; genNonGitPath(subDirPath)];
            end
            paths = [{obj.parentDir}; paths];
        end
        
        function pm = createDepPackMan( obj, dep )
            depDir = fullfile(obj.depDirPath, dep.FolderName);
            pm = PackMan([], '', '', depDir);
            
            if (~strcmp(dep.Name,'PackMan'))
                generatedPath = pm.genPath;
                if (all(cellfun(@exist, generatedPath)== 7))
                    oldPath = path;
                    addpath(generatedPath{:});
                    s = which('installDeps.m', '-ALL');
                    pathIndexesContainintDepDir = contains(s, depDir);
                    if any(pathIndexesContainintDepDir)
                        installDepsPath = s{pathIndexesContainintDepDir};
                        dpDirPth = fileparts(strrep(installDepsPath,depDir,''));
                        getDepListFunction = fullfile(depDir, dpDirPth, 'getDepList.m');
                        run(getDepListFunction);
                        structureArray = ans;
                        pm = PackMan(ans, fullfile(fileparts(installDepsPath),'external') , '', depDir);
                    end
                    path(oldPath);
                end
            end
        end
        
        function saveToFile(obj)
            pkgFile = obj.packageFilePath;
            dependencies = struct;
            
            % No need to do this:
%             if exist(pkgFile, 'file')
%                 fData = load(pkgFile);
%                 if isfield(fData, 'dependencies'), dependencies = fData.dependencies; end
%             end

            depMat = DepMat(obj.depList, obj.depDirPath);
            [allStatus, allCommitIDs] = depMat.getAllStatus;

            for i = 1:length(depMat.RepoList)
                if ( (allStatus(i) == DepMatStatus.UpToDate) || ~isempty(allCommitIDs{i}) )
                    fieldName = depMat.RepoList(i).Name;
                    dependencies.(fieldName) = depMat.RepoList(i).toStruct();
                    dependencies.(fieldName).Commit = allCommitIDs{i};
                end
            end

            [~,~,ext] = fileparts(pkgFile);
            if strcmpi(ext, '.mat')
                if exist(pkgFile, 'file')
                    save(pkgFile, 'dependencies', '-append');
                else
                    save(pkgFile, 'dependencies');
                end
            elseif strcmpi(ext, '.json')
                if exist(pkgFile, 'file')
                    fD = jsondecode( fileread(pkgFile) );
                else
                    fD = struct;
                end
                if ~isfield(fD, 'dependencies')
                    fD.dependencies = dependencies;
                end
                fNames = fieldnames(dependencies);
                for fi = 1:length(fNames)
                    fD.dependencies.(fNames{fi}) = dependencies.(fNames{fi});
                end
                PackMan.saveAsJSON(fD, pkgFile);
            else
                error('File with extension "%s" is not supported!\n', ext);
            end
        end
        
        function setDispHandler(obj, funcHandle)
            obj.dispHandler = funcHandle;
        end
    end
    
    methods (Static)
        
        function [result, varargout] = isDepListValid(depList)
            % Validates a dep list to make sure directory names are ok, etc
            % Inputs: 
            % (1) depList: dep list
            % Outputs: 
            % (1) result: if true, depList is OK. If there are any problems
            %             will be false.
            % (2) message: message describing the problem (if any)
            
            message = '';
            if isempty(depList)
                result = true; 
                varargout{1} = message; 
                return; 
            end
            
            % Names must be unique
            depNames = {depList.Name};
            if length(unique(depNames))~=length(depNames), message = sprintf('%sRepo "Name"s must be unique\n', message); end
            
            dirNames = {depList.FolderName};
            if length(unique(dirNames))~=length(dirNames), message = sprintf('%sRepo "FolderName"s must be unique\n', message); end
            
            dirNames = {depList.FolderName};
            if length(unique(dirNames))~=length(dirNames), message = sprintf('%sRepo "FolderName"s must be unique\n', message); end
            
            result = isempty(message);
            if nargout > 1, varargout{1} = message; end
        end
        
        function depListOut = mergeDepList(depList1, depList2)
            % Merges two depLists
            % Inputs: 
            % (1) depList1: dep list 1
            % (2) depList2: dep list 2. This takes precedence over depList1
            % Outputs: 
            % (1) depListOut: merged depList
            % Usage sample: 
            %   depListFull = PackMan.mergeDepList( depList1, depList2 );
            
            if isempty(depList1), depListOut = depList2; return; end
            depListOut = depList1(:);
            for i = 1:length(depList2)
                depNames = {depListOut.Name};
                ind = find( strcmp(depNames, depList2(i).Name  ));
                if isempty(ind)
                    ind = length(depListOut) + 1; 
                else
                    BU = depListOut(ind);
                    if isempty(depList2(i).Commit) % Do not erase commit id if not mentioned in new depList
                        depList2(i).Commit = BU.Commit; 
                    end
                end
                depListOut(ind, 1) = depList2(i);
            end
        end

        function depList = loadFromPackageFile(filePath)
            % Loads package info from package file
            % Inputs: 
            % (1) filePath: path to thepackage info file
            % Outputs: 
            % (2) depList: depList extracted from file
            % Usage sample: 
            %   depList = PackMan.loadFromPackageFile( './package.json' );
            
            if nargin < 1 
                if exist('jsonencode', 'builtin')
                    filePath = './package.json'; 
                else
                    filePath = './package.mat'; 
                end
            end

            depList = [];
            
            [~,~,ext] = fileparts(filePath);
            if strcmpi(ext, '.json') && ~exist(filePath, 'file')&&exist([filePath(1:(end-5)),'.mat'], 'file') % Old mat file exists, switch to json
                pkgFileMat = [filePath(1:(end-5)),'.mat'];
                fD = load(pkgFileMat);
                if PackMan.saveAsJSON(fD, filePath)
                    fprintf('".mat" package file was converted to JSON and saved as: "%s"\n', filePath);
                    if movefile(pkgFileMat, [pkgFileMat,'.bak'])
                        fprintf('Original ".mat" package file was renamed to for backup "%s"\n', [pkgFileMat,'.bak']);
                    end
                end
            end

            if ~exist(filePath, 'file'), return; end

            if strcmpi(ext, '.mat')
                fData = load(filePath);
            elseif strcmpi(ext, '.json')
                fData = jsondecode( fileread(filePath) );
                if isfield(fData, 'dependencies')&&isstruct(fData.dependencies)
                    pNames = fieldnames(fData.dependencies);
                    for p = 1:length(pNames)
                        % Fix field name cases 
                        fDNames = fieldnames(fData.dependencies.(pNames{p}));
                        DepMatRepFNames = properties(DepMatRepo);
                        for fi = 1:length(fDNames)
                            if any(strcmpi(fDNames{fi}, DepMatRepFNames))&&~any(strcmp(fDNames{fi}, DepMatRepFNames))
                                fNewName = DepMatRepFNames{find(strcmpi(fDNames{fi}, DepMatRepFNames), 1)};
                                fData.dependencies.(pNames{p}).(fNewName) = fData.dependencies.(pNames{p}).(fDNames{fi});
                                fData.dependencies.(pNames{p}) = rmfield(fData.dependencies.(pNames{p}), fDNames{fi});
                            end
                        end
                    end
                end
            else
                error('File with extension "%s" is not supported!\n', ext);
            end
            
            if ~isfield(fData, 'dependencies'), return; end
            fieldNames = fieldnames( fData.dependencies );

            for i = 1:length(fieldNames)
                fieldData = fData.dependencies.( fieldNames{i} );
                if ~isfield(fieldData, 'FolderName'), fieldData.FolderName = fieldData.Name; end
                if ~isfield(fieldData, 'Commit'), fieldData.Commit = ''; end
                if ~isfield(fieldData, 'GetLatest'), fieldData.GetLatest = true; end
                thisRepo = DepMatRepo(fieldData.Name, fieldData.Branch, fieldData.Url, fieldData.FolderName, fieldData.Commit, fieldData.GetLatest);
                depList = cat(1, depList, thisRepo);
            end
        end
        
        function ok = saveAsJSON(dataStruct, savePath, prettify)
            if nargin < 3, prettify = true; end
            try
                JSON = PackMan.covertToJson(dataStruct, prettify);
                currentFileContent = '';
                if exist(savePath, 'file')
                    currentFileContent = fileread(savePath);
                end
                if ~isequal(JSON, currentFileContent)
                    fId = fopen(savePath, 'w+'); 
                    if fId > -1
                        fprintf(fId, '%s', JSON);
                        fclose(fId);
                    else
                        ok = false;
                    end
                end
                ok = true;
            catch
                ok = false;
            end
        end
        
        function JSON = covertToJson(dataStruct, prettify)
            % Converts data struct to pretty json
            % Inputs:
            % (1) dataStruct: data to be coverted
            % (2) pretty (default: true): if true, will attempty to make
            %       JSON more human readable
            % Outputs:
            % (1) JSON: JSON string
            
            if nargin < 2, prettify = true; end
            JSON = jsonencode( dataStruct );
            if prettify
                JSON2 = JSON;
                JSON2 = strrep(JSON2, ',', sprintf(',\n'));
                JSON2 = strrep(JSON2, '{', sprintf('{\n'));
                JSON2 = strrep(JSON2, '}', sprintf('\n}'));
                indentCnt = 0;
                i = 1;
                while i <= length(JSON2)
                    if strcmp(JSON2(i), '{')
                        indentCnt = indentCnt + 1;
                    elseif strcmp(JSON2(i), '}')
                        indentCnt = indentCnt - 1;
                        if i > 1 && strcmp(JSON2(i-1), sprintf('\n'))
                            JSON2 = PackMan.replaceStrAtIndex(JSON2, i, [repmat(' ', [1, indentCnt]), '}']);
                        end
                        i = i + indentCnt;
                    elseif strcmp(JSON2(i), '"') && i > 1 && strcmp(JSON2(i-1), sprintf('\n'))
                        JSON2 = PackMan.replaceStrAtIndex(JSON2, i, [repmat(' ', [1, indentCnt]), '"']);
                        i = i + indentCnt;
                    end
                    i = i + 1;
                end
                JSON = JSON2;
            end
        end
        function strO = replaceStrAtIndex(str, ind, newStr)
            strO = '';
            if ind > 1, strO = str(1:(ind-1)); end
            strO = sprintf('%s%s', strO, newStr);
            if ind < length(str), strO = sprintf('%s%s', strO, str((ind+1):end)); end
        end
    end 
end