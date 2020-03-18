%getDepList Returns an array of DepMatRepo objects representing the
%dependencies of this project
%   Modify this if you want to add more dependencies to your project

function depList = getDepList

depList        = {'PackMan', 'release', 'https://github.com/DanielAtKrypton/PackMan.git', 'PackMan', '', true};
depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);    
% Arguments for DepMatRepo: DepMatRepo(Name, Branch, Url, FolderName, Commit, GetLatest)
% Example:
% depList        = [...
%     {'PackMan', 'dev01', 'https://github.com/DanielAtKrypton/PackMan.git', 'PackMan', '', true};
%     {'DataHash', 'master', 'https://github.com/DanielAtKrypton/DataHash.git', 'DataHash', '', true};
% ];
% depList = cell2struct(depList, {'Name', 'Branch', 'Url', 'FolderName', 'Commit', 'GetLatest'}, 2);