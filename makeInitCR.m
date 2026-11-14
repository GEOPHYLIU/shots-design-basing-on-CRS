function x0 = makeInitCR(Model, C, R, nUp, segIds, sub, subdiv)
n = nUp; x0 = zeros(3*n+1,1);
XY = zeros(n,2);
for i=1:n
    seg = Model.seg{i}(segIds(i));
    t = (sub-0.5)/subdiv;
    XY(i,:) = seg.p1 + t*(seg.p2-seg.p1);
end
P = [C; XY; R];
kCR = (R(2)-C(2))/(R(1)-C(1)+eps);
x0(1) = kCR;
for i=1:n
    x0(i+1) = kCR;
end
x0(n+2:end) = reshape(XY',[],1);
end