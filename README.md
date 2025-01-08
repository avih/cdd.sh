# cdd.sh
Add shell function "cdd", which does "cd" to a matching recently-used path.

This is useful in an interactive shell, as it allows moving quickly
between recent directories using only a small string which the target
path contains.

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

# Help output
Basic help (`cdd -h`):
```
Usage: cdd [OPTIONS] ...
Perform "cd" to a matching recently-used path.
Paths are saved in a history file after successful "cd" or "cdd".

  cdd -h | --help     Print basic help and exit.
  cdd -hh             Print extended help and exit.

  cdd STR             cd to the first stored path which contains STR.
  cdd -p [STR]        Print all stored paths [which contain STR].
  cdd -f              Flush - move $PWD now to the top of CDHIST.

  - When cdd succeeds and changes-dir, the path is printed to stdout.
  - When cd or cdd succeed, $PWD is moved to the top of $CDHIST file
    (def: ~/.cd_hist), except if it's already near the top. See info
    in extended help. CDHIST holds up to $CDHISTSIZE paths (def: 100).
  - Set CDLOOKUP=1 to automatically run "cdd STR" if "cd STR" fails.
  - Set CDHIST=  (set+empty) to disable recording/lookup in this file.
  - If $CDPERM is set, this file is searched [too], but never updated.

Requires: POSIX shell or zsh, touch, mv, optionally grep/sed/head.
Copyright 2024 Avi Halachmi  Home page: https://github.com/avih/cdd.sh
```

Extended help (`cdd -hh`) is same as the basic help, plus:
```
  CDPERM matches at the -p output begin with ": ".

  If both CDHIST and CDPERM exist, CDHIST is searched first.
  CDHIST is not created/searched/updated if $CDHIST is set and empty.
  (new paths are never saved, cdd only searches CDPERM, no updates)
  CDHIST is not created if its directory doesn't exist (cdd fails).
  CDHIST is not updated if the path was matched using CDPERM file.
  CDHIST is not updated if the path is $HOME or contains newline.

  CDHIST is also not updated if the path is already within the top
  $CDTHRESH paths (default: 5) at CDHIST, to avoid frequent rewrites.
  This means that a matched path is not necessarily the actual most
  recent, but usually that's OK. Use cdd -f to move $PWD to the top
  regardless of $CDTHRESH, or set CDTHRESH=0 to always update CDHIST.

  Uses shell for search, which may be slow-ish with big CDHISTSIZE.
  Set CDGREP=1 to use to grep instead (requires re-dot of cdd.sh).

  To restore the shell builtin "cd" (disable the wrapper, so history
  will not update after "cd"), do "unset -f cd" after dotting cdd.sh.
  In this case cdd still behaves normally - "cdd STR" changes dir and
  can update the history, while "cdd -f" adds/moves the current path.
```
