function Model = buildModel(cfg)
% 构建模型：读界面、炮检点、预计算折线段几何
% 约定：y 向下为负，地表 y=0；层界面 x 升序
% Model.layers 为 struct 数组（.x, .y），Model.seg / Model.crpY 为 cell

if ~iscell(cfg.layerFiles)
    cfg.layerFiles = {cfg.layerFiles};
end
if numel(cfg.v) < 2
    error('cfg.v 至少需要 2 个速度（入射层+反射层）');
end
if numel(cfg.layerFiles) < 1
    error('cfg.layerFiles 至少需要 1 个界面文件');
end
if numel(cfg.v) < numel(cfg.layerFiles) + 1
    error('cfg.v(%d) 数量不足：%d 个界面至少需要 %d 个速度', ...
        numel(cfg.v), numel(cfg.layerFiles), numel(cfg.layerFiles)+1);
end

Model.cfg    = cfg;
Model.v      = cfg.v(:)';
Model.nLayer = numel(cfg.v);
Model.nLayerFile = numel(cfg.layerFiles);
Model.rint   = cfg.rint;
Model.sint   = cfg.sint;
Model.maxoff = cfg.maxoff;
Model.subdiv = cfg.subdiv;
Model.surfY  = cfg.surfY;

% 读界面（struct 数组）
Model.layers = struct('x', cell(Model.nLayer,1), 'y', cell(Model.nLayer,1));
for i = 1:Model.nLayerFile
    L = importdata(cfg.layerFiles{i});
    if isstruct(L), L = L.data; end
    L = L(~isnan(L(:,1)) & ~isnan(L(:,2)), :);
    L = sortrows(L,1);
    [~,ia] = unique(L(:,1),'stable');
    L = L(ia,:);
    Model.layers(i).x = L(:,1);
    Model.layers(i).y = L(:,2);
end

% 预计算折线段（cell，不变）
Model.seg = cell(Model.nLayer,1);
for i = 1:Model.nLayerFile
    Lx = Model.layers(i).x;
    Ly = Model.layers(i).y;
    nSeg = numel(Lx)-1;
    S = struct('p1',cell(nSeg,1),'p2',cell(nSeg,1), ...
               'k',cell(nSeg,1),'mid',cell(nSeg,1),'nrm',cell(nSeg,1));
    for j = 1:nSeg
        p1 = [Lx(j), Ly(j)];
        p2 = [Lx(j+1), Ly(j+1)];
        S(j).p1 = p1; S(j).p2 = p2;
        S(j).k  = (p2(2)-p1(2))/(p2(1)-p1(1));
        S(j).mid= (p1+p2)/2;
        d = p2-p1; nrm = [-d(2), d(1)]; nrm = nrm/norm(nrm);
        if nrm(2) < 0, nrm = -nrm; end
        S(j).nrm = nrm;
    end
    Model.seg{i} = S;
end

% 面元序列
Model.xmin = cfg.rstart;
Model.xmax = cfg.rend;
Model.bin  = Model.rint/2;
Model.crpX = (Model.xmin + Model.bin/2) : Model.bin : Model.xmax;

% 每层 CRP y 插值（用 .x/.y）
Model.crpY = cell(Model.nLayer,1);
for i = 1:Model.nLayerFile
    Model.crpY{i} = interp1(Model.layers(i).x, Model.layers(i).y, ...
                            Model.crpX, 'linear', 'extrap');
end

% 未定义界面占位
for i = Model.nLayerFile+1 : Model.nLayer
    Model.layers(i).x = Model.layers(Model.nLayerFile).x;
    Model.layers(i).y = Model.layers(Model.nLayerFile).y;
    Model.seg{i}  = Model.seg{Model.nLayerFile};
    Model.crpY{i} = Model.crpY{Model.nLayerFile};
end

% 炮点、检波点
Model.shots = importdata(cfg.shotFile);
if isstruct(Model.shots), Model.shots = Model.shots.data; end
Model.recs  = importdata(cfg.recFile);
if isstruct(Model.recs), Model.recs = Model.recs.data; end
Model.shots(:,2) = cfg.surfY;
Model.recs(:,2)  = cfg.surfY;

% 最大反射角
if isempty(cfg.maxaRatio)
    Model.maxa = asin(Model.v(1:end-1)./Model.v(2:end));
else
    Model.maxa = cfg.maxaRatio;
end

% ======================= 内部降采样 =======================
if isfield(cfg,'coarseEnable') && cfg.coarseEnable
    if isfield(cfg,'coarse')
        c = cfg.coarse;
    else
        c = struct('binFactor2',4,'binFactor3',8, ...
                   'shotFactor2',2,'shotFactor3',4,'recFactor',8);
    end
    if Model.nLayerFile >= 3
        binF  = c.binFactor3;
        shotF = c.shotFactor3;
    else
        binF  = c.binFactor2;
        shotF = c.shotFactor2;
    end
    recF = c.recFactor;
    Model.coarse = struct('binFactor',binF, 'shotFactor',shotF, ...
                          'recFactor',recF, 'enable',true);

    Model.crpX = Model.crpX(1:binF:end);
    for i = 1:numel(Model.crpY)
        if ~isempty(Model.crpY{i})
            Model.crpY{i} = Model.crpY{i}(1:binF:end);
        end
    end
    if size(Model.shots,1) > 1
        Model.shots = Model.shots(1:shotF:end, :);
    end
    if size(Model.recs,1) > 1
        Model.recs = Model.recs(1:recF:end, :);
    end
    fprintf('[buildModel] 降采样：面元×%d，炮点1/%d，检波点1/%d → CRP=%d，炮=%d，检波=%d\n', ...
        binF, shotF, recF, numel(Model.crpX), size(Model.shots,1), size(Model.recs,1));
else
    Model.coarse = struct('binFactor',1, 'shotFactor',1, 'recFactor',1, 'enable',false);
end
Model.layersMat = cell(Model.nLayer,1);
for i = 1:Model.nLayer
    Model.layersMat{i} = [Model.layers(i).x, Model.layers(i).y];
end
end
