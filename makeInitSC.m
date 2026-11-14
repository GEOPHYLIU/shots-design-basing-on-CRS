function x0 = makeInitSC(Model, S, C, nUp, segIds, sub, subdiv)
% 未知量排布 x = [k0; k1; ...; k{nUp}; x1; y1; ...; x{nUp}; y{nUp}]
% 初值：透射点取所在折线段的 sub 等分点，斜率取相邻点连线斜率（优于整条弦斜率）
n = nUp; x0 = zeros(3*n+1,1);
XY = zeros(n,2);
for i=1:n
    seg = Model.seg{i}(segIds(i));
    t = (sub-0.5)/subdiv;
    XY(i,:) = seg.p1 + t*(seg.p2-seg.p1);
end

P = [S; XY; C];

% 各段斜率取相邻点连线的实际斜率
for i=1:n+1
    dx = P(i+1,1)-P(i,1);
    if abs(dx) < 1e-9
        x0(i) = sign(P(i+1,2)-P(i,2))*1e6;
    else
        x0(i) = (P(i+1,2)-P(i,2))/dx;
    end
end

% 透射点坐标（交错排布 x1,y1,x2,y2,...）
for i=1:n
    x0(n+2*i)   = XY(i,1);
    x0(n+2*i+1) = XY(i,2);
end
end
