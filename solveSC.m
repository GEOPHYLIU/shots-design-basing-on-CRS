function [pts, ok, segIds, res] = solveSC(Model, S, C, targetLayer, subdiv)
if nargin < 5, subdiv = 4; end
ok = false; pts = []; segIds = []; res = NaN;
nUp = targetLayer - 1;
if nUp == 0
    pts = [S; C]; ok = true; res = 0; return;
end

opts = optimset('Display','off','TolFun',1e-10,'MaxIter',80,'MaxFunEvals',400);

% ---------- A) 扫描初值 + fsolve ----------
[Pseed, okSeed] = seedDown(Model, S, C, targetLayer);
if okSeed
    segSeed = segIdsOfPoints(Model, Pseed, nUp);
    if ~isempty(segSeed)
        x0 = packX(Pseed, nUp);
        F  = @(x) eqSC(x, Model, S, C, nUp, segSeed);
        [x,~,ef] = fsolve(F, x0, opts);
        r = norm(F(x));
        if ef > 0 && isfinite(r) && r <= 1e-4
            P = unpackX(x, S, C, nUp);
            if validPath(Model, P, nUp, segSeed)
                pts = P; ok = true; segIds = segSeed; res = r; return;
            end
        end
        if validPath(Model, Pseed, nUp, segSeed)
            pts = Pseed; ok = true; segIds = segSeed; res = NaN; return;
        end
    end
end

% ---------- B) 按折线段枚举初值（兜底） ----------
cand = enumCandidates(Model, nUp);
xlo = min(S(1),C(1)) - Model.maxoff;
xhi = max(S(1),C(1)) + Model.maxoff;
keep = true(size(cand,1),1);
for i = 1:nUp
    for ic = 1:size(cand,1)
        seg = Model.seg{i}(cand(ic,i));
        if seg.p2(1) < xlo || seg.p1(1) > xhi
            keep(ic) = false;
        end
    end
end
cand = cand(keep,:);
if isempty(cand), return; end

for ic = 1:size(cand,1)
    segIdsTry = cand(ic,:);
    for sub = 1:subdiv
        x0 = makeInitSC(Model, S, C, nUp, segIdsTry, sub, subdiv);
        F  = @(x) eqSC(x, Model, S, C, nUp, segIdsTry);
        [x,~,ef] = fsolve(F, x0, opts);
        if ef <= 0, continue; end
        r = norm(F(x));
        if ~isfinite(r) || r > 1e-4, continue; end
        P = unpackX(x, S, C, nUp);
        if validPath(Model, P, nUp, segIdsTry)
            pts = P; ok = true; segIds = segIdsTry; res = r; return;
        end
    end
end
end

function segIds = segIdsOfPoints(Model, P, nUp)
segIds = zeros(1,nUp);
for i = 1:nUp
    id = 0;
    for j = 1:numel(Model.seg{i})
        s = Model.seg{i}(j);
        if P(i+1,1) >= min(s.p1(1),s.p2(1))-1e-6 && ...
           P(i+1,1) <= max(s.p1(1),s.p2(1))+1e-6
            id = j; break;
        end
    end
    if id == 0, segIds = []; return; end
    segIds(i) = id;
end
end

function x0 = packX(P, nUp)
x0 = zeros(3*nUp+1,1);
for i = 1:nUp+1
    dx = P(i+1,1)-P(i,1);
    if abs(dx) < 1e-9
        x0(i) = sign(P(i+1,2)-P(i,2))*1e6;
    else
        x0(i) = (P(i+1,2)-P(i,2))/dx;
    end
end
for i = 1:nUp
    x0(nUp+2*i)   = P(i+1,1);
    x0(nUp+2*i+1) = P(i+1,2);
end
end

function P = unpackX(x, S, C, nUp)
P = zeros(nUp+2,2);
P(1,:) = S; P(end,:) = C;
for i = 1:nUp
    P(i+1,1) = x(nUp+2*i);
    P(i+1,2) = x(nUp+2*i+1);
end
end

function cand = enumCandidates(Model, nUp)
cand = zeros(1,0);
for i = 1:nUp
    nSeg = numel(Model.seg{i});
    old  = cand;
    cand = zeros(size(old,1)*nSeg, size(old,2)+1);
    row = 0;
    for j = 1:nSeg
        for k = 1:size(old,1)
            row = row + 1;
            cand(row,:) = [old(k,:), j];
        end
    end
end
end