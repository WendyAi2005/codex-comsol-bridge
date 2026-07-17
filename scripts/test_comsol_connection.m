%TEST_COMSOL_CONNECTION Verify the MATLAB MCP to COMSOL Server connection.
% This script does not open a model and does not start a simulation.

fprintf('=== MATLAB MCP -> COMSOL connection test ===\n');
fprintf('MATLAB_VERSION: %s\n', version);

mliPath = 'D:\Program Files\COMSOL\COMSOL56\Multiphysics\mli';
connectionSucceeded = false;

try
    if ~isfolder(mliPath)
        error('CODEX:ComsolMliPathMissing', 'COMSOL mli directory does not exist: %s', mliPath);
    end
    fprintf('MLI_PATH_EXISTS: true\n');
    fprintf('MLI_PATH: %s\n', mliPath);

    addpath(mliPath);
    fprintf('MLI_PATH_ADDED: true\n');

    mphstartPath = which('mphstart');
    mphopenPath = which('mphopen');
    fprintf('MPHSTART_PATH: %s\n', mphstartPath);
    fprintf('MPHOPEN_PATH: %s\n', mphopenPath);

    if isempty(mphstartPath)
        error('CODEX:MphstartNotFound', 'mphstart is unavailable after adding the COMSOL mli path.');
    end
    if isempty(mphopenPath)
        error('CODEX:MphopenNotFound', 'mphopen is unavailable after adding the COMSOL mli path.');
    end

    try
        fprintf('Attempting mphstart in the MATLAB MCP-controlled session...\n');
        mphstart;
        connectionSucceeded = true;
        fprintf('COMSOL_CONNECTION_MODE: connected by mphstart\n');
    catch connectionME
        connectionReport = lower(getReport(connectionME, 'extended', 'hyperlinks', 'off'));
        alreadyConnected = contains(connectionReport, 'already connected') || ...
            contains(connectionReport, 'connection is already established') || ...
            contains(connectionReport, 'already been connected') || ...
            contains(connectionReport, '已连接') || ...
            contains(connectionReport, '已经连接');

        if alreadyConnected
            connectionSucceeded = true;
            fprintf('COMSOL_CONNECTION_MODE: existing connection reused\n');
        else
            rethrow(connectionME);
        end
    end

    import com.comsol.model.*
    import com.comsol.model.util.*
    fprintf('COMSOL_IMPORTS_OK: true\n');
    fprintf('COMSOL_SERVER_CONNECTED: %s\n', mat2str(connectionSucceeded));
    fprintf('CODEX_COMSOL_MCP_STATUS: SUCCESS\n');
catch ME
    connectionSucceeded = false;
    fullErrorReport = getReport(ME, 'extended', 'hyperlinks', 'off');
    fprintf(2, '%s\n', fullErrorReport);
    fprintf('COMSOL_SERVER_CONNECTED: false\n');
    fprintf('CODEX_COMSOL_MCP_STATUS: FAILED\n');
    rethrow(ME);
end
