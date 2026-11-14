function plot_paths(Model, Path, crpX, layerId)
figure; hold on;
for i = 1:numel(Model.layers)
    if i==1
        plot(Model.layers(i).x, Model.layers(i).y, '-r');
    else
        plot(Model.layers(i).x, Model.layers(i).y, '-c');
    end
end
for i = 1:numel(Path)
    if ~Path(i).valid || Path(i).layerId ~= layerId, continue; end
    if abs(Path(i).crp(1) - crpX) > 1e-6, continue; end
    plot(Path(i).pts(:,1), Path(i).pts(:,2),'-k');
end
axis equal; xlim([0,10000]); ylim([-2500,100]);
xlabel('Inline Position'); ylabel('Depth');
title(sprintf('CRP=%.1f, Layer=%d', crpX, layerId));
end