classdef Scatter3Animator < Animator
    %Scatter3Animator - Animator for scatter plots.
    %
    %Syntax: Scatter3Animator('embed',embed)
    %
    %Scatter3Animator Properties:
    %    data - points (ntimepoints x 2);
    %    scatterFig - handle to the background scatter plot
    %    currentPoint - handle to the current point
    %    poly - polygon defined in user input. 
    %    
    %    
    %
    % Scatter3Animator Methods:
    % Scatter3Animator - constructor
    % restrict - restrict animation to subset of frames
    % keyPressCalback - handle UI
    % inputPoly - UI polygon selection of points in scatterplot to restrict
    %             to that subset.
    % orderPoints - Order points by dimension
    %
    % Useful tips: For help message type 'h'.
    %              At any time type 'x' or 'y' to sort frames in the x or y
    %              dimension. This also works for restricted frames. 
    properties (Access = private)
        instructions = ['Scatter3Animator Guide:\n' ...
            'rightarrow: next frame\n' ...
            'leftarrow: previous frame\n' ...
            'uparrow: increase frame rate by 10\n' ...
            'downarrow: decrease frame rate by 10\n' ...
            'space: set frame rate to 1\n' ...
            'control: set frame rate to 50\n' ...
            'shift: set frame rate to 250\n' ...
            'h: help guide\n' ...
            'i: input polygon\n' ...
            'r: reset\n' ...
            's: print current matched frame and rate\n'];
        statusMsg = 'EmbedMovie:\nFrame: %d\nframeRate: %d\n';
        pointsInPoly
        dataX
        dataY
        dataZ
        t
        isTurning = false
        lineTail
        inFlow = false
    end
    
    properties (Access = public)
        behaviorWindow = 0:0;
        data
        poly
        scatterFig
        currentPoint
        az
        el
        turnRate = 1
        tailLength = 5;
        cmap = @magma
    end
    
    methods
        function obj = Scatter3Animator(data, varargin)
            [animatorArgs, ~, varargin] = parseClassArgs('Animator', varargin{:});
            obj@Animator(animatorArgs{:});
            if ~isempty(data)
                obj.data = data;
            end
            
            % User defined inputs
            if ~isempty(varargin)
                set(obj,varargin{:});
            end
            
            % Handle defaults
            if isempty(obj.nFrames)
                obj.nFrames = size(obj.data,1);
            end
            obj.frameInds = 1:obj.nFrames;
            
            % Create the backgound scatter
            c = lines(2);
            obj.scatterFig = scatter3(obj.Axes,obj.data(:,1),...
                obj.data(:,2),obj.data(:,3),2,c(1,:),'.');
            
            % Expand to fit the number of actual frames. This makes
            % indexing a whole lot easier later.
            obj.dataX = obj.data(:,1);
            obj.dataY = obj.data(:,2);
            obj.dataZ = obj.data(:,3);
            
            
            % Plot the current point
            tailMap = magma(obj.tailLength);
            widths = linspace(2.5, 4, obj.tailLength);
            obj.currentPoint = scatter3(obj.Axes,obj.dataX(1),...
                obj.dataY(1),obj.dataZ(1), 500,c(2,:),'.');
            prevFrames = mod((obj.frame - obj.tailLength):obj.frame, numel(obj.frameInds));
            prevFrames(prevFrames == 0) = obj.nFrames;
            prevFrames = obj.frameInds(prevFrames);            
            obj.lineTail = gobjects(obj.tailLength,1);
            for nTail = 1:obj.tailLength
                tailFrames = prevFrames(nTail:nTail+1);
                obj.lineTail(nTail) = plot3(obj.Axes,obj.dataX(tailFrames),...
                obj.dataY(tailFrames),obj.dataZ(tailFrames),'color',tailMap(nTail,:),'LineWidth',widths(nTail));
            end

            set(obj.getAxes(), 'XGrid','on','YGrid','on','ZGrid','on') 
            [obj.az, obj.el] = view(obj.getAxes());
        end
        
        function turn(obj)
            [obj.az, obj.el] = view(obj.getAxes());
            view(obj.getAxes(), obj.az + obj.turnRate, obj.el)
        end
        
        function turnOn(obj)
            obj.t = timer;
            obj.t.Period = .05;
            obj.t.TasksToExecute = inf;
            obj.t.ExecutionMode = 'fixedRate';
            obj.t.TimerFcn = @(src, event) obj.turn();
            start(obj.t)
        end
        
        function turnOff(obj)
            stop(obj.t)
            delete(obj.t)
        end
        
        function keyPressCallback(obj,source,eventdata)
            % determine the key that was pressed
            keyPressCallback@Animator(obj,source,eventdata);
            keyPressed = eventdata.Key;
            switch keyPressed
                case 'h'
                    fprintf(obj.instructions);
                case 's'
                    fprintf(obj.statusMsg,...
                        obj.frameInds(obj.frame),obj.frameRate);
                    fprintf('counter: %d\n', obj.frame)
                case 'i'
                    inputPoly(obj);
                case 'y'
                    if obj.scope == obj.id
                        orderPoints(obj,2);
                    end
                case 'x'
                    if obj.scope == obj.id
                        orderPoints(obj,1);
                    end
                case 'r'
                    reset(obj);
                case 'f'
                    flow(obj);
                case 'c'
                    colorize(obj);
                case 'l'
                    if ~obj.isTurning
                        turnOn(obj);
                        obj.isTurning = true;
                    else 
                        turnOff(obj);
                        obj.isTurning = false;
                    end
            end
            update(obj);
        end
        
        function inputPoly(obj)
            if obj.scope == obj.id
                % Draw a poly and find the points within.
                if isempty(obj.poly)
                    obj.poly = drawpolygon(obj.Axes,'Color','w');
                else
                    obj.poly = drawpolygon(obj.Axes,'Color','w','Position',obj.poly.Position);
                end
                xv = obj.poly.Position(:,1);
                yv = obj.poly.Position(:,2);
                obj.pointsInPoly = inpolygon(obj.data(:,1),...
                    obj.data(:,2),xv,yv);
                
                % Find a window surrounding the frames within the polygon.
                framesInPoly = obj.frameInds(obj.pointsInPoly);
                framesInPoly = unique(framesInPoly);
                framesInPoly = framesInPoly + obj.behaviorWindow;
                framesInPoly = unique(sort(framesInPoly(:)));
                framesInPoly = framesInPoly((framesInPoly > 0) &...
                    (framesInPoly <= numel(obj.frameInds)));
                
                if ~isempty(obj.links)
                    for i = 1:numel(obj.links)
                        restrict(obj.links{i},framesInPoly)
                    end
                else
                    restrict(obj,framesInPoly);
                end
            end
        end
    end
    
    methods (Access = private)
        function flow(obj)
            framesToTrack = obj.frameInds;
            restrict(obj, 1:size(obj.data,1))
            obj.frame = framesToTrack;
            arrayfun(@(X) set(X,'Visible','off'), obj.lineTail)
            set(obj.currentPoint, 'SizeData',200)
            colors = lines(2);
            c = repmat(colors(1,:),obj.nFrames,1);
            c(obj.frame, :) = repmat(colors(2,:), numel(obj.frame),1);
            set(obj.scatterFig, 'CData', c)
            obj.inFlow = true;
        end
        
        function scatterColorize(obj)
            colors = lines(1);
            c = repmat(colors(1,:),obj.nFrames,1);
            c(obj.frame, :) = obj.cmap(size(obj.currentPoint.XData, 2));
            set(obj.scatterFig, 'CData', c)
        end
        
        function colorize(obj)
            c = obj.cmap(size(obj.currentPoint.XData, 2));
            set(obj.currentPoint, 'CData', c)
        end
        
        function reset(obj)
            if ~isempty(obj.poly)
                delete(obj.poly)
                obj.poly = [];
            end
            
            % Set embedMovie and associated MarkerMovies to the orig. size
            restrict(obj,1:size(obj.data,1));
            
            % Make sure the current point only has one color.
            c = lines(2);
            set(obj.currentPoint, 'CData', c(2,:))
            arrayfun(@(X) set(X,'Visible','on'), obj.lineTail)
            set(obj.currentPoint, 'SizeData', 500)
            obj.inFlow = false;
        end
        
        function orderPoints(obj, dim)
            if dim == 1
                [~,I] = sort(obj.dataX(obj.frameInds));
            elseif dim == 2
                [~,I] = sort(obj.dataY(obj.frameInds));
            else
                error('dim must be 1 or 2')
            end         
            reorderedFrames = obj.frameInds(I);
            % Restrict associated Animations to those frames
            if ~isempty(obj.links)
                for i = 1:numel(obj.links)
                    restrict(obj.links{i},reorderedFrames)
                end
            else
                restrict(obj,reorderedFrames);
            end    
        end     
    end
    
    methods (Access = protected)
        function update(obj)
            obj.checkVisible
            set(obj.currentPoint,...
                'XData',obj.dataX(obj.frameInds(obj.frame)),...
                'YData',obj.dataY(obj.frameInds(obj.frame)),...
                'ZData',obj.dataZ(obj.frameInds(obj.frame)));
            
            prevFrames = mod((obj.frame - obj.tailLength):obj.frame, numel(obj.frameInds));
            prevFrames(prevFrames == 0) = obj.nFrames;
            prevFrames = obj.frameInds(prevFrames);            
            for nTrail = 1:obj.tailLength
                tailFrames = prevFrames(nTrail:nTrail+1);
                set(obj.lineTail(nTrail), 'XData', obj.dataX(tailFrames),...
                                           'YData', obj.dataY(tailFrames),...
                                           'ZData', obj.dataZ(tailFrames));
            end
            if obj.inFlow
                obj.scatterColorize()
            end
        end
    end
end