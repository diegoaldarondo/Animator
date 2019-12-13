function [Y2, inX] = indpad2(X, ind, padval)
%INDPAD Index into array with padding for out of bounds indices.
% Usage:
%   [Y, inX] = indpad(X, ind, padval)
% 
% Args:
%   X: array
%   ind: linear indices
%   padval: scalar value to pad with (default: NaN)
% 
% Returns:
%   Y: array of the same size as ind
%   inX: logical of the same size as ind that is true for values in X
% 
% See also: padarray, catpadarr
%%
if nargin < 3 || isempty(padval); padval = NaN; end;
%%
% inX = ind >= 1 & ind <= numel(X);
inX = ind >= 1 & ind <= size(X,1);

Y2 = repmat(padval, [size(ind,1),size(ind,2),size(X,2)]);
% size(inX)
% size(ind)
% size(X)
% size(Y2)
% size(ind(j,inX(j,:)))
for i = 1:size(X,2)
    for j = 1:size(ind,1)
        Y2(j,inX(j,:),i) = X(ind(j,inX(j,:)),i);
    end
end
%%
end
