classdef VideoAnimator < Animator
    %VideoAnimator - interactive movie
    %Subclass of Animator.
    %
    %Syntax: VideoAnimator(V)
    %
    %VideoAnimator Properties:
    %   V - 4D (i,j,channel,N) movie to animate.
    %   animal - handle to the calling Animal object to sync with
    %             MarkerMovies.
    %   img - Handle to the imshow object
    %   
    %
    %VideoAnimator Methods:
    %VideoAnimator - constructor
    %restrict - restrict animation to subset of frames
    %keyPressCalback - handle UI
    properties (Access = private)
        statusMsg = 'VideoAnimator:\nFrame: %d\nframeRate: %d\n';
        MarkerSize = 30
        LineWidth = 3
    end
    
    properties (Access = public)
        V
        img
        color
        joints
        markers
        scatterFig
        PlotSegments   
        skeleton
        nMarkers
        AxesPosition = [0 0 1 1];
    end
    
    methods
        function obj = VideoAnimator(V, varargin)
            % User defined inputs
            if ~isempty(V)
                obj.V = V;
                % Handle 3 dimensional matrices as grayscale videos. 
                if numel(size(obj.V)) == 3
                    obj.V = reshape(obj.V,size(obj.V,1),size(obj.V,2),1,size(obj.V,3));
                end
            end
            if ~isempty(varargin)
                set(obj,varargin{:});
            end
            
            % Handle defaults
            if isempty(obj.nFrames)
                obj.nFrames = size(obj.V,4);
            end
            obj.frameInds = 1:obj.nFrames;
            
            hold(obj.Axes,'off')
            obj.img = imshow(obj.V(:,:,:, obj.frame),'Parent',obj.Axes);
            set(obj.Axes,'Units','normalized',...
                'Position',obj.AxesPosition);
        end
        
        function restrict(obj, newFrames)
            restrict@Animator(obj, newFrames);
        end
        
        function keyPressCallback(obj,source,eventdata)
            % determine the key that was pressed
            keyPressCallback@Animator(obj,source,eventdata);
            keyPressed = eventdata.Key;
            switch keyPressed
                case 's'
                    fprintf(obj.statusMsg,...
                        obj.frameInds(obj.frame),obj.frameRate);
                case 'r'
                    reset(obj);
            end
            update(obj);
        end
    end
    
    methods (Access = private)
        function reset(obj)
            % Set embedMovie and associated MarkerMovies to the orig. size
            restrict(obj,1:size(obj.V,4));
        end
    end
    
    methods (Access = protected)
        function update(obj)
            set(obj.img,'CData',obj.V(:,:,:,  obj.frameInds(obj.frame)));
        end
    end
end