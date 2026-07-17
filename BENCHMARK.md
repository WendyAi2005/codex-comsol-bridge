# Benchmark

This document compares conventional conversational control with task-level
execution.

No fixed token-saving percentage is claimed until reproducible measurements
are available.

## Test definition

- COMSOL model:
- COMSOL version:
- MATLAB version:
- Number of parameter cases:
- Study type:
- Result variables:
- Hardware:
- Codex model and mode:

## Workflow A: conversational step-by-step control

- Number of Codex turns:
- Number of MATLAB MCP calls:
- Number of COMSOL solve calls:
- Returned log characters:
- Returned data characters:
- Total elapsed time:
- Successful cases:
- Failed cases:
- Context or token usage:

## Workflow B: Codex–COMSOL Bridge task-level execution

- Number of Codex turns:
- Number of MATLAB MCP calls:
- Number of COMSOL solve calls:
- Returned log characters:
- Returned data characters:
- Total elapsed time:
- Successful cases:
- Failed cases:
- Context or token usage:

## Comparison

| Metric | Step-by-step | Task-level bridge | Difference |
|---|---|---|---|
| Codex turns |  |  |  |
| MATLAB MCP calls |  |  |  |
| Returned log size |  |  |  |
| Returned result size |  |  |  |
| Elapsed time |  |  |  |
| Successful cases |  |  |  |
| Context/token usage |  |  |  |

## Interpretation rules

- Separate local numerical runtime from AI context usage.
- Do not attribute solver runtime reduction to the bridge unless measured.
- Token savings should be explained by fewer tool calls, fewer repeated logs,
  compact result return and reduced conversational control.
- Publish raw logs and measurement procedures with any numerical claim.
