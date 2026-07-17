function [snapshot, paths] = capture_comsol_model_snapshot(model, outputBase, options)
%CAPTURE_COMSOL_MODEL_SNAPSHOT Capture a reviewable snapshot of a live model.
%   This function is read-only with respect to model settings. It writes a
%   MAT snapshot, a UTF-8 JSON snapshot, and (by default) a COMSOL-generated
%   MATLAB M-file copy. The M-file is useful when a generic property snapshot
%   cannot express the semantic meaning of a module-specific setting.

if nargin < 3 || isempty(options), options = struct(); end
options = set_default(options, 'exportMFile', true);
options = set_default(options, 'includeProperties', true);
options = set_default(options, 'maxFeatureDepth', 12);

validate_model(model);
if ~(ischar(outputBase) || (isstring(outputBase) && isscalar(outputBase)))
    error('CODEX:InvalidSnapshotPath', 'outputBase must be a character vector or scalar string.');
end
outputBase = char(outputBase);
[outputFolder, ~, ~] = fileparts(outputBase);
if isempty(outputFolder), outputFolder = pwd; end
if ~isfolder(outputFolder), mkdir(outputFolder); end

paths = struct( ...
    'mat', [outputBase '.mat'], ...
    'json', [outputBase '.json'], ...
    'mfile', [outputBase '_model_export.m']);

snapshot = struct();
snapshot.schemaVersion = '1.0';
snapshot.capturedAt = timestamp_text();
snapshot.matlabVersion = version;
snapshot.modelTag = char(model.tag());
snapshot.modelLabel = safe_text(@() model.label());
snapshot.parameters = capture_parameters(model);
snapshot.nodes = empty_nodes();
snapshot.coverage = { ...
    'parameters and descriptions'; ...
    'component, geometry, selection, material, physics, mesh, study, solver, dataset, result, numerical, table, and function tags'; ...
    'labels, feature types, readable properties, and readable selections'; ...
    'COMSOL-generated MATLAB M-file when exportMFile=true'};
snapshot.limitations = { ...
    'A generic API snapshot cannot guarantee semantic coverage of every module-specific GUI setting.'; ...
    'Volatile internal state may appear in properties and must be reviewed before resuming.'; ...
    'Boundary and domain IDs must be queried again after any geometry change.'};

snapshot.nodes = collect_model_nodes(model, snapshot.nodes, options);

snapshot.mfileExport = struct('requested', logical(options.exportMFile), ...
    'success', false, 'path', paths.mfile, 'error', '', 'warning', '');
if options.exportMFile
    try
        mphsave(model, paths.mfile, 'component', 'on', 'copy', 'on', 'store', 'off');
        snapshot.mfileExport.success = true;
        fileInfo = dir(paths.mfile);
        if numel(snapshot.nodes) > 5 && ~isempty(fileInfo) && fileInfo.bytes < 4096
            snapshot.mfileExport.warning = [ ...
                'The exported M-file is unusually small and may reflect disabled/incomplete model history. ' ...
                'Use the structured snapshot and targeted API queries as primary evidence.'];
        end
    catch ME
        snapshot.mfileExport.error = getReport(ME, 'extended', 'hyperlinks', 'off');
    end
end

save(paths.mat, 'snapshot');
write_utf8(paths.json, pretty_json(snapshot));
fprintf('CODEX_SNAPSHOT_MODEL_TAG: %s\n', snapshot.modelTag);
fprintf('CODEX_SNAPSHOT_NODE_COUNT: %d\n', numel(snapshot.nodes));
fprintf('CODEX_SNAPSHOT_JSON: %s\n', paths.json);
end

function parameters = capture_parameters(model)
template = struct('name', '', 'expression', '', 'description', '', 'unit', '');
parameters = repmat(template, 0, 1);
try
    names = java_strings(model.param.varnames());
catch
    names = {};
end
for index = 1:numel(names)
    name = names{index};
    item = template;
    item.name = name;
    item.expression = safe_text(@() model.param.get(name));
    item.description = safe_text(@() model.param.descr(name));
    item.unit = safe_text(@() model.param.evaluateUnit(name));
    parameters(end + 1, 1) = item; %#ok<AGROW>
end
end

function nodes = collect_model_nodes(model, nodes, options)
componentTags = safe_tags(@() model.component.tags());
for index = 1:numel(componentTags)
    componentTag = componentTags{index};
    component = model.component(componentTag);
    componentPath = ['component/' componentTag];
    nodes(end + 1, 1) = read_node(component, componentPath, 'component', options); %#ok<AGROW>

    nodes = collect_tagged_sequences(nodes, @() component.geom.tags(), ...
        @(tag) component.geom(tag), [componentPath '/geometry'], 'geometry', options);
    nodes = collect_tagged_sequences(nodes, @() component.selection.tags(), ...
        @(tag) component.selection(tag), [componentPath '/selection'], 'selection', options);
    nodes = collect_tagged_sequences(nodes, @() component.material.tags(), ...
        @(tag) component.material(tag), [componentPath '/material'], 'material', options);
    nodes = collect_tagged_sequences(nodes, @() component.physics.tags(), ...
        @(tag) component.physics(tag), [componentPath '/physics'], 'physics', options);
    nodes = collect_tagged_sequences(nodes, @() component.multiphysics.tags(), ...
        @(tag) component.multiphysics(tag), [componentPath '/multiphysics'], 'multiphysics', options);
    nodes = collect_tagged_sequences(nodes, @() component.mesh.tags(), ...
        @(tag) component.mesh(tag), [componentPath '/mesh'], 'mesh', options);
    nodes = collect_tagged_sequences(nodes, @() component.variable.tags(), ...
        @(tag) component.variable(tag), [componentPath '/variable'], 'variable', options);
    nodes = collect_tagged_sequences(nodes, @() component.func.tags(), ...
        @(tag) component.func(tag), [componentPath '/function'], 'function', options);
end

nodes = collect_tagged_sequences(nodes, @() model.study.tags(), ...
    @(tag) model.study(tag), 'model/study', 'study', options);
nodes = collect_tagged_sequences(nodes, @() model.sol.tags(), ...
    @(tag) model.sol(tag), 'model/solver', 'solver', options);
nodes = collect_tagged_sequences(nodes, @() model.result.dataset.tags(), ...
    @(tag) model.result.dataset(tag), 'model/dataset', 'dataset', options);
nodes = collect_tagged_sequences(nodes, @() model.result.tags(), ...
    @(tag) model.result(tag), 'model/result', 'result', options);
nodes = collect_tagged_sequences(nodes, @() model.result.numerical.tags(), ...
    @(tag) model.result.numerical(tag), 'model/numerical', 'numerical', options);
nodes = collect_tagged_sequences(nodes, @() model.result.table.tags(), ...
    @(tag) model.result.table(tag), 'model/table', 'table', options);
nodes = collect_tagged_sequences(nodes, @() model.func.tags(), ...
    @(tag) model.func(tag), 'model/function', 'function', options);
end

function nodes = collect_tagged_sequences(nodes, tagFunction, objectFunction, basePath, category, options)
tags = safe_tags(tagFunction);
for index = 1:numel(tags)
    tag = tags{index};
    try
        object = objectFunction(tag);
        objectPath = [basePath '/' tag];
        nodes(end + 1, 1) = read_node(object, objectPath, category, options); %#ok<AGROW>
        nodes = collect_children(nodes, object, objectPath, category, options, 1);
    catch ME
        warning('CODEX:SnapshotNodeSkipped', 'Skipped %s/%s: %s', basePath, tag, ME.message);
    end
end
end

function nodes = collect_children(nodes, parent, parentPath, category, options, depth)
if depth > options.maxFeatureDepth, return; end
try
    tags = java_strings(parent.feature.tags());
catch
    return;
end
for index = 1:numel(tags)
    tag = tags{index};
    try
        child = parent.feature(tag);
        childPath = [parentPath '/feature/' tag];
        nodes(end + 1, 1) = read_node(child, childPath, category, options); %#ok<AGROW>
        nodes = collect_children(nodes, child, childPath, category, options, depth + 1);
    catch ME
        warning('CODEX:SnapshotFeatureSkipped', 'Skipped %s/feature/%s: %s', parentPath, tag, ME.message);
    end
end
end

function node = read_node(object, path, category, options)
node = node_template();
node.path = path;
node.category = category;
node.tag = safe_text(@() object.tag());
node.label = safe_text(@() object.label());
node.type = safe_type(object);
if options.includeProperties
    node.properties = read_properties(object);
end
try
    node.selection = pretty_json(mphgetselection(object));
catch
    node.selection = '';
end
end

function properties = read_properties(object)
template = struct('name', '', 'value', '', 'valueType', '', 'readError', '');
properties = repmat(template, 0, 1);
try
    names = java_strings(object.properties());
catch
    return;
end
for index = 1:numel(names)
    name = names{index};
    if is_volatile_property(name), continue; end
    item = template;
    item.name = name;
    item.valueType = safe_text(@() object.getValueType(name));
    try
        item.value = char(object.getString(name));
    catch ME1
        try
            item.value = strjoin(java_strings(object.getStringArray(name)), '|');
        catch ME2
            item.readError = sprintf('%s | %s', ME1.message, ME2.message);
        end
    end
    properties(end + 1, 1) = item; %#ok<AGROW>
end
end

function tf = is_volatile_property(name)
% Confirmed COMSOL client/display state that can change merely by observing.
volatile = {'progressactive', 'hasbeenplotted', 'renderinfo', ...
    'ispendingzoom', 'needsstylerepaint', 'stylerepaintinprogress', ...
    'touchpostshow'};
tf = any(strcmpi(name, volatile));
end

function value = safe_type(object)
value = '';
try
    value = char(object.getType());
catch
    try
        value = char(object.type());
    catch
        value = class(object);
    end
end
end

function value = safe_text(functionHandle)
value = '';
try
    raw = functionHandle();
    if ischar(raw)
        value = raw;
    elseif isstring(raw)
        value = char(raw);
    elseif isnumeric(raw) || islogical(raw)
        value = mat2str(raw);
    else
        value = char(raw);
    end
catch
    value = '';
end
end

function tags = safe_tags(functionHandle)
try
    tags = java_strings(functionHandle());
catch
    tags = {};
end
end

function values = java_strings(javaValues)
if isempty(javaValues), values = {}; return; end
raw = cell(javaValues);
values = cellfun(@char, raw, 'UniformOutput', false);
end

function nodes = empty_nodes()
nodes = repmat(node_template(), 0, 1);
end

function node = node_template()
propertyTemplate = struct('name', '', 'value', '', 'valueType', '', 'readError', '');
node = struct('path', '', 'category', '', 'tag', '', 'label', '', ...
    'type', '', 'properties', repmat(propertyTemplate, 0, 1), 'selection', '');
end

function validate_model(model)
try
    tag = char(model.tag());
catch ME
    error('CODEX:InvalidModelObject', 'model must be a valid COMSOL model object: %s', ME.message);
end
if isempty(tag), error('CODEX:InvalidModelObject', 'The COMSOL model tag is empty.'); end
end

function value = set_default(value, fieldName, defaultValue)
if ~isfield(value, fieldName) || isempty(value.(fieldName))
    value.(fieldName) = defaultValue;
end
end

function text = pretty_json(value)
try
    text = jsonencode(value, 'PrettyPrint', true);
catch
    text = jsonencode(value);
end
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
