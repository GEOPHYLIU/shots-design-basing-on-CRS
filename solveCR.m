function [pts, ok, segIds] = solveCR(Model, C, R, targetLayer, subdiv, segHint)
if nargin < 5, subdiv = Model.subdiv; end
if nargin < 6, segHint = []; end
ok = false; pts = []; segIds = [];
nUp = targetLayer - 1;
if nUp == 0
    pts = [C; R]; ok = true; return;
end

if ~isempty(segHint)
    [pts, ok, segIds] = tryOneCR(Model, C, R, nUp, segHint, subdiv);
    if ok, return; end
end

cand = enumCandidates(Model, nUp);
xlo = min(C(1),R(1)) - Model.maxoff;
xhi = max(C(1),R(1)) + Model.maxoff;
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
for ic = 1:size(cand,1)
    [pts, ok, segIds] = tryOneCR(Model, C, R, nUp, cand(ic,:), subdiv);
    if ok, return; end
end
end

function [pts, ok, segIds] = tryOneCR(Model, C, R, nUp, segIdsTry, subdiv)
ok = false; pts = []; segIds = [];
opts = optimset('Display','off','TolFun',1e-8,'MaxIter',50,'MaxFunEvals',200);
for sub = 1:subdiv
    x0 = makeInitCR(Model, C, R, nUp, segIdsTry, sub, subdiv);
    F  = @(x) eqCR(x, Model, C, R, nUp, segIdsTry);
    [x,~,ef] = fsolve(F, x0, opts);
    if ef <= 0, continue; end
    P = zeros(nUp+2,2);
    P(1,:) = C; P(end,:) = R;
    for i = 1:nUp
        P(i+1,1) = x(nUp + 2*i);        % 修正
        P(i+1,2) = x(nUp + 2*i + 1);    % 修正
    end
    if validPath(Model, P, nUp, segIdsTry)
        pts = P; ok = true; segIds = segIdsTry; return;
    end
end
end

function cand = enumCandidates(Model, nUp)
nSeg = arrayfun(@(i) numel(Model.seg{i}), 1:nUp);
cand = 1;
for i = 1:nUp
    old = cand;
    cand = zeros(size(old,1)*nSeg(i), size(old,2)+1);
    row = 0;
    for j = 1:nSeg(i)
        for k = 1:size(old,1)
            row = row + 1;
            cand(row,:) = [old(k,:), j];
        end
    end
end
end