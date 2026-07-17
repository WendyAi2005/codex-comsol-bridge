# COMSOL visual workflow operator guide / COMSOL 原生窗口协同操作指南

This guide defines the human-in-the-loop workflow for one shared live model.

本指南规定一个共享活动模型上的“Codex 自动化 + 人工检查/修改”工作流：

```text
Codex
  -> MATLAB MCP controlled MATLAB / MATLAB MCP 控制的 MATLAB
  -> LiveLink for MATLAB
  -> one manually started COMSOL Server / 用户手动启动的唯一 COMSOL Server
  -> one live server model / 唯一活动 Server model
  <-> one COMSOL Desktop observer / 唯一 COMSOL Desktop 观察窗口
```

The Desktop is not GUI automation and is not a second model copy. MATLAB API
remains the automation authority.

Desktop 不是鼠标自动化工具，也不是第二份模型副本；自动化控制权仍在 MATLAB API。

## 1. Direct answers / 先回答最容易混淆的问题

| Question / 问题 | Rule / 规则 |
|---|---|
| Can I edit directly in COMSOL Desktop? / 能否直接人工修改？ | **Yes, but only after a verified manual pause. / 可以，但必须先进入已验证的人工暂停。** |
| Where do I type `CODEX_MANUAL_PAUSE_STAGE='geometry'`? / 这行输入在哪里？ | Nowhere in COMSOL. It is an internal launcher variable written by Codex before an MCP run. Tell Codex “pause after geometry”. / 不在 COMSOL 中输入。这是 Codex 在 MCP 启动脚本中写入的内部变量；您只需说“几何完成后暂停”。 |
| How do I know it is really paused? / 怎么确认真的停住？ | All four pause signals in section 5 must agree. A quiet GUI alone is not evidence. / 必须同时满足第 5 节的四项暂停信号；GUI 看起来没动不算证据。 |
| Must I click Save after editing? / 修改后要点左上角保存吗？ | **No by default.** GUI edits already modify the shared live server object. Do not overwrite the original file. Codex saves run-local pre/post-edit copies. / **默认不要点。** GUI 修改已经作用于共享活动对象；不要覆盖原文件，由 Codex 保存当前 run 的修改前/后副本。 |
| Must I remember every change? / 一定要完整告诉 Codex 改了什么吗？ | No. Say “改完了，继续”. Codex captures and compares before/after snapshots. A short explanation is helpful but not authoritative. / 不必。只需说“改完了，继续”；Codex 自动做前后快照和差异检查。简短说明有帮助，但不作为唯一证据。 |
| Can Codex detect every possible GUI change automatically? / 能否识别所有改动？ | Not perfectly. The generic diff covers parameters, tags, labels, readable properties, and selections. Some module-specific semantics require targeted queries. Codex asks only about unresolved items. / 不能承诺 100%。通用差异可覆盖参数、tag、标签、可读属性和选择集；部分模块专用语义需定向查询。只有仍无法确认时，Codex 才针对具体项询问。 |
| How does the run continue? / 怎么继续？ | The user never creates a flag. Codex validates the diff and writes `approved_continue_<stage>.json`; the paused runner verifies stage and model tag, then resumes from the earliest affected dependency stage. / 用户不创建标志文件。Codex 验证差异后写入批准 JSON；暂停脚本核对阶段和 model tag，再从最早受影响阶段继续。 |

## 2. What to start and keep running / 执行前启动并保持什么

1. Manually start exactly one **COMSOL Multiphysics Server 5.6**.
2. Keep `comsolmphserver.exe` running for the entire task.
3. Ensure MATLAB MCP is available. Let MCP manage its MATLAB batch sessions.
4. For `visualMode=true`, keep exactly one `comsolmphclient.exe` attached to
   the same model tag.

1. 用户手动启动且只启动一个 **COMSOL Multiphysics Server 5.6**。
2. 整个任务期间保持 `comsolmphserver.exe` 运行。
3. 确认 MATLAB MCP 可用；MATLAB 批处理会话由 MCP 管理。
4. `visualMode=true` 时，只保留一个连接同一 model tag 的
   `comsolmphclient.exe`。

Do not start / 不要启动：

- A second MATLAB for the same task / 同一任务的第二个 MATLAB。
- The “COMSOL Multiphysics 5.6 with MATLAB” shortcut / “COMSOL with MATLAB”快捷方式。
- A second COMSOL Server / 第二个 COMSOL Server。
- A Desktop client inside every parameter case / 每个参数工况重复启动 Desktop。

Unrelated MATLAB or COMSOL windows are not closed automatically. Save their
work first. Empty unrelated processes may be closed manually to reduce license,
memory, and operator confusion, but process titles alone are not sufficient
evidence for termination.

Codex 不自动关闭无关 MATLAB/COMSOL。先保存其工作；空的无关进程可由用户手动关闭，
以减少许可证、内存占用和会话混淆，但不能仅凭窗口标题判断并结束进程。

## 3. Path, host, and port / 路径、主机和端口

Validated local defaults / 当前已验证默认值：

```matlab
config.mliPath = 'D:\Program Files\COMSOL\COMSOL56\Multiphysics\mli';
config.serverHost = 'localhost';
config.serverPort = 2036;
```

The port can differ if the Server is started/configured differently. Read the
actual host and port from the COMSOL Server window or log each time. Never guess
a port and never start another Server silently because connection failed.

如果 Server 的启动配置不同，端口可能变化。每次都读取 Server 窗口或日志中的实际主机
和端口；不要猜端口，也不要因为连接失败而静默启动第二个 Server。

Confirmed COMSOL 5.6 forms / 已确认的 COMSOL 5.6 连接形式：

```matlab
mphstart(2036)                    % localhost
mphstart('192.168.0.1', 2037)    % explicit remote host and port
```

## 4. Visual mode / 原生窗口观察模式

```matlab
config.visualMode = true;   % development, debugging, one baseline
config.visualMode = false;  % unattended or large sweeps
```

Initialize once and launch once / 初始化一次，启动一次：

```matlab
[model, connectionInfo] = initialize_comsol_session(modelPath, config);
if config.visualMode
    visualStatus = launch_comsol_visual_client(model);
end
```

Attachment is successful only when the exact model tag appears in
`ModelUtil.modelsUsedByOtherClients()`. `mphlaunch` returning by itself is not
enough. Do not edit during API geometry build, mesh generation, Study solve, or
result update.

只有同一 model tag 出现在 `ModelUtil.modelsUsedByOtherClients()` 中，才算连接成功；
不能仅凭 `mphlaunch` 返回判断。API 正在重建几何、生成网格、运行 Study 或更新结果时，
不要在 GUI 中编辑。

## 5. Checkpoint states and proof / Checkpoint 状态与证据

There are two visually quiet states, but only one is editable:

GUI 看起来暂时不动时，可能处于两种状态；只有一种允许编辑：

| State | `safeToEdit` | Meaning / 含义 | User action / 用户动作 |
|---|---:|---|---|
| `OBSERVATION_ONLY` | `false` | Brief display refresh; automation will continue automatically. / 短暂观察刷新，脚本会自动继续。 | Observe only. / 只观察。 |
| `PAUSED` | `true` | Runner is waiting for Codex's validated approval. / 脚本正在等待 Codex 验证后的续跑批准。 | Manual editing is allowed after Codex confirms it. / Codex 确认后允许人工修改。 |
| `RESUMING` | `false` | Approval accepted; API control has resumed. / 已接受批准，API 恢复控制。 | Stop editing immediately. / 立即停止编辑。 |

Manual editing is safe only when all four signals agree / 只有以下四项同时成立才可编辑：

1. Codex explicitly says: `checkpoint=<stage>, SAFE_TO_EDIT=true`.
2. `<runDir>/checkpoint_state.json` contains `"status":"PAUSED"` and
   `"safeToEdit":true`.
3. The MATLAB diary contains `CODEX_CHECKPOINT_STATUS: PAUSED` and
   `CODEX_SAFE_TO_EDIT: true`.
4. The exact model tag matches the Desktop client, and no geometry/mesh/Study
   operation is active.

1. Codex 明确告知：`checkpoint=<阶段>, SAFE_TO_EDIT=true`。
2. 当前 run 的 `checkpoint_state.json` 同时显示 `PAUSED` 和 `true`。
3. MATLAB 日志同时出现 `CODEX_CHECKPOINT_STATUS: PAUSED` 与
   `CODEX_SAFE_TO_EDIT: true`。
4. Desktop 的 model tag 完全一致，且没有几何、网格或 Study 操作正在运行。

The model label is also changed to `PAUSED - <stage>` as an extra visual hint,
but a label alone is not authorization.

模型标签会额外显示为 `PAUSED - <阶段>`，但仅凭标签仍不能开始编辑。

## 6. How to request a pause / 如何要求暂停

Planned pause / 计划暂停：

- User says: “pause after geometry / 几何完成后暂停”.
- Codex embeds `CODEX_MANUAL_PAUSE_STAGE='geometry'` in the generated MCP
  launcher. The user does not type or edit this variable.

Unplanned problem / 中途发现问题：

- User says: “pause at the next safe checkpoint / 在下一个安全点暂停”.
- Codex requests the next checkpoint through run-local control metadata.
- If an indivisible API call is active, the pause takes effect after that call,
  not in the middle of it.

During a Study solve, arbitrary suspend/resume is not assumed. Prefer a
controlled stop at a safe boundary. If an obviously invalid solve must be
stopped from Desktop, use Study **Stop** once; never kill the Server.

Study 求解期间不假定支持任意暂停后续算。优先在安全边界受控停止；若明显错误且必须
从 Desktop 停止，可使用一次 Study 的 **Stop**，绝不能结束 Server 进程。

## 7. Standard manual-edit procedure / 标准人工修改流程

1. **Request pause / 请求暂停** — say the desired stage or “next safe point”.
2. **Wait for proof / 等待证据** — do not edit until section 5 is satisfied.
3. **Automatic pre-edit protection / 自动修改前保护** — Codex saves
   `pre_edit_<stage>.mph`, `snapshot_before_<stage>.mat/.json`, diary, and state.
4. **Edit in Desktop / 在 Desktop 修改** — change only the intended nodes.
   Do not rename/delete tags casually and do not click Compute.
5. **Finish / 完成** — tell Codex only: **“改完了，继续”**. Optionally mention
   the intent, for example “changed inlet speed because...”.
6. **Automatic verification / 自动验证** — Codex captures an after-snapshot,
   compares it, writes `manual_change_report.md/.json`, rechecks ambiguous
   tags/selections/units/properties, and saves a post-edit run-local copy.
7. **Approval and resume / 批准续跑** — Codex writes
   `approved_continue_<stage>.json`. The runner verifies stage and model tag,
   changes `safeToEdit=false`, then resumes from the earliest affected stage.

The user must not create or edit checkpoint JSON/flag files manually.

用户不要手工创建或修改 checkpoint JSON/flag 文件。

## 8. Save rules / 保存规则

- GUI edits immediately affect the shared live server model. Clicking Save is
  not required for MATLAB/Codex to see them.
- Default: **do not click the top-left Save button**, because the current file
  association may point to an original or previously successful `.mph`.
- Codex saves timestamped pre-edit and post-edit copies under the active run.
- If an additional manual recovery copy is desired, ask Codex for the exact
  run-local path and use **Save As**, never overwrite the original.
- Do not close Desktop or Server until Codex confirms the after-snapshot and
  run-local save are complete.

- GUI 修改会立即作用于共享活动模型，不需要点击保存才能让 Codex 看见。
- 默认**不要点左上角 Save**，因为当前关联路径可能是原始或已验证成功的 `.mph`。
- 由 Codex 在当前 run 内保存带时间戳的修改前/后副本。
- 若希望额外人工备份，先让 Codex 给出准确的 run 路径，再使用 **Save As**；绝不覆盖原文件。
- Codex 确认后快照和 run 内保存完成前，不要关闭 Desktop 或 Server。

## 9. Automatic diff scope and limits / 自动差异检查的范围与限制

The reusable snapshot records:

- parameter names, expressions, units, and descriptions;
- component, geometry, selection, material, physics, multiphysics, mesh,
  study, solver, dataset, result, numerical, table, and function tags;
- labels, feature types, readable property values, and readable selections;
- a best-effort COMSOL-generated M-file for supplementary review.

可重复使用的快照会记录参数、组件/几何/选择集/材料/物理场/网格/Study/solver/结果等
节点的 tag、标签、类型、可读属性及选择集，并尝试生成补充审查用的 COMSOL M-file。

Limitations / 限制：

- Some module-specific settings are not semantically exposed through one
  universal API.
- Display-only volatile properties are filtered; newly discovered volatile
  fields must be added to `known_issues.md` and the filter.
- An M-file export may be incomplete when model history is disabled; it is
  supplementary, not primary evidence.
- Geometry changes invalidate assumptions about old boundary/domain IDs.
- If the automatic report is ambiguous, Codex asks only the unresolved,
  physics-relevant question before continuing.

因此用户不需要凭记忆完整复述改动，但 Codex 也不能谎称能自动识别一切。对无法由通用
差异确定的模块专用设置，必须进行定向 API 查询；仍有物理歧义时再向用户询问具体项。

## 10. Where to resume / 修改后从哪里继续

| Change / 改动 | Required action / 必须执行 |
|---|---|
| Parameter, not geometry-dependent / 不影响几何的参数 | Validate dependencies, then rerun Study/results. / 验证依赖后重跑 Study/结果。 |
| Geometry or geometry-dependent parameter / 几何或影响几何的参数 | Rebuild geometry; requery named selections and entity IDs; rebuild mesh; rerun Study/results. / 重建几何、重查选择集和实体、重建网格、重跑 Study/结果。 |
| Boundary condition or material / 边界条件或材料 | Revalidate domains, boundaries, units, and property sources; rerun Study/results. / 重验域、边界、单位和属性来源，再重跑。 |
| Mesh settings / 网格设置 | Rebuild mesh; recheck quality; rerun Study/results. / 重建并检查网格，再重跑。 |
| Study or solver settings / Study 或求解器 | Requery tags and settings; rerun the validated Study. / 重查 tag 和设置，再运行已验证 Study。 |
| Result node only / 仅结果节点 | Update results; normally no solve. / 更新结果，通常无需重算。 |

Physics, geometry, mesh, solver, or selection changes should normally continue
in a new timestamped run directory while preserving the paused run as evidence.

物理、几何、网格、求解器或选择集发生变化时，通常在新的时间戳 run 中继续，并保留暂停
run 作为证据。

## 11. Failure and emergency rules / 失败与紧急情况

- Never edit while `safeToEdit=false`.
- Never kill `comsolmphserver.exe` to stop a bad solve.
- Do not repeatedly click Stop/Compute.
- Preserve the diary, `error_report.txt`, state JSON, snapshots, and current
  `.mph` copy before retrying.
- Classify the error, make the smallest justified change, retry in a new run,
  and append the solved issue to `known_issues.md`.
- If Desktop destabilizes a long run, close visual observation only after
  coordination and continue with `visualMode=false`.

## 12. Minimal user commands / 用户最简口令

The user can operate the protocol with these natural-language messages:

- “几何完成后暂停，让我检查。”
- “在下一个安全点暂停。”
- “我看到网格有问题，先不要继续。”
- “改完了，继续。”
- “停止这次求解，保留日志，不要关 Server。”

Codex is responsible for translating these into launcher variables, state
files, snapshots, targeted queries, approvals, and restart decisions.
