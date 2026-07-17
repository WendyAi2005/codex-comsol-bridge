function status = launch_comsol_visual_client(model, config)
%LAUNCH_COMSOL_VISUAL_CLIENT Attach COMSOL Desktop to an existing model.
%   The function never starts MATLAB or COMSOL Server and never opens a
%   second model. It launches at most one Desktop client for MODEL.

if nargin < 2 || isempty(config), config = struct(); end
config = set_default(config, 'mliPath', ...
    'D:\Program Files\COMSOL\COMSOL56\Multiphysics\mli');
config = set_default(config, 'timeoutMs', 10000);
config = set_default(config, 'allowAdditionalClient', false);
config = set_default(config, 'confirmationPollCount', 45);
config = set_default(config, 'confirmationPollSeconds', 1);
config = set_default(config, 'repairMissingWindir', true);
config = set_default(config, 'errorReportPath', '');

status = struct( ...
    'success', false, ...
    'launched', false, ...
    'actionRequired', false, ...
    'state', 'NOT_STARTED', ...
    'message', '', ...
    'modelTag', '', ...
    'modelLabel', '', ...
    'timeoutMs', config.timeoutMs, ...
    'windirRepairApplied', false, ...
    'mphlaunchPath', '', ...
    'modelsUsedByOtherClientsBefore', {{}}, ...
    'modelsUsedByOtherClientsAfter', {{}}, ...
    'errorReportPath', '');

try
    if ~isfolder(config.mliPath)
        error('CODEX:MliPathMissing', ...
            'COMSOL LiveLink directory does not exist: %s', config.mliPath);
    end
    addpath(config.mliPath);
    status.mphlaunchPath = which('mphlaunch');
    if isempty(status.mphlaunchPath)
        error('CODEX:MphlaunchMissing', ...
            'mphlaunch is unavailable after adding the COMSOL mli path.');
    end

    % MATLAB MCP batch sessions can omit the lower-case Windows environment
    % variable `windir` even though `SystemRoot` is present. COMSOL 5.6
    % launches a WPF client whose font cache fails with UriFormatException
    % when `windir` is missing. Repair only this MATLAB process and children;
    % never change the user/machine environment or registry.
    if config.repairMissingWindir && isempty(getenv('windir'))
        systemRoot = getenv('SystemRoot');
        if isempty(systemRoot) || ~isfolder(systemRoot)
            error('CODEX:MissingWindowsDirectory', ...
                ['The MATLAB process has no valid windir or SystemRoot. ' ...
                 'Refusing to launch the COMSOL visual client.']);
        end
        setenv('windir', systemRoot);
        status.windirRepairApplied = true;
    end
    if isempty(model)
        error('CODEX:InvalidModel', 'The existing model object is empty.');
    end

    import com.comsol.model.*
    import com.comsol.model.util.*

    try
        status.modelTag = char(model.tag);
        status.modelLabel = char(model.label);
    catch validationME
        error('CODEX:InvalidModel', ...
            'The input is not a valid COMSOL model object: %s', validationME.message);
    end

    serverTags = java_strings_to_cell(ModelUtil.tags());
    if ~ismember(status.modelTag, serverTags)
        error('CODEX:ModelNotOnConnectedServer', ...
            'Model tag %s is not on the currently connected COMSOL Server.', ...
            status.modelTag);
    end

    status.modelsUsedByOtherClientsBefore = ...
        java_strings_to_cell(ModelUtil.modelsUsedByOtherClients());
    if ismember(status.modelTag, status.modelsUsedByOtherClientsBefore)
        status.success = true;
        status.state = 'ALREADY_CONNECTED_SAME_MODEL';
        status.message = ['A COMSOL Desktop/client is already attached to ' ...
            'the same server model. Reusing it; mphlaunch was not called.'];
        print_status(status);
        return;
    end

    if ~isempty(status.modelsUsedByOtherClientsBefore) && ...
            ~config.allowAdditionalClient
        status.actionRequired = true;
        status.state = 'OTHER_CLIENT_DETECTED';
        status.message = sprintf([ ...
            'Other client model tags are active: %s. No new Desktop was ' ...
            'launched; report this state before deciding what to do.'], ...
            strjoin(status.modelsUsedByOtherClientsBefore, ','));
        print_status(status);
        return;
    end

    mphlaunch(model, config.timeoutMs);
    status.launched = true;

    for attempt = 1:config.confirmationPollCount
        pause(config.confirmationPollSeconds);
        status.modelsUsedByOtherClientsAfter = ...
            java_strings_to_cell(ModelUtil.modelsUsedByOtherClients());
        if ismember(status.modelTag, status.modelsUsedByOtherClientsAfter)
            break;
        end
    end

    if ~ismember(status.modelTag, status.modelsUsedByOtherClientsAfter)
        error('CODEX:VisualClientNotConfirmed', ...
            ['mphlaunch returned, but the model tag %s was not reported by ' ...
             'ModelUtil.modelsUsedByOtherClients().'], status.modelTag);
    end

    status.success = true;
    status.state = 'LAUNCHED_AND_CONFIRMED';
    status.message = ['COMSOL Desktop was launched and confirmed on the ' ...
        'same server model tag.'];
    print_status(status);
catch ME
    status.success = false;
    status.state = 'FAILED';
    status.message = ME.message;
    extendedReport = getReport(ME, 'extended', 'hyperlinks', 'off');
    status.errorReportPath = resolve_error_path( ...
        config.errorReportPath, 'visual_client_error_report.txt');
    write_text_file(status.errorReportPath, extendedReport);
    print_status(status);
end
end

function print_status(status)
fprintf('CODEX_VISUAL_CLIENT_STATUS: %s\n', status.state);
fprintf('CODEX_VISUAL_CLIENT_MODEL_TAG: %s\n', status.modelTag);
fprintf('CODEX_VISUAL_CLIENT_MESSAGE: %s\n', status.message);
if ~isempty(status.errorReportPath)
    fprintf('CODEX_VISUAL_CLIENT_ERROR_REPORT: %s\n', status.errorReportPath);
end
end

function config = set_default(config, name, value)
if ~isfield(config, name) || isempty(config.(name))
    config.(name) = value;
end
end

function values = java_strings_to_cell(javaValues)
raw = cell(javaValues);
values = cellfun(@char, raw, 'UniformOutput', false);
end

function pathOut = resolve_error_path(configuredPath, defaultName)
if ~isempty(configuredPath)
    pathOut = char(configuredPath);
    parent = fileparts(pathOut);
    if ~isempty(parent) && ~isfolder(parent), mkdir(parent); end
    return;
end
if evalin('base', 'exist(''CODEX_RUN_DIR'', ''var'')')
    runDir = char(evalin('base', 'CODEX_RUN_DIR'));
else
    runDir = fullfile(pwd, 'runs', ...
        [datestr(now, 'yyyymmdd_HHMMSS') '_visual_client']);
end
if ~isfolder(runDir), mkdir(runDir); end
pathOut = fullfile(runDir, defaultName);
end

function write_text_file(pathOut, content)
fileId = fopen(pathOut, 'w', 'n', 'UTF-8');
if fileId < 0, error('CODEX:FileWriteFailed', 'Cannot write %s', pathOut); end
cleanupObject = onCleanup(@() fclose(fileId)); %#ok<NASGU>
fprintf(fileId, '%s\n', content);
end
