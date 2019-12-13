function idx = range2idx(A)
%RANGE2IDX Returns the indices specified by the rows in A.
% Usage:
%   idx = range2idx(A)

idx = arrayfun(@(i, j) i:j, A(:, 1), A(:, 2), 'UniformOutput', false);
idx = unique([idx{:}]);

end

