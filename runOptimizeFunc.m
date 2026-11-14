function [shotOpt, optInfo] = runOptimizeFunc(ShotInv, FoldOrig, Model, optParam, sInt)
if nargin < 5, sInt = 100; end

nL = Model.nLayerFile;
sStart = min(Model.shots(:,1));
sEnd   = max(Model.shots(:,1));
edges   = sStart - sInt/2 : sInt : sEnd + sInt/2;
centers = (sStart : sInt : sEnd)';
ns = numel(centers);

% 1. cnt 统计
cnt = cell(1,nL); cnt_s = cell(1,nL);
for L = 1:nL
    cnt{L}   = histcounts(ShotInv{L}, edges); cnt{L} = cnt{L}(:);
    cnt_s{L} = smoothdata(cnt{L}, 'gaussian', optParam.smoothWin);
end

% 2. 深度权重
depth = zeros(1,nL);
for L = 1:nL, depth(L) = abs(median(Model.layers(L).y)); end
w = depth / max(depth);

cntW_s = zeros(ns,1);
for L = 1:nL, cntW_s = cntW_s + w(L)*cnt_s{L}; end

% 3. 覆盖 fold 统计（修复逗号列表解析）
fold = cell(1,nL);
for L = 1:nL
    fold{L} = zeros(ns,1);
    fo = FoldOrig{L};       % 先提出来，防止解析错误
    for i = 1:ns
        kk = fo.x >= centers(i)-sInt/2 & fo.x < centers(i)+sInt/2;
        if any(kk)
            fold{L}(i) = mean(fo.n(kk)); 
        end
    end
end

kFull = centers >= 2000 & centers <= 8000;
foldAll = [];
for L = 1:nL, foldAll = [foldAll; fold{L}(kFull)]; end
foldTarget = median(foldAll) - optParam.foldTargetOffset;

% 4. 局部中位数
baseLocal_s = zeros(ns,1);
for i = 1:ns
    kWin = centers >= centers(i)-optParam.winLen/2 & centers <= centers(i)+optParam.winLen/2;
    baseLocal_s(i) = median(cntW_s(kWin));
end

% 5. Dense / Sparse 判定
isDense = cntW_s > baseLocal_s*optParam.denseThrHi;
isSparse = cntW_s < baseLocal_s*optParam.denseThrLo;
for L = 1:nL
    isDense  = isDense  | (fold{L} < foldTarget-2);
    isSparse = isSparse & (fold{L} >= foldTarget+2);
end
isSparse = isSparse & ~isDense;

isDense  = isDense  & (circshift(isDense,1)  | circshift(isDense,-1));
isSparse = isSparse & (circshift(isSparse,1) | circshift(isSparse,-1));
isNormal = ~isDense & ~isSparse;

N0 = ns; Nmax = ceil(N0 * optParam.nmaxFactor);

% 6. 5% 上浮约束
gapFold = zeros(ns,1);
for L = 1:nL, gapFold = max(gapFold, max(0, foldTarget - fold{L})); end
gapCnt = max(0, cntW_s - baseLocal_s*optParam.denseThrHi);
gap = optParam.cntWeight*gapCnt + gapFold;

denseIdx = find(isDense);
[~, ord] = sort(gap(denseIdx), 'descend');
denseIdxSorted = denseIdx(ord);

isDenseFinal = false(ns,1);
nN = sum(isNormal); nS = sum(isSparse); nCur = nN + 0.5*nS;
for k = 1:numel(denseIdxSorted)
    i = denseIdxSorted(k);
    if nCur + 2 <= Nmax
        isDenseFinal(i) = true; nCur = nCur + 2;
    else
        break;
    end
end
isDense = isDenseFinal;
isNormal = ~isDense & ~isSparse;

% 7. 生成炮点
shotOpt = [];
for i = 1:ns
    x = centers(i);
    if isDense(i)
        shotOpt = [shotOpt, x-optParam.denseStep/2, x, x+optParam.denseStep/2]; %#ok<AGROW>
    elseif isSparse(i)
        if mod(i,2)==1, shotOpt = [shotOpt, x]; end %#ok<AGROW>
    else
        shotOpt = [shotOpt, x]; %#ok<AGROW>
    end
end
% shotOpt = unique(sort(shotOpt));
% shotOpt = shotOpt(shotOpt>=sStart & shotOpt<=sEnd);
shotOpt = unique(sort(shotOpt));
shotOpt = shotOpt(:);   % ===== 关键：强制转成 N×1 列向量 =====
shotOpt = shotOpt(shotOpt>=sStart & shotOpt<=sEnd);



% 8. 返回结构体（修复 struct 组装导致类型展开）
optInfo = struct();
optInfo.centers = centers;
optInfo.cnt = cnt;
optInfo.cnt_s = cnt_s;
optInfo.cntW_s = cntW_s;
optInfo.baseLocal_s = baseLocal_s;
optInfo.fold = fold;
optInfo.foldTarget = foldTarget;
optInfo.isDense = isDense;
optInfo.isSparse = isSparse;
optInfo.isNormal = isNormal;
optInfo.N0 = N0;
optInfo.Nmax = Nmax;
optInfo.nCur = nCur;
optInfo.denseThrHi = optParam.denseThrHi;
optInfo.denseThrLo = optParam.denseThrLo;
end