%getDepList Returns an array of DepMatRepo objects representing the
%dependencies of this project
%   Modify this if you want to add more dependencies to your project

function depList = getDepList

depList = [];
% Arguments for DepMatRepo: DepMatRepo(Name, Branch, Url, FolderName, Commit, GetLatest)
% Example: 
% depList           = DepMatRepo('PackMan', 'master', 'https://github.com/OmidS/PackMan.git', 'PackMan', '', true);
% depList(end+1, 1) = DepMatRepo('depmat', 'master', 'https://github.com/OmidS/depmat.git', 'subid', '', true);

end