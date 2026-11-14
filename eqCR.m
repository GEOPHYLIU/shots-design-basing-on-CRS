function F = eqCR(x, Model, C, R, nUp, segIds)
% 与 eqSC 对称：起点 C、终点 R
n = nUp;
K  = x(1:n+1);
XY = reshape(x(n+2:end), 2, n)';
P  = [C; XY; R];
F  = zeros(3*n+1,1);
idx = 0;

idx=idx+1; F(idx) = K(1)*(P(2,1)-P(1,1)) - (P(2,2)-P(1,2));
for i=1:n-1
    idx=idx+1; F(idx) = K(i+1)*(P(i+2,1)-P(i+1,1)) - (P(i+2,2)-P(i+1,2));
end
idx=idx+1; F(idx) = K(n+1)*(P(n+2,1)-P(n+1,1)) - (P(n+2,2)-P(n+1,2));
for i=1:n
    idx=idx+1; seg=Model.seg{i}(segIds(i));
    F(idx) = seg.k*(P(i+1,1)-seg.p1(1)) - (P(i+1,2)-seg.p1(2));
end
for i=1:n
    idx=idx+1; seg=Model.seg{i}(segIds(i));
    F(idx) = cos(atan(K(i)) - atan(seg.k))*Model.v(i+1) ...
           - cos(atan(K(i+1)) - atan(seg.k))*Model.v(i);
end
end