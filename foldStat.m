function Fold = foldStat(Path, Model, targetLayer)
% 按面元统计覆盖次数
Fold.x = Model.crpX(:);
Fold.n = zeros(numel(Model.crpX),1);
for i = 1:numel(Path)
    if ~Path(i).valid || Path(i).layerId ~= targetLayer, continue; end
    [~,idx] = min(abs(Fold.x - Path(i).crp(1)));
    Fold.n(idx) = Fold.n(idx) + 1;
end
end