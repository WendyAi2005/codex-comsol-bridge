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

- [ ] If restarting, old runs/models were frozen and classified instead of
      overwritten or silently reused.
- [ ] A physical stage tree with one question, inputs, outputs, pass criteria,
      and stop conditions per checkpoint was written before model changes.
- [ ] One machine-readable parameter source exists; its revision and hash will
      be copied into each run.
- [ ] Objective and quantities of interest are explicit.
- [ ] Geometry source, dimensions, and coordinate system are explicit.
- [ ] Parameters carry units where applicable.
- [ ] Materials and property sources are explicit.
- [ ] Physics interfaces and assumptions are explicit.
- [ ] Domains, boundaries, loads, inlets/outlets, and constraints are explicit.
- [ ] Mesh strategy and study type are explicit.
- [ ] Output data, plots, model name, and save location are explicit.
- [ ] Long-run case count, ranges, outputs, checkpoint cadence, time budget,
  cancellation route, and location were reported first.
- [ ] `progress.log`, a read-only human monitor, and verified convergence plots
  are configured before submitting the solve.

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
- [ ] Diary and run-local `progress.log` are active and changing as expected.
- [ ] Long work is split into measured, restartable blocks with a saved `.mph`
  and last accepted state after every block.
- [ ] A requested stop was verified at the Server/solve level; MATLAB exit was
  not used as the sole stop signal.
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

## Suspicious-result triage

- [ ] The proposed retry states a falsifiable hypothesis, one testing change,
      confirming/rejecting evidence, and a stop condition.
- [ ] The same failure class has not already repeated twice without a user
      checkpoint.
- [ ] The violated physical expectation was stated explicitly.
- [ ] The successful model, solution, mesh statistics, and result were
      preserved before any diagnostic change.
- [ ] Field convergence was separated from derived-integral convergence.
- [ ] A diagnostic plot showed geometry, axes, units, and the questionable
      vector or integral.
- [ ] Static, parametric, frequency-domain, and transient results were labeled
      accurately.
- [ ] One source, body, mesh region, or result operator was changed at a time.
- [ ] A symmetry, conservation, reaction, energy, or alternative-evaluator
      cross-check was attempted before broad mesh refinement.
- [ ] Any human-review request included the exact artifact, coordinate frame,
      expected behavior, discrepancy, and one bounded question.
- [ ] Human visual review was not treated as GUI-edit authorization.
- [ ] Mesh refinement was targeted to the region and element direction
      implicated by evidence.
- [ ] The coarse model reaches the event being compared before medium/fine
      meshes are authorized.
- [ ] Pre/post-edit snapshots and `.mph` copies were saved in the run.
- [ ] `manual_change_report.md/.json` was reviewed and ambiguous settings were
      checked with targeted COMSOL API queries.
- [ ] Resume approval matches both checkpoint stage and exact model tag.
- [ ] If the launch MCP call timed out with the GUI open, completion was
      verified from the diary, responsive process, exact client tag, and a
      fresh-session parameter readback; the GUI was not force-terminated.
- [ ] Contact area was reported with pressure-threshold sensitivity; a raw
      `pressure > 0` integral was not accepted without a numerical-noise audit.
- [ ] Undefined mapped-gap samples were counted and the finite subset was
      reported explicitly.
- [ ] After a post-contact stationary failure, at most one evidence-based
      midpoint was attempted before reassessing static-branch stability.
- [ ] Any stationary-to-transient change checked contact auxiliary-variable
      compatibility with the selected initial solution.

## Closeout

- [ ] Actual completed work is separated from assumptions or future work.
- [ ] Latest successful and failed run paths are recorded.
- [ ] Every solved failure was added to `known_issues.md`.
- [ ] New reusable baseline facts were added to `validated_baselines.md`.
