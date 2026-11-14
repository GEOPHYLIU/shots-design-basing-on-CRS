clear; clc;
load('forward_2layer.mat');
figure('Position',[100 100 1200 600]);
subplot(2,1,1); hold on;
for i = 1:numel(Model.layers)
    if i==1
        plot(Model.layers(i).x, Model.layers(i).y, '-r','LineWidth',1.5);
    else
        plot(Model.layers(i).x, Model.layers(i).y, '-c','LineWidth',1.5);
    end
end
xlim([0 10000]); xlabel('Inline (m)'); ylabel('Depth (m)');
title('2D Model'); legend('Layer1','Layer2'); grid on;
subplot(2,1,2); hold on;
plot(Fold1.x, Fold1.n, '-b','LineWidth',1.2);
plot(Fold2.x, Fold2.n, '-r','LineWidth',1.2);
xlim([0 10000]); ylim([0 30]);
xlabel('Inline (m)'); ylabel('Folds');
title('Effective Folds（蓝：Layer1；红：Layer2）');
legend('Layer1','Layer2'); grid on;