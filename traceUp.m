function [pts, Rex, ok, dbg] = traceUp(Model, C, w, targetLayer)
ok = false; pts = []; Rex = [];
m = targetLayer - 1;
dbg = struct('stage','init','Q',[],'segIds',[],'dout',[],'Rx0',[],'Pmarch',[]);
if m == 0
    if w(2) <= 1e-9, return; end
    tS = (Model.surfY - C(2))/w(2);
    Rex = [C(1) + tS*w(1), Model.surfY];
    pts = [C; Rex]; ok = true; dbg.stage = 'direct'; return;
end

p = C(:); d = w(:)/norm(w);
Q = zeros(m,2); segIds = zeros(1,m);
good = true;
for j = 1:m
    ifn = targetLayer - j;
    [q, d, g] = marchRefract(Model, p, d, Model.layersMat{ifn}, ...
                             Model.v(ifn+1), Model.v(ifn), Model.seg{ifn});
    if ~g, good = false; break; end
    Q(j,:) = q';
    segIds(j) = segIndexAt(Model, ifn, q(1));
    p = q;
end
if ~good, dbg.stage = 'march'; return; end
if d(2) <= 1e-9, dbg.stage = 'sinking'; return; end
tS  = (Model.surfY - p(2))/d(2);
Rx0 = p(1) + tS*d(1);

Pmarch = [C; Q; [Rx0, Model.surfY]];
dbg = struct('stage','march','Q',Q,'segIds',segIds,'dout',d,'Rx0',Rx0,'Pmarch',Pmarch);
if checkUp(Model, Pmarch, C, segIds, m, targetLayer)
    pts = Pmarch; Rex = Pmarch(end,:); ok = true; return;
end

x0 = zeros(2*m+1,1);
for j = 1:m
    x0(2*j-1) = Q(j,1); x0(2*j) = Q(j,2);
end
x0(end) = Rx0;
opts = optimset('Display','off','TolFun',1e-11,'MaxIter',80,'MaxFunEvals',500);
F = @(x) eqUp(x, Model, C, w, targetLayer, segIds, m);
[x,~,ef] = fsolve(F, x0, opts);
if ef <= 0, dbg.stage = 'fsolve'; return; end
if norm(F(x)) > 1e-4, dbg.stage = 'fsolve_res'; return; end

P = zeros(m+2,2);
P(1,:) = C;
for j = 1:m
    P(j+1,1) = x(2*j-1); P(j+1,2) = x(2*j);
end
P(end,:) = [x(end), Model.surfY];
if ~checkUp(Model, P, C, segIds, m, targetLayer)
    dbg.stage = 'checkUp'; return;
end

pts = P; Rex = P(end,:); ok = true; dbg.stage = 'ok';
end

function ok = checkUp(Model, P, C, segIds, m, targetLayer)
ok = false;
for j = 1:m
    ifn = targetLayer - j;
    seg = Model.seg{ifn}(segIds(j));
    if P(j+1,1) < min(seg.p1(1),seg.p2(1))-1e-3 || ...
       P(j+1,1) > max(seg.p1(1),seg.p2(1))+1e-3
        return;
    end
    if P(j+1,2) <= C(2)-1e-3, return; end
end
if P(end,1) < Model.xmin - Model.maxoff || ...
   P(end,1) > Model.xmax + Model.maxoff
    return;
end
ok = true;
end

function [q, dOut, ok] = marchRefract(Model, p, d, L, vBelow, vAbove, segs)
ok = false; q = []; dOut = d;
tbest = inf; jbest = 0;
p = p(:); d = d(:);
for j = 1:size(L,1)-1
    a = L(j,:)';
    b = L(j+1,:)';
    e = b - a;
    M = [d, -e];
    if abs(det(M)) < 1e-12, continue; end
    ts = M \ (a - p);
    if numel(ts) < 2, continue; end
    t = ts(1); s = ts(2);
    if t > 1e-9 && s >= -1e-3 && s <= 1+1e-3 && t < tbest
        tbest = t; jbest = j;
    end
end
if jbest == 0, return; end

q = p + tbest*d;
n = segs(jbest).nrm(:);
c = dot(d, n);
tvec = d - c*n;
sinB = norm(tvec);
sinA = sinB * vAbove / vBelow;
if sinA >= 1, return; end
if sinB < 1e-12
    dOut = n;
else
    dOut = n*sqrt(1-sinA^2) + (tvec/sinB)*sinA;
end
ok = true;
end

function id = segIndexAt(Model, ifn, xq)
id = 1;
for j = 1:numel(Model.seg{ifn})
    seg = Model.seg{ifn}(j);
    if xq >= min(seg.p1(1),seg.p2(1))-1e-3 && xq <= max(seg.p1(1),seg.p2(1))+1e-3
        id = j; return;
    end
end
end

function F = eqUp(x, Model, C, w, targetLayer, segIds, m)
Q = zeros(m,2);
for j = 1:m
    Q(j,1) = x(2*j-1); Q(j,2) = x(2*j);
end
P = [C; Q; [x(2*m+1), Model.surfY]];
F = zeros(2*m+1,1);
idx = 0;

for j = 1:m
    ifn = targetLayer - j;
    seg = Model.seg{ifn}(segIds(j));
    idx = idx+1;
    F(idx) = seg.k*(Q(j,1)-seg.p1(1)) - (Q(j,2)-seg.p1(2));
end

for j = 1:m
    ifn = targetLayer - j;
    seg = Model.seg{ifn}(segIds(j));
    kB = (P(j+1,2)-P(j,2))/(P(j+1,1)-P(j,1)+eps);
    kA = (P(j+2,2)-P(j+1,2))/(P(j+2,1)-P(j+1,1)+eps);
    idx = idx+1;
    F(idx) = cos(atan(kB)-atan(seg.k))*Model.v(ifn) ...
           - cos(atan(kA)-atan(seg.k))*Model.v(ifn+1);
end

idx = idx+1;
F(idx) = (P(2,1)-P(1,1))*w(2) - (P(2,2)-P(1,2))*w(1);
end