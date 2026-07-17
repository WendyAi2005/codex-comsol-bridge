---
name: codex-comsol-bridge
description: >
  Use this skill for Codex-to-COMSOL automation through MathWorks MATLAB MCP
  Server and COMSOL LiveLink for MATLAB. It connects two mature, officially
  supported integration paths into one community-built workflow with native
  COMSOL model access, task-level local execution, compact result return,
  same-server Desktop observation, verified human takeover, model-difference
  review, safe resume, parameter sweeps and reproducible outputs.
---

# Codex–COMSOL Bridge operating procedure

## Architecture contract

Use this fixed chain:

Codex
→ MathWorks MATLAB MCP Server
→ MATLAB
→ COMSOL LiveLink for MATLAB
→ COMSOL Multiphysics Server
→ native COMSOL model, physics interfaces and solvers

This is a community-built workflow using officially supported integration
layers.

Do not insert a third-party COMSOL API wrapper between MATLAB and COMSOL
unless the user explicitly requests an alternative architecture.

The AI layer must not replace or approximate COMSOL physics. Numerical
solutions remain the responsibility of the native COMSOL model and solvers.

Use this skill as the default operating procedure for all COMSOL projects.
Treat the rules as reusable unless a project-specific `AGENTS.md` explicitly
overrides an environment value or the user changes a physical assumption.

## Load the right references

Always read:

- [references/known_issues.md](references/known_issues.md) before coding.
- [references/workflow_checklist.md](references/workflow_checklist.md) before running.

Read when relevant:

- [references/validated_baselines.md](references/validated_baselines.md) for
  AC/DC, Structural Mechanics, CFD, API tags, and known-good result variables.
- [references/new_project_workflow.md](references/new_project_workflow.md) when
  creating or inheriting a new project.
- [references/README_docs.md](references/README_docs.md) when researching an
  unfamiliar API, physics interface, feature type, or result expression.
- [references/visual_mode.md](references/visual_mode.md) when the user wants a
  native COMSOL Desktop attached to the same server model through `mphlaunch`.
- [references/operator_guide_bilingual.md](references/operator_guide_bilingual.md)
  before a user-observed run or whenever the user may pause, inspect, or edit
  the live model from COMSOL Desktop.
- [references/portability_and_publishing.md](references/portability_and_publishing.md)
  when installing on another computer, inheriting the skill in a new project,
  or preparing a sanitized public package.

## Fixed environment defaults

- Operating system: Windows.
- MATLAB: R2022b, controlled through MATLAB MCP.
- COMSOL: Multiphysics 5.6 with LiveLink for MATLAB.
- LiveLink path:
  `D:\Program Files\COMSOL\COMSOL56\Multiphysics\mli`.
- The user manually starts COMSOL Multiphysics Server 5.6.
- Preferred server: `localhost:2036`.

These are validated defaults, not universal constants. Start with
[`scripts/comsol_config_template.m`](scripts/comsol_config_template.m), then
change only environment-specific path, host, port, and version values.

Do not launch MATLAB from a shell or from the "COMSOL Multiphysics 5.6 with
MATLAB" shortcut when MATLAB MCP is available. Execute COMSOL APIs only inside
the MATLAB process launched or controlled by MATLAB MCP.

Treat each MATLAB MCP `execute_matlab_script` call as an independent batch
session. Do not rely on a previous workspace, path, import, or COMSOL
connection. Do not rely on MCP `args` for critical variables in this
environment; write paths and required values into the generated launcher, then
call `run(projectScriptPath)`.

Every launcher or standalone script must establish its own environment:

```matlab
mliPath = 'D:\Program Files\COMSOL\COMSOL56\Multiphysics\mli';
serverHost = 'localhost';
serverPort = 2036;
addpath(mliPath)
which mphstart
which mphopen
which mphlaunch
try
    if strcmpi(serverHost, 'localhost')
        mphstart(serverPort)
    else
        mphstart(serverHost, serverPort)
    end
catch
    % Reuse a confirmed existing connection, otherwise try mphstart and
    % preserve both extended error reports if connection still fails.
end
import com.comsol.model.*
import com.comsol.model.util.*
```

## Native Desktop observation mode

Keep API control in MATLAB MCP. The COMSOL Desktop is a visual client for the
same server model, never a second model or an alternate automation path.

- Default `config.visualMode=true` for development, troubleshooting, and one
  baseline case; use false for large sweeps and unattended runs.
- Initialize the connection/model once, inspect other client tags, then call
  `mphlaunch(model,10000)` at most once outside all parameter loops.
- Confirm attachment only when the exact model tag is reported by
  `ModelUtil.modelsUsedByOtherClients()`.
- If another client uses a different model, report the tag and stop. Never
  close or disconnect it without the user's approval.
- Do not automate GUI clicks. Do not let GUI edits race geometry, mesh, study,
  or result API calls; pause first when manual edits are needed.
- In MATLAB MCP batch sessions, repair a missing process-level `windir` from a
  valid `SystemRoot` before `mphlaunch`; never alter user/machine environment.
- Treat observation as checkpoint-based. Use `visualMode=false` if a GUI
  affects background stability.
- The MATLAB MCP transport can time out while an attached Desktop remains open
  because the child client retains output handles. Do not terminate the GUI to
  make the call return. Confirm the diary, process, exact model tag, and a fresh
  MCP readback, then continue in a new MCP batch session.

## Verified manual GUI takeover protocol

Read the bilingual operator guide before any run that permits GUI editing.
Desktop editing is allowed only while a staged runner is in a verified manual
pause. A quiet GUI or a short observation delay is not a pause.

### Pause authorization

The user requests a pause in natural language, for example “pause after
geometry”. Codex writes `CODEX_MANUAL_PAUSE_STAGE='geometry'` into the generated
MCP launcher. The user never types that variable into COMSOL and never creates
continue flags.

Use [`scripts/comsol_visual_checkpoint.m`](scripts/comsol_visual_checkpoint.m)
at safe boundaries. Editing is authorized only when all of these are true:

1. Codex explicitly reports the stage and `SAFE_TO_EDIT=true`.
2. The run-local `checkpoint_state.json` says `status=PAUSED` and
   `safeToEdit=true`.
3. The diary reports `CODEX_CHECKPOINT_STATUS: PAUSED` and
   `CODEX_SAFE_TO_EDIT: true`.
4. The state model tag equals the exact Desktop-attached server model tag and
   no geometry, mesh, Study, or result operation is active.

`OBSERVATION_ONLY` and `RESUMING` always mean `safeToEdit=false`.

### Before editing

The checkpoint helper must save, without overwriting an original model:

- `pre_edit_<stage>.mph`
- `snapshot_before_<stage>.mat`
- `snapshot_before_<stage>.json`
- best-effort COMSOL-generated M-file evidence
- `checkpoint_state.json` and checkpoint diary/log records

The shared Desktop model is live. GUI changes are immediately visible to API
clients; the user does not need to click Save. Default to not clicking the
top-left Save button because the current model association may point at an
original or successful file. Use a Codex-supplied run-local **Save As** path
only when an extra manual recovery copy is requested.

### After editing

The user may simply say “改完了，继续”. A verbal list of changes is helpful but
not required and is never the sole evidence. Codex must:

1. Reconnect through MATLAB MCP to the same server and exact model tag.
2. Capture an after-edit snapshot with
   [`capture_comsol_model_snapshot.m`](scripts/capture_comsol_model_snapshot.m).
3. Compare it with
   [`compare_comsol_model_snapshots.m`](scripts/compare_comsol_model_snapshots.m)
   and save `manual_change_report.md/.json`.
4. Perform targeted API queries for any ambiguous module-specific setting,
   selection, tag, unit, or property source.
5. Save a post-edit run-local `.mph` copy.
6. Call
   [`approve_comsol_checkpoint_resume.m`](scripts/approve_comsol_checkpoint_resume.m)
   only after `approved=true` and `diffReviewed=true` are justified.

The paused runner accepts only `approved_continue_<stage>.json` whose stage and
model tag match. It then sets `safeToEdit=false` before resuming. Never ask the
user to create this file.

### Automatic-diff limits

The generic snapshot covers parameters, tags, labels, feature types, readable
properties, and readable selections across geometry, materials, physics,
mesh, study, solver, and results. It does not guarantee complete semantic
coverage of every module-specific GUI control. COMSOL-generated M-files can be
incomplete when model history is disabled and are supplementary evidence.
When coverage is incomplete, ask only the specific unresolved physics question
instead of pretending all changes were detected.

### Resume dependency rules

- Geometry or geometry-dependent parameter: rebuild geometry, requery named
  selections and entity IDs, rebuild mesh, rerun Study/results.
- Material or boundary condition: revalidate domains, boundaries, units, and
  property sources, then rerun Study/results.
- Mesh: rebuild and inspect quality, then rerun Study/results.
- Study or solver: requery tags/settings and rerun the validated Study.
- Result-only change: update results; normally do not solve again.
- Unknown parameter dependency: inspect every expression that references the
  parameter and resume from the earliest affected stage.

Prefer a new timestamped run for any manual change that affects physics,
geometry, selections, mesh, Study, or solver behavior. Preserve the paused run.

Do not assume arbitrary pause/resume inside a solve. Request a controlled stop
at a safe boundary. If immediate GUI intervention is unavoidable, use Study
**Stop** once; never terminate the COMSOL Server.

## Evidence-first API policy

Never guess COMSOL API names, tags, entity IDs, selections, variables, feature
types, solver tags, or units. Resolve uncertainty in this order:

1. Current project `.mph`, `.m`, `.mat`, logs, reports, and successful runs.
2. A COMSOL Desktop-exported MATLAB model file.
3. `known_issues.md` and `validated_baselines.md`.
4. Installed MATLAB queries such as `help`, `which`, Java `properties`,
   `getType`, `getString`, `getStringArray`, and `getAllowedPropertyValues`.
5. A complete, read-only official Application Library `.mph` opened with
   `mphopen`.
6. Official LiveLink for MATLAB and physics-module manuals.

Application Library files can be preview placeholders. A path and `.mph`
extension do not prove that the model is loadable; verify with read-only
`mphopen` before using it as evidence.

## Simulation contract before coding

Confirm or explicitly state all of the following before changing the model:

1. Objective and quantities of interest.
2. Geometry source and dimensions.
3. Parameters and units.
4. Materials and property sources.
5. Physics interfaces and assumptions.
6. Domain and boundary conditions.
7. Mesh strategy and expected refinement needs.
8. Study type and solver scope.
9. Outputs, plots, tables, model filename, and run directory.

Ask the user when different choices materially change the physics. Never
silently change assumptions, units, dimensions, materials, boundary
conditions, study type, or coupling direction.

Before a long solve or parameter sweep, report the number of cases, parameter
ranges, expected outputs, and save location. Run one baseline case before any
formal sweep.

## Build in validated stages

1. Start with the smallest runnable model.
2. Build geometry and verify that it completed.
3. Query domains and boundaries from the built geometry.
4. Create named selections and assert expected entity counts.
5. Set material-property sources and values explicitly.
6. Add one physics interface and the minimum boundary conditions.
7. Build the mesh and print completion.
8. Add one study and solve one baseline case.
9. Evaluate a small set of physical sanity checks or analytical comparisons.
10. Save, reopen in a fresh MATLAB MCP session, verify physics tags, and read
    at least one stored result before calling the workflow reusable.
11. Add complexity one feature at a time: sweep, nonlinearity, contact,
    rotation, multiphysics coupling, or moving mesh.

## Selection and material rules

- Prefer named selections over naked entity IDs.
- After every geometry change, query selections again; old IDs are invalid
  until reverified.
- `mphselectbox` tests entity vertices. Enclose the complete target entity,
  include a small tolerance, print returned IDs, and assert the expected count.
- Convert COMSOL Java tag arrays with `cell(javaTags)` and then
  `cellfun(@char, ..., 'UniformOutput', false)`.
- If no material node exists, do not leave a physics property source at
  `from_mat`. Query allowed values, set the relevant `*_mat` field to
  `userdef`, and set every required value explicitly.
- Keep parameters unit-bearing whenever possible, for example:

  ```matlab
  model.param.set('L', '10[mm]');
  model.param.set('Uin', '1[m/s]');
  ```

## Script and artifact contract

- Use clear tags such as `comp1`, `geom1`, `mesh1`, `std1`, `sol1`, and `pg1`
  only after confirming they exist or creating them explicitly.
- Print major progress with `fprintf`.
- Create a new `runs/YYYYMMDD_HHMMSS[_label]/` directory for every attempt.
- Never overwrite an original or successful `.mph` file.
- Save on success:
  - `matlab_diary.txt`
  - `workspace.mat`
  - `run_report.md`
  - a timestamped or run-local `.mph`
  - required CSV/MAT data and plots
- During a manual checkpoint also save:
  - `checkpoint_state.json`
  - pre/post-edit `.mph` copies
  - before/after `.mat` and `.json` snapshots
  - `manual_change_report.md` and `.json`
  - the Codex-generated resume approval JSON
- Also save `error_report.txt` on failure using:

  ```matlab
  getReport(ME, 'extended', 'hyperlinks', 'off')
  ```

- End automation output with an unambiguous success or failure marker.

Use [scripts/run_livelink_batch.m](scripts/run_livelink_batch.m) only when the
user explicitly requests shell batch execution or MATLAB MCP is genuinely
unavailable. The default path is MATLAB MCP plus a generated launcher.

## Failure loop

Classify failures as one or more of:

- MATLAB syntax
- LiveLink connection
- path or permissions
- COMSOL tag
- domain/boundary selection
- parameters or units
- geometry
- mesh
- material or physics setup
- solver convergence
- license/module availability
- memory/compute resources
- result evaluation/export

For every failure:

1. Preserve the failed run directory.
2. Read both diary and extended error report.
3. Identify the exact failing line and root cause from evidence.
4. Make the smallest change that addresses that cause.
5. Retry in a new timestamped run directory.
6. Verify the expected artifacts and scan logs for warnings.
7. Add a row to `known_issues.md` with symptom, root cause, fix, prevention,
   and related file/line.

Do not ignore solver warnings. Do not report success unless MATLAB MCP actually
ran the script and the expected result files exist.

## Portability and public distribution

- Keep `mliPath`, `serverHost`, `serverPort`, `visualMode`, model paths, and
  version expectations in configuration.
- Install the reusable copy under
  `%USERPROFILE%\.codex\skills\codex-comsol-bridge\`; keep a project source
  or override under `<project>\.agents\skills\codex-comsol-bridge\` when
  needed.
- On a new machine, validate MATLAB MCP first, then LiveLink connection, exact
  Desktop model attachment, one small baseline, and fresh-session reopen/readback
  before a sweep or long solve.
- A public package includes `SKILL.md`, `agents/openai.yaml`, reusable scripts,
  generic references, sanitized issue examples, and an owner-selected license.
- Exclude runs, results, backups, large `.mph`, credentials, private hosts,
  absolute user/project paths, confidential geometry/material data, and logs.
- Distinguish actually tested version combinations from expected compatibility.
- Do not choose a public license on the user's behalf.

## Prohibited behavior

- Do not guess boundary/domain IDs, tags, units, variables, or physics.
- Do not overwrite source models or successful runs.
- Do not delete old results.
- Do not start an unrequested parameter sweep or long solve.
- Do not add complex couplings before the single-physics baseline works.
- Do not fabricate MATLAB, COMSOL, MCP, solver, or export results.
- Do not authorize GUI editing without verified `PAUSED/safeToEdit=true` state.
- Do not ask the user to create resume flags or overwrite the original model.
- Do not claim automatic diff coverage is complete when targeted queries are
  still required.
