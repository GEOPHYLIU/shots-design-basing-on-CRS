function onAutoOptimize(app)
    try
        app.readCfg();
        app.openProgress('自动优化...');
        dq = parallel.pool.DataQueue;
        afterEach(dq, @(frac) app.updateProgress(frac));

        cfg = app.Cfg; cfg.coarseEnable = true;
        Model = buildModel(cfg);
        nL = Model.nLayerFile;
        app.FoldOrig = cell(1,nL);
        for L = 1:nL
            [Path, ~] = traceAll(Model, 'forward', L, @(k,n) send(dq, k/n));
            app.FoldOrig{L} = foldStat(Path, Model, L);
        end
        app.ShotInv = cell(1,nL);
        for L = 1:nL
            [PathInv, ~] = traceAll(Model, 'inversion', L, @(k,n) send(dq, k/n));
            app.ShotInv{L} = sort(arrayfun(@(p) p.shot(1), PathInv));
        end
        [shotOpt, optInfo] = runOptimizeFunc(app.ShotInv, app.FoldOrig, Model, app.OptParam, app.SintEdit.Value);
        app.ShotOpt = shotOpt; app.OptInfo = optInfo;
        app.plotOpt(optInfo);
        f = fullfile(app.OutDir,'shot_opt.csv');
        writematrix([shotOpt, zeros(size(shotOpt))], f);
        cfg.shotFile = f;
        ModelOpt = buildModel(cfg);
        app.FoldOpt = cell(1,nL);
        for L = 1:nL
            [Path, ~] = traceAll(ModelOpt, 'forward', L, @(k,n) send(dq, k/n));
            app.FoldOpt{L} = foldStat(Path, ModelOpt, L);
        end
        compare3layerFunc(app.FoldOrig, app.FoldOpt, app.CompareAxes);
        app.closeProgress();
        app.updateButtonState();
%     catch ME
%         app.closeProgress();
%         fprintf('!!! 报错: %s\n', ME.message);
        
           catch ME
        app.closeProgress(); 
        rethrow(ME);   % 强制把错误抛到命令行，打印行号 
        for k = 1:numel(ME.stack)
            fprintf('  at %s line %d\n', ME.stack(k).name, ME.stack(k).line);
        end
        uialert(app.UIFigure, ME.message, '错误');
    end
end