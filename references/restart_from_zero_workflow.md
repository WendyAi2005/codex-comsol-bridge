# Clean restart workflow

Use this workflow when a previous COMSOL effort became too long, mixed
diagnostics with physical conclusions, or accumulated uncertain geometry,
solver, and reference-state choices.

## Contents

- [Reset rules](#reset-rules)
- [Stage tree](#stage-tree)
- [Checkpoint contract](#checkpoint-contract)
- [Stop and ask rules](#stop-and-ask-rules)
- [Promotion rules](#promotion-rules)

## Reset rules

1. Preserve every original CAD, parameter file, `.mph`, successful run, and
   failed run. Never restart by overwriting or deleting evidence.
2. Mark old solutions with an explicit scope such as `diagnostic_only`,
   `geometry_evidence_only`, or `superseded`. Do not leave interpretation
   implicit.
3. Start a new project lineage or timestamped baseline model. Do not initialize
   it from an old solution unless the user explicitly accepts the old physics,
   variables, contact formulation, and reference state.
4. Create one machine-readable parameter source. Generate human-readable
   parameter documentation from it. Record revision and SHA-256 in every run.
5. Write the physical stage tree before opening COMSOL. Each stage must answer
   one physical question and have defined inputs, outputs, pass criteria, and
   stop conditions.
6. Keep solver/contact diagnostics separate from real-device or paper results.
   Missing gravity, damping, magnetic coupling, inertia, or calibration must be
   visible in the result status.

## Stage tree

### R0 — Freeze and inventory

- Question: What evidence exists, and what is its valid interpretation scope?
- Inputs: old models, runs, diaries, reports, images, parameter files.
- Outputs: inventory, immutable source paths, accepted/superseded statuses,
  unresolved physical questions.
- Pass: no source artifact is overwritten; facts and assumptions are separated.
- Stop: any original file identity or provenance is uncertain.

### N0 — Physical contract

- Question: What device behavior will this new model answer?
- Inputs: geometry description, coordinate frame, materials, loads, motion,
  measured/calibrated values, requested outputs.
- Outputs: one-page contract and ordered stage tree.
- Pass: every material assumption, direction, sign, unit, and excluded effect is
  explicit.
- Stop: two plausible interpretations would materially change the physics.

### E0 — Environment and connection

- Question: Is the fixed MATLAB MCP → MATLAB → LiveLink → existing Server chain
  working without a second MATLAB or Server?
- Inputs: configured MLI path, host, port, versions.
- Outputs: connection log, exact process IDs, model tags, optional Desktop tag.
- Pass: one MATLAB, one intended Server, verified API availability.
- Stop: host/port, version, license, or ownership is ambiguous.

### G0 — Geometry and reference state

- Question: Are scale, coordinate frames, identities, relative positions,
  interfaces, gaps, and intended motions physically correct?
- Inputs: untouched CAD plus parameter source.
- Outputs: geometry manifest, measurements, selections, annotated orthogonal
  views, initial-gap map, assertions.
- Pass: at least three known lengths and one area/volume agree with their
  unit-consistent targets; expected repeated bodies and selections match.
- Stop: scale/alignment is uncertain, a selection count fails, or the physical
  reference state cannot be identified.

### P0 — Minimal single-physics baseline

- Question: Does one physics interface reproduce the expected sign, symmetry,
  scale, and boundary-condition behavior?
- Inputs: G0 geometry, explicit materials and property sources, minimum loads.
- Outputs: one bounded solution and sanity checks.
- Pass: field and integral checks agree within a declared tolerance.
- Stop: an unexpected force, flux, displacement, reaction, or contact region is
  unexplained. Visualize and isolate before changing the mesh.

### M0 — Mesh evidence

- Question: Is the target physical event active, and are the relevant integral
  quantities adequately resolved?
- Inputs: accepted P0 model; coarse mesh first.
- Outputs: mesh statistics, local quality, target-event result.
- Pass: the coarse model reaches the physical event and produces finite,
  interpretable outputs.
- Stop: the event is absent. Fix the reference state/model definition; do not
  spend on medium/fine meshes.

### S0 — One representative study

- Question: Can one representative case solve with bounded cost and observable
  convergence?
- Inputs: accepted geometry, physics, and coarse/working mesh.
- Outputs: diary, `progress.log`, convergence plot, result table, run-local MPH.
- Pass: stored solution is finite, physically plausible, and warning-audited.
- Stop: repeated failure class, runaway iteration cost, or no accepted state.

### V0 — Fresh-session acceptance

- Question: Are the saved model and results reusable outside the creating
  MATLAB session?
- Inputs: saved S0 MPH.
- Outputs: independent reopen report; persisted tags, mesh, study, solution
  values, and at least one physical result.
- Pass: no rerun is needed and results reproduce.
- Stop: abnormal MATLAB exit, missing solution, tag drift, or file lock whose
  ownership is unclear.

Only after V0 may the model add one complexity at a time: parameter lookup,
nonlinearity, contact, time dependence, motion, circuit coupling, or full
multiphysics.

## Checkpoint contract

For every checkpoint record:

- physical question;
- exact input model and parameter revision/hash;
- number of cases and parameter list;
- active and deliberately inactive physics;
- mesh tag/statistics;
- output definitions and units;
- pass criteria and stop conditions;
- run directory and model/study/solution tags;
- `SAFE_TO_EDIT` state;
- whether the result is physical, calibrated, exploratory, or diagnostic.

When the user requests manual review after each physical checkpoint, stop after
the report. Do not infer permission to run the next mesh, range, coupling, or
study.

## Stop and ask rules

Stop and request one bounded user decision when:

- CAD orientation, polarity, assembly alignment, contact side, or intended
  motion cannot be proven from artifacts;
- a result is numerically converged but contradicts the visible geometry or a
  physical invariant;
- two consecutive retries reproduce the same failure class;
- mesh refinement or step bisection is being repeated without a new hypothesis;
- a diagnostic model omits physics required for the requested device claim;
- the coarse model never reaches the event intended for mesh comparison;
- a long solve lacks a trustworthy progress log, convergence plot, or stop
  route.

The user question must include the exact image or report, coordinate convention,
expected behavior, observed discrepancy, and the consequence of each choice.

## Promotion rules

Promote a checkpoint only when:

1. the solver completed without unreviewed warnings;
2. the intended physical event occurred;
3. result definitions and units were independently checked;
4. spatial plots agree with integral outputs;
5. the saved MPH passed fresh-session reopen/readback;
6. diagnostic limitations are explicit;
7. the user approved the next physical checkpoint when approval was requested.
