function printRuns(centers, mask, name)
% 打印连续 true 的区间，如 "=== Dense ===\n  [4525, 4925]\n"
if nargin < 3, name = ''; end
if ~any(mask)
    fprintf('=== %s ===\n  （无）\n', name);
    return;
end
fprintf('=== %s ===\n', name);
d = diff([0; mask(:); 0]);
starts = find(d==1);  ends = find(d==-1)-1;
for i = 1:numel(starts)
    fprintf('  [%.0f, %.0f]\n', centers(starts(i)), centers(ends(i)));
end
end