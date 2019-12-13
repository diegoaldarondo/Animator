function str = mkfun(name, varargin)
%MKFUN Makes a function template in the current directory.
% Usage:
%   mkfun name
%   mkfun name arg1 arg2 ...
%   str = mkfun(_) % returns string of function template
%
% See also: alias

if ~isempty(which(name))
    error('Function already exists in path: %s', which(name))
end

template = {
    'function #name(#args)'
    '%#NAME Description'
    '% Usage:'
    };

args = '';
if nargin > 1
    args = strjoin(varargin, ', ');
    arg_strings = cf(@(x) ['%   ' x ': '], varargin);
    
    template = [template; {
            '%   #name(#args)'
            '% '
            '% Args:'
        };
        arg_strings(:)];
else
    template{end+1} = '%   #name';
end

template = [template; {
    '% '
    '% See also: '
    ''
    ''
    'end'
    ''
    }];

str = regexprep(strjoin(template, '\n'), {'#name', '#NAME', '#args'}, {name, upper(name), args});
writestr(str, [name '.m']);

edit(name)

if nargout < 1; clear str; end

end

