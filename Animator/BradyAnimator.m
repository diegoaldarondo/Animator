classdef BradyAnimator < Animator
    %BradyAnimator - interactive cluster visualization. Look at all
    %clusters at once
    %Subclass of Animator.
    %
    %Syntax: BradyAnimator(raster)
    %
    %BradyAnimator Properties:
    %    C - Nx1 cluster ids
    %
    %BradyAnimator Methods:
    %BradyAnimator - constructor
    %restrict - restrict animation to subset of frames
    %keyPressCalback - handle UI
    properties (Access = private)
        statusMsg = 'BradyAnimator:\nFrame: %d\nframeRate: %d\n';
    end
    
    properties (Access = public)
        C
        clusters
        markers
        skeleton
        cid = 1
        nTiles = 25
        win = -10:10
        bouts
        uniqueClusters
        h
        cameraPositions = {[1.9472e+03 -1.5211e+03 802.8497],...
                            [0 0 1.9053e+03],...
                            [1.2402e+03 1.2942e+03 645.8040]};
        camPosId = 1
    end
    
    methods
        function obj = BradyAnimator(C, markers, skeleton, varargin)
            [animatorArgs, ~, varargin] = parseClassArgs('Animator', varargin{:});
            obj@Animator(animatorArgs{:});
            set(obj.Axes, 'XColor','none', 'YColor','none', 'ZColor','none')
            obj.C = C;
            obj.markers = markers;
            obj.skeleton = skeleton;
            if ~isempty(varargin)
                set(obj,varargin{:});
            end
            obj.nFrames = numel(obj.win);
            obj.frameInds = 1:numel(obj.win);
            obj.frame = 1;
            obj.uniqueClusters = unique(obj.C);
            obj.bouts = obj.getBouts();
            title(obj.Axes, sprintf('Cluster: %d', obj.cid));

%             text(obj.Axes, .9, .9,  num2str(obj.cid),'Units','normalized','FontWeight','bold');
            pos = obj.getPositions(obj.nTiles);
            lim = [-110 110];
            obj.h = cell(obj.nTiles, 1);
            for nTile = 1:obj.nTiles
                if nTile > size(obj.bouts, 1)
                    set(obj.h{nTile,1}.Axes,'Visible',false)
                    continue
                end
                obj.h{nTile} = Keypoint3DAnimator(obj.markers, obj.skeleton, 'Position', pos(nTile,:));
                ax = obj.h{nTile}.Axes;
                set(ax, 'XLim',lim, 'YLim',lim, 'ZLim', lim, 'CameraPosition', obj.cameraPositions{obj.camPosId});
                daspect(ax, [1 1 1])
                set(ax, 'Color','none','XColor','none', 'YColor','none', 'ZColor','none')
                randEx = randperm(size(obj.bouts{obj.cid},1),1);
                obj.h{nTile,1}.restrict(obj.bouts{obj.cid}(randEx, :));
                set(obj.h{nTile}.Axes,'Visible',true)
            end
            Animator.linkAll({obj obj.h{:}});
        end
        
        function setCluster(obj, newCluster)
            obj.cid = newCluster;
            for nTile = 1:obj.nTiles
                if nTile > size(obj.bouts, 1)
                    set(obj.h{nTile}.Axes,'Visible',false)
                    continue
                end
                set(obj.h{nTile}.Axes,'Visible',true)
                set(obj.h{nTile}.Axes, 'CameraPosition', obj.cameraPositions{obj.camPosId});
                randEx = randperm(size(obj.bouts{obj.cid},1),1);
                obj.h{nTile,1}.restrict(obj.bouts{obj.cid}(randEx, :));
            end
            title(obj.Axes, sprintf('Cluster: %d', obj.cid));
        end
        
        function bouts = getBouts(obj)
            %GETBOUTS - Get the windows surrounding all bouts for all
            %behaviors. 
            %
            % Syntax: obj.getBouts()
            
            bouts = cell(numel(obj.uniqueClusters));
            for nClust = 1:numel(obj.uniqueClusters)
                bw = obj.C == nClust;
                bw = imdilate(bw,strel('disk',5));
                conncomp = bwconncomp(bw);
                midpoints = cellfun(@(X) X(round(end/2)), conncomp.PixelIdxList);
                bouts{nClust} = obj.win + midpoints';
                bouts{nClust}(bouts{nClust} < 1) = 1;
                bouts{nClust}(bouts{nClust} > numel(obj.C)) = numel(obj.C);
            end
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