classdef VideoAnimatorTransparent < VideoAnimator
    %VideoAnimator - interactive movie
    %Subclass of Animator.
    %
    %Syntax: VideoAnimator(V)
    %
    %VideoAnimator Properties:
    %   V - 4D (i,j,channel,N) movie to animate.
    %   img - Handle to the imshow object
    %
    %
    %VideoAnimator Methods:
    %VideoAnimator - constructor
    %restrict - restrict animation to subset of frames
    %keyPressCalback - handle UI
    methods
        function obj = VideoAnimatorTransparent(V, varargin)
%             [VideoAnimatorArgs, ~, varargin] = parseClassArgs('VideoAnimator', varargin{:});
            if size(V,3) == 1
               V = repmat(V,1,1,3,1);
            end
            
            obj@VideoAnimator(V, varargin{:});
        end
    end
    methods (Access = protected)
        function update(obj)
            obj.checkVisible()
            im = obj.V(:,:,:,  obj.frameInds(obj.frame));
            im(im < 20) = 0;
            if size(obj.V,3) == 3                
                alpha = (im(:,:,1) & im(:,:,2) & im(:,:,3)) * .5;
            else
                alpha = (im(:,:,1)) * .5;
            end
            alpha(~alpha) = 0;
            set(obj.img,'CData',im,'AlphaData', alpha);

        end
    end
end