# Portability and publishing / 跨项目、跨电脑与发布指南

## Portable configuration / 可迁移配置

Keep environment values in configuration, not scattered through model code:

```matlab
config = comsol_config_template();
config.mliPath = 'D:\Program Files\COMSOL\COMSOL56\Multiphysics\mli';
config.serverHost = 'localhost';
config.serverPort = 2036;
config.visualMode = true;
```

On another computer, change only installed paths, server host/port, MATLAB and
COMSOL versions, and project-specific model paths. Do not silently change
physics, units, material data, dimensions, boundary conditions, or Study type.

换电脑时只修改安装路径、Server 主机/端口、软件版本和项目模型路径；不要借迁移之机
静默修改物理假设、单位、材料、尺寸、边界条件或 Study 类型。

## Install into a new Codex project / 新项目安装

Recommended user-level installation / 推荐用户级安装：

```text
%USERPROFILE%\.codex\skills\codex-comsol-bridge\
```

Project source or override / 项目源副本或项目级覆盖：

```text
<project>\.agents\skills\codex-comsol-bridge\
```

Add a short project `AGENTS.md` rule requiring this skill for every COMSOL,
LiveLink, `.mph`, mesh, Study, solver, sweep, or export task. Project-specific
paths and physical assumptions belong in the project; validated generic rules
belong in the user-level skill.

新项目的 `AGENTS.md` 应明确：所有 COMSOL/LiveLink/`.mph`/网格/Study/solver/扫描/
导出任务都先使用本 skill。项目专用路径和物理假设放项目内；已验证通用规则放用户级
skill。

## New-machine acceptance test / 新电脑验收顺序

1. Install a mutually supported MATLAB, COMSOL, and LiveLink combination.
2. Configure MATLAB MCP and verify a plain MATLAB script actually executes.
3. Manually start one COMSOL Server and record its host/port.
4. Run `test_comsol_connection.m`; verify `which mphstart`, `which mphopen`,
   MATLAB version, and server connection.
5. Run a blank/small model visual sync test; verify the exact other-client tag.
6. Run one small baseline and save to a timestamped run.
7. Reopen the saved `.mph` in a fresh MCP session and read a stored result.
8. Only then enable formal sweeps or long solves.

## Files to publish / 建议发布内容

Include / 包含：

- `SKILL.md`
- `agents/openai.yaml`
- reusable scripts under `scripts/`
- generic references and sanitized known-issue examples
- a license selected by the publisher

Exclude / 排除：

- `runs/`, `results/`, `models/`, `backups/`, temporary files, and large `.mph`
- license credentials, usernames/passwords, private server addresses
- machine-specific absolute project paths, user names, proprietary material or
  geometry data, and confidential logs

This project does not choose a public software license automatically. The owner
must select one before public distribution.

本项目不会自动替发布者选择开源许可证；公开发布前由所有者明确选择许可证。

## Versioning / 版本管理

- Keep a semantic skill version in release notes or package metadata.
- State versions actually tested separately from versions merely expected to work.
- Keep `known_issues.md` append-only for solved failures; remove private paths
  when preparing a public package.
- Validate the installed skill after every change and rerun connection,
  checkpoint, and reopen smoke tests after changing MATLAB/COMSOL versions.
