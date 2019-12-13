function new_filename = get_new_filename(filename)
%GET_NEW_FILENAME Returns a new filename based on the one specified.
% Usage:
%   new_filename = get_new_filename(filename)

% Break filename into components
[pathstr, name, ext] = fileparts(filename);
base = fullfile(pathstr, name);

% Iterate until we find a non-existing filename
num = 1;
new_filename = [base ext];
while exists(new_filename)
    num = num + 1;
    new_filename = [base ' (' num2str(num) ')' ext];
end

end

