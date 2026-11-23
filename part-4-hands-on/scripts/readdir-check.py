#!/usr/bin/env python3
"""Does this file system show a new entry through a directory handle that was
already listed? Box 0.3.0 lists a new box folder twice through one handle; on
btrfs the second listing misses the folder Box just made, so the first start of
each new box stops with "its first-use contents changed before the record write"
(known gap 5). Changes nothing outside a temporary folder.

    python3 scripts/readdir-check.py [folder]     # default: ~/.strands/box
"""
import os
import sys
import tempfile

base = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/.strands/box")
folder = tempfile.mkdtemp(dir=base)
try:
    handle = os.open(folder, os.O_RDONLY | os.O_DIRECTORY)
    # os.scandir on a descriptor duplicates it, lists it with readdir, then
    # rewinds it: the same steps Box takes.
    before = sorted(e.name for e in os.scandir(handle))
    os.mkdir("private", dir_fd=handle)
    after = sorted(e.name for e in os.scandir(handle))
    os.close(handle)
finally:
    p = os.path.join(folder, "private")
    if os.path.isdir(p):
        os.rmdir(p)
    os.rmdir(folder)

fs = os.popen("stat -f -c %T " + base).read().strip() or "unknown"
print(f"{base} ({fs}): listed {before}, made 'private', listed again {after}")
if after == ["private"]:
    print("ok: the new folder shows. Box's first start should work here.")
else:
    print("the new folder is missing: expect the first start of each new box to stop (known gap 5).")
    sys.exit(1)
