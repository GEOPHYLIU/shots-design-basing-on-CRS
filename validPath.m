function ok = validPath(Model, P, nUp, segIds)
% nUp = 上覆界面数；P 有 nUp+2 行，P(1)=起点，P(end)=反射点 C
ok = true;

% 上覆透射点 P1..P{nUp}
for i = 1:nUp
    seg = Model.seg{i}(segIds(i));
    p = P(i+1,:);
    if p(1) < min(seg.p1(1),seg.p2(1))-1e-6 || ...
       p(1) > max(seg.p1(1),seg.p2(1))+1e-6
        ok = false; return;
    end
    segVec = seg.p2 - seg.p1;
    vin  = P(i+1,:) - P(i,:);
    vout = P(i+2,:) - P(i+1,:);
    cIn  = dot(vin, segVec)/norm(vin)/norm(segVec);
    cOut = dot(vout, segVec)/norm(vout)/norm(segVec);
    % 透射点：入射/出射在界面同侧，与界面线段夹角余弦同号
    if cIn * cOut <= 0
        ok = false; return;
    end
end

% 反射点 C：y 与目的层界面一致
C = P(end,:);
targetLayer = nUp + 1;
yExp = interp1(Model.layers(targetLayer).x, Model.layers(targetLayer).y, ...
                C(1), 'linear', 'extrap');
if abs(C(2)-yExp) > 1e-3
    ok = false; return;
end

% 全反射约束
if ~isempty(Model.maxa)
    for i = 1:nUp
        vin = P(i+1,:) - P(i,:);
        seg = Model.seg{i}(segIds(i));
        cosAng = abs(dot(vin,seg.nrm))/norm(vin);
        if cosAng < cos(Model.maxa(i)) - 1e-9
            ok = false; return;
        end
    end
end
end