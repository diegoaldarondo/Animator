function frame = readFrameByTime(videoPath, frameTimes)
%READFRAME Reads a single video frame via mmread.
% Usage:
%   frame = readFrame(videoPath, frameTimes)
% 
% Returns:
%   frame:
%       Numeric array containing the frame data
% 
% See also: mmread

video = mmread(videoPath, [], frameTimes, false, true);
frame = video.frames.cdata;

end

