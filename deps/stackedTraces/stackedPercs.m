function f = stackedPercs(X, Y, varargin)
            %compareTraces plot aligned and imputed marker traces together
            %
            %   Syntax: Animal.compareTraces(frameIds,markerIds);
            %           compareTraces(Animal,frameIds,markerIds);
            %
            %           Animal.compareTraces(Animal,frameIds,markerIds,...
            %               interTraceSpacing,barHeight,offset,colors);
            %   Inputs: frameIds - Frames to plot
            %           markerIds - Markers to plot (3d marker dimension)
            %
            %   Optional: interTraceSpacing - distance between middle of
            %             traces
            %             barHeight - height of bars denoting bad frames
            %             colors - Nx3 matrix of rgb color values. N must
            %             equal numel(markerIds).
            numvarargs = length(varargin);
            if numvarargs > 4
                error('myfuns:somefun2Alt:TooManyInputs', ...
                    'Accepts at most 4 optional inputs');
            end
            optargs = {10,10,10,[]};
            optargs(1:numvarargs) = varargin;
            [interTraceSpacing, barHeight, offset,c] = optargs{:};
            
            % Organize the necessary data
            numTraces = size(Y,3);            
            midlines = ((numTraces-1)*interTraceSpacing):-interTraceSpacing:0;
            barEdges = midlines-round(barHeight/2);
            map = @(X,n,target) [linspace(X(1),target(1),n)',...
                linspace(X(2),target(2),n)',...
                linspace(X(3),target(3),n)'];
            nColorsInMap = 7;
            target = [1 1 1].*.7;
            if isempty(c)
                c = lines(numTraces);
            end
            
            % Allocate figure
            f = gcf; set(f,'color','w'); hold on;
            addToolbarExplorationButtons;
            for i = 1:numTraces
                % Color the background gray where there was imputation
%                 imputeBlocks = bwconncomp(BF(:,i) | any(isnan(X(:,i)),2));
%                 Pix = imputeBlocks.PixelIdxList;
%                 for j = 1:numel(Pix)
%                     pos = [Pix{j}(1)/obj.fps,...
%                         barEdges(i),...
%                         numel(Pix{j})/obj.fps,...
%                         barHeight];
%                     rectangle('Position',pos,'FaceColor',[1 1 1].*.9,...
%                         'EdgeColor','none')
%                 end
                
                % Plot the traces with an offset for the imputed and orig.
                medY = squeeze(nanmedian(nanmean(Y(:,:,i),1)));
                cmap = map(c(i,:),nColorsInMap,target);
%                 plot((1:numel(frameIds))/obj.fps,...
%                     X(:,i) - medX + midlines(i) + offset/2,...
%                     'color',cmap(1,:),'LineWidth',2)
                [hl,hp] = plotperc(X,  squeeze(Y(:,:, i) - medY + midlines(i)), 60,'alpha','transparency',.25);
%                 keyboard;
                hl.Color = cmap(1,:);
                set(hl, 'LineWidth',2)
                hp.FaceColor = cmap(1,:);
            end
            xlabel('Time (s)');
            yticks(midlines(end:-1:1))
%             labels = cell(numTraces,1);            
%             for i = 1:numTraces
%                 labels{i} = [nodes{markerIds3D(i)}...
%                     dim{mod(markerIds(i),3)+1}];
%             end
%             yticklabels(labels(end:-1:1));
            set(gca,'box','off');
            axis tight
        end