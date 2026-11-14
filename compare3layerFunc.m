function stats = compare3layerFunc(FoldOrig, FoldOpt, ax)
if nargin < 3 || isempty(ax)
    error('compare3layerFunc 必须传入 uiaxes 句柄，不弹窗');
end
nL = numel(FoldOrig);
cla(ax); hold(ax,'on'); % 修复：去掉 'reset'
colors = {'b','r','g'};
for L = 1:nL
    if iscell(FoldOrig), fo = FoldOrig{L}; else, fo = FoldOrig(L); end
    if iscell(FoldOpt),  fn = FoldOpt{L};  else, fn = FoldOpt(L);  end
    plot(ax, fo.x, fo.n, '-',  'Color', colors{min(L,3)}, 'LineWidth',1.2);
    plot(ax, fn.x, fn.n, '--', 'Color', colors{min(L,3)}, 'LineWidth',1.2);
end
xlabel(ax,'Inline (m)'); ylabel(ax,'Folds'); grid(ax,'on');
xlim(ax,[0 10000]); ylim(ax,[0 30]);
lg = {};
for L = 1:nL
    lg{end+1} = sprintf('L%d 原', L); %#ok<AGROW>
    lg{end+1} = sprintf('L%d 优', L); %#ok<AGROW>
end
legend(ax, lg, 'Location','best');

segs = {[4562.5 4937.5],'低覆盖1'; [6812.5 7287.5],'低覆盖2'; [7812.5 8637.5],'偏高区'};
stats = cell(size(segs,1), nL+1);
for s = 1:size(segs,1)
    xr = segs{s,1};
    stats{s,1} = segs{s,2};
    for L = 1:nL
        if iscell(FoldOrig), fo = FoldOrig{L}; else, fo = FoldOrig(L); end
        if iscell(FoldOpt),  fn = FoldOpt{L};  else, fn = FoldOpt(L);  end
        ko = fo.x>=xr(1) & fo.x<=xr(2);
        kn = fn.x>=xr(1) & fn.x<=xr(2);
        stats{s,L+1} = sprintf('%.1f→%.1f', mean(fo.n(ko)), mean(fn.n(kn)));
    end
end
end