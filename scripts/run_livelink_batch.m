function run_livelink_batch(mainScriptPath)
%RUN_LIVELINK_BATCH Fallback shell-batch wrapper for a COMSOL MATLAB script.
% Run this from the project root. MATLAB MCP remains the preferred executor.

if nargin ~= 1 || ~(ischar(mainScriptPath) || isstring(mainScriptPath))
    error('CODEX:InvalidInput', 'Provide one script path, for example src/main.m.');
end

projectRoot = pwd;
mainScriptPath = char(mainScriptPath);
if ~isfile(mainScriptPath)
    mainScriptPath = fullfile(projectRoot, mainScriptPath);
end
if ~isfile(mainScriptPath)
    error('CODEX:MainScriptNotFound', 'Main script not found: %s', mainScriptPath);
end
mainScriptPath = canonical_file(mainScriptPath);

mliPath = 'D:\Program Files\COMSOL\COMSOL56\Multiphysics\mli';
if ~isfolder(mliPath)
    error('CODEX:MliPathMissing', 'COMSOL LiveLink directory not found: %s', mliPath);
end
addpath(mliPath);

runsRoot = fullfile(projectRoot, 'runs');
if ~isfolder(runsRoot), mkdir(runsRoot); end
runDir = unique_run_directory(runsRoot, datestr(now, 'yyyymmdd_HHMMSS'));
mkdir(runDir);

CODEX_RUN_DIR = runDir; %#ok<NASGU>
CODEX_PROJECT_ROOT = projectRoot; %#ok<NASGU>
diaryPath = fullfile(runDir, 'matlab_diary.txt');
workspacePath = fullfile(runDir, 'workspace.mat');
reportPath = fullfile(runDir, 'run_report.md');
errorPath = fullfile(runDir, 'error_report.txt');

diary(diaryPath);
diaryCleanup = onCleanup(@() diary('off')); %#ok<NASGU>
startedAt = datetime('now');
status = 'FAILED';
connectionSummary = 'Not connected';
workspaceNote = '';

fprintf('CODEX COMSOL LiveLink fallback batch\n');
fprintf('Project root: %s\n', projectRoot);
fprintf('Run directory: %s\n', runDir);
fprintf('Main script: %s\n', mainScriptPath);
fprintf('MATLAB version: %s\n', version);

try
    mphstartPath = which('mphstart');
    mphopenPath = which('mphopen');
    fprintf('which mphstart: %s\n', mphstartPath);
    fprintf('which mphopen: %s\n', mphopenPath);
    if isempty(mphstartPath) || isempty(mphopenPath)
        error('CODEX:LiveLinkFunctionsMissing', ...
            'mphstart or mphopen is missing after addpath(%s).', mliPath);
    end

    connectionSummary = connect_comsol();
    fprintf('COMSOL connection: %s\n', connectionSummary);
    import com.comsol.model.*
    import com.comsol.model.util.*

    run(mainScriptPath);
    status = 'SUCCESS';
    completedAt = datetime('now');
    workspaceNote = save_workspace_snapshot(workspacePath);
    write_run_report(reportPath, status, mainScriptPath, runDir, startedAt, ...
        completedAt, connectionSummary, workspaceNote, '');
    fprintf('CODEX_RUN_STATUS: SUCCESS\n');
catch ME
    completedAt = datetime('now');
    extendedReport = getReport(ME, 'extended', 'hyperlinks', 'off');
    fprintf(2, '%s\n', extendedReport);
    write_text_file(errorPath, extendedReport);
    write_run_report(reportPath, status, mainScriptPath, runDir, startedAt, ...
        completedAt, connectionSummary, workspaceNote, extendedReport);
    fprintf('CODEX_RUN_STATUS: FAILED\n');
end
fprintf('Artifacts: %s\n', runDir);
end

function summary = connect_comsol()
try
    fprintf('Trying mphstart(2036)...\n');
    mphstart(2036);
    summary = 'Connected with mphstart(2036)';
catch portME
    if is_already_connected(portME)
        summary = 'Existing COMSOL connection reused';
        return;
    end
    try
        fprintf('Trying mphstart...\n');
        mphstart;
        summary = 'Connected with mphstart';
    catch defaultME
        if is_already_connected(defaultME)
            summary = 'Existing COMSOL connection reused';
            return;
        end
        error('CODEX:ComsolConnectionFailed', ...
            ['Both connection attempts failed.\n\n--- mphstart(2036) ---\n%s' ...
             '\n\n--- mphstart ---\n%s'], ...
            getReport(portME, 'extended', 'hyperlinks', 'off'), ...
            getReport(defaultME, 'extended', 'hyperlinks', 'off'));
    end
end
end

function tf = is_already_connected(ME)
messageText = lower(getReport(ME, 'basic', 'hyperlinks', 'off'));
patterns = {'already connected', 'connection is already established', ...
    'already been connected'};
tf = any(cellfun(@(item) contains(messageText, item), patterns));
end

function pathOut = canonical_file(pathIn)
info = dir(pathIn);
pathOut = fullfile(info(1).folder, info(1).name);
end

function runDir = unique_run_directory(runsRoot, stamp)
runDir = fullfile(runsRoot, stamp);
counter = 1;
while isfolder(runDir)
    runDir = fullfile(runsRoot, sprintf('%s_%03d', stamp, counter));
    counter = counter + 1;
end
end

function note = save_workspace_snapshot(workspacePath)
note = '';
variables = evalin('caller', 'whos');
saveNames = {};
skipped = {};
for index = 1:numel(variables)
    variableClass = variables(index).class;
    if strcmp(variableClass, 'onCleanup') || startsWith(variableClass, 'com.comsol.') || ...
            startsWith(variableClass, 'java.')
        skipped{end+1} = variables(index).name; %#ok<AGROW>
    else
        saveNames{end+1} = variables(index).name; %#ok<AGROW>
    end
end
try
    if isempty(saveNames)
        placeholder = 'No serializable variables.'; %#ok<NASGU>
        save(workspacePath, 'placeholder');
    else
        quotedNames = cellfun(@(name) ['''' strrep(name, '''', '''''') ''''], ...
            saveNames, 'UniformOutput', false);
        command = sprintf('save(''%s'', %s);', ...
            strrep(workspacePath, '''', ''''''), strjoin(quotedNames, ', '));
        evalin('caller', command);
    end
    if ~isempty(skipped)
        note = ['Skipped nonserializable objects: ' strjoin(skipped, ', ')];
    end
catch saveME
    note = ['Workspace snapshot fallback: ' saveME.message];
    save(workspacePath, 'note');
end
end

function write_run_report(pathOut, status, scriptPath, runDir, startedAt, ...
        completedAt, connectionSummary, workspaceNote, errorText)
lines = {
    '# COMSOL LiveLink Run Report'
    ''
    ['- Status: **' status '**']
    ['- Main script: `' scriptPath '`']
    ['- Run directory: `' runDir '`']
    ['- Started: ' char(startedAt, 'yyyy-MM-dd HH:mm:ss Z')]
    ['- Completed: ' char(completedAt, 'yyyy-MM-dd HH:mm:ss Z')]
    ['- MATLAB: ' version]
    ['- COMSOL connection: ' connectionSummary]
    };
if ~isempty(workspaceNote)
    lines = [lines; {''; '## Workspace note'; ''; workspaceNote}]; %#ok<AGROW>
end
if ~isempty(errorText)
    lines = [lines; {''; '## Failure'; ''; ...
        'See `error_report.txt` for the complete extended report.'}]; %#ok<AGROW>
end
write_text_file(pathOut, strjoin(lines, newline));
end

function write_text_file(pathOut, content)
fileId = fopen(pathOut, 'w', 'n', 'UTF-8');
if fileId < 0, error('CODEX:FileWriteFailed', 'Cannot write %s', pathOut); end
cleanupObject = onCleanup(@() fclose(fileId)); %#ok<NASGU>
fprintf(fileId, '%s\n', content);
end
