function secs = systime
%SYSTIME Returns precise system time in seconds.
% Usage:
%   secs = systime
%
% Note: This is just a wrapper for GetSystemTimePreciseAsFileTime
%
% See also: GetSystemTimePreciseAsFileTime

if ispc
    secs = GetSystemTimePreciseAsFileTime;
else
    secs = now * 86400 - 50522817600; % same units
end

end

