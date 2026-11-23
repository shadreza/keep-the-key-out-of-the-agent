# Known gaps

What went wrong when these steps were tested, and what to do instead. Gaps 1 to 4 are from 2026-11-23 (box 0.3.0, Debian GNU/Linux 12, x86_64), on a test machine inside a locked-down sandbox; on a normal laptop you probably won't hit 1 to 3. Gap 5 is from 2026-11-24, on an ordinary Linux laptop. Check on yours.

## 1. The installer needs to write to `/var/tmp`

`install.sh` makes its download folder at a fixed path, `/var/tmp/box-download.XXXXXXXX`. It doesn't read `TMPDIR`. Where `/var/tmp` isn't writable, it stops:

```text
mktemp: failed to create directory via template '/var/tmp/box-download.XXXXXXXX': Permission denied
install.sh: cannot create temporary storage
```

What we did: a copy of the installer with only that path changed to a writable folder. The rest ran as published: checksum, archive checks, install. A normal laptop can write `/var/tmp`.

## 2. A long `BOX_HOME` path breaks the box's socket

With `HOME` (and so `~/.strands/box`) in a deep folder, `box run` stopped before the box started:

```text
strands-box: error: unsafe box directory .../.strands/box/r/b-5f9ad220466f7864/box: its broker socket path exceeds the platform limit
```

A Unix socket path has a length limit, and the run folder sits under `~/.strands/box/r/<box ID>/box`. What we did: `BOX_HOME` set to a short path (Box's command reference documents `BOX_HOME`). With a normal home folder you won't hit this.

## 3. The box didn't start on the test machine

With a short `BOX_HOME`, the box was created and then stopped:

```text
strands-box: box b-6e9df4e13b170f5d created · config ~/.strands/box/r/b-6e9df4e13b170f5d/box.toml
strands-box: error: telemetry setup failed: telemetry configuration: the telemetry port could not be bound: Permission denied (os error 13)
```

This isn't the usage telemetry that `box telemetry off` controls; that was already off (`Telemetry is off (set by BOX_TELEMETRY).`). Box Core opens a local telemetry port when a box starts (the error names it), and the test machine's sandbox doesn't let programs open ports. The same happened with a minimal profile that runs `/bin/sh` instead of Claude Code, so it isn't the agent.

What the hands-on does instead: steps 8 to 10 (the run, the placeholder key, the denials, the `.env` gap) are written from Box's docs. On a laptop the next day, a box did start, with a shell in place of Claude Code: see [Part 3's probe](../part-3-what-strands-box-changes/README.md#try-it-with-no-model). `box runs history` on that box ID had nothing to read (`cannot read records at ... records.jsonl: No such file or directory`), because the run never started.

## 4. yarn is skipped on Debian

`box profile create` skipped yarn with `it runs /usr/bin/dash, which is the command of no tool table`. The hands-on doesn't use yarn. If your project does, check Box's yarn pack README before you rely on it in a box.

## 5. Box wouldn't start with its home on btrfs

On an Arch-based Linux laptop whose home folder is on btrfs, every `box run` stopped right after it made the box, before anything ran in it ([`captured/09-btrfs-home.txt`](captured/09-btrfs-home.txt)):

```text
strands-box: error: unsafe box directory ~/.strands/box/r/b-6a0d4a56d9cbe382/box: its first-use contents changed before the record write
```

It happened with the default `~/.strands/box`, with a fresh short folder in the home folder, and with btrfs compression turned off for that folder. With `BOX_HOME` on tmpfs, the same profiles ran. We haven't found the cause, so treat btrfs as the likely link, not a proven one.

What we did: point `BOX_HOME` at a short folder on tmpfs, and link the installed packages there so nothing is downloaded again.

```sh
export BOX_HOME=/tmp/box-$USER
mkdir -p "$BOX_HOME" && ln -sfn ~/.strands/box/packages "$BOX_HOME/packages"
```

Set it in each terminal you run `box` from. Profiles you create live in `$BOX_HOME/profiles` and go when the machine restarts: run step 5's `box profile create` again and add step 7's `[filesystem]` table. Keep the folder short: a long `BOX_HOME` breaks the box's socket (gap 2).
