function writestr(str, filename)
%WRITESTR Write a string to a file. Plain and simple!
% Usage:
%   writestr(str, filename)
%   writestr(cellstr, filename)
%
% See also: saveText

if iscellstr(str)
    str = strjoin(str,'\n');
end

f = fopen(filename, 'w');
fprintf(f, '%s', str);
fclose(f);


end

