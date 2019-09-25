classdef QuiverAnimator < Animator
    %QuiverAnimator - Interactive animation of points moving through a 
    %vector field
    %Subclass of Animator.
    %
    %Syntax: QuiverAnimator('embed',embed)
    %
    %QuiverAnimator Properties:
    %   embed - embedded points (replicated so size matches nFrames)
    %   embedFrames - corresponding movie Frames, in case there is a
    %                 mismatch in frames between other Animators.
    %   scatterFig - handle to the background scatter plot
    %   currentPoint - handle to the current point
    %   animal - handle to the calling Animal object to sync with
    %            MarkerMovies. Currently deprecated.
    %   poly - polygon defined in user input. 
    %   AxesPosition - position within current figure
    %   step - stepsize between grid points in calculating vector field
    %          (smaller stepsize takes longer and renders more lines)
    %   vectorSize - size of unit vectors
    %   normVectors - 1 or 0, if 1 normalize vectors to unit length,
    %                 otherwise use speed as the magnitude of the vector.
    %   cmap - colormap to use for vectorfield.
    %   embedX - X dimension of embedding
    %   embedY - Y dimension of embedding
    %   quiver - Handle to quiverc object
    %   orderPoints - Order points by dimension
    %
    %QuiverAnimator Methods:
    %QuiverAnimator - constructor
    %restrict - restrict animation to subset of frames
    %keyPressCalback - handle UI
    properties (Access = private)
        instructions = ['QuiverAnimator Guide:\n' ...
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
        behaviorWindow = 0:0;
    end
    
    properties (Access = public)
        embed
        poly
        step=.75;
        vectorSize = 1;
        normVectors = 1;
        cmap = @magma;
        embedX
        embedY
        embedFrames
        quiver
        currentPoint
        animal
        AxesPosition = [0 0 1 1];
    end
    
    methods
        function obj = QuiverAnimator(varargin)
            
            % User defined inputs
            if ~isempty(varargin)
                set(obj,varargin{:});
            end
            
            % Handle defaults
            if isempty(obj.embedFrames)
                obj.embedFrames = (1:size(obj.embed,1))';
            end
            if isempty(obj.nFrames)
                obj.nFrames = size(obj.embed,1);
            end
            
            % Get a vector, frameInds, of length nFrames where frameInds(i)
            % is the value in embedFrames closest to i.
            [obj.frameInds, I] = deal(zeros(obj.nFrames,1));
            count = 1;
            for i = 1:numel(obj.frameInds)
                if i <= obj.embedFrames(count)
                    obj.frameInds(i) = obj.embedFrames(count);
                else
                    if count < numel(obj.embedFrames)
                        count = count + 1;
                    end
                    obj.frameInds(i) = obj.embedFrames(count);
                end
                I(i) = count;
            end
            
            % Create the backgound quiver
            set(obj.Parent,'CurrentAxes',obj.Axes)
            X = smoothdata(obj.embed(:,1),'gaussian',5);
            Y = smoothdata(obj.embed(:,2),'gaussian',5);
            [gX, gY, gdX, gdY] = ...
                quiverVars(X,Y,'step',obj.step,'densityThresh',3,'ubound',100,'lbound',0);
            obj.quiver = quiverc(gX,gY,gdX,gdY,'NormVectors',obj.normVectors,'VectorSize',obj.vectorSize,'cmap',obj.cmap);
            xlim(obj.Axes,[min(obj.embed(:,1)) max(obj.embed(:,1))])
            ylim(obj.Axes,[min(obj.embed(:,2)) max(obj.embed(:,2))])
            % Expand to fit the number of actual frames. This makes
            % indexing a whole lot easier later.
            obj.embedX = obj.embed(I,1);
            obj.embedY = obj.embed(I,2);
            obj.embed = obj.embed(I,:);
            obj.embedFrames = obj.embedFrames(I);
            
            % Plot the current point
            obj.currentPoint = scatter(obj.Axes,obj.embedX(1),...
                obj.embedY(1), 500,'w.');
            set(obj.Axes,'Units','normalized',...
                'Position',obj.AxesPosition);
        end
        
        function restrict(obj, newFrames)
            obj.embedX = obj.embed(newFrames,1);
            obj.embedY = obj.embed(newFrames,2);
            restrict@Animator(obj, newFrames);
            obj.frameInds = obj.embedFrames(newFrames);
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
                    disp('callback')
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
                case 'b'
                    if obj.scope == obj.id
                        obj.animal.bradyMovie(repmat({'imputed'},16,1),[4 4]);
                        % obj.animal.bradyMovie(repmat({'imputed'},16,1),[4 4],true);
                        % obj.animal.bradyMovie(repmat({'imputed'},9,1),[3 3]);
                    end
                    pause(1)
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
                obj.pointsInPoly = inpolygon(obj.embed(:,1),...
                    obj.embed(:,2),xv,yv);
                
                % Find a window surrounding the frames within the polygon.
                framesInPoly = obj.embedFrames(obj.pointsInPoly);
                framesInPoly = unique(framesInPoly);
                framesInPoly = framesInPoly + obj.behaviorWindow;
                framesInPoly = unique(sort(framesInPoly(:)));
                framesInPoly = framesInPoly((framesInPoly > 0) &...
                    (framesInPoly <= numel(obj.embedFrames)));
                
                if ~isempty(obj.links)
                    for i = 1:numel(obj.links)
                        % if isa(obj.animal.h{i},'MarkerAnimator')
                        restrict(obj.links{i},framesInPoly)
                    end
                else
                    restrict(obj,framesInPoly);
                end
                
            end
        end
        
    end
    
    methods (Access = private)
        
        function reset(obj)
            if ~isempty(obj.poly)
                delete(obj.poly)
                obj.poly = [];
            end
            
            % Set embedMovie and associated MarkerMovies to the orig. size
            restrict(obj,true(size(obj.embed,1),1));
            if ~isempty(obj.animal)
                for i = 1:numel(obj.animal.h)
                    if isa(obj.animal.h{i},'MarkerAnimator')
                        restrict(obj.animal.h{i},...
                            1:size(obj.animal.h{i}.markers,1))
                    end
                end
            end
        end
        
        
        function orderPoints(obj, dim)
            if dim == 1
                [~,I] = sort(obj.embedX);
            elseif dim == 2
                [~,I] = sort(obj.embedY);
            else
                error('dim must be 1 or 2')
            end
            
            reorderedFrames = obj.frameInds(I);
            % Restrict associated Animations to those frames
            if ~isempty(obj.links)
                for i = 1:numel(obj.links)
                    % if isa(obj.animal.h{i},'MarkerAnimator')
                    restrict(obj.links{i},reorderedFrames)
                end
            else
                restrict(obj,reorderedFrames);
            end
            
        end
        
    end
    
    methods (Access = protected)
        function update(obj)
            set(obj.currentPoint,'XData',obj.embedX(obj.frame),...
                'YData',obj.embedY(obj.frame));
        end
        
        
    end
end