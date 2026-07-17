function approval = approve_comsol_checkpoint_resume(model, runDir, stage, validation)
%APPROVE_COMSOL_CHECKPOINT_RESUME Write a validated resume approval file.
%   The user never creates this file manually. Codex calls this function only
%   after capturing an after-edit snapshot, comparing it with the before-edit
%   snapshot, and completing any targeted COMSOL API queries.

if nargin < 4 || isempty(validation), validation = struct(); end
validation = set_default(validation, 'approved', false);
validation = set_default(validation, 'diffReviewed', false);
validation = set_default(validation, 'notes', '');
validation = set_default(validation, 'changeReportPath', '');

modelTag = validate_model(model);
runDir = char(runDir);
stage = char(stage);
statePath = fullfile(runDir, 'checkpoint_state.json');
if ~isfile(statePath)
    error('CODEX:CheckpointStateMissing', 'Checkpoint state not found: %s', statePath);
end
state = jsondecode(fileread(statePath));
if ~strcmpi(char(state.status), 'PAUSED') || ~logical(state.safeToEdit)
    error('CODEX:CheckpointNotPaused', 'Checkpoint is not in a confirmed PAUSED/safe-to-edit state.');
end
if ~strcmp(char(state.stage), stage)
    error('CODEX:CheckpointStageMismatch', 'State stage is %s, requested %s.', char(state.stage), stage);
end
if ~strcmp(char(state.modelTag), modelTag)
    error('CODEX:CheckpointModelMismatch', 'State model tag is %s, live tag is %s.', char(state.modelTag), modelTag);
end
if ~logical(validation.approved) || ~logical(validation.diffReviewed)
    error('CODEX:ResumeNotValidated', ...
        'Resume requires validation.approved=true and validation.diffReviewed=true.');
end

approval = struct();
approval.schemaVersion = '1.0';
approval.approved = true;
approval.approvedAt = timestamp_text();
approval.stage = stage;
approval.modelTag = modelTag;
approval.changeReportPath = char(validation.changeReportPath);
approval.notes = char(validation.notes);
approvalPath = fullfile(runDir, ['approved_continue_' stage '.json']);
write_utf8(approvalPath, pretty_json(approval));
fprintf('CODEX_RESUME_APPROVAL: %s\n', approvalPath);
end

function tag = validate_model(model)
try, tag = char(model.tag()); catch ME
    error('CODEX:InvalidModelObject', 'Invalid COMSOL model object: %s', ME.message);
end
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

function value = timestamp_text()
value = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
end
