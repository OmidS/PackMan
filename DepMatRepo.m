classdef DepMatRepo
    % DepMatRepo. Represets a dependency on a git repository
    %
    %
    %
    %     Licence
    %     -------
    %     Part of DepMat. https://github.com/tomdoel/depmat
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    

    properties
        Name
        Url
        Branch
        FolderName
        Commit
        GetLatest
    end
    
    methods
        function obj = DepMatRepo(name, branch, url, folderName, commit, getLatest)
            if nargin > 0
                obj.Name = name;
                obj.Branch = branch;
                obj.Url = url;
                obj.FolderName = folderName;
                if nargin < 5, commit = ''; end
                obj.Commit = commit;
                if nargin < 6, getLatest = true; end
                obj.GetLatest = getLatest;
            end
        end
        function strct = toStruct(obj)
            strct = struct( ...
                'Name', obj.Name, ...
                'Branch', obj.Branch, ...
                'Url', obj.Url, ...
                'FolderName', obj.FolderName, ...
                'Commit', obj.Commit, ...
                'GetLatest', obj.GetLatest ...
            );
        end
    end
    
end

