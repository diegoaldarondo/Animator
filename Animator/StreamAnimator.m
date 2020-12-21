classdef StreamAnimator < Animator
    %StreamAnimator - interactive movie
    %Subclass of Animator.
    %
    %Syntax: StreamAnimator(V)
    %
    %StreamAnimator Properties:
    %   filePath - Path to video from which to decode frames
    %   img - Handle to the imshow object
    %   
    %
    %StreamAnimator Methods:
    %StreamAnimator - constructor
    %restrict - restrict animation to subset of frames
    %keyPressCalback - handle UI
    properties (Access = private)
        statusMsg = 'StreamAnimator:\nFrame: %d\nframeRate: %d\n';
        instructions = ['StreamAnimator Guide:\n' ...
            'rightarrow: next frame\n' ...
            'leftarrow: previous frame\n' ...
            'uparrow: increase frame rate\n' ...
            'downarrow: decrease frame rate\n' ...
            'space: set frame rate to 1\n' ...
            'control: set frame rate to 50\n' ...
            'shift: set frame rate to 250\n' ...
            'h: help guide\n' ...
            'r: reset\n' ...
            's: print current frame and rate\n'];
        MarkerSize = 30
        LineWidth = 3
        rate
        prevFrame
        vidReader
    end
    
    properties (Access = public)
        filePath
        img
        clim
        
    end
    
    methods
        function obj = StreamAnimator(filePath, varargin)
            [animatorArgs, ~, varargin] = parseClassArgs('Animator', varargin{:});
            obj@Animator(animatorArgs{:});
            % User defined inputs
            if ~isempty(varargin)
                set(obj,varargin{:});
            end
            obj.filePath = filePath;
%             video = mmread(obj.filePath, 1, [], false, true);
%             obj.rate = round(video.rate, 2);
%             obj.vidReader = vision.VideoFileReader(obj.filePath);
            obj.vidReader = VideoReader(obj.filePath);
            
            
            % Handle defaults
            if isempty(obj.nFrames)
                obj.nFrames = obj.vidReader.FrameRate*obj.vidReader.Duration;
%                 obj.nFrames = obj.rate*video.totalDuration;

%                 obj.nFrames = obj.vidReader.NumFrames;
            end
            obj.rate = obj.vidReader.FrameRate;
            
            obj.frameInds = 1:obj.nFrames;
            if ~isempty(obj.clim)
                obj.img = imagesc(obj.Axes, obj.getVideoFrame(obj.frame), obj.clim);
            else
                obj.img = imagesc(obj.Axes, obj.getVideoFrame(obj.frame));
            end
            axis(obj.Axes, 'ij','tight')
        end
        
%         function time = frame2time(obj, frame)
%             time = (frame:frame+1)/obj.rate;
%         end
        function time = frame2time(obj, frame)
            time = frame/obj.rate;
        end
        
%         function frame = getVideoFrame(obj, frame)
%             time = obj.frame2time(frame);
%             disp('called')
%             frame = readFrameByTime(obj.filePath, time);
%         end
        function frame = getVideoFrame(obj, frame)
            time = obj.frame2time(frame);
            disp('called')
            obj.vidReader.currentTime = time;
            if obj.vidReader.hasFrame()
                frame = readFrame(obj.vidReader);
            end
        end
        
        function restrict(obj, newFrames)
            restrict@Animator(obj, newFrames);
        end
        
        function keyPressCallback(obj,source,eventdata)
            obj.prevFrame = obj.frame;
            % determine the key that was pressed
            keyPressCallback@Animator(obj,source,eventdata);
            keyPressed = eventdata.Key;
            switch keyPressed
                case 's'
                    fprintf(obj.statusMsg,...
                        obj.frameInds(obj.frame),obj.frameRate);
                case 'r'
                    reset(obj);
                case 'h'
                    fprintf(obj.instructions)
            end
%             update(obj);
        end
    end
    
    methods (Access = private)
        function reset(obj)
            restrict(obj,1:obj.nFrames);
        end
    end
    
    methods (Access = protected)
        function update(obj)
            obj.checkVisible
            try
                set(obj.img,'CData',obj.getVideoFrame(obj.frame));
            catch
                disp('Failed to decode frame.')
            end
        end
    end
end