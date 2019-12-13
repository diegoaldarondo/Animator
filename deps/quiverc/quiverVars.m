function [gX, gY, gdX, gdY] = quiverVars(X, Y, varargin)
% Create a grid representation of the vectorfield of variables X and Y. For
% use in quiver function. 
% usage:
%   [gX, gY, gdX, gdY] = quiverVars(X, Y, 'step',5','lbound',1)
%
% arguments:
%   X: (1 x t) timeseries
%   Y: (1 x t) timeseries
%   step: Step size of grid
%   lbound: Lower bound of grid
%   ubound: Upper bound of grid
%   densityThresh: Number of points in grid bin required to maintain vector
%   diffStep: Number of timesteps to use in differentiation. 
p = inputParser;
addOptional(p, 'step', .5, @isnumeric)
addOptional(p, 'lbound', 1, @isnumeric)
addOptional(p, 'ubound', 99, @isnumeric)
addOptional(p, 'densityThresh', 5, @isnumeric)
addOptional(p, 'diffStep', 1, @isnumeric)

parse(p, varargin{:});
lbound = p.Results.lbound;
ubound = p.Results.ubound;
step = p.Results.step;
diffStep = p.Results.diffStep;
densityThresh = p.Results.densityThresh;

if size(X,2) == 1 && size(X,1) > size(X,2)
    X = X';
end
if size(Y,2) == 1 && size(Y,1) > size(Y,2)
    Y = Y';
end

% Differentiate
dX = zeros(size(X));
dY = zeros(size(Y));
if diffStep == 1
    tempX = diffpad(X, 2, diffStep, 0, 'post');
    tempY = diffpad(Y, 2, diffStep, 0, 'post');
else
    tempX = X - circshift(X,diffStep);
    tempY = Y - circshift(Y,diffStep);
    tempX = tempX(diffStep+1:end);
    tempY = tempY(diffStep+1:end);
end
dX(1:numel(tempX)) = tempX;
dY(1:numel(tempY)) = tempY;

% Create mesh
% xpts = prctile(X, lbound):step:prctile(X, ubound);
xpts = min(X):step:max(X);
ypts = prctile(Y, lbound):step:prctile(Y, ubound);
[gX, gY] = meshgrid(xpts,ypts);

% Calculate the median gradient within the mesh bins
gdX = zeros(size(gX));
gdY = zeros(size(gY));
for ngX = 1:size(gX,2)-1
    for ngY = 1:size(gY,1)-1
        inX = X > gX(1, ngX) & X <= gX(1,ngX+1);
        inY = Y > gY(ngY,1) & Y <= gY(ngY+1, 1);
        in = inX & inY;
        if sum(in) < densityThresh
            continue;
        end
        gdX(ngY,ngX) = median(dX(in));
        gdY(ngY,ngX) = median(dY(in));
    end
end
end