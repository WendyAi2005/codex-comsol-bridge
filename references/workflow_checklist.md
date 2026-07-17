# COMSOL simulation checklist

## Environment

- [ ] Read `known_issues.md` and apply relevant prevention rules.
- [ ] Use MATLAB MCP; do not launch MATLAB from a shell or COMSOL shortcut.
- [ ] Treat this MCP call as an independent batch session.
- [ ] Add `D:\Program Files\COMSOL\COMSOL56\Multiphysics\mli`.
- [ ] Confirm `which mphstart` and `which mphopen` are nonempty.
- [ ] If `visualMode=true`, confirm `which mphlaunch` is nonempty.
- [ ] Connect to the manually started COMSOL Server, preferring port 2036.
- [ ] Confirm configured `serverHost` and `serverPort` from the Server window
      or log; do not guess or silently start a second Server.
- [ ] Put critical variables in the generated launcher, not only MCP `args`.
- [ ] Select `visualMode`: true for development/debug/single case, false for
      unattended or large sweeps.
- [ ] Before `mphlaunch`, inspect `ModelUtil.modelsUsedByOtherClients()` and
      stop/report if another client owns a different model tag.
- [ ] If MATLAB MCP has no `windir`, set it from valid `SystemRoot` for this
      MATLAB process only.

## Simulation contract

- [ ] Objective and quantities of interest are explicit.
- [ ] Geometry source, dimensions, and coordinate system are explicit.
- [ ] Parameters carry units where applicable.
- [ ] Materials and property sources are explicit.
- [ ] Physics interfaces and assumptions are explicit.
- [ ] Domains, boundaries, loads, inlets/outlets, and constraints are explicit.
- [ ] Mesh strategy and study type are explicit.
- [ ] Output data, plots, model name, and save location are explicit.
- [ ] Long-run case count, ranges, outputs, and location were reported first.

## API evidence

- [ ] Existing project files and successful runs were inspected first.
- [ ] Uncertain tags, feature types, variables, and properties were queried.
- [ ] Any official reference `.mph` passed a read-only `mphopen` test.
- [ ] No tag, entity ID, variable, unit, or physics assumption was guessed.

## Build

- [ ] Geometry built successfully.
- [ ] Selections were queried after the final geometry build.
- [ ] `mphselectbox` boxes enclose entity vertices with tolerance.
- [ ] Named selections were created and entity counts asserted.
- [ ] Java tags use `cell` plus `cellfun(@char,...)` conversion.
- [ ] Material-backed properties do not remain at `from_mat` without materials.
- [ ] Physics and boundary conditions were added in a minimal baseline.
- [ ] Mesh generated successfully.
- [ ] One baseline study exists before any sweep or coupling expansion.

## Run and verify

- [ ] A new timestamped run directory was created for this attempt.
- [ ] Diary and progress output are active.
- [ ] Solver completed and warnings were inspected.
- [ ] Results passed physical sanity or analytical checks where possible.
- [ ] `.mph`, workspace, report, data, and plots were saved.
- [ ] Failure runs include `error_report.txt` with an extended report.
- [ ] Successful models were reopened in a fresh MATLAB MCP session.
- [ ] Physics tags and at least one stored result were verified after reopen.
- [ ] Original and successful models were not overwritten.
- [ ] Visual mode launched at most once outside parameter loops.
- [ ] The Desktop-reported model tag exactly matches the MATLAB model tag.
- [ ] GUI and API edits were not performed concurrently.
- [ ] If manual editing is planned, `checkpoint_state.json`, diary, Codex
      message, and exact model tag all confirm `PAUSED/safeToEdit=true`.
- [ ] The user was not asked to type launcher variables or create continue
      flags.
- [ ] Pre/post-edit snapshots and `.mph` copies were saved in the run.
- [ ] `manual_change_report.md/.json` was reviewed and ambiguous settings were
      checked with targeted COMSOL API queries.
- [ ] Resume approval matches both checkpoint stage and exact model tag.
- [ ] If the launch MCP call timed out with the GUI open, completion was
      verified from the diary, responsive process, exact client tag, and a
      fresh-session parameter readback; the GUI was not force-terminated.

## Closeout

- [ ] Actual completed work is separated from assumptions or future work.
- [ ] Latest successful and failed run paths are recorded.
- [ ] Every solved failure was added to `known_issues.md`.
- [ ] New reusable baseline facts were added to `validated_baselines.md`.
