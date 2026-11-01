# WindowsOptimizer

Windows 11 optimizer with three product files: `All in One.cmd` (one portable batch, strict ASCII/CRLF), `launcher.ps1` (download/elevation), and the French user README. `Tools/`, `Game Configs/`, LICENSE and Git metadata are resources. Agent instructions are English; human documentation and console messages are French. Keep authored explanatory comments out of code; put necessary constraints and sources in this file or [docs/batch-constraints.md](docs/batch-constraints.md). Preserve licenses, upstream notices, shebangs and tool directives.

Before producing or citing measurements, gains, durations, VM or gaming-PC results, read `~/projects/winopt-bench/AGENTS.md`. It excludes all connections to `pc-gaming` until explicitly requested, requires one VM operator, and distinguishes VM mechanics from gaming gains.

## Verification

Before choosing validation, citing or producing metrics, or deciding batch/launcher structure changes, read [docs/verification.md](docs/verification.md). It owns the conditional contract checks, measurement methods and execution traps. There is no repository test suite; the external HP lab check is partial static proof, not PowerShell, launcher or Windows execution proof.

`44` means non-ASCII/NUL, `42` invalid line endings, `43` unreadable file. The format command exists twice: in the batch (using `%WINOPT_SELF%` and suppressed output) and in [docs/verification.md](docs/verification.md#contract-checks). Update both in the same commit. Published LF returning `42` is expected: `.gitattributes` stores LF in Git and checks out CRLF; raw GitHub serves LF. The batch validates before its first GOTO/CALL, normalizes a temporary copy, relaunches and propagates its exit code. The launcher also explicitly normalizes CRLF. Preserve both paths; `44` is rejected without repair. Do not change attributes to force CRLF blobs, add UTF-8/chcp 65001, accents or typographic quotes to the batch.

## Project and publication contract

- Keep code, README and publication aligned. Measure README figures from code or HTTP, never estimates (methods in [docs/verification.md](docs/verification.md#measurement-methods)).
- Preserve the deliberately single, dense, portable batch. Navigate by label, not line number; avoid extra layers/files.
- Windows 11 is the only supported validation target. Legacy Windows 10 paths promise no compatibility. VM coverage excludes laptops, real GPU/network hardware, effective Defender disablement, MAS and WinUtil.
- Restore captured state or a documented Windows fallback. Deleting a value is not always the inverse operation. Tell the author before changing a value or profile axis, even if internal logic suggests another choice.
- Research Windows tweaks with recent web evidence: understand the mechanism, compare Microsoft documentation with technical forums, reproducible tests and field reports. Microsoft documentation can be incomplete, outdated or overly cautious. Keep sources in [docs/batch-constraints.md](docs/batch-constraints.md#sources), outside code and the user README.
- `main` publishes raw files directly to users and the launcher. Public paths are contracts: `launcher.ps1`, `All in One.cmd`, `Tools/Timer & Interrupt/SetTimerResolution.exe`, `Tools/NVIDIA Inspector/nvidiaProfileInspector.exe`, and its `Kaylers_profile.nip`. Rename/move only with a coordinated batch/launcher/README release and `curl -sI` checks on old/new URLs. Already distributed batches use `WINOPT_RELEASE_BASE_URL`; raw GitHub does not redirect.
- `Game Configs/`, LICENSE and `.gitignore` can move without raw-URL effects. No batch/launcher caller was found for Fortnite templates, `Tools/O&O ShutUp10/ooshutup10_kayler.cfg`, `GoInterruptPolicy.exe` or `MeasureSleep.exe`; do not assume they are dead without author agreement. Executed Valorant settings live in `::VALPS`, not the separate template: changing only one causes drift.
- Bundled Tools binaries lack documented source/version/license provenance; do not invent it.

## Technical constraints

Before changing a batch or launcher area, read its section in [docs/batch-constraints.md](docs/batch-constraints.md): startup/launcher, profiles, helpers, interaction, safe settings, system, browser policies, memory/storage, nvidia, tcp, input, energy, timers/storage calls, security, ai, removal, cleaning, backup/restore, file handling, runtimes, external tools, valorant. Research sources are in its [Sources](docs/batch-constraints.md#sources) section.

Numbered `REM n.n - ...` lines are catalogue metadata consumed by winopt-bench, not explanatory comments. Preserve their text and placement until producer and consumer share a replacement contract; unchanged batch execution alone does not prove catalogue/coverage compatibility.

## Execution guards

Never test the full batch on a real machine: it changes system settings. Full runs belong in `~/vms/win11/`, under the bench's authorization/operator rules. Windows 10 is out of scope; never run win11 and win10 VMs simultaneously or stop/reset another thread's VM.

Obtain explicit confirmation for published commit amendment, reset --hard, file deletion, main or remote changes unless already authorized in the current scope. Preserve unknown files as potential active work.
