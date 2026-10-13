# KeyRelay 0.1.0 validation

The remote-client adapter refactor preserves the original US key planner and physical Shift/Ctrl sending. GUI and CLI share one adapter registry. Sunlogin, ToDesk and UU are experimental presets, not verified client compatibility.

Current local checks:

- 12 regression checks pass: the 9 original checks and adapter IDs, default/overridden delay, CLI order, target resolution and conflicting/unknown clients.
- All original planning fixtures are retained. The planner and US key mapping remain byte-identical to the published baseline.
- The app builds and its input self-check passes. Both keyrelay and vmtype wrappers expose the same CLI.
- 12 legacy generic CLI cases match baseline exit status, stdout and stderr exactly. Both wrappers also match for all six client dry-runs.
- The native GUI shows client selection and evidence status. ESXi selection, multiline permission, disabled/enabled send controls and custom/default Tab widths were checked without typing into a target.
- Adapter dry-runs do not send keys; remote target-side acceptance is tracked separately in docs/COMPATIBILITY.md.

No new Sunlogin, ToDesk, UU or Windows App remote acceptance is claimed. No customer files or configuration are changed by local checks.

---

# Legacy baseline validation (KeyWeaver 1.2.1)

The initial public prerelease was refactored from a single Swift file into Core, Platform, CLI and App modules. Keyboard behavior was kept intact.

Checks completed on an Apple Silicon Mac:

- 9 dependency-free regression checks pass with `zsh test.sh`.
- All 140 pre/post-refactor input planning results match, including key codes, modifier flags and validation errors.
- 22 CLI cases match baseline exit status, standard output and standard error exactly.
- Sender control flow, cancellation, timing and physical event posting match the baseline after naming and formatting changes.
- The app bundle and Swift package build successfully; signatures and release archive integrity are checked.
- The English GUI opens correctly; Tab settings, explicit line-break permission and disabled/enabled typing controls were checked without sending keys.
- All source filenames, comments, app names and UI strings are English. README has full English and Chinese documentation.

These checks are not a claim of universal remote-client acceptance. Local AppKit/TextEdit repeated characters remain a known unresolved issue. Current Windows App remote regression remains pending. No customer files or configuration were modified by these refactor checks.
