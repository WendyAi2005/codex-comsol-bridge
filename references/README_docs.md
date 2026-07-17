# Documentation and evidence order

This workflow uses COMSOL Multiphysics 5.6 with LiveLink for MATLAB and MATLAB
R2022b through MATLAB MCP.

Use information sources in this order:

1. Current project models, MATLAB scripts, MAT files, run reports, diaries, and
   error reports.
2. A MATLAB model file exported from COMSOL Desktop.
3. [known_issues.md](known_issues.md) and
   [validated_baselines.md](validated_baselines.md).
4. Installed MATLAB queries:

   ```matlab
   which mphstart
   which mphopen
   help mphstart
   help mphopen
   help mphsave
   help mphglobal
   help mpheval
   help mphinterp
   help mphmax
   ```

5. COMSOL Java feature inspection: `tags`, `properties`, `getType`,
   `getString`, `getStringArray`, and `getAllowedPropertyValues`.
6. A complete official Application Library model opened read-only with
   `mphopen`.
7. The official LiveLink for MATLAB manual.
8. The matching module manual: AC/DC, Structural Mechanics, CFD, Heat
   Transfer, Multibody Dynamics, or another installed module.

Do not infer that an Application Library `.mph` is complete from its name or
existence. Preview placeholders must be rejected after a read-only open test.

Record every solved, reusable failure in [known_issues.md](known_issues.md).
