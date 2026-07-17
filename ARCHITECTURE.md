# Architecture

Community-built bridge using officially supported integration layers.

基于官方集成层构建的社区端到端桥接方案。

## Integration path A

```text
Codex → MathWorks MATLAB MCP Server → MATLAB
```

Codex invokes MATLAB through MCP. MATLAB executes deterministic local scripts,
so loops, large arrays and intermediate logs do not need to remain in the
conversational context.

Codex 通过 MCP 调用 MATLAB；MATLAB 执行确定性的本地脚本；循环、大型数组
和中间日志不必持续进入对话上下文。

## Integration path B

```text
MATLAB → COMSOL LiveLink for MATLAB → COMSOL
```

LiveLink for MATLAB is the officially supported interface between MATLAB and
COMSOL. MATLAB accesses the native model object in COMSOL Multiphysics Server.
Numerical solutions are computed by COMSOL's native physics interfaces and
solvers.

LiveLink 是 MATLAB 与 COMSOL 之间的官方接口；MATLAB 访问 COMSOL Server
中的原生模型对象；实际求解由 COMSOL 原生物理接口和求解器完成。

## Combined workflow

```text
Codex
→ MATLAB MCP
→ MATLAB
→ LiveLink for MATLAB
→ COMSOL Multiphysics Server
→ native COMSOL multiphysics model
```

The two integration paths are individually mature. This project connects and
systematizes them into one reusable workflow. The complete workflow is
community-built, while each connection layer uses an interface supplied or
officially supported by its corresponding vendor. No third-party COMSOL API
wrapper is inserted between MATLAB and COMSOL.

两段链路分别成熟；本项目将两段链路系统化连接；完整流程为社区工作流；各连接
层使用厂商提供或正式支持的接口；不在 MATLAB 与 COMSOL 之间添加第三方
COMSOL API 封装。

## Why not a fixed COMSOL MCP tool list

A fixed MCP tool set is limited by the number and scope of tools already
wrapped. This bridge instead lets MATLAB generate and execute COMSOL API calls.
Its accessible scope is determined by installed COMSOL modules, licenses,
software version and available APIs, rather than by a finite list of
repository-defined tools.

固定 MCP 工具集的能力受已封装工具数量限制；本方案通过 MATLAB 生成并执行
COMSOL API 调用；可访问范围取决于 COMSOL 模块、许可证、版本和 API，而非
仓库预定义的有限工具列表。

## Accuracy boundary

API and GUI workflows can operate on the same COMSOL model and native solvers.
Automation does not automatically guarantee that the physical model is
accurate. Results still require mesh-independence checks, time-step
verification, experimental comparison and physical-reasonableness review.

API 方式与 GUI 方式可调用同一 COMSOL 模型和求解器；自动化接口不会自动保证
物理模型准确；结果仍需进行网格独立性、时间步验证、实验对比和物理合理性检查。

Physical accuracy remains dependent on model assumptions, material parameters,
boundary conditions, mesh quality, solver settings and experimental
validation.

## Task-level execution

A conventional step-by-step mode asks the AI to participate frequently in
intermediate operations. Codex–COMSOL Bridge submits the complete task as a
MATLAB script. MATLAB and COMSOL locally complete parameter sweeps, solves,
exception handling and result export, then return only summaries, evidence and
artifact paths.

普通逐步模式让 AI 频繁参与中间操作；本方案把完整任务下发为 MATLAB 脚本；
本地完成参数扫描、求解、异常处理和结果导出；只返回摘要、证据和文件路径。

No fixed token-saving percentage is claimed without reproducible
measurements.

## Observation and human takeover

COMSOL Desktop connects to the same Server and exact same model tag. The GUI is
an observation and manual-inspection entry point, while the API remains the
primary automation control path.

Before a manual edit, automation must enter a verified safe pause. After the
edit, resume only after before/after snapshots, a model-difference report,
targeted API review where necessary and an approved continuation file.

COMSOL Desktop 连接同一 Server 和同一模型 Tag；GUI 作为观察和人工检查入口；
API 仍是自动化主控制路径；人工修改前必须进入安全暂停；修改后通过快照、差异
报告和审批文件恢复执行。

This is an independent community project built on officially supported
integration layers. It is not affiliated with or endorsed by OpenAI,
MathWorks, or COMSOL AB.
