#!/usr/bin/env python3
"""Stage, unstage, or toggle only the changed lines a selection covers.

Git has no native "stage these lines", so this filters a zero-context diff down to the
hunks overlapping the range and applies just those to the index.

    git-stage-lines.py stage   FILE START END
    git-stage-lines.py unstage FILE START END
    git-stage-lines.py toggle  FILE START END

START and END are 1-based inclusive line numbers, read from the working tree when staging
and from the index when unstaging. Passing the whole file's range acts on all of it.

`toggle` unstages when the range holds anything staged and stages otherwise, so one key
covers both directions. Where a hunk is part staged and part not, unstaging wins, keeping
the key's meaning as "remove".
"""

import re
import subprocess
import sys

HUNK = re.compile(rb"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@")

# Staging reads the index against the working tree, so its patch always applies to the
# index cleanly. Unstaging reads HEAD against the index and applies in reverse.
SIDES = {"stage": [], "unstage": ["--cached"]}


def git(args, **kw):
    return subprocess.run(["git"] + args, capture_output=True, **kw)


def main(argv):
    if len(argv) != 5 or argv[1] not in ("stage", "unstage", "toggle"):
        print(__doc__, file=sys.stderr)
        return 2
    mode, path, start, end = argv[1], argv[2], int(argv[3]), int(argv[4])

    if mode == "toggle":
        parsed = read_diff(path, "unstage")
        if parsed is None:
            return 1
        _, staged = parsed
        mode = "unstage" if any(overlaps(h[0], start, end) for h in staged) else "stage"

    parsed = read_diff(path, mode)
    if parsed is None:
        return 1
    header, hunks = parsed
    reverse = mode == "unstage"
    keep = [narrow(h, start, end, reverse) for h in hunks if overlaps(h[0], start, end)]
    keep = [h for h in keep if h is not None]
    if not keep:
        kind = "unstaged" if mode == "stage" else "staged"
        print(f"no {kind} change on lines {start}-{end} of {path}")
        return 0

    patch = header + b"".join(body for _, body in keep)
    # --unidiff-zero is required because the patch carries no context lines to match on.
    apply_args = ["apply", "--cached", "--unidiff-zero"]
    if mode == "unstage":
        apply_args.append("--reverse")
    proc = git(apply_args + ["-"], input=patch)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr.decode(errors="replace"))
        return proc.returncode
    print(f"{mode}d {len(keep)} hunk(s) on lines {start}-{end} of {path}")
    return 0


def read_diff(path, mode):
    """The zero-context diff whose hunks `mode` acts on, as (header, hunks), or None."""
    proc = git(["diff", "-U0", "--no-color"] + SIDES[mode] + ["--", path])
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr.decode(errors="replace"))
        return None
    return split_hunks(proc.stdout)


def split_hunks(diff):
    """Split a diff into its file header and a list of (line range, hunk bytes).

    Ranges are on the new side of the diff, which is the side the caller's line numbers are
    counted on: the working tree when staging, the index when unstaging.
    """
    header, hunks, current = [], [], None
    for line in diff.splitlines(keepends=True):
        match = HUNK.match(line)
        if match:
            if current:
                hunks.append(current)
            _, _, new_start, new_count = match.groups()
            first, count = int(new_start), int(new_count or 1)
            # A pure deletion has a count of 0 and sits between two lines. Cover both of them:
            # git names the line before the gap, while helix draws its marker on the line after,
            # so either is a reasonable thing to have the cursor on.
            span = (first, first + count - 1) if count else (first, first + 1)
            current = (span, bytearray(line))
        elif current is not None:
            current[1].extend(line)
        else:
            header.append(line)
    if current:
        hunks.append(current)
    return b"".join(header), [(span, bytes(body)) for span, body in hunks]


def narrow(hunk, start, end, reverse):
    """Cut a hunk down to the lines the range covers, or return it whole if it covers all of them.

    Git has no line level staging, so a hunk is trimmed the way `git add -p` lets you edit one by
    hand. Which lines to drop and which to turn into context depends on the direction, because
    reverse applying swaps the two sides:

    Staging, applied forwards, an unwanted `+` is dropped so it is never added, and an unwanted
    `-` becomes context so it stays in the index.

    Unstaging, applied in reverse, an unwanted `+` becomes context so it stays staged, and an
    unwanted `-` is dropped so it is not restored. Getting this backwards produces context lines
    that are not in the index, and git rejects the patch outright.

    Returns None if nothing is left to do.
    """
    span, body = hunk
    if start <= span[0] and span[1] <= end:
        return hunk

    lines = body.splitlines(keepends=True)
    match = HUNK.match(lines[0])
    old_start, _, new_start, _ = match.groups()
    old_start, new_start = int(old_start), int(new_start)

    removed = [l for l in lines[1:] if l.startswith(b"-")]
    added = [l for l in lines[1:] if l.startswith(b"+")]
    # `+` lines sit at consecutive new-side line numbers, which is what the range refers to
    wanted = {i for i in range(len(added)) if start <= new_start + i <= end}
    if not wanted and added:
        return None

    # Pair a removal with the addition at the same offset, which is what a modified line looks
    # like. Removals past the last addition ride along with it.
    def is_removal(i):
        if not added:
            return True
        return (i if i < len(added) else len(added) - 1) in wanted

    # Emit each pair together. Position matters in a patch: an addition has to sit next to the
    # removal it replaces, not after every removal in the hunk, or it lands in the wrong place.
    out, old_count, new_count = [], 0, 0
    for i in range(max(len(removed), len(added))):
        if i < len(removed):
            if is_removal(i):
                out.append(removed[i])
                old_count += 1
            elif not reverse:
                out.append(b" " + removed[i][1:])  # context, so it counts on both sides
                old_count += 1
                new_count += 1
        if i < len(added):
            if i in wanted:
                out.append(added[i])
                new_count += 1
            elif reverse:
                out.append(b" " + added[i][1:])
                old_count += 1
                new_count += 1

    head = f"@@ -{old_start},{old_count} +{new_start},{new_count} @@\n".encode()
    return (span, head + b"".join(out))


def overlaps(span, start, end):
    return span[0] <= end and start <= span[1]


if __name__ == "__main__":
    sys.exit(main(sys.argv))
