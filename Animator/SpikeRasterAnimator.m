classdef SpikeRasterAnimator < Animator
    %SpikeRasterAnimator - interactive raster visualization.
    %Subclass of Animator.
    %
    %Syntax: SpikeRasterAnimator(raster)
    %
    %SpikeRasterAnimator Properties:
    %    spike_times - nSamples x 1 - X axis data
    %    neuron_indices - nSamples x nLines - Y axis data
    %
    %SpikeRasterAnimator Methods:
    %SpikeRasterAnimator - constructor
    %restrict - restrict animation to subset of frames
    %keyPressCalback - handle UI
    properties (Access = private)
        statusMsg = 'SpikeRasterAnimator:\nFrame: %d\nframeRate: %d\n';
        frameTimes
    end
    
    properties (Access = public)
        raster
        LineWidth = 3
        viewingWindow = -50:50
        X
        Y
        interTraceSpacing = 1
        animal
        lines
        nMarkers
        centerLine
    end
    
    methods
        function obj = SpikeRasterAnimator(spike_times, neuron_indices, nFrames, maxTime, varargin)
            [animatorArgs, ~, varargin] = parseClassArgs('Animator', varargin{:});
            obj@Animator(animatorArgs{:});
            % User defined inputs
            if ~isempty(varargin)
                set(obj,varargin{:});
            end
            
            % Handle defaults
            if isempty(obj.nFrames)
                obj.nFrames = nFrames;
            end
            obj.frameInds = 1:obj.nFrames;
            axes(obj.Axes)
            hold(obj.Axes,'on');
            obj.frameTimes = linspace(0,maxTime,nFrames);
%             neuron_indices = [neuron_indices neuron_indices+1 nan(size(neuron_indices))]';
%             spike_times = [spike_times spike_times nan(size(spike_times))]';
%             plot(spike_times(:), neuron_indices(:),'k','LineWidth',1);
            scatter(spike_times, neuron_indices,1,'k.','LineWidth',1);
            % Plot the current frame line
            obj.centerLine = line(obj.Axes,[obj.frame obj.frame],...
                get(obj.Axes,'YLim'),'color','k','LineWidth',obj.LineWidth, 'LineStyle','--');
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
            restrict(obj,1:size(obj.X,1));
        end
    end
    
    methods (Access = protected)
        function update(obj)
            obj.checkVisible()
            lims = [min(obj.frameTimes(obj.frame)+obj.viewingWindow) max(obj.frameTimes(obj.frame)+obj.viewingWindow)];
            set(obj.centerLine,'XData',obj.frameTimes([obj.frame obj.frame]),'YData', get(gca,'YLim'));
            set(obj.Axes, 'XLim', lims)
        end
    end
end