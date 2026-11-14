function onPreview(app)
    try
        app.readCfg();
        cfg = app.Cfg; cfg.coarseEnable = false;
        app.Model = buildModel(cfg);
        ax = app.ModelAxes;
        cla(ax);                       % 不用 'reset'
        hold(ax,'on');
        layers = app.Model.layers;     % 先赋局部变量
        nL = app.Model.nLayerFile;
        for i = 1:nL
            L = layers{i};             % 局部变量 {i}
            plot(ax, L(:,1), L(:,2), '-','LineWidth',1.5);
        end
        xlabel(ax,'Inline (m)'); ylabel(ax,'Depth (m)');
        title(ax, sprintf('模型：%d 层', nL));
        grid(ax,'on');
    catch ME
        uialert(app.UIFigure, ME.message, '错误');
    end
end