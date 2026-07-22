function evidence = configure_comsol_long_run_observability(model, studyTag, runDir)
%CONFIGURE_COMSOL_LONG_RUN_OBSERVABILITY Configure verified COMSOL 5.6 outputs.
%   Uses progress.log as the machine-readable source of truth and enables
%   native Study convergence plots. Call before the solve through MATLAB MCP.

arguments
    model
    studyTag (1,:) char
    runDir (1,:) char
end

import com.comsol.model.util.*

assert(isfolder(runDir), 'Run directory does not exist: %s', runDir);
rawStudyTags = model.study.tags();
studyTags = cell(rawStudyTags);
studyTags = cellfun(@char, studyTags, 'UniformOutput', false);
assert(any(strcmp(studyTags, studyTag)), ...
    'Study tag does not exist: %s', studyTag);

progressLog = fullfile(runDir, 'progress.log');
fid = fopen(progressLog, 'a');
assert(fid >= 0, 'Cannot create or append progress log: %s', progressLog);
fprintf(fid, '\n[%s] OBSERVABILITY_CONFIG_START study=%s\n', ...
    char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')), studyTag);
fclose(fid);

ModelUtil.showProgress(progressLog);

study = model.study(studyTag);
study.setGenConv(true);
assert(study.isGenConv(), 'COMSOL convergence plots were not enabled.');

evidence = struct();
evidence.progressLog = progressLog;
evidence.studyTag = studyTag;
evidence.convergencePlotsEnabled = logical(study.isGenConv());
evidence.configuredAt = char(datetime('now', ...
    'Format', 'yyyy-MM-dd HH:mm:ssXXX'));

fprintf('COMSOL_OBSERVABILITY_READY progress_log=%s study=%s genconv=%d\n', ...
    progressLog, studyTag, evidence.convergencePlotsEnabled);
end
