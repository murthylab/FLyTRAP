function [fileNames, fileList] = getFileNames(fileNamePattern)
% [fileNames, fileList] = getFileNames(fileNamePattern)
% PARAM:
%  fileNamePattern - input to rdir (see rdir help)
% RETURNS:
%  fileNames       - cell array of file names matching pattern
%  fileList        - rdir output

% created 20150731, janc

fileList = rdir(fileNamePattern);
fileNames = {fileList.name}';