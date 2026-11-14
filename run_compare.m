clear; clc;

load('forward_2layer.mat');
Fold1_orig = Fold1; Fold2_orig = Fold2; ModelOrig = Model;

if ~isfile('forward_2layer_opt.mat')
    error('请先跑 run_forward_opt.m 生成 forward_2layer_opt.mat');
end
load('forward_2layer_opt.mat');

figure('Position',[100 100 1200 600]);
subplot(2,1,1);
plot(Fold1_orig.x, Fold1_orig.n, '-b','LineWidth',1.2); hold on;
plot(Fold1_opt.x,  Fold1_opt.n,  '-r','LineWidth',1.2);
xlabel('Inline (m)'); ylabel('Folds'); title('Layer 1 Folds');
legend('Original','Optimized'); grid on; xlim([0 10000]); ylim([0 30]);

subplot(2,1,2);
plot(Fold2_orig.x, Fold2_orig.n, '-b','LineWidth',1.2); hold on;
plot(Fold2_opt.x,  Fold2_opt.n,  '-r','LineWidth',1.2);
xlabel('Inline (m)'); ylabel('Folds'); title('Layer 2 Folds');
legend('Original','Optimized'); grid on; xlim([0 10000]); ylim([0 30]);

fprintf('=== 关键区间优化前后对比 ===\n');
segs = {[4562.5 4937.5],'低覆盖1'; [6812.5 7287.5],'低覆盖2'};
for s = 1:size(segs,1)
    xr = segs{s,1}; name = segs{s,2};
    k1o = Fold1_orig.x>=xr(1) & Fold1_orig.x<=xr(2);
    k1n = Fold1_opt.x >=xr(1) & Fold1_opt.x <=xr(2);
    k2o = Fold2_orig.x>=xr(1) & Fold2_orig.x<=xr(2);
    k2n = Fold2_opt.x >=xr(1) & Fold2_opt.x <=xr(2);
    fprintf('%-8s L1: 原%.1f→新%.1f | L2: 原%.1f→新%.1f\n', ...
        name, mean(Fold1_orig.n(k1o)), mean(Fold1_opt.n(k1n)), ...
        mean(Fold2_orig.n(k2o)), mean(Fold2_opt.n(k2n)));
end