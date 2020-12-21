function hh = quiverc(X,Y,U,V,varargin)
% Modified version did not use the padded-line nan trick for lines with the
% same color. This makes it way faster.
% Diego Aldarondo 08-2019
% Modified version of Quiver to plots velocity vectors as arrows
% with components (u,v) at the points (x,y) using the current colormap
% Bertrand Dano 3-3-03
% Copyright 1984-2002 The MathWorks, Inc.
%QUIVERC Quiver color plot.
%   QUIVERC(X,Y,U,V) plots velocity vectors as arrows with components (u,v)
%   at the points (x,y).  The matrices X,Y,U,V must all be the same size
%   and contain corresponding position and velocity components (X and Y
%   can also be vectors to specify a uniform grid).  QUIVER automatically
%   scales the arrows to fit within the grid.
%
%   QUIVERC(U,V) plots velocity vectors at equally spaced points in
%   the x-y plane.
%
%   QUIVERC(U,V,S) or QUIVER(X,Y,U,V,S) automatically scales the
%   arrows to fit within the grid and then stretches them by S.  Use
%   S=0 to plot the arrows without the automatic scaling.
%
%   QUIVERC(...,LINESPEC) uses the plot linestyle specified for
%   the velocity vectors.  Any marker in LINESPEC is drawn at the base
%   instead of an arrow on the tip.  Use a marker of '.' to specify
%   no marker at all.  See PLOT for other possibilities.
%
%   QUIVERC(...,'filled') fills any markers specified.
%
%   H = QUIVERC(...) returns a vector of line handles.
%
%   Example:
%      [x,y] = meshgrid(-2:.2:2,-1:.15:1);
%      z = x .* exp(-x.^2 - y.^2); [px,py] = gradient(z,.2,.15);
%      contour(x,y,z), hold on
%      quiverc(x,y,px,py), hold off, axis image
%
%   See also FEATHER, QUIVER3, PLOT.
%   Clay M. Thompson 3-3-94
%   Copyright 1984-2002 The MathWorks, Inc.
%   $Revision: 5.21 $  $Date: 2002/06/05 20:05:16 $
%
%-------------------------------------------------------------

% Arrow head parameters
sym = '';
filled = 0;
ls = '-';
ms = '';
col = '';

% Parse optional inputs
p = inputParser;
addOptional(p, 'LineWidth', 2, @isnumeric)
addOptional(p, 'VectorSize', 1, @isnumeric)
addOptional(p, 'NormVectors', false, @isnumeric)
% Size of arrow head relative to the length of the vector
addOptional(p, 'alpha', .33, @isnumeric)
% Width of the base of the arrow head relative to the length
addOptional(p, 'beta', .3, @isnumeric)
addOptional(p, 'plotarrows', true, @isnumeric)
addOptional(p, 'autoscale', false, @isnumeric)
addOptional(p, 'cmap', @viridis, @(X) isa(X, 'function_handle'))
addOptional(p, 'nColors', 64, @isnumeric)
addOptional(p, 'density', [], @isnumeric)

parse(p, varargin{:});
lw = p.Results.LineWidth;
VectorSize = p.Results.VectorSize;
NormVectors = p.Results.NormVectors;
alpha = p.Results.alpha;
beta = p.Results.beta;
plotarrows = p.Results.plotarrows;
autoscale = p.Results.autoscale;
cmap = p.Results.cmap;
density = p.Results.density;

% Parse the string inputs
nin = numel(varargin);
if ~isempty(varargin)
    while ischar(varargin{nin})
        vv = varargin{nin};
        if ~isempty(vv) && strcmpi(vv(1),'f')
            filled = 1;
            nin = nin-1;
        else
            [l,c,m,msg] = colstyle(vv);
            if ~isempty(msg)
                error('Unknown option "%s".',vv);
            end
            if ~isempty(l), ls = l; end
            if ~isempty(c), col = c; end
            if ~isempty(m), ms = m; plotarrows = 0; end
            if isequal(m,'.'), ms = ''; end % Don't plot '.'
            nin = nin-1;
        end
    end
end

% Check numeric input arguments
[msg,x,y,u,v] = xyzchk(X,Y,U,V);
if ~isempty(msg), error(msg); end




% Scalar expand u,v
if numel(u)==1, u = u(ones(size(x))); end
if numel(v)==1, v = v(ones(size(u))); end

% if autoscale
%     % Base autoscale value on average spacing in the x and y
%     % directions.  Estimate number of points in each direction as
%     % either the size of the input arrays or the effective square
%     % spacing if x and y are vectors.
%     if min(size(x))==1, n=sqrt(numel(x)); m=n; else [m,n]=size(x); end
%     delx = diff([min(x(:)) max(x(:))])/n;
%     dely = diff([min(y(:)) max(y(:))])/m;
%     len = sqrt((u.^2 + v.^2)/(delx.^2 + dely.^2));
%     autoscale = autoscale*0.9 / max(len(:));
%     u = u*autoscale; v = v*autoscale;
% end

% Define colormap
vr=sqrt(u.^2+v.^2);
nColors = 64;

if ~isempty(density)
    vrn=round(density/max(density(:))*nColors);
else
    vrn=round(vr/max(vr(:))*nColors);
end
    

% CC=colormap(nColors);
CC = cmap(nColors);
ax = newplot;
next = lower(get(ax,'NextPlot'));
hold_state = ishold;


% Make velocity vectors and plot them

x = x(:).';y = y(:).';
u = u(:).';v = v(:).';
if NormVectors
    u = u./sqrt(u.^2 + v.^2) * VectorSize;
    v = v./sqrt(u.^2 + v.^2) * VectorSize;
else
    u = u.* VectorSize;
    v = v.* VectorSize;
end
vrn=vrn(:).';
uu = [x;x+u;NaN(size(u))];
vv = [y;y+v;NaN(size(u))];
vrn1= [vrn;NaN(size(u));NaN(size(u))];

uui=uu(:);  vvi=vv(:);  vrn1=vrn1(:); imax=size(uui);
hold on
colors = unique(vrn1(~isnan(vrn1)));
line_ids = 0:2;
h1 = gobjects(numel(colors),1);
for nColor = 1:numel(colors)
    color_id = colors(nColor);
    if color_id == 0
        continue;
    end
    ids = (find((vrn1 == color_id) & ~isnan(vrn1)) + line_ids)';
    c = CC(color_id,:);
    h1(nColor) = line(uui(ids(:)),vvi(ids(:)),'LineWidth',lw,'Color',c);
end


% Make arrow heads and plot them
if plotarrows
    hu = [x+u-alpha*(u+beta*(v+eps));x+u; ...
        x+u-alpha*(u-beta*(v+eps));NaN(size(u))];
    hv = [y+v-alpha*(v-beta*(u+eps));y+v; ...
        y+v-alpha*(v+beta*(u+eps));NaN(size(v))];
    vrn2= [vrn;NaN(size(vrn));NaN(size(vrn));NaN(size(vrn))];
    
    uui=hu(:);  vvi=hv(:);  vrn2=vrn2(:); imax=size(uui);
    line_ids = 0:3;
    h2 = gobjects(numel(colors),1);
    for nColor = 1:numel(colors)
        color_id = colors(nColor);
        if color_id == 0
            continue;
        end
        ids = (find((vrn2 == color_id) & ~isnan(vrn2)) + line_ids)';
        c = CC(color_id,:);
        h2(nColor) = line(uui(ids(:)),vvi(ids(:)),'LineWidth',lw,'Color',c);
    end
else
    h2 = [];
end

% Plot marker on base
if ~isempty(ms)
    hu = x; hv = y;
    hold on
    h3 = plot(hu(:),hv(:),[col ms]);
    if filled, set(h3,'markerfacecolor',get(h1,'color')); end
else
    h3 = [];
end

if ~hold_state, hold off, view(2); set(ax,'NextPlot',next); end

if nargout>0, hh = [h1;h2;h3]; end
