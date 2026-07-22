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

## Codex–COMSOL Bridge local replacement regression

Validated on 2026-07-18 after replacing both the user-level and project-level
skills with `codex-comsol-bridge`:

- Baseline run: `runs/20260718_001618_structural_cantilever_new_skill`.
- MATLAB MCP connected to `localhost:2036`; no second MATLAB or Server was
  started.
- One 3D linear-elastic cantilever case solved in 7.301 s.
- Maximum displacement: 0.002006962259961058 m.
- Tip-center displacement: 0.002001204271869751 m.
- Maximum von Mises stress: 64945504.38433591 Pa.
- Beam-theory tip difference: 0.0602135934875707%.
- Fresh-session verification:
  `runs/20260718_001817_structural_reopen_verification`.
- Reopen confirmed physics tag `solid` and reproduced maximum displacement
  with relative difference `1.080441016869486e-15`.
- The saved model was not overwritten. Final SHA-256:
  `02D631E699E9619B863C4539F4328AA9BC25E2F5E5C60ECF0A776CEC1D11496A`.
- `visualMode=false` was used for this deterministic regression run.

## Symmetry-led permanent-magnet force diagnostic

Validated on 2026-07-18 with MATLAB R2022b, COMSOL Server 5.6, LiveLink for
MATLAB, and a stored 3D Magnetic Fields, No Currents solution:

- A body-surface Maxwell-stress result showed a symmetry-forbidden lateral
  force above 10% of the main attractive component.
- Orthogonal field-line plots showed a visually symmetric primary field.
- Re-solving one bounded case with only the local three-source group enabled
  left the erroneous body-surface lateral components nearly unchanged, so the
  other sources were not the cause.
- Symmetric closed-cuboid Maxwell-stress probes in air reduced the lateral
  ratio below 1% while preserving the main attractive force within the
  diagnostic convergence band.
- Probe offset and quadrature order were varied independently; a fresh MATLAB
  MCP session reopened the saved model and reproduced the reusable function's
  force result to floating-point precision without solving again.
- This validates the diagnostic method, not a universal probe dimension or a
  publication acceptance threshold. Each project must scan probe offset and
  quadrature order and cross-check representative cases with energy or virtual
  work.

Reusable implementation:
`scripts/evaluate_maxwell_force_probe.m`.

## COMSOL 5.6 transient-contact API evidence

Validated read-only on 2026-07-19:

- `Structural_Mechanics_Module\Verification_Examples\ring_impact.mph`
  confirms `Transient`, generalized-alpha, `PenaltyDynamic`, and
  `AugmentedLagrangeDynamic` APIs.
- `Structural_Mechanics_Module\Contact_and_Friction\transient_rolling_contact.mph`
  confirms that a Time Dependent study can retain `AugmentedLagrange` and use
  generalized-alpha integration.
- The local ShellContact allowed-value query returned `Penalty`,
  `PenaltyDynamic`, `AugmentedLagrange`, and `AugmentedLagrangeDynamic`.
- Changing an already solved stationary model to
  `AugmentedLagrangeDynamic` can change contact auxiliary variables and make
  the stationary solution fail during transient initial-value merging. Method
  availability does not prove seed compatibility.

Evidence: `runs/20260719_184500_comsol56_official_transient_contact_api_audit`
and `runs/20260719_185000_stage4_shell_dynamic_contact_allowed_values_audit`.
