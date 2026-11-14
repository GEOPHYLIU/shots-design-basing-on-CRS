% function plotOpt(app, optInfo)
%     ax = app.OptAxes;
%     delete(ax.Children);
%     hold(ax,'on');
%     colors = {'b','r','g'};
%     for L = 1:numel(optInfo.cnt)
%         plot(ax, optInfo.centers, optInfo.cnt{L}, '-', ...
%             'Color', colors{min(L,3)}, 'LineWidth', 1.2);
%     end
%     plot(ax, optInfo.centers, optInfo.cntW_s, '-k', 'LineWidth', 2);
%     plot(ax, optInfo.centers, optInfo.baseLocal_s*optInfo.denseThrHi, '--r', 'LineWidth', 1.2);
%     plot(ax, optInfo.centers, optInfo.baseLocal_s*optInfo.denseThrLo, '--g', 'LineWidth', 1.2);
%     plot(ax, [min(optInfo.centers) max(optInfo.centers)], ...
%              [optInfo.foldTarget optInfo.foldTarget], '--m', 'LineWidth', 1.5);
%     if any(optInfo.isDense)
%         plot(ax, optInfo.centers(optInfo.isDense), optInfo.cntW_s(optInfo.isDense), ...
%              'rv', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
%     end
%     if any(optInfo.isSparse)
%         plot(ax, optInfo.centers(optInfo.isSparse), optInfo.cntW_s(optInfo.isSparse), ...
%              'g^', 'MarkerFaceColor', 'g', 'MarkerSize', 8);
%     end
%     xlabel(ax, '炮点位置 (m)');
%     ylabel(ax, 'Count');
%     title(ax, '优化图（红：Dense；绿：Sparse；品红：foldTarget）');
%     grid(ax, 'on');
%     zoom(ax, 'on');
%     pan(ax, 'on');
% end
        function plotOpt(app, optInfo)
            ax = app.OptAxes;
            delete(ax.Children); % 清空坐标轴
            hold(ax, 'on');

            % 准备颜色，为了和原来的线色对应，这里稍微调亮
            colors = {[0.3 0.5 0.9], [0.9 0.5 0.3], [0.4 0.8 0.4]}; 
            nL = numel(optInfo.cnt);

            % 1. 拼接不同层的 cnt，并画并列柱状图 (Grouped Bar)
            cnt_mat = zeros(numel(optInfo.centers), nL);
            for L = 1:nL
                cnt_mat(:, L) = optInfo.cnt{L};
            end
            
            % 画 bar，如果不支持 BarWidth 参数可以去掉
            hBar = bar(ax, optInfo.centers, cnt_mat, 'grouped');
            for L = 1:nL
                hBar(L).FaceColor = colors{min(L,3)};
                hBar(L).EdgeColor = 'none'; % 去掉边框更清爽
            end
            
            % 取消 X 轴缩放，防止柱子和线错位
            xlim(ax, [min(optInfo.centers), max(optInfo.centers)]);

            % 2. 使用右侧 Y 轴画趋势线（避免和柱子比例冲突）
            yyaxis(ax, 'right');
            % 平滑加权线（黑色实线）
            plot(ax, optInfo.centers, optInfo.cntW_s, '-k', 'LineWidth', 2);
            % 阈值虚线（红/绿）
            plot(ax, optInfo.centers, optInfo.baseLocal_s*app.OptParam.denseThrHi, '--r', 'LineWidth', 1.5);
            plot(ax, optInfo.centers, optInfo.baseLocal_s*app.OptParam.denseThrLo, '--g', 'LineWidth', 1.5);
            
            % 将右侧 Y 轴颜色设为黑色，不干扰左侧
            ax.YAxis(2).Color = 'k'; 
            ylabel(ax, '加权平滑 Count', 'Color', 'k');

            % 3. 在左轴画 foldTarget 品红色水平线
            yyaxis(ax, 'left');
            plot(ax, [min(optInfo.centers) max(optInfo.centers)], ...
                     [optInfo.foldTarget optInfo.foldTarget], '--m', 'LineWidth', 1.5);

            % 4. 在左轴标出 Dense 和 Sparse 的关键点
            % 为了避免标记遮挡柱子，如果是在柱顶画，可以适当取值，或者不画标记，只靠底部的颜色区分
            % 这里保留原版的三角标记（压在柱子上）
            if any(optInfo.isDense)
                plot(ax, optInfo.centers(optInfo.isDense), optInfo.cntW_s(optInfo.isDense), ...
                     'rv', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'LineStyle', 'none');
            end
            if any(optInfo.isSparse)
                plot(ax, optInfo.centers(optInfo.isSparse), optInfo.cntW_s(optInfo.isSparse), ...
                     'g^', 'MarkerFaceColor', 'g', 'MarkerSize', 8, 'LineStyle', 'none');
            end

            % 5. 设置标题、坐标轴标签
            xlabel(ax, '炮点位置 (m)');
            ylabel(ax, '原始反演 Count');
            title(ax, '反演 Count 对比与优化区间（红：Dense；绿：Sparse）');
            
            % 6. 生成图例
            legItems = cell(1, nL);
            for L = 1:nL
                legItems{L} = sprintf('Layer %d Count', L);
            end
            legItems{end+1} = '加权平滑 Count (右轴)';
            legItems{end+1} = 'Dense 门槛 (1.05×base)';
            legItems{end+1} = 'Sparse 门槛 (0.95×base)';
            legItems{end+1} = 'foldTarget';
            
            legend(ax, legItems, 'Location', 'northwest');
            grid(ax, 'on');
            zoom(ax, 'on');
            pan(ax, 'on');
        end