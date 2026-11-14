% model_config.m —— 模型固化配置（无基线）
% 所有 run_* 脚本、APP 开头 run('model_config.m')

%% ===== 两层配置 =====
cfg2.layerFiles = {'layer1bl.txt','layer2blnew.txt'};
cfg2.v          = [2500, 2800, 3200];
cfg2.rint       = 25;
cfg2.sint       = 100;
cfg2.rstart     = 0;
cfg2.rend       = 10000;
cfg2.maxoff     = 2500;
cfg2.maxaRatio  = [];
cfg2.subdiv     = 2;
cfg2.surfY      = 0;
cfg2.shotFile   = 'S.txt';
cfg2.recFile    = 'R.txt';

%% ===== 三层配置 =====
cfg3.layerFiles = {'layer1bl.txt','layer2blnew.txt','layer3bl_smooth.txt'};
cfg3.v          = [2500, 2800, 3200, 3500];
cfg3.rint       = 25;
cfg3.sint       = 100;
cfg3.rstart     = 0;
cfg3.rend       = 10000;
cfg3.maxoff     = 2500;
cfg3.maxaRatio  = [];
cfg3.subdiv     = 2;
cfg3.surfY      = 0;
cfg3.shotFile   = 'S.txt';
cfg3.recFile    = 'R.txt';

%% ===== 优化参数（UI 可改，默认值）=====
optParam.foldTargetOffset = 4;
optParam.cntWeight        = 3;
optParam.nmaxFactor       = 1.05;
optParam.denseThrHi       = 1.05;
optParam.denseThrLo       = 0.95;
optParam.smoothWin        = 7;
optParam.winLen           = 1000;
optParam.denseStep        = 50;
optParam.sparseStep       = 200;
optParam.normalStep       = 100;

%% ===== 粗采样（按层数自适应）=====
coarse.enable      = true;
coarse.binFactor2  = 4;
coarse.binFactor3  = 8;
coarse.shotFactor2 = 2;
coarse.shotFactor3 = 4;
coarse.recFactor   = 8;

fprintf('[model_config] 配置已加载\n');