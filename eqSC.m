function F = eqSC(x, Model, S, C, nUp, segIds)
% x = [k0, k1..k{nUp}, x1,y1, ..., x{nUp},y{nUp}]'  长度 3*nUp+1
% 方程顺序：段0斜率, 段1..段{nUp-1}斜率, 段{nUp}斜率,
%           折线约束(1..nUp), Snell(1..nUp)
n = nUp;
K  = x(1:n+1);
XY = reshape(x(n+2:end), 2, n)';
P  = [S; XY; C];
F  = zeros(3*n+1,1);
idx = 0;

% 1) 段 0 斜率
idx = idx+1;
F(idx) = K(1)*(P(2,1)-P(1,1)) - (P(2,2)-P(1,2));

% 2) 段 1..n-1 斜率
for i = 1:n-1
    idx = idx+1;
    F(idx) = K(i+1)*(P(i+2,1)-P(i+1,1)) - (P(i+2,2)-P(i+1,2));
end

% 3) 段 n 斜率
idx = idx+1;
F(idx) = K(n+1)*(P(n+2,1)-P(n+1,1)) - (P(n+2,2)-P(n+1,2));

% 4) 折线约束
for i = 1:n
    idx = idx+1;
    seg = Model.seg{i}(segIds(i));
    F(idx) = seg.k*(P(i+1,1)-seg.p1(1)) - (P(i+1,2)-seg.p1(2));
end

% 5) Snell
for i = 1:n
    idx = idx+1;
    seg = Model.seg{i}(segIds(i));
    F(idx) = cos(atan(K(i)) - atan(seg.k))*Model.v(i+1) ...
           - cos(atan(K(i+1)) - atan(seg.k))*Model.v(i);
end
end