function info = comsol_visual_checkpoint(model, runDir, stage, config)
%COMSOL_VISUAL_CHECKPOINT Publish a verified observation/manual-edit state.
%   A checkpoint is editable only when checkpoint_state.json says PAUSED and
%   safeToEdit=true and Codex has explicitly told the user that editing is safe.
%   Resume requires an approval JSON written by
%   approve_comsol_checkpoint_resume; the user never creates flag files.

if nargin < 4 || isempty(config), config = struct(); end
config = set_default(config, 'plannedPauseStage', '');
config = set_default(config, 'observationSeconds', 3);
config = set_default(config, 'manualTimeoutSeconds', 1800);
config = set_default(config, 'checkpointLogPath', fullfile(runDir, 'checkpoints.csv'));
config = set_default(config, 'savePreEditModel', true);

modelTag = validate_model(model);
previousLabel = char(model.label());
runDir = char(runDir);
stage = char(stage);
if ~isfolder(runDir), mkdir(runDir); end

pauseRequestPath = fullfile(runDir, ['pause_at_' stage '.json']);
pauseRequested = strcmpi(stage, char(config.plannedPauseStage)) || isfile(pauseRequestPath);
timestamp = timestamp_text();

if pauseRequested
    model.label(['PAUSED - ' stage]);
    beforeBase = fullfile(runDir, ['snapshot_before_' stage]);
    [~, snapshotPaths] = capture_comsol_model_snapshot(model, beforeBase);
    preEditModelPath = fullfile(runDir, ['pre_edit_' stage '.mph']);
    if config.savePreEditModel
        mphsave(model, preEditModelPath, 'copy', 'on', 'store', 'off');
    else
        preEditModelPath = '';
    end
    state = make_state('PAUSED', true, stage, modelTag, char(model.label()), timestamp);
    state.beforeSnapshotMat = snapshotPaths.mat;
    state.beforeSnapshotJson = snapshotPaths.json;
    state.preEditModelPath = preEditModelPath;
    state.previousModelLabel = previousLabel;
    state.resumeApprovalPath = fullfile(runDir, ['approved_continue_' stage '.json']);
    write_state(runDir, state);
    append_checkpoint(config.checkpointLogPath, state);
    fprintf('CODEX_CHECKPOINT_STATUS: PAUSED\n');
    fprintf('CODEX_SAFE_TO_EDIT: true\n');
    fprintf('CODEX_CHECKPOINT_STAGE: %s\n', stage);
    fprintf('CODEX_CHECKPOINT_MODEL_TAG: %s\n', modelTag);
    fprintf('CODEX_WAITING_FOR_CODEX_APPROVAL: %s\n', state.resumeApprovalPath);

    waitTimer = tic;
    while ~isfile(state.resumeApprovalPath)
        pause(2);
        if toc(waitTimer) > config.manualTimeoutSeconds
            error('CODEX:ManualPauseTimeout', ...
                'No validated Codex resume approval within %.0f seconds at %s.', ...
                config.manualTimeoutSeconds, stage);
        end
    end
    approval = jsondecode(fileread(state.resumeApprovalPath));
    if ~isfield(approval, 'approved') || ~logical(approval.approved) || ...
            ~strcmp(char(approval.stage), stage) || ~strcmp(char(approval.modelTag), modelTag)
        error('CODEX:InvalidResumeApproval', ...
            'Resume approval must be approved and match stage/model tag.');
    end
    model.label(previousLabel);
    state = make_state('RESUMING', false, stage, modelTag, char(model.label()), timestamp_text());
    state.approval = approval;
    write_state(runDir, state);
    append_checkpoint(config.checkpointLogPath, state);
    fprintf('CODEX_CHECKPOINT_STATUS: RESUMING\n');
    fprintf('CODEX_SAFE_TO_EDIT: false\n');
else
    model.label(['CHECKPOINT - ' stage]);
    state = make_state('OBSERVATION_ONLY', false, stage, modelTag, ...
        char(model.label()), timestamp);
    write_state(runDir, state);
    append_checkpoint(config.checkpointLogPath, state);
    fprintf('CODEX_CHECKPOINT_STATUS: OBSERVATION_ONLY\n');
    fprintf('CODEX_SAFE_TO_EDIT: false\n');
    fprintf('CODEX_CHECKPOINT_STAGE: %s\n', stage);
    pause(config.observationSeconds);
end
info = state;
end

function state = make_state(status, safeToEdit, stage, modelTag, modelLabel, timestamp)
state = struct('schemaVersion', '1.0', 'status', status, ...
    'safeToEdit', logical(safeToEdit), 'stage', stage, ...
    'modelTag', modelTag, 'modelLabel', modelLabel, 'updatedAt', timestamp);
end

function write_state(runDir, state)
write_utf8(fullfile(runDir, 'checkpoint_state.json'), pretty_json(state));
end

function append_checkpoint(logPath, state)
if ~isfile(logPath)
    append_utf8(logPath, 'timestamp,status,safe_to_edit,stage,model_tag,model_label');
end
line = sprintf('%s,%s,%s,%s,%s,%s', state.updatedAt, state.status, ...
    mat2str(state.safeToEdit), state.stage, state.modelTag, state.modelLabel);
append_utf8(logPath, line);
end

function tag = validate_model(model)
try, tag = char(model.tag()); catch ME
    error('CODEX:InvalidModelObject', 'Invalid COMSOL model object: %s', ME.message);
end
if isempty(tag), error('CODEX:InvalidModelObject', 'The COMSOL model tag is empty.'); end
end

function value = set_default(value, fieldName, defaultValue)
if ~isfield(value, fieldName) || isempty(value.(fieldName)), value.(fieldName) = defaultValue; end
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

function append_utf8(filePath, textContent)
fileId = fopen(filePath, 'a', 'n', 'UTF-8');
if fileId < 0, error('CODEX:FileWriteFailed', 'Cannot append %s', filePath); end
cleanupObject = onCleanup(@() fclose(fileId)); %#ok<NASGU>
fprintf(fileId, '%s\n', textContent);
end

function value = timestamp_text()
value = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
end
