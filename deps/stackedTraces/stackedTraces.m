function [f, lines] = stackedTraces(X, Y, varargin)
            %stackedTraces plot aligned and imputed marker traces together
            %
            %   Syntax: stackedTraces(X,Y);
            %           stackedTraces(X,Y);
            %
            %           stackedTraces(X,Y,interTraceSpacing);
            %   Inputs: X - t x 1 - X Axis
            %           Y - t x nTraces - Traces to plot 
            %
            %   Optional: interTraceSpacing - distance between middle of
            %             traces
            %   Outputs: f - figure handle
            %            lines - Line array of plotted lines
            numvarargs = length(varargin);
            if numvarargs > 1
                error('myfuns:somefun2Alt:TooManyInputs', ...
                    'Accepts at most 1 optional inputs');
            end
            optargs = {10};
            optargs(1:numvarargs) = varargin;
            [interTraceSpacing] = optargs{:};
            
            % Organize the necessary data
            numTraces = size(Y,2);            
            midlines = ((numTraces-1)*interTraceSpacing):-interTraceSpacing:0;
            % Allocate figure
            f = gcf;
            hold on;
            lines = gobjects(numTraces,1);
            for i = 1:numTraces
                % Plot the traces with an offset for the imputed and orig.
                medY = nanmedian(Y(:,i));
                lines(i) = plot(X, Y(:, i) - medY + midlines(i));
            end
        end