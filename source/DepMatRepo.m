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
        function bol = eq(obj1,obj2)
            if ~strcmp(class(obj1),class(obj2))
                error('Objects are not of the same class')
            end
            s1 = numel(obj1);
            s2 = numel(obj2);
            if s1 == s2
                bol = false(size(obj1));
                for k=1:s1
                    bol(k) = scalarExpEq(obj1(k),obj2(k));
                 end
            elseif s1 == 1
                bol = scalarExpEq(obj2,obj1);
            elseif s2 == 1
                bol = scalarExpEq(obj1,obj2);
            else
                error('Dimension missmatch')
            end
            function ret = scalarExpEq(ns,s)
                % ns is nonscalar array
                % s is scalar array
                ret = false(size(ns));
                n = numel(ns);
                for kk=1:n
                    if isequal(ns(kk).Name, s.Name) && ...
                       isequal(ns(kk).Branch, s.Branch) && ...
                       isequal(ns(kk).Url, s.Url) && ...
                       isequal(ns(kk).FolderName, s.FolderName) && ...
                       isequal(ns(kk).Commit, s.Commit) && ...
                       isequal(ns(kk).GetLatest, s.GetLatest) 
                        ret(kk) = true;
                    else
                        ret(kk) = false;
                    end
                end
             end
        end
        function str = getVersionStr(obj)
            str = sprintf('Commit: %s...', obj.Commit(1:min(7, length(obj.Commit))));
        end
    end
    
end

