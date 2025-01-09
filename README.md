# cdd.sh
Add shell function "cdd", which does "cd" to a matching recently-used path.

This can be useful in interactive shells, as it allows moving between
recent directories very quickly and intuitively .

It's typically more useful than searching the shell's history, because
that probably includes non-cd commands which will also match the search,
and also cd to relative paths, which won't help in a different directory.

Some shells also have "pushd" and "popd" which may be useful, but these
still expect the user to maintain mental order of the paths, only useful
when going back in reverse order, and mostly less nice than plain search.

In contrast, "cdd" tries to keep it simple: "cdd THING" changes dir to
the first matching path.

It maintains/search history of absolute paths, more recent paths first,
and works the same in any directory. History is updated automatically
by default after "cd" or "cdd". The history file is a plain list, and
can be edited manually if needed. Fixed-list mode is also supported.

# Usage
- Save `cdd.sh` someplace. We'll assume it's at `~/scripts/cdd.sh` .
- At the shell init file, like `~/.bashrc`, `~/.zshrc`, etc, add:
    ```
    . ~/scripts/cdd.sh    # dot, space, and the path
    ```
- Then, when `cd` (or `cdd`) succeeds, the resulting path is added
to the history file.
-  `cdd FOO` will then search `FOO` at the history file, and `cd` to
a recent path which includes `FOO`, if one exists.
- History remains between sessions, and concurrent sessions work too.

# Help output

### Basic help (`cdd -h`):
```
Usage: cdd [OPTIONS] ...
Perform "cd" to a matching recently-used path.
Paths are saved in a history file after successful "cd" or "cdd".

  cdd -h | --help     Print basic help and exit.
  cdd -hh             Print extended help and exit.

  cdd PAT             cd to the first stored path which contains PAT.
  cdd -p [PAT]        Print all stored paths [which contain PAT].
  cdd -f              Flush - add/move $PWD now to the top of CDHIST.

  - PAT is sub-pattern, e.g. all of "abc", "bc", "c*f" match "abcdef".
  - When cd or cdd succeed, $PWD is moved to the top of $CDHIST file,
    unless it's already within the top 5 paths (default: ~/.cd_hist).
  - Set CDLOOKUP=1 to automatically run "cdd ARG" if "cd ARG" fails.
  - Set CDHIST=  (set+empty) to disable (ignore) the history file.
  - If $CDPERM is set, this file is searched [too], but never updated.

Requires: POSIX shell or zsh, touch, mv, optionally grep/sed/head.
Copyright 2024 Avi Halachmi  Home page: https://github.com/avih/cdd.sh
```

### Extended help (`cdd -hh`):
```
Usage: cdd [OPTIONS] ...
Perform "cd" to a matching recently-used path.
Paths are saved in a history file after successful "cd" or "cdd".

  cdd -h | --help     Print basic help and exit.
  cdd -hh             Print extended help and exit.

  cdd PAT             cd to the first stored path which contains PAT.
  cdd -p [PAT]        Print all stored paths [which contain PAT].
  cdd -f              Flush - add/move $PWD now to the top of CDHIST.

  - PAT is sub-pattern, e.g. all of "abc", "bc", "c*f" match "abcdef".
    Implemented as shell unquoted   case...in *$PAT*)...   therefore:
    - PAT without pattern/esc chars (* ? [ ] \) matches a sub-string.
    - '*', '?', and simple '[...]' apply normally in all POSIX shells.
    - Escaped '\<thing>' or non-trivial PAT may differ between shells.
    - In zsh PAT is a sub-string by default. May depend on sh options.
    - See also CDGREP below, to use grep instead of shell pattern.
  - When cdd succeeds and changes dir, the path is printed to stdout.
  - When cd or cdd succeed, $PWD is moved to the top of $CDHIST file,
    unless it's already within the top 5 paths (default: ~/.cd_hist).
  - This update and -f keep the top $CDHISTSIZE paths (default: 100).
  - Set CDLOOKUP=1 to automatically run "cdd ARG" if "cd ARG" fails.
  - Set CDHIST=  (set+empty) to disable (ignore) the history file.
  - If $CDPERM is set, this file is searched [too], but never updated.
    CDPERM matches at the -p output begin with ": ".

  If both CDHIST and CDPERM files exist, CDHIST is searched first.
  CDHIST is not created/searched/updated if $CDHIST is set and empty.
  ($CDPERM file is still searched if non-empty)
  CDHIST is not created if its directory doesn't exist (cdd fails).
  CDHIST is not updated if the path was matched using CDPERM file.
  CDHIST is not updated if the path is $HOME or contains newline.

  CDHIST is also not updated if the path is already within the top
  $CDTHRESH paths (default: 5) at CDHIST, to avoid frequent rewrites.
  This means that a matched path is not necessarily the actual most
  recent, but usually that's OK. Use cdd -f to move $PWD to the top
  regardless of $CDTHRESH, or set CDTHRESH=0 to always update CDHIST.

  Uses shell for search, which may be slow-ish with big CDHISTSIZE.
  Set CDGREP=1 to use grep instead (requires re-dot of cdd.sh).
  This uses PAT as grep BRE pattern instead of a shell sub-pattern.

  To restore the shell builtin "cd" (disable the wrapper, so history
  will not update after "cd"), do "unset -f cd" after dotting cdd.sh.
  In this case cdd still works normally - "cdd PAT" changes dir and
  can update the history, while "cdd -f" adds/moves $PWD to the top.

Requires: POSIX shell or zsh, touch, mv, optionally grep/sed/head.
Copyright 2024 Avi Halachmi  Home page: https://github.com/avih/cdd.sh
```
