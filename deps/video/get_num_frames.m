function num_frames = get_num_frames(filename)
%GET_NUM_FRAMES Returns the number of frames in a video.
% Usage:
%   num_frames = get_num_frames(filename)

ext = get_ext(filename);

switch ext
    case '.ufmf'
        num_frames = ufmf_get_num_frames(filename);
    case '.fmf'
        num_frames = fmf_get_num_frames(filename);
    otherwise
        vinfo = video_open(filename);
        num_frames = vinfo.n_frames;
        video_close(vinfo);
end

end

