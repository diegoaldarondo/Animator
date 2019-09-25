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
        animal
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
            if ~isempty(obj.markers)
                if ~isempty(obj.skeleton)
                    % Private constructions
                    obj.nFrames = size(obj.markers,3);
                    obj.frameInds = 1:obj.nFrames;
                    obj.nMarkers = size(obj.markers,1)*size(obj.markers,2);
                    obj.color = obj.skeleton.segments.color;
                    obj.joints = cat(1,obj.skeleton.segments.joints_idx{:});
                    
                    % get color groups
                    c = cell2mat(obj.color);
                    [colors,~,cIds] = unique(c,'rows');
                    [~, MaxNNodes] = mode(cIds);
                    
                    % Get the first frames marker positions
                    curX = squeeze(obj.markers(:,1,obj.frame)');
                    curY = squeeze(obj.markers(:,2,obj.frame)');
                    curX = curX(obj.joints)';
                    curY = curY(obj.joints)';
                    
                    catnanX = cat(1,curX,nan(1,size(curX,2)));
                    catnanY = cat(1,curY,nan(1,size(curY,2)));
                    
                    nanedXVec = nan(MaxNNodes*3,size(colors,1));
                    nanedYVec = nan(MaxNNodes*3,size(colors,1));
                    for i = 1:size(colors,1)
                        nanedXVec(1:numel(catnanX(:,cIds==i)),i) = reshape(catnanX(:,cIds==i),[],1);
                        nanedYVec(1:numel(catnanY(:,cIds==i)),i) = reshape(catnanY(:,cIds==i),[],1);
                    end
                    
                    hold on;
                    obj.PlotSegments = line(obj.Axes,...
                        nanedXVec,...
                        nanedYVec,...
                        'LineStyle','-',...
                        'Marker','.',...
                        'MarkerSize',obj.MarkerSize,...
                        'LineWidth',obj.LineWidth);
                    set(obj.PlotSegments, {'color'}, mat2cell(colors,ones(size(colors,1),1)));
                else
                    hold on;
                    obj.scatterFig = scatter(gca, obj.markers(:,1,obj.frame), obj.markers(:,2,obj.frame),200,'r.');
                end
            end
            %             axis(obj.Axes,'off')
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
            if ~isempty(obj.markers)
                if ~isempty(obj.skeleton)
                    % Find color groups
                    c = cell2mat(obj.color);
                    [colors,~,cIds] = unique(c,'rows');
                    
                    % Get the first frames marker positions
                    curX = squeeze(obj.markers(:,1,obj.frame)');
                    curY = squeeze(obj.markers(:,2,obj.frame)');
                    curX = curX(obj.joints)';
                    curY = curY(obj.joints)';
                    
                    catnanX = cat(1,curX,nan(1,size(curX,2)));
                    catnanY = cat(1,curY,nan(1,size(curY,2)));
                    
                    % Put into cell for vectorized graphics update
                    nanedXVec = cell(size(colors,1),1);
                    nanedYVec = cell(size(colors,1),1);
                    for i = 1:size(colors,1)
                        nanedXVec{i} = reshape(catnanX(:,cIds==i),[],1);
                        nanedYVec{i} = reshape(catnanY(:,cIds==i),[],1);
                    end
                  
                    valueArray = cat(2, nanedXVec, nanedYVec);
                    nameArray = {'XData','YData'};
                    set(obj.PlotSegments,nameArray,valueArray)
                    
                else
                    set(obj.scatterFig,'XData',obj.markers(:,1,obj.frame),'YData',obj.markers(:,2,obj.frame))
                end
            end
        end
    end
end