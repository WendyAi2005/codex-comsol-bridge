# Codex–COMSOL Bridge

**A community-built, end-to-end COMSOL automation bridge that connects two
mature, officially supported integration paths: Codex through MathWorks
MATLAB MCP Server, and MATLAB through COMSOL LiveLink for MATLAB.**

**基于官方集成层，将 Codex、MATLAB 与 COMSOL 串联成端到端多物理场自动化通道。**

> **Two mature integration paths. One native COMSOL automation workflow.**<br>
> **两段成熟官方链路，一条直达 COMSOL 原生模型与求解器的自动化通道。**

This repository is not another third-party COMSOL API wrapper. It connects
two existing integration paths:

```text
Codex → MathWorks MATLAB MCP Server → MATLAB
MATLAB → COMSOL LiveLink for MATLAB → COMSOL
```

into one reusable workflow:

```text
Codex
  ↓ MCP
MathWorks MATLAB MCP Server
  ↓
MATLAB
  ↓ COMSOL LiveLink for MATLAB
COMSOL Multiphysics Server
  ↓
Native COMSOL model, physics interfaces and solvers
```

本项目不是重新封装一套受限的 COMSOL 工具接口，而是把两段已有成熟做法
直接连接起来：

```text
Codex → MATLAB MCP → MATLAB
MATLAB → LiveLink for MATLAB → COMSOL
```

组合后，Codex 可以通过 MATLAB MCP 进入 MATLAB，再通过 COMSOL 官方
LiveLink for MATLAB 访问 COMSOL Server 中的原生模型对象、物理接口、
多物理场耦合、Study、求解器和结果系统。

The complete workflow is community-built. Each integration layer is supplied
or officially supported by its corresponding vendor.

整体工作流由社区构建，但每一段连接都使用对应厂商提供或正式支持的集成层。

Community-built bridge using officially supported integration layers.

基于官方集成层构建的社区端到端桥接方案。

## Why this architecture matters / 为什么这一组合重要

### 1. Two mature integration paths, connected end to end

The following two paths are already established:

```text
Codex → MATLAB MCP → MATLAB
MATLAB → LiveLink for MATLAB → COMSOL
```

This project connects them into a single reusable Codex-to-COMSOL workflow.

其新颖点不是重新发明某个接口，而是把两段分别成熟的链路组合成一条完整、
可复用、可观察和可恢复的自动化工作流。

### 2. Native COMSOL API access

The workflow does not depend on a fixed collection of third-party COMSOL MCP
tools. MATLAB reaches the native COMSOL model object through LiveLink for
MATLAB and the COMSOL API.

This makes the workflow suitable for models involving:

- geometry and named selections;
- materials and property definitions;
- meshing;
- AC/DC and magnetic fields;
- Structural Mechanics;
- CFD and fluid flow;
- multiphysics couplings;
- rotating machinery;
- contact and buckling;
- studies, solvers and result evaluation.

Available capabilities still depend on the installed COMSOL modules,
licenses and software version.

该方案不受第三方 COMSOL MCP 预定义工具数量的直接限制。只要对应功能已由
当前 COMSOL 版本、模块、许可证和 API 提供，就可以通过 LiveLink 和原生模型
对象进行程序化访问。

### 3. Native solver fidelity

The AI layer controls the model but does not replace or approximate COMSOL's
physics.

Numerical solutions are still computed by the native COMSOL model, physics
interfaces and solvers.

This preserves COMSOL's native solver behavior. Physical accuracy still
depends on correct assumptions, geometry, material data, boundary conditions,
mesh quality, solver settings and experimental validation.

AI 层只负责任务编排、代码生成和 API 调用，不替代 COMSOL 求解器。实际数值
计算仍由 COMSOL 原生物理接口和求解器完成。

因此，应表述为保持 COMSOL 原生接口覆盖范围、求解能力和数值行为，而不是
无条件保证所有仿真结果都准确。

### 4. From conversational control to task-level execution

A conventional step-by-step workflow often keeps Codex inside every small
simulation operation:

```text
set one parameter
→ call MATLAB
→ run COMSOL
→ return logs
→ inspect in Codex
→ decide the next action
→ repeat
```

This repository moves repeated operations into one reproducible MATLAB task:

```text
describe the complete task once
→ Codex generates one task-level MATLAB launcher
→ MATLAB completes loops, checks, solves and exports locally
→ LiveLink controls COMSOL
→ only summaries, evidence and artifact paths return to Codex
```

The efficiency advantage does not merely come from running COMSOL locally.
Conventional workflows also use a local solver.

The difference is the orchestration granularity:

- Codex does not need to participate in every simulation case;
- parameter loops execute inside MATLAB;
- full solver logs remain in local files;
- large arrays remain in MAT, CSV or XLSX files;
- only compact summaries, warnings and file paths return to Codex;
- repeated tool calls and repeated conversational context are reduced.

效率优势并不是简单的“本地软件负责计算”，因为普通方案同样由本地软件求解。

真正的区别是：

**将逐步骤、逐工况的对话式控制，收敛为一次任务级交付。**

参数循环、求解、异常记录、数据筛选和文件导出由 MATLAB 与 COMSOL 在本地
完成，只把摘要、证据、警告和结果路径返回给 Codex。

### 5. Observable and recoverable automation

The workflow also adds a research-oriented control layer:

- same-server, same-model COMSOL Desktop observation;
- API control without fragile GUI clicking;
- verified manual pause checkpoints;
- safe human takeover;
- before/after model snapshots;
- structured model-difference review;
- approved resume from the earliest affected stage;
- timestamped models, logs, data, plots and reports;
- original `.mph` model protection.

这不仅是一条“能运行”的链路，也是一套可观察、可人工接管、可检查修改差异、
可验证恢复的 COMSOL 自动化流程。

## Conventional control vs task-level bridge

| Dimension | Conventional conversational control | Codex–COMSOL Bridge |
|---|---|---|
| Codex involvement | Participates in many small steps | Intervenes mainly at task and decision boundaries |
| MATLAB MCP calls | Often repeated per step or case | One launcher can complete an entire task |
| Parameter sweeps | Agent may coordinate each case | MATLAB completes the loop locally |
| Solver logs | Frequently returned to the conversation | Saved locally; compact evidence is returned |
| Large result arrays | May enter the model context | Stored in MAT/CSV/XLSX artifacts |
| COMSOL access | Depends on the selected wrapper | Native model object through LiveLink |
| Physics coverage | May be limited by predefined MCP tools | Determined by COMSOL modules, licenses and API |
| Desktop observation | Often separate from automation | Same Server and exact same model tag |
| Manual editing | Informal and difficult to verify | Verified pause, snapshot, diff and approved resume |
| Recovery | Relies heavily on conversation state | Uses files, logs, checkpoints and timestamped runs |

## 常规控制与任务级桥接对比

| 对比维度 | 常规对话式控制 | Codex–COMSOL Bridge |
|---|---|---|
| Codex介入方式 | 频繁参与单个步骤和工况 | 主要在任务边界和决策点介入 |
| MATLAB MCP调用 | 可能逐步骤、逐工况调用 | 一个任务启动器可完成整组任务 |
| 参数扫描 | AI协调每个工况 | MATLAB本地完成循环 |
| 求解日志 | 反复返回对话上下文 | 完整保存在本地，仅返回摘要 |
| 大型结果 | 可能直接进入上下文 | 保存为MAT、CSV或XLSX |
| COMSOL访问 | 取决于第三方封装工具 | 通过LiveLink访问原生模型对象 |
| 物理场覆盖 | 受预定义MCP工具限制 | 由COMSOL模块、许可证和API决定 |
| 原生窗口 | 可能与自动化对象分离 | 同Server、同模型Tag观察 |
| 人工修改 | 难以确认修改内容 | 安全暂停、快照、差异审查、审批续跑 |
| 中断恢复 | 依赖当前对话状态 | 依赖文件、日志、检查点和时间戳运行目录 |

> This is an independent community project built on officially supported
> integration layers. It is not affiliated with or endorsed by OpenAI,
> MathWorks, or COMSOL AB. Product names and trademarks belong to their
> respective owners.
>
> 本项目是基于官方集成层构建的独立社区项目，不代表 OpenAI、MathWorks
> 或 COMSOL AB 官方背书或联合发布。

## Research automation capabilities / 科研自动化能力

1. **Official integration chain / 官方集成链路**
   Connect Codex → MathWorks MATLAB MCP Server → MATLAB → COMSOL LiveLink
   for MATLAB → an existing COMSOL Multiphysics Server without starting a
   second MATLAB or Server.

2. **Native COMSOL API access / COMSOL原生API访问**
   Use the LiveLink model object and COMSOL API. Discover uncertain tags,
   selections, entity IDs, variables and feature types from model evidence
   instead of guessing them.

3. **Task-level local execution / 任务级本地执行**
   Put parameter loops, checks, solves, exception handling and exports into a
   reproducible MATLAB task-level launcher rather than coordinating each case
   through a separate conversational step.

4. **Compact result return / 紧凑结果回传**
   Keep full logs and large arrays in local MAT, CSV or XLSX artifacts. Return
   compact summaries, warnings, evidence and artifact paths to Codex.

5. **Same-model Desktop observation / 同模型原生窗口观察**
   Launch optional native Desktop observation and verify that it is attached
   to the exact same Server and model tag with
   `ModelUtil.modelsUsedByOtherClients()`.

6. **Verified human takeover / 可验证人工接管**
   Allow GUI editing only at a verified `PAUSED` / `safeToEdit=true`
   checkpoint. API control remains the primary automation path.

7. **Model diff and safe resume / 模型差异检查与安全续跑**
   Capture before/after model snapshots, generate a structured difference
   report, run targeted API checks for unresolved settings, and resume only
   after stage/tag-matched approval from the earliest affected dependency
   stage.

8. **Reproducible evidence / 可复现仿真证据**
   Save timestamped logs, reports, models, data, plots and failure evidence.
   Reuse validated AC/DC, Structural Mechanics and 3D CFD baseline knowledge,
   while rechecking the installed modules, licenses and version.

9. **Original-model protection / 原模型保护**
   Never overwrite original or successful `.mph` files. Save run-local model
   copies and preserve failed or paused evidence.

10. **Portable configuration / 可移植配置**
    Configure the MLI path, Server host, port and `visualMode` for each
    machine while keeping the automation, safety and recovery workflow
    reusable.

## Validated environment / 已验证环境

- Windows
- MATLAB R2022b
- COMSOL Multiphysics 5.6
- LiveLink for MATLAB
- COMSOL Server at `localhost:2036`

These are tested values, not universal requirements. Edit
[`scripts/comsol_config_template.m`](scripts/comsol_config_template.m) for your
machine and verify version compatibility before long solves.

## 30-second quick start / 30秒快速开始

1. Install and configure MathWorks MATLAB MCP Server.
2. Install COMSOL Multiphysics with LiveLink for MATLAB.
3. Manually start exactly one COMSOL Multiphysics Server.
4. Copy this repository into the Codex user skill directory.
5. Configure the MLI path, Server host and port.
6. Ask Codex to use `$codex-comsol-bridge`.
7. Run one small baseline before a sweep or long solve.

中文：

1. 安装并配置MathWorks MATLAB MCP Server；
2. 安装COMSOL及LiveLink for MATLAB；
3. 手动启动一个COMSOL Multiphysics Server；
4. 将仓库放入Codex用户级Skill目录；
5. 配置mli路径、Server地址和端口；
6. 要求Codex调用`$codex-comsol-bridge`；
7. 参数扫描或长时间求解前先运行一个小型基准工况。

## Installation / 安装

Copy this repository to the user-level Codex skills folder:

```text
%USERPROFILE%\.codex\skills\codex-comsol-bridge\
```

Or keep a project-specific copy at:

```text
<project>\.agents\skills\codex-comsol-bridge\
```

Your project `AGENTS.md` should require `codex-comsol-bridge` for every
COMSOL, LiveLink, `.mph`, geometry, mesh, Study, solver, sweep or export task.

## First run / 首次运行

1. Install and configure MathWorks MATLAB MCP Server.
2. Manually start exactly one COMSOL Multiphysics Server.
3. Record the actual Server host and port shown in its window or log.
4. Configure `mliPath`, `serverHost` and `serverPort`.
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

The Desktop is an observer for the same live Server model. Attachment is
accepted only when the exact model tag appears in
`ModelUtil.modelsUsedByOtherClients()`.

## Manual GUI editing / 人工修改

The user never types `CODEX_MANUAL_PAUSE_STAGE` into COMSOL and never creates a
continue flag. Editing is allowed only after all pause evidence agrees:

- Codex explicitly reports `SAFE_TO_EDIT=true`;
- `checkpoint_state.json` says `PAUSED` and `safeToEdit=true`;
- the MATLAB diary contains matching markers;
- the exact Desktop model tag matches and no geometry, mesh or Study operation
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
ARCHITECTURE.md
BENCHMARK.md
```

Important references:

- [`known_issues.md`](references/known_issues.md)
- [`workflow_checklist.md`](references/workflow_checklist.md)
- [`validated_baselines.md`](references/validated_baselines.md)
- [`new_project_workflow.md`](references/new_project_workflow.md)
- [`portability_and_publishing.md`](references/portability_and_publishing.md)
- [`ARCHITECTURE.md`](ARCHITECTURE.md)
- [`BENCHMARK.md`](BENCHMARK.md)

## Safety and scope / 安全边界

- Never guess COMSOL tags, domains, boundaries, units or physics assumptions.
- Never overwrite original or successful `.mph` files.
- Do not publish proprietary models, geometry, material data, logs,
  credentials, license information or private Server addresses.
- Automatic model diff is evidence, not a guarantee of complete semantic
  coverage for every COMSOL module. Ambiguous settings require targeted API
  queries.
- Specific capabilities depend on installed COMSOL modules, licenses, software
  versions and available APIs.
- Physical accuracy depends on model assumptions, material parameters,
  boundary conditions, mesh, solver settings and experimental validation.

## License

MIT License. See [`LICENSE`](LICENSE).
