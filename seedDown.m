function [P, ok] = seedDown(Model, S, C, targetLayer)
% 下行路径初值：以出射角 theta 扫描（射线自 S 向下逐层折射），
% 使射线在目的层界面上的落点横坐标命中 C(1)，再用二分细化。
% 返回 P = [S; P1; ...; P{nUp}; C]
ok = false; P = [];
nUp = targetLayer - 1;
if nUp <= 0, P = [S; C]; ok = true; return; end

thGrid = (-85:2:85)'*pi/180;
fPrev = NaN; thPrev = NaN; okBr = false;
for i = 1:numel(thGrid)
    [~, xhit, g] = shootDown(Model, S, thGrid(i), targetLayer);
    if ~g, continue; end
    f = xhit - C(1);
    if ~isnan(fPrev) && fPrev*f <= 0
        thLo = thPrev; thHi = thGrid(i); okBr = true; break;
    end
    fPrev = f; thPrev = thGrid(i);
end
if ~okBr, return; end

% 二分：落点横坐标对出射角单调
fLo = fAt(Model, S, thLo, targetLayer, C);
for it = 1:40
    thMid = 0.5*(thLo+thHi);
    fm = fAt(Model, S, thMid, targetLayer, C);
    if isnan(fm)
        thHi = thMid; continue;
    end
    if fLo*fm <= 0
        thHi = thMid;
    else
        thLo = thMid; fLo = fm;
    end
end

thBest = 0.5*(thLo+thHi);
[pts, xhit, g] = shootDown(Model, S, thBest, targetLayer);
if ~g, return; end
if abs(xhit - C(1)) > 1.0, return; end          % 命中容差 1 m

pts(end,:) = C;                                  % 落点校正为 CRP
P = pts; ok = true;
end

% ======================= 局部函数 =======================
function f = fAt(Model, S, th, targetLayer, C)
[~, xhit, g] = shootDown(Model, S, th, targetLayer);
if ~g
    f = NaN;
else
    f = xhit - C(1);
end
end

function [pts, xhit, ok] = shootDown(Model, S, th, targetLayer)
ok = false; pts = []; xhit = NaN;
d = [sin(th); -cos(th)];                         % 单位方向，y 向下为负
p = [S(1); S(2)];
pts = p';
for i = 1:targetLayer-1
    [q, d, g] = rayStep(Model, p, d, Model.layersMat{i}, ...
                        Model.v(i+1), Model.v(i), Model.seg{i});
    if ~g, return; end
    pts = [pts; q']; %#ok<AGROW>
    p = q;
end
[q, g] = hitLine(Model.layersMat{targetLayer}, p, d);
if ~g, return; end
pts = [pts; q']; xhit = q(1); ok = true;
end

function [q, dOut, ok] = rayStep(Model, p, d, L, vBelow, vAbove, segs)
% 下行：由上一介质折射进入下一介质
ok = false; q = []; dOut = d;
tbest = inf; jbest = 0;
for j = 1:size(L,1)-1
    a = L(j,:)'; b = L(j+1,:)'; e = b - a;
    M = [d, -e];
    if abs(det(M)) < 1e-12, continue; end
    ts = M \ (a - p);
    if ts(1) > 1e-9 && ts(2) >= -1e-9 && ts(2) <= 1+1e-9 && ts(1) < tbest
        tbest = ts(1); jbest = j;
    end
end
if jbest == 0, return; end
q = p + tbest*d;

n = segs(jbest).nrm(:);                          % 界面法线，指向地表
c = dot(d, n);
tvec = d - c*n;
sinB = norm(tvec);                               % 入射介质中的 sinθ
sinA = sinB * vBelow / vAbove;                   % 折射后 sinθ = sinθ * v2/v1
if sinA >= 1, return; end                         % 全反射
if sinB < 1e-12
    dOut = -n;
else
    dOut = -n*sqrt(1-sinA^2) + (tvec/sinB)*sinA;  % 指向下方
end
ok = true;
end

function [q, ok] = hitLine(L, p, d)
ok = false; q = [];
tbest = inf;
for j = 1:size(L,1)-1
    a = L(j,:)'; b = L(j+1,:)'; e = b - a;
    M = [d, -e];
    if abs(det(M)) < 1e-12, continue; end
    ts = M \ (a - p);
    if ts(1) > 1e-9 && ts(2) >= -1e-9 && ts(2) <= 1+1e-9 && ts(1) < tbest
        tbest = ts(1);
    end
end
if isinf(tbest), return; end
q = p + tbest*d; ok = true;
end
