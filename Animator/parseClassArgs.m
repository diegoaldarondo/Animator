function [classArgs, classInds, nonClassArgs] = parseClassArgs(className, varargin)
%% parseClassArgs - Parse arguments specific to a class
% Inputs:
%   className - Name of class whose arguments you wish to parse
%
% Outputs:
%   classArgs - Cell array of class arguments
%   classInds - Logical indices denoting original positions of class
%               arguments. (class name & argument)
% Syntax:
%   [classArgs, classInds] = parseClassArgs(className, varargin{:})

nameIds = cellfun(@ischar, varargin); % logical array: 1 = string
nameIds(2 : 2 : end) = false; % all even indices are set to 0
names = varargin(nameIds); % keyword of arguments
% create a 1 x nArgs array where elements {2*i}, {2*i+1} are 1 if varargin{2*i} is a property of className
% e.g. varargin = { "Axes", 2, "foo", 3} & className = "Label3D" => classInds = [ 1 1 0 0]
classInds = repelem(contains(names, properties(className)), 1, 2);
classArgs = varargin(classInds);
nonClassArgs = varargin(~classInds);
end