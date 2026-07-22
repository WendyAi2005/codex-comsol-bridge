# Long-solve progress, convergence, and cancellation

Read this reference before any solve expected to last more than five minutes,
any nonlinear contact/time-dependent solve, or any monitored parameter sweep.

## Required architecture

Use one computational chain only:

```text
Codex
  -> MathWorks MATLAB MCP
  -> the MCP-owned MATLAB process
  -> the one manually started COMSOL Server
       -> progress.log: machine-readable source of truth
       -> read-only progress monitor window: human-readable tail of progress.log
       -> COMSOL convergence plots: nonlinear/time-step trend
```

The monitor window is an observer, not a second MATLAB or COMSOL client. It
must never submit work or modify the model.

## COMSOL 5.6 API evidence

Installed COMSOL 5.6 documentation confirms:

- `ModelUtil.showProgress(true)` enables progress display for lengthy tasks
  while connected to a server.
- `ModelUtil.showProgress(filename)` logs progress to a client-side file.
- `model.study(studyTag).setGenConv(true)` enables convergence plots, and
  `isGenConv()` verifies the setting.

The documentation describes progress being shown in a window *or* on a file;
it does not promise that the Boolean and filename overloads are simultaneous
independent sinks. Never call both and claim dual output without a local
version-specific smoke test. The guaranteed default is therefore:

1. configure `progress.log` with the filename overload;
2. show that exact file in an independent read-only tail window;
3. enable the native COMSOL convergence plots on the Study.

Use `scripts/configure_comsol_long_run_observability.m` and
`scripts/watch_comsol_progress.ps1`. MATLAB `diary` is still required, but it
is not a substitute for solver progress.

## Preflight contract

Before submitting a long solve:

1. Report case count, time/parameter range, requested output states, expected
   outputs, checkpoint size, and run directory.
2. Run and fresh-reopen one bounded baseline.
3. Record the MATLAB PID, COMSOL Server PID, server host/port, exact model tag,
   Study tag, Solution tag, and start time in `run_report.md`.
4. Create the run-local `progress.log` before calling the solver and verify it
   is writable.
5. Enable and verify convergence plots with `setGenConv(true)` and
   `isGenConv()`.
6. Start the read-only progress monitor window before the solve.
7. Define the cancellation route and checkpoint cadence before submission.
8. Keep `SAFE_TO_EDIT=false` throughout the solve.

Do not submit a monolithic long transient merely because its requested output
list is finite. Divide it into restartable blocks sized to finish in roughly
5-15 minutes during the exploratory phase. Save a run-local `.mph`, result
summary, and last accepted time/parameter after every completed block. Increase
block size only after measured runtime and convergence behavior justify it.

## What Codex monitors

At the agreed interval, normally ten minutes for a long local solve, read only:

- `progress.log` size, last-write time, and tail;
- MATLAB and COMSOL Server process existence and CPU deltas;
- new checkpoint/result files;
- current time/parameter, nonlinear iteration, residual/error trend, step
  rejection, and solver warnings visible in the log;
- convergence plots at checkpoints or when the user shares a live view.

A temporarily unchanged log is not by itself proof of a hang; direct
factorization or assembly can be quiet. Correlate it with CPU change and the
last solver phase. Conversely, a process being alive is not proof of useful
progress.

Escalate rather than waiting indefinitely when any of these occurs:

- residual/error grows persistently or oscillates without accepted steps;
- the same time/parameter is retried repeatedly;
- NaN/Inf, singularity, inverted elements, or repeated time-step reduction
  appears;
- no checkpoint has completed within twice the measured block budget;
- progress output is unavailable, so neither the user nor Codex can diagnose
  the run.

## Cancellation and stop verification

Stopping the MATLAB controller alone does **not** prove that the COMSOL solve
stopped. A submitted solve can continue inside COMSOL Server as an orphaned
solve while Desktop was previously waiting for the server to become idle.

Use this order:

1. Prefer the visible COMSOL progress-bar cancel action or a locally validated
   cancellation API while the controlling client is responsive.
2. If the controller is blocked and the user explicitly authorizes stopping,
   terminate only the exact recorded COMSOL Server PID as the last resort.
   Do not kill unrelated COMSOL, MATLAB, or Desktop processes.
3. Preserve the prepared model, diary, progress log, and every completed
   checkpoint. Never promote an incomplete state to an accepted result.
4. Verify the stop independently: the exact solve no longer advances, the
   recorded Server is idle or gone, Desktop shows no active solve, and the
   progress log/checkpoint set remains unchanged over a bounded recheck.
5. If the Server was terminated, state that it must be manually restarted
   before the next MATLAB MCP connection. Never start a second Server.

Do not report `STOP_CONFIRMED` merely because MATLAB exited or the MCP call
returned.

## Acceptance evidence

Every completed long-run block must leave:

- `progress.log`;
- `matlab_diary.txt`;
- a checkpoint `.mph` that reopens in a fresh MATLAB MCP session;
- last accepted time/parameter and iteration summary;
- convergence plot export or a documented native plot tag;
- `run_report.md` with start/end time, process IDs, model/study/solution tags,
  warnings, and stop/completion status;
- `error_report.txt` for failed or canceled blocks.
