# Nonlinear contact and snap-through diagnostics

Use this reference before retrying a post-buckling contact, snap-through,
impact, or stationary continuation failure.

## Evidence-first stopping rule

1. Preserve the last valid `.mph`, failed `.mph`, diary, error report, mesh
   statistics, parameter snapshot, and exact seed solution number.
2. Plot deformed geometry, mapped gap, contact pressure, and failed-coordinate
   locations in the model coordinate system before changing mesh or solver.
3. Reject a stored state when its scale is physically impossible even if all
   values are technically finite. Values near `1e100` are failed-iteration
   artifacts, not solutions.
4. Try at most one midpoint after a failed continuation step. If the midpoint
   fails with the same class of NaN/Inf error, stop step bisection and diagnose
   branch stability or formulation.
5. Refine only a region implicated by the plots and failure coordinates. Do
   not use repeated global refinement as a generic convergence remedy.

## Contact metrics

- Report peak pressure, contact force, mapped gap, and pressure-thresholded
  area together.
- Keep the user's strict `pressure > 0` area definition, but flag it as
  numerically noise-sensitive. Also report at least three small positive
  pressure thresholds or a documented relative threshold.
- Count undefined mapped-gap samples separately. Compute minimum gap from the
  finite mapped subset; do not silently replace undefined values with zero.
- Validate coordinate units independently. `mpheval(...).p` can follow the
  geometry coordinate unit even when expression outputs request another unit;
  do not multiply coordinates by 1000 without a range assertion.
- Do not compare extrema from `mphmax` and refined `mpheval` with exact
  equality. Record evaluator and refinement, then use a scale-aware tolerance.

## Stationary-to-transient transition

Interpret alternating free-edge NaN/Inf failures after first contact as
possible loss of the stationary post-contact branch, especially when a
smaller continuation step also fails. A transient impact or dynamic relaxation
may then be the correct formulation.

Before changing study type:

1. Inspect a loadable COMSOL 5.6 Application Library contact/impact model.
2. Query the current contact feature's allowed method values.
3. Preserve the stationary seed and verify its exact study and solution number.
4. Check dependent-variable compatibility. Changing from an augmented
   Lagrangian method to its dynamic variant can change auxiliary variables and
   make a stationary solution impossible to merge as transient initial data.
5. Prefer a transient contact method demonstrated by an official model that
   preserves the seed variables, or explicitly map only compatible fields.
6. Derive the time scale from a physical event such as RPM and pole pitch.
   Label an arbitrary numerical ramp as relaxation, never as a physical peak.

## Triboelectric claim boundary

Do not call maximum pressure the best generating point. A candidate workpoint
must consider effective area, area-weighted mean pressure, peak pressure,
pressure uniformity, contact duration, separation, material limits, cyclic
durability, and an experimentally calibrated pressure-to-charge relation.
