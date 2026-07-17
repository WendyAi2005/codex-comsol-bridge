# New COMSOL project workflow

## Inheritance

Codex reads `AGENTS.md` from the opened project and applicable parent
directories. Folder inheritance is environment-dependent; do not assume a new
folder automatically inherits a particular parent file. Install the user-level
`comsol-matlab-sim` skill so it remains available when a completely unrelated
folder is opened as a new project.

Create a project-specific `AGENTS.md` only when the project needs additional
rules, a different environment, or explicit physical decisions. Do not copy
fixed physical parameters from another project without user confirmation.

## Recommended structure

```text
project/
  AGENTS.md              # optional project overrides and physical decisions
  models/                # source and generated models; never overwrite source
  src/                   # MATLAB model-building and postprocessing scripts
  runs/                  # one timestamped folder per attempt
  results/               # curated final exports only
  scripts/               # project launchers or utilities
  .agents/skills/        # optional project-only extensions
```

## Bootstrap sequence

1. Read inherited and project `AGENTS.md` files.
2. Load the global `comsol-matlab-sim` skill.
3. Create the project structure without deleting existing content.
4. Inventory existing `.mph`, `.m`, `.mat`, logs, and exported model files.
5. Run a minimal MCP connection test; do not open a large model yet.
6. Write the simulation contract: objective, geometry, units, materials,
   physics, boundary conditions, mesh, study, outputs, and save locations.
7. Inspect the closest validated or official reference only for API evidence.
8. Build and solve one minimal baseline case.
9. Save all artifacts and compare with a simple physical or analytical check.
10. Reopen the saved `.mph` in a fresh MATLAB MCP session and verify tags and
    one stored result.
11. Add one complexity at a time and preserve each run directory.
12. If GUI editing is expected, run the lightweight checkpoint/diff smoke test
    before a long model build.

## Reuse boundaries

Reuse these workflow mechanisms freely:

- MATLAB MCP launcher pattern.
- mli path and COMSOL Server connection sequence.
- timestamped artifact contract.
- evidence-first API inspection.
- named-selection and entity-count assertions.
- explicit `*_mat=userdef` handling when no material node exists.
- failure classification, minimal retry, and known-issue recording.
- save/reopen/result-read verification.
- verified manual checkpoint, before/after snapshots, targeted diff review,
  and Codex-only resume approval.
- portable environment configuration through `comsol_config_template.m`.

Do not automatically reuse these physical decisions:

- geometry dimensions
- material values
- loads, inlet speeds, magnetization, contact laws, or turbulence models
- mesh size
- study type
- solver tolerances
- parameter ranges
- coupling direction or rotating-frame assumptions

Those belong to each new project's simulation contract.
