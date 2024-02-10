classdef DraggableKeypoint2DAnimator < Animator
    %DraggableKeypoint2DAnimator - Animate multicolor keypoints in 2D with
    %   draggable nodes. Concrete subclass of Animator.
    %
    %   DraggableKeypoint2DAnimator Properties:
    %   frame - current frame number
    %   frameRate - current frame rate
    %   MarkerSize - size of markers
    %   LineWidth - width of segments
    %   markers - positions of markers to plot
    %   skeleton - skeleton relating markers to one another
    %   PlotSegments - handles to linesegments
    %   points - handles to invisible draggable points.
    %
    %   DraggableKeypoint2DAnimator Methods:
    %   DraggableKeypoint2DAnimator - constructor
    %   restrict - restrict the animation to a subset of the frames
    %   getCurrentFramePositions - Get the positions of markers in the
    %       frame.
    %   createDragPointsLine - Create draggable points
    %   resetFrame - Reset frame to the original position.
    %   keyPressCallback - handle UI
    properties (Access = private)
        nMarkers % # markers
        origMarkers % Original positions of markers? SHAPE: (# frames, 2, # markers)
        color % marker color, optionally provided by skeleton in constructor
        joints % Adjacency list between markers. SHAPE: (# joints, 2)
        instructions = ['DraggableKeypoint2DAnimator Guide:\n'...
            'rightarrow: next frame\n' ...
            'leftarrow: previous frame\n' ...
            'uparrow: increase frame rate by 10\n' ...
            'downarrow: decrease frame rate by 10\n' ...
            'space: set frame rate to 1\n' ...
            'control: set frame rate to 50\n' ...
            'shift: set frame rate to 250\n' ...
            'h: help guide\n'];
        statusMsg = 'DraggableKeypoint2DAnimator:\nFrame: %d\nframeRate: %d\n'
    end
    
    properties (Access = public)
        MarkerSize = 20;
        DragPointColor = [1 1 1];
        LineWidth = 3;
        markers % x,y position of markers. SHAPE: (# frames, 2, # markers)
        % NOTE: Why are there seperate x and y position arrays? why not just pull from markers
        markersX % x positions: SHAPE (# frames, 1, # markers)
        markersY % y positions: SHAPE (# frames, 1, # markers)
        skeleton % Copy of the Label3D skeleton struct
        markerColors % optional: specifies the color for each joint
        PlotSegments % array Line objects. Each line is a colored section of the skeleton (e.g. right arm) SHAPE: (#cams x 1)
        points % single Line object which renders individal points for this camera
        selectedNode % currently selected node during click/drag. Unset when mouse is released.
        selectedNodePosition % position of selected node
        dragged % Logical array if marker has been moved by hand. SHAPE (# frames, # markers)
        % NOTE: dragged is not reset to 0 if point is re-triangulated.
        visibleDragPoints = true % toggle whether to show visible drag points (label3d sets as true)
    end
    
    methods
        function obj = DraggableKeypoint2DAnimator(markers, skeleton, varargin)
            %DraggableKeypoint2DAnimator - constructor for DraggableKeypoint2DAnimator class.
            %DraggableKeypoint2DAnimator is a concrete subclass of Animator.
            %
            %Inputs:
            %   markers: Time x nDimension x nMarkers matrix of keypoints.
            %   skeleton: Structure with two fields:
            %       skeleton.color: nSegments x 3 matrix of RGB values
            %       skeleton.joints_idx: nSegments x 2 matrix of integers
            %           denoting directed edges between markers.
            %   Syntax: DraggableKeypoint2DAnimator(markers, skeleton, varargin);
            [animatorArgs, ~, varargin] = parseClassArgs('Animator', varargin{:});
            obj@Animator(animatorArgs{:});
            
            % Check inputs
            validateattributes(markers, {'numeric'}, {'3d'})
            validateattributes(skeleton, {'struct'}, {})
            obj.markers = markers;
            obj.dragged = false(size(obj.markers, 1), size(markers, 3));
            obj.skeleton = skeleton;
            obj.color = obj.skeleton.color;
            obj.joints = obj.skeleton.joints_idx;

            if isfield(obj.skeleton, 'marker_colors')
                obj.markerColors = obj.skeleton.marker_colors;
            else
                obj.markerColors = [];
            end

            validateattributes(obj.joints, {'numeric'}, {'positive'})
            validateattributes(obj.color, {'numeric'}, {'nonnegative'})
            if max(max(obj.joints)) > size(obj.markers, 3)
                error('Invalid joints_idx: Idx exceeds number of markers');
            end
            if size(obj.color, 1) ~= size(obj.joints, 1)
                error('Number of colors and number of segments do not match');
            end
            
            % User defined inputs
            if ~isempty(varargin)
                set(obj, varargin{:});
            end
            obj.origMarkers = obj.markers;
            
            % Private constructions
            obj.nFrames = size(obj.markers, 1);
            obj.frameInds = 1 : obj.nFrames;
            obj.markersX = obj.markers(:, 1, :);
            obj.markersY = obj.markers(:, 2, :);
            obj.nMarkers = size(obj.markers, 3);
            
            % Get color groups
            [colors, ~, cIds] = unique(obj.color, 'rows');
            [~, MaxNNodes] = mode(cIds);
            
            % Get the first frames marker positions
            curX = obj.markersX(obj.frameInds(obj.frame), :);
            curY = obj.markersY(obj.frameInds(obj.frame), :);
            curX = curX(obj.joints)';
            curY = curY(obj.joints)';
            
            %%% Very fast updating procedure with low level graphics.
            % Concatenate with nans between segment ends to represent all
            % segments with the same color as one single line object
            catnanX = cat(1, curX, nan(1, size(curX, 2)));
            catnanY = cat(1, curY, nan(1, size(curY, 2)));
            
            % Put into array for vectorized graphics initialization
            nanedXVec = nan(MaxNNodes * 2, size(colors, 1));
            nanedYVec = nan(MaxNNodes * 2, size(colors, 1));
            for nColor = 1 : size(colors, 1)
                nanedXVec(1 : numel(catnanX(:, cIds == nColor)), nColor) = reshape(catnanX(:, cIds == nColor), [], 1);
                nanedYVec(1 : numel(catnanY(:, cIds == nColor)), nColor) = reshape(catnanY(:, cIds == nColor), [], 1);
            end
            obj.PlotSegments = line(obj.Axes, ...
                nanedXVec, ...
                nanedYVec, ...
                'LineStyle', '-', ...
                'Marker', '.', ...
                'MarkerSize', obj.MarkerSize, ...
                'LineWidth', obj.LineWidth, 'HitTest', 'off');
            set(obj.PlotSegments, {'color'}, mat2cell(colors, ones(size(colors, 1), 1)));
            
            % This sets up a trick to lock draggable points to multiple
            % colored lines.
            frameX = obj.markersX(obj.frameInds(obj.frame), :);
            frameY = obj.markersY(obj.frameInds(obj.frame), :);
            % obj.points = obj.createDragPointsLine(obj.Axes, frameX, frameY, ...
            %     'LineStyle', 'none', 'LineWidth', 1, ...
            %     'Marker', '.', 'MarkerSize', ...
            %     20, 'Color', obj.DragPointColor);

            if isempty(obj.markerColors)
                obj.points = obj.createDragPointsScatter(obj.Axes, frameX, frameY, ...
                    SizeData=obj.MarkerSize * 2, ...
                    MarkerFaceColor=[1, 1, 1], ...
                    MarkerEdgeColor=[1, 1, 1]);
            else
                obj.points = obj.createDragPointsScatter(obj.Axes, frameX, frameY, ...
                    CData=obj.markerColors, ...
                    SizeData=obj.MarkerSize * 2, ...
                    MarkerFaceColor='flat', ...
                    MarkerEdgeColor='flat');
            end


            ax = handle(obj.Axes);
            disableDefaultInteractivity(ax)
            ax.Interactions = [zoomInteraction regionZoomInteraction rulerPanInteraction];
        end
        
        function restrict(obj, newFrames)
            % Recompute markersX & markersY based on newFrames frameInds mapping
            obj.markersX = obj.markers(newFrames, 1, :);
            obj.markersY = obj.markers(newFrames, 2, :);
            % update frameInds to newFrames, reset nFrames, and set frame = 1
            restrict@Animator(obj, newFrames);
        end
        
        function curMarker = getCurrentFramePositions(obj)
            % Get the x,y positions of each marker in the current frame: (# markers, 2) DOUBLES MATRIX
            % Return NaN for coordinate if marker is not defined
            x = obj.points.XData;
            y = obj.points.YData;
            curMarker = [x ; y]';
        end
        
        function returnLine = createDragPointsLine(obj, ax, x, y, varargin)
            % Create invisible draggable plotting points to act as anchors
            % for multicolor lines.
            % Consider reimplementing with draggable()
            returnLine = line(ax, x, y, ...,
                'HitTest', 'on', ...
                'ButtonDownFcn', @obj.handleClickOnLine, ...
                'PickableParts', 'all', ...
                'Visible', obj.visibleDragPoints, ...
                varargin{:});
        end

        function returnScatter = createDragPointsScatter(obj, ax, x, y, varargin)
            % Create invisible draggable plotting points to act as anchors
            % for multicolor lines.
            % Consider reimplementing with draggable()
            % keyboard;

            returnScatter = scatter(ax, x, y, varargin{:}, ...
                HitTest= 'on', ...
                ButtonDownFcn=@obj.handleClickOnLine, ...
                PickableParts='all', ...
                Visible=obj.visibleDragPoints);
        end
        
        function handleClickOnLine(obj, lineObj, hitEvent)
            % Handle clicks on invisible draggable line
            obj.selectedNode = obj.getSelectedNode(lineObj);
            obj.dragged(obj.frameInds(obj.frame), obj.selectedNode) = true;
            rootFigure = ancestor(lineObj, 'figure');
            set(rootFigure, 'WindowButtonMotionFcn', @(figureObj, mouseEvent) obj.handleDrag(figureObj, mouseEvent, lineObj))
            set(rootFigure, 'WindowButtonUpFcn', @(figureObj, mouseEvent) obj.cleanupDrag(figureObj, mouseEvent))
        end
        
        % UNUSED: TODO delete?
        function deleteDataTips(obj)
            lines = obj.points;
            for nLine = 1:numel(lines)
                delete(lines(nLine).Children)
            end
        end
        
        function index = getSelectedNode(obj, src)
            % Find the index of the clicked node
            
            % Get current axes and coords
            h1 = gca;
            coords = get(h1, 'currentpoint');
            
            % Get all x and y data
            x = src.XData;
            y = src.YData;
            
            % Check which data point has the smallest distance to the dragged point
            x_diff = abs(x-coords(1, 1, 1));
            y_diff = abs(y-coords(1, 2, 1));
            [~, index] = min(sqrt(x_diff .^ 2 + y_diff .^ 2));
            obj.selectedNodePosition = [x(index), y(index)];
        end
        
        function handleDrag(obj, figureObj, mouseEvent, lineObj)
            % figueObj = object that triggered callback. In this case, always: "Label3D GUI"
            % mouesEvent = event data
            % lineObj = "Line" object that triggered the original ButtonDown callback
            
            % Create new x and y data and exchange coords for the dragged point
            h1 = gca;
            coords = get(h1, 'currentpoint');
            x_new = lineObj.XData;
            y_new = lineObj.YData;
            x_new(obj.selectedNode) = coords(1, 1, 1);
            y_new(obj.selectedNode) = coords(1, 2, 1);
            % update plot
            set(lineObj, 'xdata', x_new, 'ydata', y_new);
            obj.dragged(obj.frameInds(obj.frame), obj.selectedNode) = true;
            obj.update()
        end
        
        function cleanupDrag(obj, figureObj, mouseEvent)
            % Stop dragging mode
            set(figureObj, 'WindowButtonMotionFcn', '')
            set(figureObj, 'WindowButtonUpFcn', '')
            
            % Run the figure's windowKeyPress fcn to allow for syncing
            
            % This calls keyPressCallback on all animators with the following effects:
            %
            % DraggableKeypoint2DAnimator:  -
            % Keypoint3DAnimator:  -
            % Label3D:  checkForClickedNodes(), checkStatus(), & update()
            % VideoAnimator:  update()
            
            dummyEvent = struct();
            dummyEvent.Key = 'temp';
            figureObj.WindowKeyPressFcn([], dummyEvent)
            
            obj.selectedNode = nan;
            obj.selectedNodePosition = [];
        end
        
        function resetFrame(obj)
            % Reset the frame to the original positions of markers.
            f = obj.frameInds(obj.frame);
            obj.markers(f, :, :) = obj.origMarkers(f, :, :);
            obj.markersX = obj.markers(:, 1, :);
            obj.markersY = obj.markers(:, 2, :);
            obj.points.XData = squeeze(obj.markers(f, 1, :));
            obj.points.YData = squeeze(obj.markers(f, 2, :));
            obj.dragged(f, :) = false;
            obj.update();
        end
        
        function deleteSelectedNode(obj)
            obj.points.XData(obj.selectedNode) = nan;
            obj.points.YData(obj.selectedNode) = nan;
            obj.dragged(obj.frameInds(obj.frame), obj.selectedNode) = false;
            
            % will reset obj.selectedNode -- MUST CALL AFTER prior lines
            obj.cleanupDrag(obj.Parent, []);
            
            obj.update();
        end
        
        function keyPressCallback(obj, source, eventdata)
            % keyPressCallback - Handle UI
            % Extends Animator callback function
            
            % Extend Animator callback function
            keyPressCallback@Animator(obj, source, eventdata);
            
            % determine the key that was pressed
            keyPressed = eventdata.Key;
            switch keyPressed
                case 'h'
                    message = obj(1).instructions;
                    fprintf(message);
                case 'r'
                    reset(obj);
            end
        end
    end
    
    methods (Access = private)
        function reset(obj)
            restrict(obj, 1 : size(obj.markers, 1));
        end
    end
    
    methods (Access = protected)
        function update(obj)
            obj.checkVisible()
            % Find color groups
            [colors, ~, cIds] = unique(obj.color, 'rows');
            
            curFrameCoords = obj.getCurrentFramePositions();
            
            % Get the joints for the current frame
            curX = curFrameCoords(:, 1);
            curY = curFrameCoords(:, 2);
            
            curX = curX(obj.joints)';
            curY = curY(obj.joints)';
            
            %%% Very fast updating procedure with low level graphics.
            % Concatenate with nans between segment ends to represent all
            % segments with the same color as one single line object
            catnanX = cat(1, curX, nan(1, size(curX, 2)));
            catnanY = cat(1, curY, nan(1, size(curY, 2)));
            
            % Put into cell for vectorized graphics update
            nanedXVec = cell(size(colors, 1), 1);
            nanedYVec = cell(size(colors, 1), 1);
            for i = 1:size(colors, 1)
                nanedXVec{i} = reshape(catnanX(:, cIds == i), [], 1);
                nanedYVec{i} = reshape(catnanY(:, cIds == i), [], 1);
            end
            
            % Update the values
            valueArray = cat(2, nanedXVec, nanedYVec);
            nameArray = {'XData', 'YData'};
            segments = obj.PlotSegments;
            set(segments, nameArray, valueArray);
        end
    end
end
