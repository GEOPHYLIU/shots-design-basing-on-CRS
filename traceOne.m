function [full, Rex, ok] = traceOne(Model, Start, C, targetLayer)
ok = false; full = []; Rex = [];
segC = segOfLayerAt(Model, targetLayer, C(1));
if isempty(segC), return; end

[Pdown, okSC] = solveSC(Model, Start, C, targetLayer);
if ~okSC, return; end

n = segC.nrm;
u = C - Pdown(end-1,:);  u = u/norm(u);
w = u - 2*dot(u,n)*n;
if w(2) <= 1e-9, return; end

[Pup, Rex, okUp] = traceUp(Model, C, w, targetLayer);
if ~okUp, return; end

full = [Pdown; Pup(2:end,:)];
ok = true;
end

function seg = segOfLayerAt(Model, targetLayer, xq)
seg = [];
if targetLayer < 1 || targetLayer > numel(Model.seg), return; end
for j = 1:numel(Model.seg{targetLayer})
    s = Model.seg{targetLayer}(j);
    if xq >= min(s.p1(1),s.p2(1))-1e-9 && xq <= max(s.p1(1),s.p2(1))+1e-9
        seg = s; return;
    end
end
end