function T = imtile(I, varargin)
%IMTILE Tiles a stack or set of images.
% Usage:
%   T = imtile(stack)
%   T = imtile(I1, I2, ...)

if ~iscell(I) && ismatrix(I)
   I = {I}; 
end
if ndims(I) == 3
    I = arr2cell(I,3);
end
if ndims(I) == 4
    I = stack2cell(I);
end

I = [horz(I) varargin];

N = numel(I);
cols = ceil(sqrt(N));
rows = ceil(N / cols);

if N < cols*rows
    I((N+1):(cols*rows)) = {zeros(size(I{1}),'like',I{1})};
end

I = reshape(I,cols,rows)';

T = af(@(r)cellcat(I(r,:),2),1:rows);
T = cellcat(T,1);


end

