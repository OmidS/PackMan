function repos = TestRepoList
    % TestRepoList. An example list of repositories for use with DepMatUpdate
    %
    %
    %
    %     Licence
    %     -------
    %     Part of DepMat. https://github.com/tomdoel/depmat
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    
    repos = DepMatRepo.empty;
    repos(end + 1) = DepMatRepo('coremat', 'master', 'https://github.com/tomdoel/coremat.git');
    repos(end + 1) = DepMatRepo('dicomat', 'master', 'https://github.com/tomdoel/dicomat.git');
    repos(end + 1) = DepMatRepo('matnat', 'master', 'https://github.com/tomdoel/matnat.git');
end

