# Validated COMSOL 5.6 Baselines

Validated on 2026-07-17 through the configured MATLAB MCP, MATLAB R2022b,
COMSOL Multiphysics Server 5.6, and the LiveLink directory:

`D:\Program Files\COMSOL\COMSOL56\Multiphysics\mli`

## Official models inspected as API references

| Area | Official model | Confirmed API details |
|---|---|---|
| AC/DC | `ACDC_Module\Magnetostatics\permanent_magnet.mph` | `MagnetostaticsNoCurrents`, `MagneticFluxConservation`, `ZeroMagneticScalarPotential`, `mfnc.normB`, `mfnc.Bx/By/Bz` |
| Structural | `COMSOL_Multiphysics\Structural_Mechanics\tapered_cantilever.mph` and `Structural_Mechanics_Module\Verification_Examples\large_deformation_beam.mph` | `SolidMechanics`, `Fixed`, `BoundaryLoad`, `ForceArea`, `solid.mises`, `solid.disp` |
| CFD | `COMSOL_Multiphysics\Fluid_Dynamics\cylinder_flow.mph` | `LaminarFlow`, `InletBoundary`, `OutletBoundary`, `U0in`, `p0`, `spf.U`, `p` |

## From-scratch models actually solved

| Baseline | Script | Physics tag | Main verified result | Successful run |
|---|---|---|---|---|
| 3D permanent magnet in air | `src/build_acdc_permanent_magnet.m` | `mfnc` | max `|B|` = 0.892158686 T | `runs/20260717_112255_acdc_permanent_magnet_retry2` |
| 3D steel cantilever | `src/build_structural_cantilever.m` | `solid` | tip displacement = 0.00200120427 m; beam-theory difference = 0.0602% | `runs/20260717_113214_structural_cantilever_retry1` |
| 3D laminar circular pipe | `src/build_cfd_3d_pipe.m` | `spf` | max velocity = 0.0193780116 m/s; pressure drop = 0.423059028 Pa | `runs/20260717_114147_cfd_3d_laminar_pipe` |

The earlier 2D channel model in `src/build_cfd_laminar_channel.m` remains a
working auxiliary example, but the validated CFD baseline for future work is
the 3D circular pipe.

## Saved-model reopen verification

`src/verify_multiphysics_baselines.m` was executed in a fresh MATLAB MCP batch
session. It reopened the three saved `.mph` files, confirmed physics tags
`mfnc`, `solid`, and `spf`, and read stored solution metrics without rerunning
the studies.

Final verification run:

`runs/20260717_114811_reopen_verification_3d_cfd_final`

## Reusable prevention rules learned

- `mphselectbox` must enclose the target entity's vertices; an inner box can
  return zero entities even when it lies inside the domain.
- A minimal model without material nodes must set `*_mat='userdef'` and supply
  every required material property explicitly.
- COMSOL 5.6 `mphmax` does not accept a `'unit'` name/value argument.
- MATLAB MCP executions are independent batch sessions; pass required paths in
  the generated launcher and do not rely on a previous workspace.
- Convert COMSOL Java tag arrays with `cell(...)` followed by
  `cellfun(@char, ..., 'UniformOutput', false)`.
- A read-only warning from `mphopen` is expected during verification and helps
  ensure original saved models are not overwritten.

## Native Desktop same-model observation baseline

Validated on 2026-07-17 with `mphlaunch(model,10000)` through MATLAB MCP:

- Successful run: `runs/20260717_150639_visual_sync_test`
- Server model tag: `CodexVisualTest20260717150718`
- Desktop attachment: the exact tag appeared in
  `ModelUtil.modelsUsedByOtherClients()`.
- API synchronization probe: `visual_sync_probe = 2[mm]`.
- A fresh MATLAB MCP session reattached to the same server, confirmed the
  Desktop tag, and read the same parameter value.
- No Study was run, the input `.mph` was copied first, and only the run-local
  copy was saved.

The required MATLAB MCP workaround is process-local: if `windir` is missing,
copy the valid `SystemRoot` value to `windir` before `mphlaunch`. The helper
must still confirm the exact model tag because a return from `mphlaunch` alone
does not prove that the GUI stayed open.

## Full visual 3D CFD workflow

Validated on 2026-07-17 by reusing the same Desktop-attached server model and
building every stage through MATLAB MCP:

- Successful run: `runs/20260717_164308_visual_cfd_3d_full_workflow`
- Checkpoints: connection, parameters, geometry/selections, physics, mesh,
  pre-solve, solved, and results saved.
- Physics: 3D Laminar Flow (`spf`), one stationary case, no sweep.
- Solve time: 134.444 s.
- Maximum velocity: 0.01937801161251777 m/s.
- Pressure drop from z=0.01 m to z=0.49 m: 0.4230590283980105 Pa.
- A fresh MATLAB MCP session confirmed the live Desktop tag, reopened the
  saved `.mph` under a new tag, verified `spf`, `mesh1`, `std1`, and `pgv`, and
  read identical stored values without solving again.
- No original model was overwritten and no second Desktop or Server started.

The reusable staged script is `src/run_visual_cfd_3d_full_workflow.m`. A later
lightweight protocol test validated the safer checkpoint design: the launcher
selects a planned stage, `checkpoint_state.json` exposes `PAUSED` and
`safeToEdit=true`, a separate MATLAB MCP session snapshots and compares the
same live model, and the runner resumes only after a Codex-generated
`approved_continue_<stage>.json` matches both stage and model tag. The user
never creates a continue flag.

## Verified manual checkpoint and diff protocol

Validated on 2026-07-17 without solving or overwriting a source model:

- Final snapshot smoke test: `runs/20260717_172734_snapshot_diff_verified`.
- Captured 64 live model nodes through COMSOL 5.6 readable APIs.
- A temporary parameter produced exactly one captured change.
- Removing it produced zero changes against the original structured snapshot.
- Final pause/resume test: `runs/20260717_172923_checkpoint_protocol_verified`.
- The paused runner published `PAUSED/safeToEdit=true`; a second MATLAB MCP
  session verified the exact same model tag, captured the change, wrote a
  report and validated approval; the original runner changed to
  `RESUMING/safeToEdit=false`.
- The final test restored the original model label, removed the temporary
  parameter, used valid millisecond timestamps, and reconfirmed the exact
  Desktop-attached model tag from a fresh MCP session.
- Result property `touchpostshow` was observed to change merely from display
  access and is filtered as volatile.
- COMSOL M-file export can be incomplete when model history is disabled; use
  the structured snapshot plus targeted queries as primary evidence.
