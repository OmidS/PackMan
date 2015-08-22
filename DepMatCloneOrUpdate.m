function [success, changed] = DepMatCloneOrUpdate(sourceDir, repoDef)
    % DepMatCloneOrUpdate. Performs a clone or update of a git repository
    %
    %
    %
    %     Licence
    %     -------
    %     Part of DepMat. https://github.com/tomdoel/depmat
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    repo = DepMatRepository(sourceDir, repoDef);
    [success, changed] = repo.cloneOrUpdate;
end