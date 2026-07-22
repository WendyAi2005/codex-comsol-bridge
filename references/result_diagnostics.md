# Result anomaly diagnostics

Use this workflow after a native COMSOL solve completes but a field, force,
flux, stress, displacement, or integral result appears nonphysical.

## Core rule

Treat mesh refinement as a hypothesis test, not a reflex. More elements do not
prove that a derived result is more physical. First determine whether the
problem is in the model, field solution, result operator, visualization, or
interpretation.

## Evidence ladder

1. Preserve the solved `.mph`, diary, mesh statistics, tables, and parameter
   snapshot in the current run directory.
2. State the violated expectation precisely: symmetry, zero component, sign,
   scale, conservation, monotonicity, or analytical limit.
3. Query the exact selections, coordinate frame, units, physics features,
   material sources, boundary conditions, and result expressions from the
   model. Do not infer them from labels or plots.
4. Compare the primary field across the existing mesh levels separately from
   the derived quantity. A stable field with an unstable surface integral
   points to result evaluation or local mesh topology, not necessarily the PDE
   solution.
5. Render diagnostic plots before another solve:
   - show geometry and coordinate axes;
   - plot scalar magnitude plus vector direction or streamlines;
   - overlay the questionable force, flux, or displacement;
   - include symmetry planes and expected zero directions;
   - state whether the image is static, parametric, frequency-domain, or truly
     time-dependent.
6. Ask for human visual interpretation only with a bounded question. Supply
   the exact artifact, expected behavior, observed discrepancy, and the
   coordinate/polarity convention. Continue safe read-only diagnostics while
   waiting when possible.
7. Isolate one cause at a time. Examples include disabling all but one source
   group, replacing one result operator, or holding the mesh fixed while
   changing one material source. Preserve inactive geometry when its presence
   is part of the test.
8. Cross-check with an independent physical evaluator. Examples include a
   closed auxiliary surface in a homogeneous medium, virtual work, central
   energy differences, reaction balance, or a conservation integral.
9. Refine only after the prior evidence identifies the relevant boundary,
   domain, gradient direction, singular edge, or integration surface.
10. Reopen the saved diagnostic model in a fresh MATLAB MCP session and verify
    at least one stored result before accepting the fix.

## Mesh decision guide

| Evidence | Preferred next action |
|---|---|
| Field plot changes materially with refinement | Refine the field-gradient region and repeat a bounded convergence check. |
| Field is stable but a boundary integral oscillates | Inspect the integration surface, singular edges, averaging, and alternative evaluators. |
| Result is dominated by sharp corners or poles | Move the integration surface into a smooth homogeneous region when physics permits. |
| Error follows one unstructured surface mesh | Partition and mesh the local surrounding domain symmetrically; do not refine unrelated far-field regions. |
| A domain is naturally sweepable and cross-gradients are controlled | Consider mapped/swept prism or hexahedral elements and validate against the prior mesh. |
| Only the solid interior can be hexahedral but the result is evaluated in surrounding air | Do not expect the solid-only element-type change to fix the result. |
| A symmetry-forbidden component persists while the primary field looks symmetric | Test the result operator and numerical self-force before changing geometry or polarity. |

## Electromagnetic force pattern

Maxwell-stress force calculations evaluate a small difference between large
local tractions and can be sensitive to sharp magnet edges and non-symmetric
surface meshes. For a body fully surrounded by air:

1. Keep the built-in body-surface Force Calculation as a cross-check.
2. Evaluate the air field on a closed auxiliary surface that encloses only the
   target body and stays away from sharp poles and other bodies.
3. Integrate the air Maxwell stress with symmetric quadrature.
4. Scan more than one auxiliary-surface offset and quadrature order.
5. Compare the main force component, symmetry-forbidden components, and torque.
6. Use virtual work or central magnetic-energy differences for representative
   publication cases.

Use [`../scripts/evaluate_maxwell_force_probe.m`](../scripts/evaluate_maxwell_force_probe.m)
only when the probe is wholly inside a solved `mu_r=1` air region and the
requested field expressions have been verified in the current model.

## Human-review request template

Provide:

- artifact path and model/run identifier;
- exact view plane and global coordinate directions;
- source/polarity/contact convention;
- expected physical behavior;
- measured discrepancy and convergence history;
- one concrete question, such as whether the displayed force points toward the
  physically expected side.

Do not ask the user to edit merely because a plot looks suspicious. If an edit
is necessary, enter a verified `SAFE_TO_EDIT=true` checkpoint first.
