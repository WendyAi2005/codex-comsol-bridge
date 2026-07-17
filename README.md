# COMSOL MATLAB Simulation Skill

Reusable Codex skill and MATLAB utilities for automating COMSOL Multiphysics
through MATLAB MCP and LiveLink for MATLAB, with optional native COMSOL Desktop
observation and verified human-in-the-loop checkpoints.

面向 Codex 的可复用 COMSOL with MATLAB / LiveLink 自动化 skill，支持 COMSOL
Server 连接、模型构建与求解、原生 Desktop 同模型观察，以及经过验证的人工暂停、修改
差异检查和安全续跑流程。

> This is an independent community project. It is not affiliated with or
> endorsed by COMSOL AB, MathWorks, or OpenAI. COMSOL, MATLAB, and related
> product names are trademarks of their respective owners.

## What it provides / 功能

- MATLAB MCP → LiveLink → an existing COMSOL Server workflow
- Evidence-first COMSOL API discovery; no guessed tags or entity IDs
- Timestamped logs, reports, models, data, plots, and failure evidence
- Native Desktop observation with exact same-server/model-tag verification
- Verified `PAUSED` / `safeToEdit` checkpoint protocol for manual GUI edits
- Before/after model snapshots, structured diff, targeted API review, and
  Codex-generated resume approval
- Reusable AC/DC, Structural Mechanics, and 3D CFD baseline knowledge
- Portable configuration for MLI path, host, port, and visual mode

## Validated environment / 已验证环境

- Windows
- MATLAB R2022b
- COMSOL Multiphysics 5.6
- LiveLink for MATLAB
- COMSOL Server at `localhost:2036`

These are tested values, not universal requirements. Edit
[`scripts/comsol_config_template.m`](scripts/comsol_config_template.m) for your
machine and verify version compatibility before long solves.

## Installation / 安装

Copy this repository to the user-level Codex skills folder:

```text
%USERPROFILE%\.codex\skills\comsol-matlab-sim\
```

Or keep a project-specific copy at:

```text
<project>\.agents\skills\comsol-matlab-sim\
```

Your project `AGENTS.md` should require `comsol-matlab-sim` for every COMSOL,
LiveLink, `.mph`, geometry, mesh, Study, solver, sweep, or export task.

## First run / 首次运行

1. Install and configure MATLAB MCP.
2. Manually start exactly one COMSOL Multiphysics Server.
3. Record the actual Server host and port shown in its window or log.
4. Configure `mliPath`, `serverHost`, and `serverPort`.
5. Run `scripts/test_comsol_connection.m` through MATLAB MCP.
6. Run one small baseline before any sweep or long solve.
7. Save to a timestamped run, then reopen the saved `.mph` in a fresh MCP
   session and read one stored result.

Do not start a second MATLAB or COMSOL Server for the same automation task.

## Native Desktop observation / 原生窗口观察

```matlab
config = comsol_config_template();
config.visualMode = true;

[model, connectionInfo] = initialize_comsol_session(modelPath, config);
if config.visualMode
    visualStatus = launch_comsol_visual_client(model);
end
```

The Desktop is an observer for the same live server model. Attachment is
accepted only when the exact model tag appears in
`ModelUtil.modelsUsedByOtherClients()`.

## Manual GUI editing / 人工修改

The user never types `CODEX_MANUAL_PAUSE_STAGE` into COMSOL and never creates a
continue flag. Editing is allowed only after all pause evidence agrees:

- Codex explicitly reports `SAFE_TO_EDIT=true`;
- `checkpoint_state.json` says `PAUSED` and `safeToEdit=true`;
- the MATLAB diary contains matching markers;
- the exact Desktop model tag matches and no geometry, mesh, or Study operation
  is running.

After editing, the user may simply say “改完了，继续”. The automation captures
and compares the live model, performs targeted queries for ambiguous settings,
saves a run-local copy, and generates a stage/tag-matched approval before
resuming.

See the bilingual
[`operator_guide_bilingual.md`](references/operator_guide_bilingual.md) for the
complete operating procedure.

## Repository layout / 目录

```text
SKILL.md
agents/openai.yaml
scripts/
references/
```

Important references:

- [`known_issues.md`](references/known_issues.md)
- [`workflow_checklist.md`](references/workflow_checklist.md)
- [`validated_baselines.md`](references/validated_baselines.md)
- [`new_project_workflow.md`](references/new_project_workflow.md)
- [`portability_and_publishing.md`](references/portability_and_publishing.md)

## Safety and scope / 安全边界

- Never guess COMSOL tags, domains, boundaries, units, or physics assumptions.
- Never overwrite original or successful `.mph` files.
- Do not publish proprietary models, geometry, material data, logs, credentials,
  license information, or private server addresses.
- Automatic model diff is evidence, not a guarantee of complete semantic
  coverage for every COMSOL module. Ambiguous settings require targeted API
  queries.

## License

MIT License. See [LICENSE](LICENSE).
