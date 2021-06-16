classdef ClusterKeypointAnimator < Animator
    %ClusterKeypointAnimator - interactive cluster visualization. Look at all
    %clusters at once
    %Subclass of Animator.
    %
    %Syntax: ClusterKeypointAnimator(raster)
    %
    %ClusterKeypointAnimator Properties:
    %    C - Nx1 cluster ids
    %
    %ClusterKeypointAnimator Methods:
    %ClusterKeypointAnimator - constructor
    %restrict - restrict animation to subset of frames
    %keyPressCalback - handle UI
    properties (Access = private)
        statusMsg = 'ClusterKeypointAnimator:\nFrame: %d\nframeRate: %d\n';
    end
    
    properties (Access = public)
        C
        clusters
        markers
        skeleton
        cid = 1
        uniqueClusters
        h
        cameraPositions = {[1.9472e+03 -1.5211e+03 802.8497],...
                            [0 0 1.9053e+03],...
                            [1.2402e+03 1.2942e+03 645.8040]};
        camPosId = 1
    end
    
    methods
        function obj = ClusterKeypointAnimator(C, clusters, markers, skeleton, varargin)
            [animatorArgs, ~, varargin] = parseClassArgs('Animator', varargin{:});
            obj@Animator(animatorArgs{:});
            set(obj.Axes,'Visible',false);
            % User defined inputs
            obj.C = C;
            obj.clusters = clusters;
            obj.markers = markers;
            obj.skeleton = skeleton;

            if ~isempty(varargin)
                set(obj,varargin{:});
            end
            obj.nFrames = numel(obj.C);
            obj.frameInds = 1:numel(obj.C);
            obj.frame = 1;
            obj.clusters
            nClusters = numel(obj.clusters);
            pos = obj.getPositions(nClusters);
            lim = [-110 110];
            obj.h = cell(nClusters,2);
            for nClust = 1:nClusters
                frames = obj.C == obj.clusters(nClust);
                obj.h{nClust, 1} = Keypoint3DAnimator(obj.markers(frames,:,:), obj.skeleton,'Position', pos(nClust,:));
                ax = obj.h{nClust, 1}.Axes;
                set(ax, 'XLim',lim, 'YLim',lim, 'ZLim', lim, 'CameraPosition', obj.cameraPositions{obj.camPosId});
                daspect(ax, [1 1 1])
                
                obj.h{nClust, 2} = ClusterAnimator(obj.C(frames), 'Axes', ax);
                Animator.linkAll( obj.h(nClust,:))
                obj.h{nClust, 2}.setCluster(obj.clusters(nClust));
                set(ax, 'XColor','none', 'YColor','none', 'ZColor','none')
            end
            Animator.linkAll({obj obj.h{:}});
        end
        
        function pos = positionFromNRows(obj, clusters, nRows)
            %POSITIONFROMNROWS - Get the axes positions of each camera view
            %given a set number of rows
            %
            %Inputs: views - number of views
            %        nRows - number of rows
            %
            %Syntax: obj.positionFromNRows(views, nRows)
            %
            %See also: GETPOSITIONS
            nClusters = numel(clusters);
            len = ceil(nClusters/nRows);
            pos = zeros(numel(clusters), 4);
            pos(:,1) = rem(clusters-1, len)/len;
            pos(:,2) = (1 - 1/nRows) - 1/nRows*(floor((clusters-1) / len));
            pos(:,3) = 1/len;
            pos(:,4) = 1/nRows;
        end
        
        function pos = getPositions(obj, nClusters)
            %GETPOSITIONS - Get the axes positions of each camera view
            %
            %
            %Inputs: nViews - number of views
            %
            %Syntax: obj.getPositions(views, nRows)
            %
            %See also: POSITIONFROMNROWS
            clusters = 1:nClusters;
            nRows = floor(sqrt(nClusters));
            if nClusters > 3
                pos = obj.positionFromNRows(clusters, nRows);
            else
                pos = obj.positionFromNRows(clusters, 1);
            end
        end
        
        function restrict(obj, newFrames)
            restrict@Animator(obj, newFrames);
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
                case 'v'
                    obj.camPosId = obj.camPosId + 1;
                    obj.camPosId = mod(obj.camPosId, numel(obj.cameraPositions));
                    if obj.camPosId == 0
                        obj.camPosId = numel(obj.cameraPositions);
                    end
                    % Reset the views
                    for nClust = 1:numel(obj.clusters)
                        set(obj.h{nClust, 1}.Axes, 'CameraPosition', obj.cameraPositions{obj.camPosId});
                    end
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