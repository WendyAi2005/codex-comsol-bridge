function report = compare_comsol_model_snapshots(beforeInput, afterInput, outputBase)
%COMPARE_COMSOL_MODEL_SNAPSHOTS Compare two captured live-model snapshots.
%   Writes <outputBase>.json and <outputBase>.md. This is an evidence aid,
%   not a guarantee that every COMSOL module-specific semantic setting is
%   covered. Ambiguous physics-affecting changes require targeted queries.

before = load_snapshot(beforeInput);
after = load_snapshot(afterInput);
if ~strcmp(before.modelTag, after.modelTag)
    error('CODEX:SnapshotModelMismatch', ...
        'Snapshot model tags differ: %s versus %s.', before.modelTag, after.modelTag);
end

beforeMap = snapshot_records(before);
afterMap = snapshot_records(after);
allKeys = unique([keys(beforeMap), keys(afterMap)]);
allKeys = sort(allKeys);
changeTemplate = struct('kind', '', 'category', '', 'key', '', 'before', '', 'after', '');
changes = repmat(changeTemplate, 0, 1);
for index = 1:numel(allKeys)
    key = allKeys{index};
    beforeExists = isKey(beforeMap, key);
    afterExists = isKey(afterMap, key);
    if beforeExists && afterExists
        beforeValue = beforeMap(key);
        afterValue = afterMap(key);
        if strcmp(beforeValue, afterValue), continue; end
        kind = 'changed';
    elseif beforeExists
        beforeValue = beforeMap(key);
        afterValue = '';
        kind = 'removed';
    else
        beforeValue = '';
        afterValue = afterMap(key);
        kind = 'added';
    end
    item = changeTemplate;
    item.kind = kind;
    item.category = category_from_key(key);
    item.key = key;
    item.before = beforeValue;
    item.after = afterValue;
    changes(end + 1, 1) = item; %#ok<AGROW>
end

categories = unique({changes.category});
[restartPoint, reviewRequired] = restart_recommendation(categories, changes);
report = struct();
report.schemaVersion = '1.0';
report.comparedAt = timestamp_text();
report.modelTag = before.modelTag;
report.beforeCapturedAt = before.capturedAt;
report.afterCapturedAt = after.capturedAt;
report.changeCount = numel(changes);
report.categories = categories;
report.restartPoint = restartPoint;
report.targetedReviewRequired = reviewRequired;
report.changes = changes;
report.limitation = ['Automatic diff covers captured parameters, tags, labels, readable properties, ' ...
    'and selections, plus the separately exported M-files. It cannot guarantee semantic coverage ' ...
    'of every module-specific GUI setting.'];

[folder, ~, ~] = fileparts(outputBase);
if ~isempty(folder) && ~isfolder(folder), mkdir(folder); end
write_utf8([outputBase '.json'], pretty_json(report));
write_utf8([outputBase '.md'], markdown_report(report));
fprintf('CODEX_MANUAL_CHANGE_COUNT: %d\n', report.changeCount);
fprintf('CODEX_RESTART_RECOMMENDATION: %s\n', report.restartPoint);
fprintf('CODEX_TARGETED_REVIEW_REQUIRED: %s\n', mat2str(report.targetedReviewRequired));
end

function snapshot = load_snapshot(inputValue)
if isstruct(inputValue)
    snapshot = inputValue;
    return;
end
path = char(inputValue);
if endsWith(path, '.json', 'IgnoreCase', true)
    snapshot = jsondecode(fileread(path));
else
    data = load(path, 'snapshot');
    if ~isfield(data, 'snapshot')
        error('CODEX:SnapshotMissing', '%s does not contain variable snapshot.', path);
    end
    snapshot = data.snapshot;
end
end

function records = snapshot_records(snapshot)
records = containers.Map('KeyType', 'char', 'ValueType', 'char');
records('model:label') = snapshot.modelLabel;
for index = 1:numel(snapshot.parameters)
    item = snapshot.parameters(index);
    records(['parameter:' item.name]) = pretty_json(struct( ...
        'expression', item.expression, 'description', item.description, 'unit', item.unit));
end
for index = 1:numel(snapshot.nodes)
    node = snapshot.nodes(index);
    records(['node:' node.path]) = pretty_json(struct( ...
        'category', node.category, 'tag', node.tag, 'label', node.label, 'type', node.type));
    if ~isempty(node.selection)
        records(['selection:' node.path]) = node.selection;
    end
    for propertyIndex = 1:numel(node.properties)
        property = node.properties(propertyIndex);
        records(['property:' node.path ':' property.name]) = pretty_json(struct( ...
            'value', property.value, 'valueType', property.valueType, 'readError', property.readError));
    end
end
end

function category = category_from_key(key)
if startsWith(key, 'parameter:')
    category = 'parameter';
elseif startsWith(key, 'model:')
    category = 'model';
elseif contains(key, '/geometry/')
    category = 'geometry';
elseif contains(key, '/selection/') || startsWith(key, 'selection:')
    category = 'selection';
elseif contains(key, '/material/')
    category = 'material';
elseif contains(key, '/physics/') || contains(key, '/multiphysics/')
    category = 'physics';
elseif contains(key, '/mesh/')
    category = 'mesh';
elseif contains(key, '/study/')
    category = 'study';
elseif contains(key, '/solver/')
    category = 'solver';
elseif contains(key, '/result/') || contains(key, '/dataset/') || ...
        contains(key, '/numerical/') || contains(key, '/table/')
    category = 'result';
else
    category = 'other';
end
end

function [restartPoint, reviewRequired] = restart_recommendation(categories, changes)
reviewRequired = false;
if isempty(changes)
    restartPoint = 'none';
    return;
end
if any(ismember(categories, {'geometry', 'selection'}))
    restartPoint = 'rebuild_geometry_requery_selections_mesh_study_results';
    reviewRequired = true;
elseif any(strcmp(categories, 'mesh'))
    restartPoint = 'rebuild_mesh_then_study_results';
elseif any(ismember(categories, {'material', 'physics'}))
    restartPoint = 'revalidate_domains_boundaries_units_then_study_results';
    reviewRequired = true;
elseif any(strcmp(categories, 'parameter'))
    restartPoint = 'classify_parameter_dependency_then_rebuild_from_earliest_affected_stage';
    reviewRequired = true;
elseif any(ismember(categories, {'study', 'solver'}))
    restartPoint = 'revalidate_study_solver_then_solve';
    reviewRequired = true;
elseif any(strcmp(categories, 'result'))
    restartPoint = 'update_results_no_solve_unless_expression_requires_new_solution';
else
    restartPoint = 'targeted_review_before_resume';
    reviewRequired = true;
end
end

function text = markdown_report(report)
lines = { ...
    '# Manual COMSOL change report / COMSOL 人工修改差异报告'; ...
    ''; ...
    ['- Model tag / 模型 tag: `' report.modelTag '`']; ...
    ['- Changes / 改动数: **' num2str(report.changeCount) '**']; ...
    ['- Restart recommendation / 建议续跑点: `' report.restartPoint '`']; ...
    ['- Targeted review required / 是否需定向复核: `' mat2str(report.targetedReviewRequired) '`']; ...
    ''; ...
    '> Automatic comparison is evidence, not a promise of complete semantic coverage. / 自动比较是证据，不保证覆盖所有模块专用语义。'; ...
    ''; ...
    '| Kind | Category | Key | Before | After |'; ...
    '|---|---|---|---|---|'};
for index = 1:numel(report.changes)
    item = report.changes(index);
    lines{end + 1, 1} = sprintf('| %s | %s | `%s` | %s | %s |', ... %#ok<AGROW>
        item.kind, item.category, escape_table(item.key), ...
        escape_table(shorten(item.before)), escape_table(shorten(item.after)));
end
text = strjoin(lines, newline);
end

function value = shorten(value)
value = regexprep(value, '[\r\n]+', ' ');
if strlength(value) > 220, value = [extractBefore(string(value), 218) '...']; end
value = char(value);
end

function value = escape_table(value)
value = strrep(char(value), '|', '\|');
end

function text = pretty_json(value)
try, text = jsonencode(value, 'PrettyPrint', true); catch, text = jsonencode(value); end
end

function write_utf8(filePath, textContent)
fileId = fopen(filePath, 'w', 'n', 'UTF-8');
if fileId < 0, error('CODEX:FileWriteFailed', 'Cannot write %s', filePath); end
cleanupObject = onCleanup(@() fclose(fileId)); %#ok<NASGU>
fprintf(fileId, '%s\n', textContent);
end

function value = timestamp_text()
value = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
end
