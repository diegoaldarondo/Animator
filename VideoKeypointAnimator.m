classdef VideoKeypointAnimator < VideoAnimator
    
    properties (Access=public)
        keypoints
        keypointsScatter
    end
    
    methods
        function obj = VideoKeypointAnimator(V, keypoints, varargin)
            %Initialize VideoKeypointAnimator
            obj = obj@VideoAnimator(V);
            % Set the video
            if ~isempty(V)
                obj.V = V;
                if numel(size(obj.V)) == 3
                    obj.V = reshape(obj.V,size(obj.V,1),size(obj.V,2),1,size(obj.V,3));
                end
            end
            
            % Set the keypoints
            obj.keypoints = keypoints;
            
            % Set all other parameters
            if ~isempty(varargin)
                set(obj,varargin{:});
            end
            
            % Set up the scatter plot ontop of the video
            hold on;
            obj.keypointsScatter = ...
                scatter(gca, obj.keypoints(1,1,:),...
                        obj.keypoints(1,2,:),'g');
        end  
    end
    
    methods (Access = protected)
        function update(obj)
            update@VideoAnimator()
            set(obj.img,'CData',obj.V(:,:,obj.frame));
            if ~isempty(obj.markers)
               set(obj.scatterFig,'XData',obj.keypoints(:,1,obj.frame),'YData',obj.keypoints(:,2,obj.frame)) 
            end
        end
    end
end