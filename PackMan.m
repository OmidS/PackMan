classdef PackMan
    %PackMan Package manager class
    %   Uses DepMat tp provide dependency management
    
    properties
        depList % List of dependencies
        parentDir        % Path to main directory of the package
        depDirPath       % Path to subdirectory for dependencies
        packageFilePath  % Path to package info file
    end
    
    methods
        function obj = PackMan( depList, depDirPath, packageFilePath )
            % Inputs:
            % (1) depList (default): a structure or DepMat array of the
            %             dependencies.
            % (2) depDirPath (default: './external'): path to the 
            %             directory to install dependencies
            % (3) packageFilePath (default: './package.mat'): path to package
            %             info file
            % Outputs:
            % (1) PackMan object
            % Usage sample:
            % 
            
            obj.parentDir = pwd;
            
            if nargin < 1 || isempty(depList), depList = DepMat.empty; end
            if nargin < 2 || isempty(depDirPath), depDirPath = fullfile(obj.parentDir, '/external'); end
            if nargin < 3 || isempty(packageFilePath), packageFilePath = fullfile(obj.parentDir, '/package.mat'); end
            
            [depListOk, message] = PackMan.isDepListValid(depList);
            if ~depListOk, error('PackMan:DepListError', 'Problem in depList:%s\n', message); end
            
            obj.depList = depList;
            obj.depDirPath = depDirPath;
            obj.packageFilePath = packageFilePath;
            
            obj.install();
            obj.saveToFile();
        end
        
        function install(obj)
            % Installs dependecies in the dep directory
            % Inputs: 
            % (none)
            % Outputs
            % (none)
            % Usage sample: 
            %   pm = PackMan();
            %   obj.install();
            
            % If you want to load dependecies from package.mat, uncomment the follwing
            depListF = PackMan.loadFromPackageFile(obj.packageFilePath);
            
            [depListOk, message] = PackMan.isDepListValid(depListF);
            if depListOk
                obj.depList = PackMan.mergeDepList(depListF, obj.depList);
            else
                fprintf('WARNING: Problem in dependencies listed in file %s:%s\n', obj.packageFilePath, message);
                fprintf('Discarding package file info!\n'); 
            end
            
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Install/update dependencies
            depMat = DepMat(obj.depList, obj.depDirPath);
            depMat.cloneOrUpdateAll;
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
                if isequal(allStatus(i), DepMatStatus.UpToDate)
                    fieldName = depMat.RepoList(i).Name;
                    dependencies.(fieldName) = depMat.RepoList(i).toStruct();
                    dependencies.(fieldName).Commit = allCommitIDs{i};
                end
            end

            if exist(pkgFile, 'file')
                save(pkgFile, 'dependencies', '-append');
            else
                save(pkgFile, 'dependencies');
            end
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
                    BU = depListOut(i);
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
            %   depList = PackMan.loadFromPackageFile( './package.mat' );
            
            if nargin < 1, filePath = './package.mat'; end

            depList = [];

            if ~exist(filePath, 'file'), return; end
            fData = load(filePath);

            if ~isfield(fData, 'dependencies'), return; end

            fieldNames = fieldnames( fData.dependencies );

            for i = 1:length(fieldNames)
                fieldData = fData.dependencies.( fieldNames{i} );
                if ~isfield(fieldData, 'Commit'), fieldData.Commit = ''; end
                thisRepo = DepMatRepo(fieldData.Name, fieldData.Branch, fieldData.Url, fieldData.FolderName, fieldData.Commit);
                depList = cat(1, depList, thisRepo);
            end
        end
    end 
end

