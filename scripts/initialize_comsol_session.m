function [model, connectionInfo] = initialize_comsol_session(modelPath, config)
%INITIALIZE_COMSOL_SESSION Connect to COMSOL 5.6 and load/reuse one model.
%   CONFIG.visualMode defaults to true. This function does not launch the
%   Desktop client; call launch_comsol_visual_client(model) once afterwards.

if nargin < 1, modelPath = ''; end
if nargin < 2 || isempty(config), config = struct(); end
if ~(ischar(modelPath) || isstring(modelPath))
    error('CODEX:InvalidModelPath', 'modelPath must be a character vector or string.');
end
modelPath = char(modelPath);

config = set_default(config, 'visualMode', true);
config = set_default(config, 'mliPath', ...
    'D:\Program Files\COMSOL\COMSOL56\Multiphysics\mli');
config = set_default(config, 'serverHost', 'localhost');
config = set_default(config, 'serverPort', 2036);
config = set_default(config, 'allowDefaultPortFallback', true);
config = set_default(config, 'modelTag', '');
config = set_default(config, 'reuseServerModel', true);
config = set_default(config, 'errorReportPath', '');

if ~(islogical(config.visualMode) && isscalar(config.visualMode))
    error('CODEX:InvalidVisualMode', 'config.visualMode must be true or false.');
end
if ~(isnumeric(config.serverPort) && isscalar(config.serverPort))
    error('CODEX:InvalidServerPort', 'config.serverPort must be a numeric scalar.');
end
if ~(ischar(config.serverHost) || (isstring(config.serverHost) && isscalar(config.serverHost)))
    error('CODEX:InvalidServerHost', 'config.serverHost must be a character vector or scalar string.');
end

connectionInfo = struct( ...
    'success', false, ...
    'mliPath', char(config.mliPath), ...
    'mphstartPath', '', ...
    'mphopenPath', '', ...
    'mphlaunchPath', '', ...
    'serverHost', char(config.serverHost), ...
    'serverPort', config.serverPort, ...
    'connectionMode', '', ...
    'visualMode', config.visualMode, ...
    'modelPath', modelPath, ...
    'modelTag', '', ...
    'modelLabel', '', ...
    'modelSource', '', ...
    'serverTagsBefore', {{}}, ...
    'serverTagsAfter', {{}}, ...
    'modelsUsedByOtherClients', {{}}, ...
    'errorReportPath', '', ...
    'errorReport', '');

try
    if ~isfolder(config.mliPath)
        error('CODEX:MliPathMissing', ...
            'COMSOL LiveLink directory does not exist: %s', config.mliPath);
    end
    addpath(config.mliPath);

    connectionInfo.mphstartPath = which('mphstart');
    connectionInfo.mphopenPath = which('mphopen');
    connectionInfo.mphlaunchPath = which('mphlaunch');
    if isempty(connectionInfo.mphstartPath) || isempty(connectionInfo.mphopenPath)
        error('CODEX:LiveLinkFunctionsMissing', ...
            'mphstart or mphopen is unavailable after adding the mli path.');
    end

    connectionInfo.connectionMode = connect_existing_server( ...
        char(config.serverHost), config.serverPort, config.allowDefaultPortFallback);

    import com.comsol.model.*
    import com.comsol.model.util.*

    connectionInfo.serverTagsBefore = java_strings_to_cell(ModelUtil.tags());
    connectionInfo.modelsUsedByOtherClients = ...
        java_strings_to_cell(ModelUtil.modelsUsedByOtherClients());

    requestedTag = char(config.modelTag);
    if ~isempty(requestedTag) && ismember(requestedTag, connectionInfo.serverTagsBefore)
        if ~config.reuseServerModel
            error('CODEX:ModelTagAlreadyExists', ...
                ['Model tag %s already exists on the server. Refusing to ' ...
                 'overwrite it because config.reuseServerModel is false.'], requestedTag);
        end
        model = ModelUtil.model(requestedTag);
        connectionInfo.modelSource = 'existing_server_tag';
    else
        if isempty(modelPath)
            error('CODEX:ModelPathRequired', ...
                'Provide modelPath when the requested server model tag does not exist.');
        end
        if ~isfile(modelPath)
            error('CODEX:ModelFileMissing', 'Model file does not exist: %s', modelPath);
        end
        modelPath = canonical_file(modelPath);
        connectionInfo.modelPath = modelPath;
        if isempty(requestedTag)
            model = mphopen(modelPath);
        else
            model = mphopen(modelPath, requestedTag, '-nostore');
        end
        connectionInfo.modelSource = 'file';
    end

    connectionInfo.modelTag = char(model.tag);
    connectionInfo.modelLabel = char(model.label);
    connectionInfo.serverTagsAfter = java_strings_to_cell(ModelUtil.tags());
    if ~ismember(connectionInfo.modelTag, connectionInfo.serverTagsAfter)
        error('CODEX:ModelNotOnServer', ...
            'Loaded model tag %s is not present on the connected server.', ...
            connectionInfo.modelTag);
    end

    connectionInfo.success = true;
    fprintf('COMSOL_SESSION_STATUS: SUCCESS\n');
    fprintf('COMSOL_CONNECTION_MODE: %s\n', connectionInfo.connectionMode);
    fprintf('COMSOL_MODEL_TAG: %s\n', connectionInfo.modelTag);
    fprintf('COMSOL_MODEL_SOURCE: %s\n', connectionInfo.modelSource);
    fprintf('COMSOL_VISUAL_MODE: %s\n', mat2str(connectionInfo.visualMode));
catch ME
    connectionInfo.errorReport = getReport(ME, 'extended', 'hyperlinks', 'off');
    connectionInfo.errorReportPath = resolve_error_path( ...
        config.errorReportPath, 'initialize_comsol_error_report.txt');
    write_text_file(connectionInfo.errorReportPath, connectionInfo.errorReport);
    fprintf(2, 'COMSOL_SESSION_STATUS: FAILED\n');
    fprintf(2, 'COMSOL_SESSION_ERROR_REPORT: %s\n', connectionInfo.errorReportPath);
    rethrow(ME);
end
end

function mode = connect_existing_server(host, port, allowFallback)
try
    if strcmpi(host, 'localhost') || strcmp(host, '127.0.0.1')
        mphstart(port);
        mode = sprintf('mphstart(%g)', port);
    else
        mphstart(host, port);
        mode = sprintf('mphstart(''%s'',%g)', host, port);
    end
catch portME
    if is_already_connected(portME)
        mode = 'existing_connection_reused';
        return;
    end
    if ~allowFallback || ~(strcmpi(host, 'localhost') || strcmp(host, '127.0.0.1'))
        rethrow(portME);
    end
    try
        mphstart;
        mode = 'mphstart';
    catch defaultME
        if is_already_connected(defaultME)
            mode = 'existing_connection_reused';
            return;
        end
        error('CODEX:ComsolConnectionFailed', ...
            ['Could not connect to the existing COMSOL Server.\n\n' ...
             '--- explicit host/port connection ---\n%s\n\n--- mphstart default ---\n%s'], ...
            getReport(portME, 'extended', 'hyperlinks', 'off'), ...
            getReport(defaultME, 'extended', 'hyperlinks', 'off'));
    end
end
end

function tf = is_already_connected(ME)
textValue = lower(getReport(ME, 'extended', 'hyperlinks', 'off'));
tf = contains(textValue, 'already connected') || ...
    contains(textValue, 'connection is already established') || ...
    contains(textValue, 'already been connected');
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

function pathOut = canonical_file(pathIn)
info = dir(pathIn);
pathOut = fullfile(info(1).folder, info(1).name);
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
        [datestr(now, 'yyyymmdd_HHMMSS') '_comsol_session']);
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
