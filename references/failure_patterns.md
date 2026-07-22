# Failure patterns and recovery rules

This is the reusable, sanitized index of failures observed in real
MATLAB-MCP/LiveLink/COMSOL work. Read `known_issues.md` for dated evidence and
project files for case-specific values.

## Contents

- [Control chain and process ownership](#control-chain-and-process-ownership)
- [MATLAB launchers and files](#matlab-launchers-and-files)
- [COMSOL API and version traps](#comsol-api-and-version-traps)
- [Geometry, CAD, selections, and units](#geometry-cad-selections-and-units)
- [Desktop observation and manual edits](#desktop-observation-and-manual-edits)
- [Results and visualization](#results-and-visualization)
- [Nonlinear contact and time dependence](#nonlinear-contact-and-time-dependence)
- [Anti-repetition rule](#anti-repetition-rule)

## Control chain and process ownership

| Symptom | Likely cause | Required response |
|---|---|---|
| A new MATLAB or Server appears | Automation bypassed the fixed chain | Stop; retain the MATLAB MCP process and the one user-started Server only. |
| MATLAB exits but COMSOL still computes | The solve was already submitted Server-side | Do not resubmit. Read `progress.log`, inspect the exact Server/Study, and verify cancellation at the Server level. |
| MATLAB MCP times out during a solve | Transport timeout is shorter than solver duration | Treat state as unknown/running, not failed. Inspect the same run and never launch a duplicate. |
| Several large models finish, then MATLAB exits abnormally | Native teardown instability after many model open/remove cycles | Prefer one independent large model per MCP batch and require clean fresh-session verification. |
| Saved MPH remains locked | Exact model tag is still loaded on Server | Query all and other-client tags; remove only the automation-owned unused tag. |

## MATLAB launchers and files

| Symptom | Likely cause | Required response |
|---|---|---|
| Project script cannot see MCP arguments | Each execute call is an independent batch and critical args were not injected | Assign every path/value in the generated launcher, then call `run(projectScript)`. |
| Generated launcher fails at parse time | Dense nested expressions or broken quoting | Keep launchers shallow; split calculations and parse-test before an expensive solve. |
| Solve succeeded but report generation failed | Reporting code was coupled to solving | Preserve MPH/workspace; rebuild the report without resolving. Test report assembly on small data. |
| Preference-file permission error occurs after `mphsave` | MATLAB preference directory is restricted | Separate filesystem preference failure from COMSOL failure and preserve the already-written model. |
| Chinese text becomes mojibake | UTF-8 bytes were decoded through a legacy code page | Use byte-preserving copies or explicit UTF-8 reads; reject replacement/mojibake markers before publishing. |
| Timestamp contains unexpected characters | Unsupported MATLAB datetime pattern | Test formatting on the installed MATLAB and use a timezone-neutral millisecond timestamp. |
| Exported M-file is unexpectedly tiny | COMSOL model history is disabled | Treat M-file export as supplementary; use structured API snapshots as primary evidence. |

## COMSOL API and version traps

| Symptom | Likely cause | Required response |
|---|---|---|
| Official `.mph` opens as preview | Application Library path is a placeholder | Prove every reference with read-only `mphopen` before using it as API evidence. |
| Java tag conversion fails | MATLAB cannot directly `cellstr` a Java string array | Use `cell(javaTags)` then `cellfun(@char,...)`. |
| Evaluator rejects a familiar option | LiveLink functions differ by version and evaluator | Read installed help for that exact function; do not assume option parity. |
| `getType`, `contains`, or `getVersion` is missing | Assumed Java convenience method is not exposed | Query `properties()`/`tags()` and convert returned Java values explicitly. |
| Array-valued property fails with `getString` | Wrong scalar getter | Inspect the installed property and use the appropriate array getter. |
| Contact/structural expression cannot find `u` | COMSOL allocated `u2,v2,w2` or another field name | Query `physics.field(...).component()` and persist/assert the returned component name. |
| Geometry feature rejects `input/tool` | Property names were copied from a different partition feature | Query installed properties for the exact feature type and finalize full geometry before counting entities. |
| MATLAB structure assignment fails in a loop | Empty zero-field struct cannot accept populated records | Accumulate heterogeneous/nested records in cells, then concatenate after construction. |

## Geometry, CAD, selections, and units

| Symptom | Likely cause | Required response |
|---|---|---|
| CAD appears 1000 times too small/large | Import unit semantics and geometry length unit were mixed | Record `lengthUnit` and scale factor; verify three known dimensions plus one area/volume before physics. Scale same-assembly imports together. |
| Plot coordinates are 1000 times too large | Geometry coordinates were already in mm and were scaled again | Treat coordinate units separately from expression units and assert coordinate ranges before plotting. |
| Visible entity is not selected by `mphselectbox` | Box lies inside the entity; selection tests vertices | Enclose the complete entity bounding box with tolerance and assert count. |
| Material property is undefined | Physics remains `from_mat` without a material node | Query allowed sources, use `userdef`, and set every required property explicitly. |
| Correct geometry fails an absolute equality assertion | Tolerance ignores measurement scale | Audit topology and spans, then use a documented relative tolerance. Never weaken first without evidence. |
| Boolean/vector agreement unexpectedly fails | Row/column implicit expansion produced a matrix | Normalize decoded vectors with `(:).'` before scalar comparisons. |
| Garbled CAD names cause wrong identity | Labels were treated as semantic identity | Identify bodies by volume, area, bounding box, centroid, dimensions, repetition, and position; create named selections and assert counts. |
| Contact or mesh comparison yields no event | Initial gap/reference state never reaches contact/snap/flux path | Stop before medium/fine meshes; visualize local gaps and review the reference state. |

## Desktop observation and manual edits

| Symptom | Likely cause | Required response |
|---|---|---|
| `mphlaunch` returns but no attached Desktop exists | Client crashed or did not remain attached | Require the exact tag in `modelsUsedByOtherClients()`; return value alone proves nothing. |
| Visual client crashes with a WPF URI/font error | MATLAB batch lacks process-level `windir` | Set `windir` from valid `SystemRoot` for that MATLAB process only. |
| Model label changes after save | `mphsave` associates label with output filename | Capture label before/after save; use exact tag and parameter readback as persistent evidence. |
| MCP call hangs while Desktop stays responsive | Visual child retained inherited output handles | Verify diary, process, exact tag, and fresh readback. Do not close the GUI merely to unblock transport. |
| GUI looks idle so user starts editing | Observation was mistaken for a safe pause | Allow edits only with `PAUSED`, `safeToEdit=true`, matching tag, snapshots, and no active model operation. |
| Snapshot reports display-only changes | Volatile result property changed through observation | Filter only empirically confirmed volatile properties; target-query every physics-relevant ambiguity. |

## Results and visualization

| Symptom | Likely cause | Required response |
|---|---|---|
| Derived force violates symmetry while field looks symmetric | Sharp-edge Maxwell-stress surface/integration mesh dominates | Freeze model, visualize field and force, isolate sources, and cross-check on a symmetric air surface or energy method before refining. |
| Flux quadrature oscillates with order | Integration surface crosses a material/field discontinuity | Plot the integrand and partition quadrature at interfaces before raising order. |
| Contact area above zero is implausibly huge | Numerical interpolation noise is counted as contact | Report pressure-threshold sensitivity, total force, peak pressure, and spatial maps; use a justified positive threshold. |
| Gap contains undefined samples | Pair mapping is undefined outside valid overlap | Count undefined samples and report min/max only on the finite subset. |
| Plot triangulation fails | `mpheval.t` is zero-based integer connectivity | Audit coordinate/connectivity shapes and convert connectivity with `double(t)+1`. |
| A converged result is physically empty | Load, contact, flux path, or event is inactive | Treat as model/reference-state evidence, not mesh convergence or device performance. |

## Nonlinear contact and time dependence

| Symptom | Likely cause | Required response |
|---|---|---|
| Stationary continuation repeatedly reaches NaN/Inf after first contact | Usable static branch may have ended | Preserve last valid state, render pressure/gap, localize failed DOFs, try at most one justified midpoint, then reassess formulation. |
| Transient cannot reuse stationary seed | Contact method changed auxiliary variables | Compare dependent variables and retain a compatible contact formulation or map fields explicitly. |
| Transient spends a long time at `t=0` | Auto time step is incompatible with requested output/contact scale | Compare with an official same-physics model and validate a very short manual-step prefix before extension. |
| Expected final output time is missing | Decimal endpoint is below an integer multiple by one floating increment | Build time lists from integer multiples; inspect stored `solvals` before calling it a solver failure. |
| Peak contact pressure will not converge at a free edge | Local singularity/mesh sensitivity dominates `Pmax` | Use total normal force, force-displacement curve, thresholded area, gaps, and compression as primary metrics. Keep `Pmax` auxiliary. |
| Long diagnostic transient produces plausible pressure | Missing real forcing, gravity, damping, or calibration | Label it `diagnostic_only`; never promote its time/pressure/area to real-device dynamics. |

## Anti-repetition rule

Before any retry, state all four items:

1. the falsifiable hypothesis explaining the failure;
2. the single change that tests it;
3. the evidence that would confirm or reject it;
4. the stop condition.

If a proposed retry cannot supply all four, do not run it. Render or inspect the
existing evidence instead. Two consecutive occurrences of the same failure
class require a checkpoint report and user decision, not another automatic
mesh, step, tolerance, unit, or solver modification.
