classdef IndicatorAnimator < Animator
    %IndicatorAnimator - interactive indicator
    %Subclass of Animator.
    %
    %Syntax: IndicatorAnimator(X)
    %
    %IndicatorAnimator Properties:
    %   logic - logical vector of when the indicator should be on. 
    %   Patch - handle to indicator Patch. 
    %   Color - Color of the indicator
    %
    %IndicatorAnimator Methods:
    %IndicatorAnimator - constructor
    %restrict - restrict animation to subset of frames
    %keyPressCalback - handle UI
    properties (Access = private)
        statusMsg = 'IndicatorAnimator:\nFrame: %d\nframeRate: %d\n';
    end
    
    properties (Access = public)
        logic
        Patch
        Color = 'r';
        patchX = [0 1 1 0];
        patchY = [0 0 1 1];
    end
    
    methods
        function obj = IndicatorAnimator(logic, varargin)
            [animatorArgs, ~, varargin] = parseClassArgs('Animator', varargin{:});
            obj@Animator(animatorArgs{:});
            % User defined inputs
            if ~isempty(logic)
                obj.logic = logic;
            end
            
            if ~isempty(varargin)
                set(obj,varargin{:});
            end
            % Handle defaults
            if isempty(obj.nFrames)
                obj.nFrames = size(obj.logic, 1);
            end
            obj.frameInds = 1:obj.nFrames;
            if obj.logic(1)                
                obj.Patch = patch(obj.Axes, obj.patchX, obj.patchY, obj.Color,'FaceAlpha',.5,'LineStyle','none');
            else 
                obj.Patch = patch(obj.Axes, obj.patchX, obj.patchY, obj.Color,'FaceAlpha',0,'LineStyle','none');
            end
            axis(obj.Axes,'off');
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
            restrict(obj,1:size(obj.logic,1));
        end
    end
    
    methods (Access = protected)
        function update(obj)
            obj.checkVisible
            if obj.logic(obj.frameInds(obj.frame))
                set(obj.Patch, 'FaceAlpha', .5)
            else
                set(obj.Patch, 'FaceAlpha', 0)
            end
        end
    end
end