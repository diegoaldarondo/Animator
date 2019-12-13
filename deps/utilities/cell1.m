function C = cell1(sz, dim)
%CELL1 Creates a 1d empty cell array. Convenience for cell(sz, 1).
% Usage:
%   C = cell1(sz)
%   C = cell1(sz, dim)
% 
% Args:
%   sz: length of the cell array
%   dim: along which dimension to create cell array (default = 1)
%
% Returns:
%   C: empty cell array with sz elements in dimension dim
% 
% See also: cell

if nargin < 2
    dim = 1;
end

sz2 = ones(1,max(2,dim));
sz2(dim) = sz;

C = cell(sz2);

end
