function [Path, info] = traceAll(Model, mode, targetLayer, progressFcn)
if nargin < 4, progressFcn = []; end

Path = struct('shot',{},'crp',{},'rec',{},'pts',{},'layerId',{},'valid',{});
if strcmp(mode,'forward')
    starts = Model.shots;  isForward = true;
else
    starts = Model.recs;   isForward = false;
end
nCRP   = numel(Model.crpX);
tStart = tic;

PathCell = cell(nCRP,1);
infoCell = cell(nCRP,1);

useParfor = ~isempty(ver('parallel')) && license('test','Distrib_Computing_Toolbox');

if useParfor
    parfor k = 1:nCRP
        try
            [PathCell{k}, infoCell{k}] = traceOneCRP(Model, starts, k, targetLayer, isForward, progressFcn);
        catch ME
            fprintf('!!! parfor CRP %d 报错: %s\n', k, ME.message);
            fprintf('  at %s line %d\n', ME.stack(1).name, ME.stack(1).line);
            rethrow(ME);
        end
    end
else
    for k = 1:nCRP
        try
            [PathCell{k}, infoCell{k}] = traceOneCRP(Model, starts, k, targetLayer, isForward, progressFcn);
        catch ME
            fprintf('!!! for CRP %d 报错: %s\n', k, ME.message);
            fprintf('  at %s line %d\n', ME.stack(1).name, ME.stack(1).line);
            rethrow(ME);
        end
    end
end

Path = [PathCell{:}];
infos = cell2mat(infoCell);
info = struct('nTry',sum(infos(:,1)),'nDown',sum(infos(:,2)), ...
              'nOK',sum(infos(:,3)),'nOff',sum(infos(:,4)), ...
              'usedParfor',useParfor);
fprintf('  完成：尝试 %d，下行成功 %d，有效 %d，超偏移 %d，用时 %.1fs（%s）\n', ...
    info.nTry, info.nDown, info.nOK, info.nOff, toc(tStart), ...
    ternary(useParfor,'并行','串行'));
end

function s = ternary(c,a,b)
if c, s=a; else, s=b; end
end

function [Pk, inf] = traceOneCRP(Model, starts, k, targetLayer, isForward, progressFcn)
if iscell(Model.crpY)
    current_Y = Model.crpY{targetLayer}(k);
else
    current_Y = Model.crpY(targetLayer, k);
end
C = [Model.crpX(k), current_Y];

Pk = struct('shot',{},'crp',{},'rec',{},'pts',{},'layerId',{},'valid',{});
nTry=0; nDown=0; nOK=0; nOff=0;
nStart = size(starts,1);
for i = 1:nStart
    P0 = starts(i,:);
    if abs(P0(1)-C(1)) > Model.maxoff, continue; end
    nTry = nTry + 1;
    [full, Rex, ok] = traceOne(Model, P0, C, targetLayer);
    if ~ok, continue; end
    nDown = nDown + 1;
    if norm(Rex-P0) > Model.maxoff, nOff=nOff+1; continue; end
    idx = numel(Pk)+1;
    Pk(idx).pts = full; Pk(idx).crp = C; Pk(idx).layerId = targetLayer; Pk(idx).valid = true;
    if isForward
        Pk(idx).shot = P0; Pk(idx).rec = Rex;
    else
        Pk(idx).rec = P0;  Pk(idx).shot = Rex;
    end
    nOK = nOK+1;
end
inf = [nTry, nDown, nOK, nOff];
if ~isempty(progressFcn), progressFcn(k, numel(Model.crpX)); end
end