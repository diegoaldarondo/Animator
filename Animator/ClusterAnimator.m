classdef ClusterAnimator < Animator
    %ClusterAnimator - interactive raster visualization.
    %Subclass of Animator.
    %
    %Syntax: ClusterAnimator(raster)
    %
    %ClusterAnimator Properties:
    %    C - Nx1 cluster ids
    %
    %ClusterAnimator Methods:
    %ClusterAnimator - constructor
    %restrict - restrict animation to subset of frames
    %keyPressCalback - handle UI
    properties (Access = private)
        statusMsg = 'ClusterAnimator:\nFrame: %d\nframeRate: %d\n';
    end
    
    properties (Access = public)
        C
        cid = 1
        uniqueClusters
    end
    
    methods
        function obj = ClusterAnimator(C, varargin)
            [animatorArgs, ~, varargin] = parseClassArgs('Animator', varargin{:});
            obj@Animator(animatorArgs{:});
            % User defined inputs
            obj.C = C;
            if ~isempty(varargin)
                set(obj,varargin{:});
            end
            
            % Handle defaults
            if isempty(obj.nFrames)
                obj.nFrames = size(obj.C,1);
            end
            obj.frameInds = 1:obj.nFrames;
            obj.uniqueClusters = unique(obj.C);
        end
        
        function restrict(obj, newFrames)
            restrict@Animator(obj, newFrames);
        end
        
        function setCluster(obj, newCluster)
            obj.cid = newCluster;
            frames = obj.C == obj.cid;
            if ~isempty(obj.links)
                for i = 1:numel(obj.links)
                    restrict(obj.links{i},frames)
                end
            else
                restrict(obj,frames);
            end
%             text(obj.Axes, 20, 100, 20, num2str(obj.cid),'Units','normalized');
            text(obj.Axes, .5, .9,  num2str(obj.cid),'Units','normalized','FontWeight','bold');

        end
        
        function keyPressCallback(obj,source,eventdata)
            % determine the key that was pressed
            keyPressCallback@Animator(obj,source,eventdata);
            keyPressed = eventdata.Key;
            modifiers = get(gcf, 'CurrentModifier');
            wasShiftPressed = ismember('shift',   modifiers);
            switch keyPressed
                case 's'
                    fprintf(obj.statusMsg,...
                        obj.frameInds(obj.frame),obj.frameRate);
                case 'r'
                    reset(obj);
                case 'c'
                    newCluster = inputdlg('Enter clu number:');
                    newCluster = str2double(newCluster);
                    if isnumeric(newCluster) && ~isempty(newCluster) && ~isnan(newCluster)
                        obj.setCluster(newCluster)
                    end
                case 'tab'
                    if wasShiftPressed
                        obj.cid  = obj.cid - 1;
                    else
                        obj.cid  = obj.cid + 1;
                    end
                    obj.cid = mod(obj.cid, numel(obj.uniqueClusters));
                    if obj.cid == 0
                        obj.cid = numel(obj.uniqueClusters);
                    end
                    obj.setCluster(obj.cid)
            end
            update(obj);
        end
    end
    
    methods (Access = private)
        function reset(obj)
            % Set embedMovie and associated MarkerMovies to the orig. size
            restrict(obj,1:size(obj.C,1));
        end
    end
    
    methods (Access = protected)
        function update(obj)
        end
    end
end