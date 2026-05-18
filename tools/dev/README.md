# Godot dev helpers

Use the repo wrapper instead of calling `godot` or `$env:GODOT_BIN` directly.
On Windows, prefer the `.cmd` entry because it works even when direct `.ps1`
execution is disabled:

```powershell
.\tools\dev\godot.cmd --headless --path . --quit-after 3
.\tools\dev\godot.cmd --headless --path . --script "res://tests_or_debug/DebugCoreSmokeTest.gd"
```

The wrapper resolves Godot in this order:

1. `.godot-bin` local override file in the repo root.
2. Process, user, or machine `GODOT_BIN`.
3. `godot` or `godot4` from `PATH`.
4. `%LOCALAPPDATA%\CodexGodot` stable cache.
5. Common Program Files Godot folders.
6. Codex temp Godot folders.

If it finds a Codex temp Godot folder, it copies the executable files into
`%LOCALAPPDATA%\CodexGodot\...` before running, so later sessions do not depend
on the temp folder still existing.

To pin the resolved executable as the user-level `GODOT_BIN`:

```powershell
.\tools\dev\godot.cmd --persist-user-env --print-path
```

For a machine-specific override, create `.godot-bin` in the repo root with one
line containing the full Godot executable path. That file is intentionally
gitignored.
