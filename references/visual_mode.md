# Native COMSOL Desktop observation mode

Use this mode only to observe the exact model object controlled by MATLAB MCP.
It is not GUI automation and does not create a second MATLAB, Server, or model.

## Standard call

```matlab
config = struct();
config.visualMode = true;
config.modelTag = 'ProjectBaseline';

[model, connectionInfo] = initialize_comsol_session(modelPath, config);

if config.visualMode
    visualStatus = launch_comsol_visual_client(model);
    assert(visualStatus.success, visualStatus.message);
end
```

Both helpers are installed with this skill and should be copied into the new
project's `scripts/` directory. `initialize_comsol_session` reuses an existing
server tag with `ModelUtil.model(tag)` rather than reopening or overwriting it.

## COMSOL 5.6 facts verified locally

- `mphlaunch(model)` starts a COMSOL visual client for the server model.
- `mphlaunch(model,10000)` uses a 10-second server-busy timeout.
- `ModelUtil.modelsUsedByOtherClients()` is the required confirmation source.
- MATLAB MCP may omit `windir`; the WPF client crashes during font startup if
  it remains missing. Set only the current process value from valid
  `SystemRoot`, then call `mphlaunch`.
- `mphsave` can update the active model label to the output filename.

## Concurrency and ownership

- Inspect client tags before launch. Reuse the same-tag visual client.
- If a different tag is active, report it and wait for user direction. Never
  close or disconnect an existing client automatically.
- Launch once per model/session, outside every parameter loop.
- Keep the GUI observation-only during API geometry, mesh, study, and result
  operations. Pause automation before manual edits.
- Observe key checkpoints rather than expecting frame-by-frame animation.
- Switch to `visualMode=false` when the GUI affects unattended stability.

## Manual editing contract

The GUI is editable only when `comsol_visual_checkpoint` has published all of:

- `checkpoint_state.json` with `status=PAUSED` and `safeToEdit=true`;
- diary markers `CODEX_CHECKPOINT_STATUS: PAUSED` and
  `CODEX_SAFE_TO_EDIT: true`;
- the exact model tag used by the attached Desktop;
- a run-local pre-edit `.mph` and structured before-snapshot.

`OBSERVATION_ONLY` is not an edit pause. `RESUMING` means the user must stop
editing. The user asks for a pause in natural language and never types
`CODEX_MANUAL_PAUSE_STAGE` into COMSOL or creates a continue flag.

After the user says “改完了，继续”, capture and compare the after-state, run
targeted API queries where generic coverage is ambiguous, save a post-edit
copy, and generate the matching approval JSON. See
`operator_guide_bilingual.md` for the complete protocol.

## MATLAB MCP transport behavior

The independent batch MCP launcher may report a tools-call timeout while a
successfully launched Desktop remains open. The MATLAB process can already be
gone; the visual client keeps inherited output handles open. Do not close or
kill the Desktop merely to clear this timeout. Instead:

1. Read the run-local MATLAB diary for `LAUNCHED_AND_CONFIRMED`.
2. Confirm `comsolmphclient.exe` is responsive.
3. Use a fresh MATLAB MCP session to confirm the exact other-client model tag
   and read the synchronization probe.
4. Treat those checks as completion evidence and continue automation.

## Evidence required before reporting success

1. `which mphlaunch` resolves under the fixed COMSOL 5.6 `mli` directory.
2. The helper returns `LAUNCHED_AND_CONFIRMED` or
   `ALREADY_CONNECTED_SAME_MODEL`.
3. The exact MATLAB `model.tag` appears in
   `ModelUtil.modelsUsedByOtherClients()`.
4. A low-risk parameter or description change is read back from a fresh
   MATLAB MCP session while the Desktop remains attached.
