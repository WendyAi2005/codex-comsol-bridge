function config = comsol_config_template()
%COMSOL_CONFIG_TEMPLATE Copy and edit these environment-specific defaults.
% Do not put passwords or license credentials in a published project.
config = struct();
config.mliPath = 'D:\Program Files\COMSOL\COMSOL56\Multiphysics\mli';
config.serverHost = 'localhost';
config.serverPort = 2036;
config.visualMode = true;
config.allowDefaultPortFallback = false;
config.reuseServerModel = false;
config.modelTag = '';
config.visualLaunchTimeoutMs = 10000;
end
