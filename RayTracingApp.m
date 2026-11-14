classdef RayTracingApp < handle
    properties (Access = public)
        UIFigure; TabGroup; StatusLabel
        OutDirLabel
        AutoButton; ManualButton; StopButton
        Layer1Edit; Layer2Edit; Layer3Check; Layer3Edit; L3PickButton
        V1Edit; V2Edit; V3Edit; V4Edit
        RintEdit; SintEdit; MaxoffEdit
        ShotEdit; RecEdit
        Bin2Edit; ShotF2Edit; Bin3Edit; ShotF3Edit; RecFEdit
        FoldOffEdit; CntWEdit; NmaxEdit; DenseHiEdit; DenseLoEdit
        DenseStepEdit; SparseStepEdit; NormalStepEdit
        ModelAxes; LayerDropDown; FoldAxes; OptAxes; ManualTxtLabel; CompareAxes
        LogTextArea
        Cfg struct = struct()
        OptParam struct = struct()
        Model struct = struct()
        FoldOrig cell = {}
        FoldOpt cell = {}
        ShotInv cell = {}
        ShotOpt double = []
        OptInfo struct = struct()
        OutDir char = ''
        ManualShotFile char = ''
        CancelFlag logical = false
    end

    methods (Access = public)
        function app = RayTracingApp()
            app.buildUI();
            app.updateButtonState();
            if nargout == 0, clear app; end
        end
    end

    methods (Access = private)

        %% ================= 建界面 =================
  
               function buildUI(app)
            app.UIFigure = uifigure('Name','基于CRP的炮点优化APP','Position',[100 60 1024 768]);
            gl = uigridlayout(app.UIFigure,[2 1]);
            gl.RowHeight = {70,'1x'};   % 高度加高以容纳日志
            gl.Padding = [3 3 3 3];

            % 将工具栏分成 2 行 × 6 列
            % 列1~5给按钮，列6给右侧的日志框
            tb = uigridlayout(gl,[2 6]);
            tb.RowHeight = {30, 30};     
            tb.ColumnWidth = {100, 100, 100, 100, 40, '1x'}; 
            tb.Padding = [0 0 0 0];
            
            % --- 第一行 ---
            app.AutoButton   = uibutton(tb,'Text','自动优化','Enable','off', ...
                'ButtonPushedFcn',@(s,e) app.onAutoOptimize());
            app.AutoButton.Layout.Row = 1; app.AutoButton.Layout.Column = 1;

            app.ManualButton = uibutton(tb,'Text','手动优化','Enable','off', ...
                'ButtonPushedFcn',@(s,e) app.onManualOptimize());
            app.ManualButton.Layout.Row = 1; app.ManualButton.Layout.Column = 2;

            app.StopButton   = uibutton(tb,'Text','停止', ...
                'ButtonPushedFcn',@(s,e) app.onStop());
            app.StopButton.Layout.Row = 1; app.StopButton.Layout.Column = 3;

            app.OutDirLabel  = uilabel(tb,'Text','输出：未选');
            app.OutDirLabel.Layout.Row = 1; app.OutDirLabel.Layout.Column = [4 5];

            % --- 第二行 ---
            uibutton(tb,'Text','输出目录','ButtonPushedFcn',@(s,e) app.onOutDir(), ...
                'Layout', matlab.ui.layout.GridLayoutOptions('Row', 2, 'Column',[1 2]));
            
            % 隐藏原来的 StatusLabel，保持代码兼容
            app.StatusLabel = uilabel(tb, 'Visible', 'off'); 
            
            % --- 右侧：日志框，跨 2 行 ---
            app.LogTextArea = uitextarea(tb,'Editable','off','Value',{'就绪'}, ...
                'FontName','Microsoft YaHei','FontSize',10);
            app.LogTextArea.Layout.Row = [1 2]; 
            app.LogTextArea.Layout.Column = 6;

            % 下方 TabGroup 保持不变
            app.TabGroup = uitabgroup(gl);
            app.buildTab1(); app.buildTab2(); app.buildTab3(); app.buildTab4();
        end 
        
        
        
%         function buildUI(app)
%             app.UIFigure = uifigure('Name','CRP追踪观测系统优化APP','Position',[100 60 1024 768]);
%             gl = uigridlayout(app.UIFigure,[2 1]);
%             gl.RowHeight = {95,'1x'};   % 高度加高以容纳日志
%             gl.Padding = [3 3 3 3];
% 
%             tb = uigridlayout(gl,[2 5]);
%             tb.RowHeight = {25,55};     % 第二行用于日志
%             tb.ColumnWidth = {100,100,100,100,'1x'};
%             tb.Padding = [0 0 0 0];
%             
%             app.AutoButton   = uibutton(tb,'Text','自动优化','Enable','off', ...
%                 'ButtonPushedFcn',@(s,e) app.onAutoOptimize());
%             app.ManualButton = uibutton(tb,'Text','手动优化','Enable','off', ...
%                 'ButtonPushedFcn',@(s,e) app.onManualOptimize());
%             app.StopButton   = uibutton(tb,'Text','停止', ...
%                 'ButtonPushedFcn',@(s,e) app.onStop());
%             app.OutDirLabel  = uilabel(tb,'Text','输出：未选');
%             app.OutDirLabel.Layout.Row = 1; app.OutDirLabel.Layout.Column = 4;
%             uibutton(tb,'Text','输出目录','ButtonPushedFcn',@(s,e) app.onOutDir());
%             
%             % 用多行文本框替换进度条作为日志
%             app.LogTextArea = uitextarea(tb,'Editable','off','Value',{'就绪'}, ...
%                 'FontName','Microsoft YaHei','FontSize',10);
%             app.LogTextArea.Layout.Row = 2; 
%             app.LogTextArea.Layout.Column = [1 5];
%             app.StatusLabel = uilabel(tb, 'Visible', 'off'); % 隐藏旧标签
% 
%             app.TabGroup = uitabgroup(gl);
%             app.buildTab1(); app.buildTab2(); app.buildTab3(); app.buildTab4();
%         end

        function buildTab1(app)
            tab = uitab(app.TabGroup,'Title','模型');
            main = uigridlayout(tab,[1 2]);
            main.ColumnWidth = {430,'1x'};
            main.Padding = [4 2 4 2];

            left = uigridlayout(main,[22 4]);
            left.ColumnWidth = {100,100,100,100};
            left.RowHeight = repmat({20},1,22);
            left.Padding = [0 0 0 0];
            left.Layout.Column = 1;

            uilabel(left,'Text','第一层文件');
%             app.Layer1Edit = uieditfield(left,'Text','Value','','ValueChangedFcn',@(s,e) app.updateButtonState());
            app.Layer1Edit = uieditfield(left,'Text','Value','','ValueChangedFcn',@(s,e) app.updateButtonState(), ...
    'Layout', matlab.ui.layout.GridLayoutOptions('Row', 1, 'Column', [2 3]));
            
            uibutton(left,'Text','选择','ButtonPushedFcn',@(s,e) app.pickFile(app.Layer1Edit,'*.txt'));
            

            uilabel(left,'Text','第二层文件');
            app.Layer2Edit = uieditfield(left,'Text','Value','','ValueChangedFcn',@(s,e) app.updateButtonState(),...
    'Layout', matlab.ui.layout.GridLayoutOptions('Row', 2, 'Column', [2 3]));
            
            
            uibutton(left,'Text','选择','ButtonPushedFcn',@(s,e) app.pickFile(app.Layer2Edit,'*.txt'));
           

            app.Layer3Check = uicheckbox(left,'Text','启用第三层','Value',false, ...
                'ValueChangedFcn',@(s,e) app.onLayer3Toggle());
            app.Layer3Edit = uieditfield(left,'Text','Value','','Enable','off', ...
                'ValueChangedFcn',@(s,e) app.updateButtonState(),...
    'Layout', matlab.ui.layout.GridLayoutOptions('Row', 3, 'Column', [2 3]));
            app.L3PickButton = uibutton(left,'Text','选择','Enable','off', ...
                'ButtonPushedFcn',@(s,e) app.pickFile(app.Layer3Edit,'*.txt'));
         
            
            uilabel(left,'Text','炮点文件');
            app.ShotEdit = uieditfield(left,'Text','Value','','ValueChangedFcn',@(s,e) app.updateButtonState(),...
    'Layout', matlab.ui.layout.GridLayoutOptions('Row', 4, 'Column', [2 3]));
            uibutton(left,'Text','选择','ButtonPushedFcn',@(s,e) app.pickFile(app.ShotEdit,'*.txt'));
           
            
            uilabel(left,'Text','检波点文件');
            app.RecEdit = uieditfield(left,'Text','Value','','ValueChangedFcn',@(s,e) app.updateButtonState(),...
    'Layout', matlab.ui.layout.GridLayoutOptions('Row', 5, 'Column', [2 3]));
            uibutton(left,'Text','选择','ButtonPushedFcn',@(s,e) app.pickFile(app.RecEdit,'*.txt'));
            
            
            uilabel(left,'Text','模型层速度','FontSize',13,'FontWeight','bold'); uilabel(left,'Text','');
            uilabel(left,'Text','');
            
            uibutton(left,'Text','预览模型','FontSize',12,'FontWeight','bold','ButtonPushedFcn',@(s,e) app.onPreview());
            
            uilabel(left,'Text','v1'); app.V1Edit = uieditfield(left,'numeric','Value',2500,'ValueChangedFcn',@(s,e) app.updateButtonState());
            uilabel(left,'Text','v2'); app.V2Edit = uieditfield(left,'numeric','Value',2800,'ValueChangedFcn',@(s,e) app.updateButtonState());
            uilabel(left,'Text','v3'); app.V3Edit = uieditfield(left,'numeric','Value',3200,'ValueChangedFcn',@(s,e) app.updateButtonState());
            uilabel(left,'Text','v4'); app.V4Edit = uieditfield(left,'numeric','Value',3500,'Enable','off','ValueChangedFcn',@(s,e) app.updateButtonState());
            
            uilabel(left,'Text','观测系统参数','FontSize',13,'FontWeight','bold'); uilabel(left,'Text','');uilabel(left,'Text','');uilabel(left,'Text','');
            uilabel(left,'Text','道距'); app.RintEdit = uieditfield(left,'numeric','Value',25,'ValueChangedFcn',@(s,e) app.updateButtonState());
            uilabel(left,'Text','炮距'); app.SintEdit = uieditfield(left,'numeric','Value',100,'ValueChangedFcn',@(s,e) app.onSintChanged());
            uilabel(left,'Text','最大偏移距'); app.MaxoffEdit = uieditfield(left,'numeric','Value',2500,'ValueChangedFcn',@(s,e) app.updateButtonState());
            uilabel(left,'Text','');
            uilabel(left,'Text','');
            
            uilabel(left,'Text','稀疏参数','FontSize',13,'FontWeight','bold'); uilabel(left,'Text','');uilabel(left,'Text','');uilabel(left,'Text','');
            uilabel(left,'Text','两层 面元放大倍数'); app.Bin2Edit = uieditfield(left,'numeric','Value',4);
            uilabel(left,'Text','炮距放大倍数'); app.ShotF2Edit = uieditfield(left,'numeric','Value',2);
            uilabel(left,'Text','道距放大倍数'); app.RecFEdit = uieditfield(left,'numeric','Value',8);
            uilabel(left,'Text','');
            uilabel(left,'Text','');
            
            uilabel(left,'Text','三层 面元放大倍数'); app.Bin3Edit = uieditfield(left,'numeric','Value',8);
            uilabel(left,'Text','炮距放大倍数'); app.ShotF3Edit = uieditfield(left,'numeric','Value',4);
            
            uilabel(left,'Text','加密权重选择','FontSize',13,'FontWeight','bold'); uilabel(left,'Text','');uilabel(left,'Text','');uilabel(left,'Text','');
            uilabel(left,'Text','反演炮数权重'); app.CntWEdit = uieditfield(left,'numeric','Value',3);
            uilabel(left,'Text','覆盖次数变化影响'); app.FoldOffEdit = uieditfield(left,'numeric','Value',4);
            uilabel(left,'Text','炮点数量控制'); app.NmaxEdit = uieditfield(left,'numeric','Value',1.05);
            uilabel(left,'Text',''); uilabel(left,'Text','');
            
            uilabel(left,'Text','加密门槛'); app.DenseHiEdit = uieditfield(left,'numeric','Value',1.05);
            uilabel(left,'Text','稀疏门槛'); app.DenseLoEdit = uieditfield(left,'numeric','Value',0.95);
            
            uilabel(left,'Text','优化参数','FontSize',13,'FontWeight','bold'); uilabel(left,'Text','');uilabel(left,'Text','');uilabel(left,'Text','');
            uilabel(left,'Text','Dense步长'); app.DenseStepEdit = uieditfield(left,'numeric','Value',50);
            uilabel(left,'Text','Sparse步长'); app.SparseStepEdit = uieditfield(left,'numeric','Value',200);
            uilabel(left,'Text','Normal步长'); app.NormalStepEdit = uieditfield(left,'numeric','Value',100);
            
            right = uigridlayout(main,[1 1]);
            right.Layout.Column = 2;
            app.ModelAxes = uiaxes(right);
        end

        function buildTab2(app)
            tab = uitab(app.TabGroup,'Title','正演');
            main = uigridlayout(tab,[1 2]);
            main.ColumnWidth = {180,'1x'};
            main.Padding = [4 4 4 4];
            left = uigridlayout(main,[4 1]);
            left.RowHeight = {28,28,30,'1x'};
            left.Layout.Column = 1;
            uilabel(left,'Text','选择层：');
            app.LayerDropDown = uidropdown(left,'Items',{'1','2','3'},'Value','1');
            uibutton(left,'Text','正演运算','ButtonPushedFcn',@(s,e) app.onForward());
            right = uigridlayout(main,[1 1]);
            right.Layout.Column = 2;
            app.FoldAxes = uiaxes(right);
        end

        function buildTab3(app)
            tab = uitab(app.TabGroup,'Title','反演+优化');
            main = uigridlayout(tab,[1 2]);
            main.ColumnWidth = {180,'1x'};
            main.Padding = [4 4 4 4];
            left = uigridlayout(main,[6 1]);
            left.RowHeight = {32,32,32,32,28,'1x'};
            left.Layout.Column = 1;
            uibutton(left,'Text','反演运算','ButtonPushedFcn',@(s,e) app.onInversion());
            uibutton(left,'Text','自动优化','ButtonPushedFcn',@(s,e) app.onOptimize());
            uibutton(left,'Text','输出自动优化点','ButtonPushedFcn',@(s,e) app.onWriteCSV());
            uibutton(left,'Text','输入手动优化点','ButtonPushedFcn',@(s,e) app.onPickManualTxt());
            app.ManualTxtLabel = uilabel(left,'Text','手动优化点：未选');
            right = uigridlayout(main,[1 1]);
            right.Layout.Column = 2;
            app.OptAxes = uiaxes(right);
        end

        function buildTab4(app)
            tab = uitab(app.TabGroup,'Title','对比');
            main = uigridlayout(tab,[1 2]);
            main.ColumnWidth = {180,'1x'};
            main.Padding = [4 4 4 4];
            left = uigridlayout(main,[2 1]);
            left.RowHeight = {32,'1x'};
            left.Layout.Column = 1;
            uibutton(left,'Text','优化点正演','ButtonPushedFcn',@(s,e) app.onOptForward());
            right = uigridlayout(main,[1 1]);
            right.Layout.Column = 2;
            app.CompareAxes = uiaxes(right);
        end

        %% ================= 辅助函数 =================
        function addLog(app, msg)
            t = datetime('now', 'Format', 'HH:mm:ss');
            newLog = [char(t) ' - ' msg];
            oldVal = app.LogTextArea.Value;
            if ischar(oldVal), oldVal = {oldVal}; end
            newVal = [oldVal; {newLog}];
            if length(newVal) > 6
                newVal = newVal(end-5:end); % 保留最近6行
            end
            app.LogTextArea.Value = newVal;
            drawnow limitrate;
        end

        function pickFile(app, editField, filter)
            [f,p] = uigetfile(filter, '选择文件', app.OutDir);
            if isequal(f,0), return; end
            editField.Value = fullfile(p,f);
            app.updateButtonState();
        end

        function p = resolvePath(app, fname)
            if isempty(fname), p = ''; return; end
            if exist(fname,'file') == 2, p = fname;
            elseif ~isempty(app.OutDir) && exist(fullfile(app.OutDir, fname),'file') == 2
                p = fullfile(app.OutDir, fname);
            else, p = fname; end
        end

        function [cfg, optParam] = readCfg(app)
            run('model_config.m');
            cfg = cfg2;
            cfg.layerFiles = {app.resolvePath(app.Layer1Edit.Value), ...
                              app.resolvePath(app.Layer2Edit.Value)};
            if app.Layer3Check.Value
                cfg.layerFiles{end+1} = app.resolvePath(app.Layer3Edit.Value);
                cfg.v = [app.V1Edit.Value, app.V2Edit.Value, app.V3Edit.Value, app.V4Edit.Value];
            else
                cfg.v = [app.V1Edit.Value, app.V2Edit.Value, app.V3Edit.Value];
            end
            cfg.rint = app.RintEdit.Value; cfg.sint = app.SintEdit.Value;
            cfg.maxoff = app.MaxoffEdit.Value;
            cfg.shotFile = app.resolvePath(app.ShotEdit.Value);
            cfg.recFile  = app.resolvePath(app.RecEdit.Value);
            cfg.coarse = struct('binFactor2',app.Bin2Edit.Value,'binFactor3',app.Bin3Edit.Value, ...
                                'shotFactor2',app.ShotF2Edit.Value,'shotFactor3',app.ShotF3Edit.Value, ...
                                'recFactor',app.RecFEdit.Value,'enable',true);
            optParam = struct('foldTargetOffset',app.FoldOffEdit.Value,'cntWeight',app.CntWEdit.Value, ...
                              'nmaxFactor',app.NmaxEdit.Value,'denseThrHi',app.DenseHiEdit.Value, ...
                              'denseThrLo',app.DenseLoEdit.Value,'smoothWin',7,'winLen',1000, ...
                              'denseStep',app.DenseStepEdit.Value,'sparseStep',app.SparseStepEdit.Value, ...
                              'normalStep',app.NormalStepEdit.Value);
            app.Cfg = cfg; app.OptParam = optParam;
        end

        function updateButtonState(app)
            app.AutoButton.Enable = ternary(app.checkAutoReady(), 'on','off');
            app.ManualButton.Enable = ternary(app.checkManualReady(), 'on','off');
            if ~app.checkAutoReady()
                app.StatusLabel.Text = ['未就绪（自动）：' app.autoMissing()];
            elseif isempty(app.ManualShotFile)
                app.StatusLabel.Text = '自动已就绪；手动需先自动优化 + 选炮点txt';
            elseif isempty(app.FoldOrig)
                app.StatusLabel.Text = '就绪（自动），手动需先跑自动优化';
            else
                [~, fn, ext] = fileparts(app.ManualShotFile);
                app.StatusLabel.Text = ['就绪：可自动优化 / 手动优化（txt：' fn ext '）'];
            end
        end

        function ok = checkAutoReady(app)
            ok = false;
            files = {app.Layer1Edit.Value, app.Layer2Edit.Value, app.ShotEdit.Value, app.RecEdit.Value};
            for i = 1:numel(files)
                if isempty(files{i}) || ~isfile(files{i}), return; end
            end
            if app.Layer3Check.Value && (isempty(app.Layer3Edit.Value) || ~isfile(app.Layer3Edit.Value)), return; end
            if isempty(app.OutDir) || ~isfolder(app.OutDir), return; end
            nLayer = 2 + double(app.Layer3Check.Value);
            v = [app.V1Edit.Value, app.V2Edit.Value, app.V3Edit.Value];
            if app.Layer3Check.Value, v(end+1) = app.V4Edit.Value; end
            if numel(v) < nLayer+1, return; end
            ok = true;
        end

        function ok = checkManualReady(app)
            ok = ~isempty(app.FoldOrig) && ~isempty(app.ManualShotFile) && ...
                 ~isempty(app.OutDir) && isfile(app.ManualShotFile) && ~isempty(app.Model);
        end

        function msg = autoMissing(app)
            if isempty(app.Layer1Edit.Value) || ~isfile(app.Layer1Edit.Value), msg='缺第一层文件'; return; end
            if isempty(app.Layer2Edit.Value) || ~isfile(app.Layer2Edit.Value), msg='缺第二层文件'; return; end
            if app.Layer3Check.Value && (isempty(app.Layer3Edit.Value) || ~isfile(app.Layer3Edit.Value)), msg='缺第三层文件'; return; end
            if isempty(app.ShotEdit.Value) || ~isfile(app.ShotEdit.Value), msg='缺炮点文件'; return; end
            if isempty(app.RecEdit.Value) || ~isfile(app.RecEdit.Value), msg='缺检波点文件'; return; end
            if isempty(app.OutDir) || ~isfolder(app.OutDir), msg='缺输出目录'; return; end
            msg='参数不合法';
        end

        function onSintChanged(app)
             app.FoldOrig = {}; app.Model = struct(); app.updateButtonState();
        end

        %% ================= 回调 =================
        function onLayer3Toggle(app)
            v = app.Layer3Check.Value;
            if v
                app.Layer3Edit.Enable = 'on'; app.V4Edit.Enable = 'on'; app.L3PickButton.Enable = 'on';
            else
                app.Layer3Edit.Enable = 'off'; app.V4Edit.Enable = 'off'; app.L3PickButton.Enable = 'off';
            end
            app.updateButtonState();
        end

        function onOutDir(app)
            d = uigetdir(app.OutDir,'选择输出目录');
            if isequal(d,0), return; end
            app.OutDir = d; app.OutDirLabel.Text = ['输出：' d]; app.updateButtonState();
        end

        function onPickManualTxt(app)
            [f,p] = uigetfile('*.txt','选择炮点 txt', app.OutDir);
            if isequal(f,0), return; end
            app.ManualShotFile = fullfile(p,f);
            app.ManualTxtLabel.Text = ['手动txt：' f]; app.updateButtonState();
        end
 
        function onPreview(app)
            try
                app.readCfg();
                cfg = app.Cfg; cfg.coarseEnable = false;
                app.Model = buildModel(cfg);
                ax = app.ModelAxes; cla(ax); hold(ax,'on');
                layers = app.Model.layers;
                for i = 1:app.Model.nLayerFile
                    plot(ax, layers(i).x, layers(i).y, '-','LineWidth',1.5);
                end
                xlabel(ax,'Inline (m)'); ylabel(ax,'Depth (m)');
                title(ax, sprintf('模型：%d 层', app.Model.nLayerFile)); grid(ax,'on');
                app.addLog('模型预览成功');
            catch ME
                rethrow(ME); 
            end
        end       

        function onForward(app)
            try
                app.readCfg(); app.addLog('开始第1层正演...');
                cfg = app.Cfg; cfg.coarseEnable = false;
                Model = buildModel(cfg);
                L = str2double(app.LayerDropDown.Value);
                [Path, ~] = traceAll(Model, 'forward', L, []);
                Fold = foldStat(Path, Model, L);
                ax = app.FoldAxes; cla(ax); plot(ax, Fold.x, Fold.n, '-b','LineWidth',1.2);
                xlabel(ax,'Inline (m)'); ylabel(ax,'Folds'); grid(ax,'on');
                title(ax, sprintf('第 %d 层 Fold', L));
                app.addLog('正演完成');
            catch ME
                uialert(app.UIFigure, ME.message, '错误');
            end
        end

        function onInversion(app)
            try
                app.readCfg(); app.addLog('开始跑反演...');
                cfg = app.Cfg; cfg.coarseEnable = true;
                ModelInv = buildModel(cfg);
                nL = ModelInv.nLayerFile;
                app.ShotInv = cell(1,nL);
                for L = 1:nL
                    [PathInv, ~] = traceAll(ModelInv, 'inversion', L, []);
                    app.ShotInv{L} = sort(arrayfun(@(p) p.shot(1), PathInv));
                end
                app.addLog('反演完成');
            catch ME
                uialert(app.UIFigure, ME.message, '错误');
            end
        end

        function onOptimize(app)
            try
                if isempty(app.ShotInv), error('请先跑反演'); end
                app.addLog('开始计算优化炮点...');
                cfg = app.Cfg; cfg.coarseEnable = true;
                app.Model = buildModel(cfg);
                app.FoldOrig = cell(1,app.Model.nLayerFile);
                for L = 1:app.Model.nLayerFile
                    [Path, ~] = traceAll(app.Model, 'forward', L, []);
                    app.FoldOrig{L} = foldStat(Path, app.Model, L);
                end
                [shotOpt, optInfo] = runOptimizeFunc(app.ShotInv, app.FoldOrig, app.Model, app.OptParam, app.SintEdit.Value);
                app.ShotOpt = shotOpt; app.OptInfo = optInfo;
                app.plotOpt(optInfo);
                app.addLog(sprintf('优化完成，生成炮点 %d 个', numel(shotOpt)));
                app.updateButtonState();
            catch ME
                uialert(app.UIFigure, ME.message, '错误');
            end
        end

        function onWriteCSV(app)
            try
                if isempty(app.ShotOpt), error('请先优化'); end
                if isempty(app.OutDir), error('请先选输出目录'); end
                f = fullfile(app.OutDir,'shot_opt.csv');
                writematrix([app.ShotOpt(:), zeros(size(app.ShotOpt(:)))], f);
                app.addLog(['已写入 ' f]);
            catch ME
                uialert(app.UIFigure, ME.message, '错误');
            end
        end

        function onOptForward(app)
            try
                if isempty(app.ShotOpt), error('请先优化或读入炮点'); end
                if isempty(app.OutDir), error('请先选输出目录'); end
                app.addLog('开始优化后正演验证...');
                f = fullfile(app.OutDir,'shot_opt.csv');
                writematrix([app.ShotOpt(:), zeros(size(app.ShotOpt(:)))], f);
                cfg = app.Cfg; cfg.coarseEnable = true; cfg.shotFile = f;
                ModelOpt = buildModel(cfg);
                nL = ModelOpt.nLayerFile;
                app.FoldOpt = cell(1,nL);
                for L = 1:nL
                    [Path, ~] = traceAll(ModelOpt, 'forward', L, []);
                    app.FoldOpt{L} = foldStat(Path, ModelOpt, L);
                end
                compare3layerFunc(app.FoldOrig, app.FoldOpt, app.CompareAxes);
                app.addLog('对比图已生成');
            catch ME
                uialert(app.UIFigure, ME.message, '错误');
            end
        end

        function onAutoOptimize(app)
            try
                app.readCfg(); 
                app.addLog('开始自动优化...');
                cfg = app.Cfg; cfg.coarseEnable = true;
                Model = buildModel(cfg);
                nL = Model.nLayerFile;
                app.FoldOrig = cell(1,nL);
                for L = 1:nL
                    [Path, ~] = traceAll(Model, 'forward', L, []);
                    app.FoldOrig{L} = foldStat(Path, Model, L);
                end
                app.ShotInv = cell(1,nL);
                for L = 1:nL
                    [PathInv, ~] = traceAll(Model, 'inversion', L, []);
                    app.ShotInv{L} = sort(arrayfun(@(p) p.shot(1), PathInv));
                end
                [shotOpt, optInfo] = runOptimizeFunc(app.ShotInv, app.FoldOrig, Model, app.OptParam, app.SintEdit.Value);
                app.ShotOpt = shotOpt; app.OptInfo = optInfo;
                app.plotOpt(optInfo);
                f = fullfile(app.OutDir,'shot_opt.csv');
                writematrix([shotOpt(:), zeros(size(shotOpt(:)))], f);
                
                cfg.shotFile = f;
                ModelOpt = buildModel(cfg);
                app.FoldOpt = cell(1,nL);
                for L = 1:nL
                    [Path, ~] = traceAll(ModelOpt, 'forward', L, []);
                    app.FoldOpt{L} = foldStat(Path, ModelOpt, L);
                end
                compare3layerFunc(app.FoldOrig, app.FoldOpt, app.CompareAxes);
                app.addLog('自动优化完成，对比图已生成');
                app.updateButtonState();
            catch ME
                rethrow(ME);
            end
        end
        
        function onManualOptimize(app)
            try
                 if isempty(app.ManualShotFile), error('请先选炮点 txt'); end
                 if isempty(app.Model) || isempty(app.Model.shots), error('请先跑自动优化或预览模型'); end
                 app.addLog('开始手动优化验证...');
                 data = importdata(app.ManualShotFile);        
                 if isstruct(data), data = data.data; end
                 sint = app.SintEdit.Value;
                 x = round(data(:,1)/sint)*sint;
                 sStart = min(app.Model.shots(:,1)); sEnd = max(app.Model.shots(:,1));
                 x = unique(x(x>=sStart & x<=sEnd));
                 app.ShotOpt = x;
                 f = fullfile(app.OutDir,'shot_opt.csv');
                 writematrix([x(:), zeros(size(x(:)))], f);
                 
                 cfg = app.Cfg; cfg.coarseEnable = true; cfg.shotFile = f;
                 ModelOpt = buildModel(cfg);
                 nL = ModelOpt.nLayerFile;
                 app.FoldOpt = cell(1,nL);
                 for L = 1:nL
                     [Path, ~] = traceAll(ModelOpt, 'forward', L, []);
                     app.FoldOpt{L} = foldStat(Path, ModelOpt, L);
                 end
                 compare3layerFunc(app.FoldOrig, app.FoldOpt, app.CompareAxes);
                 [~, fn, ext] = fileparts(app.ManualShotFile);
                 app.addLog(['手动优化验证完成：' fn ext]);
            catch ME
                 uialert(app.UIFigure, ME.message, '错误');
            end
        end

        function onStop(app)
            app.CancelFlag = true;
            app.addLog('已发出停止请求，等待当前计算结束...');
        end

        function plotOpt(app, optInfo)
            ax = app.OptAxes;
            delete(ax.Children); 
            hold(ax, 'on');

            colors = {[0.3 0.5 0.9], [0.9 0.5 0.3], [0.4 0.8 0.4]}; 
            nL = numel(optInfo.cnt);
            cnt_mat = zeros(numel(optInfo.centers), nL);
            for L = 1:nL
                cnt_mat(:, L) = optInfo.cnt{L};
            end
            
            % 左侧 Y 轴（柱子）
            hBar = bar(ax, optInfo.centers, cnt_mat, 'grouped');
            for L = 1:nL
                hBar(L).FaceColor = colors{min(L,3)};
                hBar(L).EdgeColor = 'none'; 
            end
            xlim(ax, [min(optInfo.centers), max(optInfo.centers)]);
            ylabel(ax, '原始反演 Count');
            hFold = plot(ax, [min(optInfo.centers) max(optInfo.centers)], ...
                     [optInfo.foldTarget optInfo.foldTarget], '--m', 'LineWidth', 1.5);

            % 右侧 Y 轴（趋势线）
            yyaxis(ax, 'right');
            max_val = max(optInfo.cntW_s) * 1.1;
            min_val = min(optInfo.cntW_s) * 0.9;
            if max_val == min_val, max_val = min_val + 1; end
            ylim(ax, [min_val, max_val]);
            
            hSmooth = plot(ax, optInfo.centers, optInfo.cntW_s, '-k', 'LineWidth', 2);
            hDenseLine = plot(ax, optInfo.centers, optInfo.baseLocal_s*app.OptParam.denseThrHi, '--r', 'LineWidth', 1.5);
            hSparseLine = plot(ax, optInfo.centers, optInfo.baseLocal_s*app.OptParam.denseThrLo, '--g', 'LineWidth', 1.5);
            
            ax.YAxis(2).Color = 'k'; 
            ylabel(ax, '加权平滑 Count', 'Color', 'k');

            % 图例
            legItems = cell(1, nL);
            for L = 1:nL
                legItems{L} = sprintf('Layer %d Count', L);
            end
            hLeg = [hBar(:)', hFold, hSmooth, hDenseLine, hSparseLine];
            legNames = [legItems, {'foldTarget (目标基线)', '加权平滑 Count', ...
                                    'Dense 门槛 (1.05×base)', 'Sparse 门槛 (0.95×base)'}];
            legend(ax, hLeg, legNames, 'Location', 'northwest');
            
            grid(ax, 'on'); zoom(ax, 'on'); pan(ax, 'on');
            title(ax, '反演 Count 对比与优化区间');
        end
    end
end

function s = ternary(c,a,b)
if c, s=a; else, s=b; end
end