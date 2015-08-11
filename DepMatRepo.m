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
    end
    
    methods
        function obj = DepMatRepo(name, branch, url)
            if nargin > 0
                obj.Name = name;
                obj.Branch = branch;
                obj.Url = url;
            end
        end
    end
    
end

