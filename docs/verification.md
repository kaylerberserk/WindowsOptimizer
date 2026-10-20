# Verification and measurement methods

Read this owner through the root [AGENTS.md](../AGENTS.md#verification) before choosing validation, citing or producing metrics, or deciding batch/launcher structure changes. The root owns authorization, format and publication boundaries; these procedures grant no additional execution permission.

## Contract checks

There is no repository test suite. The command below uses external hp-dev lab tooling, not files supplied by a fresh clone. On hp-dev, first read the active host machine index (`~/.agents/MACHINE.md`, topic `machine.d/vm-charge.md`) to locate the lab, then run from the worktree root:

```bash
REPO="$PWD" ~/vms/winopt-lab/check.sh --local
```

This checks working-copy ASCII/CRLF, labels, targets, parentheses and unsafe echo parentheses without SSH or VM commands. It does not validate PowerShell, the launcher or Windows execution. After structural edits, every `goto`/`call :` must resolve, depth must be zero at every label, and each `if/else` must close; global balance alone is insufficient.

Working-copy format must return `0` with this Windows PowerShell check:

```powershell
powershell -NoProfile -Command "try{$b=[IO.File]::ReadAllBytes('All in One.cmd');for($i=0;$i-lt$b.Length;$i++){if($b[$i]-eq0-or$b[$i]-gt127){exit 44};if(($b[$i]-eq10-and($i-eq0-or$b[$i-1]-ne13))-or($b[$i]-eq13-and($i+1-ge$b.Length-or$b[$i+1]-ne10))){exit 42}};exit 0}catch{exit 43}"
```

On Windows, test the local and published launcher separately, each in a temporary directory containing only `launcher.ps1`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\launcher.ps1 -VerifyOnly
```

It downloads/verifies without launching the batch and reports its source and an informational SHA-256; no hash is pinned. Linux PowerShell parsing is supplementary, not Windows PowerShell 5.1 compatibility proof.

For comment-only edits, compare the effective noncomment batch command stream byte-for-byte, including labels and inline PowerShell. Check comment/continuation boundaries before deletion. Parse PowerShell with its real parser and compare significant tokens and AST structure before/after, including strings and here-strings. `::SAFEPS `, `::SECREGPS `, `::SECTARGETPS ` and `::VALPS ` are executable self-read payload prefixes, not batch comments. Preserve extraction, substring offsets, completeness checks and the unique SECTARGETPS definition. Classify nested comments with the PowerShell parser; preserve executable payloads and data fixtures.

## Measurement methods

Run from the repository root with `f="All in One.cmd"`. Strip CR (`tr -d '\r'`) before end-anchored patterns. Recompute when code changes; historical figures belong in Git. These repository structure methods belong here; experiments belong to winopt-bench.

- VC++ minimum: inspect `:VC14_REG_OK` (`VC_REG_MINOR`) and `:DETECT_VC14_RUNTIME`; timer: search `5275`; memory-compression threshold: inspect `:SET_MEMORY_POWER_PROFILE` and `RAM_GB`.
- Advanced cleaning steps: `grep -c 'set /a "CLEAN_STEP+=1"' "$f"` must equal `grep -oE 'CLEAN_TOTAL=[0-9]+' "$f"`.
- PowerShell invocation count: `grep -viE '^\s*(@?rem|::)(\s|$)' "$f" | grep -oiE 'powershell(\.exe)?"? +-' | wc -l`. Count a loop/helper once; `where powershell` and echoed mentions are not invocations. Case-sensitive comment filtering is not comparable. This count alone does not measure latency.
- Privacy registry writes: within `:OPTIMISATIONS_SYSTEME`, use the command range between the `echo` containing `Desactivation de la telemetrie et des publicites...` and the `echo` containing `Preparation du reglage des services Windows...`. Count `reg add` excluding Autologger and the ContentDeliveryManager loop body, then add the `for %%V in (` values. Count WMI autologgers from `for %%L in (` and explicit `Autologger\...` names without duplicates. Keep these counting methods independent of explanatory comments.
- Disabled tasks: `tr -d '\r' < "$f" | sed -n '/^for %%T in ($/,/^) do set "WINOPT_TELEMETRY_TASKS/p' | grep -c '^\s*"Microsoft'`. Actual availability requires `Get-ScheduledTask`, or an existing stock capture: `iconv -f UTF-16 -t UTF-8 ~/vms/win11/states/0_stock/tasks.txt` (`\Path\Name|State`).
- Runtime sizes: final `content-length` from `curl -sIL <url>` for batch URLs matching `directx_Jun2010_redist.exe|vc_redist`. `aka.ms` VC++ URLs track current packages; sizes change.
- Registry comparisons: `~/vms/win11/states/0_stock/reg.json` uses `utf-8-sig`; `python3 ~/vms/winopt-lab/cmp.py <tagA> <tagB> [x]`. `absent -> cle absente` and the reverse only describe empty keys; count with `cmp.py A B x | grep -cE ': absent -> cle absente|: cle absente -> absent'`.
- Durations: first column of VM `runs/<name>.timeline`, at `Voulez-vous redemarrer maintenant`, starting from fresh `stock`. Never present unremeasured VM/hardware figures as current or VM duration as gaming gain.

## Execution methods and traps

On hp-dev only, use the external lab located through the host topic above (`VM=win11` default): `vm.sh start|stop|status`, `lab.sh reset|prep|state|snapshot`, `suite.sh <name> "<pattern=>key | ...>" [reset|reset=rt] [reboot]`, `cmp.py`, `check.sh`. The full check can access/reset the guest; only `--local` is static. `rt` is fresh Windows plus official VC++/DirectX via `rt_install.ps1`; use `stock` for durations and any runtime change. Format and VerifyOnly checks do not apply tweaks; VerifyOnly still downloads and cleans temporary files.

- Verify syntax, parentheses, encoding and logic by execution; a scratch-key helper test finds issues parsing cannot. Revalidate established methods; corroborate independent advice, but reproducible defects/costly limits need not recur before correction. Remove advice only with evidence of harm, replacement or uselessness.
- Drive real console prompts key by key with `drive.py`: buffered input may be consumed by children; SSH choice.exe rejects digits and NIC restart kills SSH. UI calls such as SystemParametersInfo need interactive sessions (service/SSH error 1459; a temporary `/it` task can test them when authorized).
- When output is hidden and progress stops, inspect live children for input waits. Read fresh-stock state, never infer defaults from already optimized pc-gaming.
- Verify stored state rather than exit codes: bcdedit deletion can return 1 for absence; UCPD/policy may reject writes without useful status. reg add creates missing paths, so absence is not a no-op proof; inspect the actual refusal.
- Produce Windows files through heredocs/programs: shell redirection to nul may otherwise become a Unix path. Escape `^(`/`^)` in echo inside blocks; global balance misses premature closure. Test isolated blocks with echo substitutes.
- Extract test fragments only by labels anchored at line start, never a call :LABEL match. Before sending one, check size, absence of HKLM/HKCR/powercfg, and that every call targets the fragment; unanchored extraction previously executed whole sections on pc-gaming.
- Reset the VM by cold restore of the disk snapshot (`lab.sh reset`); a live `savevm` snapshot restores more slowly, so do not reintroduce it.
- After the Gaming protections profile and a reboot, VBS/HVCI run in the VM and slow it. Account for that before blaming the script for a slow run.
