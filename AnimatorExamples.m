%% Get example video (requires image processing toolbox)
clear all;
close all;
clc;
folder = fileparts(which('cameraman.tif'));
video_path = fullfile(folder, 'rhinos.avi');
reader = VideoReader(video_path);
V = cell(1);
count = 1;
while hasFrame(reader)
    V{count} = readFrame(reader);
    count = count + 1;
end
V = cat(4, V{:});

%% Test out VideoAnimator
fVid = figure('Name','VideoAnimator Test');

% Press 'h' for help messages
VideoAnimator(V)

%% Test out a keypoint animator
close all
fKp2d = figure('Name','KeypointAnimator Test');

% Make random data to plot.
nMarkers = 10;
markers = rand(size(V,4),2,nMarkers)*size(V,1)*.5;

% Create a random skeleton connecting these markers.
skeleton = struct();
skeleton.color = repelem(lines(nMarkers/2),2,1);
skeleton.joints_idx = randi(nMarkers,nMarkers,2);

% Plot the keypoints
Keypoint2DAnimator(markers, skeleton)

%% Try them together
close all
fVidKp2d = figure('Name','Combination Test');

% Keep animators together in a cell
h = cell(2,1);
h{1} = VideoAnimator(V);
h{2} = Keypoint2DAnimator(markers, skeleton,...
                          'xlim',[0 size(V,2)],'ylim',[0 size(V,1)]);
axis off;

% Link all animators in the cell array.
Animator.linkAll(h)

pos = [200 200 size(V,2)*2 size(V,1)*2];
set(fVidKp2d,'pos',pos);

%% Test out a 3d keypoint animator
close all
fKp3d = figure('Name','KeypointAnimator Test');

% Make random data to plot.
nMarkers = 10;
markers = rand(size(V,4),3,nMarkers)*size(V,1)*.5;

% Plot the keypoints
Keypoint3DAnimator(markers, skeleton)

%% Overlay several Animators in the same figure
close all
fMulti = figure('Name','Combination Test 2');
h = cell(4,1);
h{1} = VideoAnimator(V, 'AxesPosition', [0 0 .25 .25]);
h{2} = VideoAnimator(V, 'AxesPosition', [.25 .25 .25 .25]);
h{3} = VideoAnimator(V, 'AxesPosition', [.5 .5 .25 .25]);
h{4} = Keypoint2DAnimator(markers, skeleton,...
                          'xlim', [0 size(V,2)],...
                          'ylim', [0 size(V,1)],...
                          'AxesPosition', [.75 .75 .25 .25]);
axis off;
Animator.linkAll(h)
set(fMulti,'pos',pos);


%% You can use many Animators at the same time.  
% The biggest limit on the number of Animators that can be used at once is
% the number of different graphics objects on the figure. Plotting too many
% lines is often the main source of slowdown. 
close all
fStress = figure('Name','Stress Test');
nCopies = 5;
h = cell(nCopies^2,1);
for nCopyX = 1:nCopies
   for nCopyY = 1:nCopies
       startPosX = (nCopyX-1)*(1/nCopies);
       startPosY = (nCopyY-1)*(1/nCopies);
       h{(nCopyX-1)*nCopies + nCopyY} = ...
           VideoAnimator(V,...
            'AxesPosition',[startPosX startPosY (1/nCopies) (1/nCopies)]);
   end
end
Animator.linkAll(h)
set(fStress,'pos',pos);

%% Show how indicators work.
close all
fIndic = figure('Name','Indicator Test');
logic = rand(size(V,4),1) > .5;
h = cell(3,1);
h{1} = VideoAnimator(V);
h{2} = IndicatorAnimator(logic,'AxesPosition',[0 0 .25 .25]);
h{3} = IndicatorAnimator(logic,'AxesPosition',[.25 0 .25 .25],'Color','g');
h{4} = IndicatorAnimator(logic,'AxesPosition',[.4 .1 .5 .25],'Color','b');
Animator.linkAll(h)
set(fIndic,'pos',pos);

%% Show how raster animators work
close all
fRaster = figure('Name','Raster Test');
logic = rand(size(V,4),1) > .5;
h = cell(3,1);
h{1} = VideoAnimator(V);
h{2} = IndicatorAnimator(logic,'AxesPosition',[0 .25 .25 .25]);
h{3} = RasterAnimator(logic,'AxesPosition',[0 0 1 .25]);
Animator.linkAll(h)
set(fRaster,'pos',pos);

%% Show how scatter animators work
close all
fScatter = figure('Name','Scatter Test');
t = linspace(0, 2*pi, size(V,4));
X = cos(t) + rand(size(t))*.2;
Y = sin(t) + rand(size(t))*.2;
EmbeddingAnimator('embed',[X; Y]')

%% Link a scatter animator with a video animator
close all
fScatterVid = figure('Name','Scatter and Video Test');
h = cell(3,1);
h{1} = VideoAnimator(V, 'AxesPosition', [0 0 (1/3) 1]);

% The 'id' property enables the use of special UI for specific Animators.
% In the case of ScatterAnimators, it allows for interactive selection of
% regions of the scatter plot. This is done by first putting the Animator 
% in the scope of the figure by pressing the number key corresponding to 
% the Animator's id, then pressing 'i' (for input). 
% Scope can be set programatically with Animator.scope = id;
h{2} = EmbeddingAnimator('embed',[X; Y]','AxesPosition', [(1/3) 0 (1/3) 1], 'id', 1);
h{3} = EmbeddingAnimator('embed',[Y; X]','AxesPosition', [(2/3) 0 (1/3) 1], 'id', 2);
Animator.linkAll(h)

% Access the axes using the Animator.getAxes method as below:
cellfun(@(X) set(X.getAxes, 'color', 'k', 'XTick', [], 'YTick', []), h)


% Access the figure handle using the Animator.Parent property.
% They share the same Parent. 
assert(isequal(h{1}.Parent, h{2}.Parent, h{3}.Parent));
set(h{1}.Parent,'pos',pos,'color',[.5 .5 .5])


% Try pressing '1' to set the scope then 'i' to select a region of the
% scatter animator. You'll see that once you make your selection, the video
% and the scatter animator frames are restricted to that region.
% You can reset the Animators at any time by pressing 'r'. 

%% Show how quiver animators work
% QuiverAnimators are very similart to ScatterAnimators, except they show a
% flow field representation of the scattered data.
close all
fQuiver = figure('Name','Quiver Test');
t = linspace(0, 50*pi, 10000);
X = cos(t) + rand(size(t))*.1;
Y = sin(t) + rand(size(t))*.1;

h = cell(1);
h{1} = QuiverAnimator('embed',[X; Y]','step',.05,'vectorSize',.1,'densityThresh',1);
set(h{1}.getAxes,'color','k')

%% Show how heatmap animators work
nDims = 50;
heatmap = repelem(X', 1, nDims) .* rand(1,nDims);
h = cell(1);
h{1} = HeatMapAnimator(heatmap);
set(h{1}.getAxes, 'XTick',[])
% Press 'z' to toggle between zscored and non-zscored data. 
