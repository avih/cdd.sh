# dot me
# cdd.sh - Add function "cdd" which does cd to a matching recently-used path.
# Copyright 2024 Avi Halachmi  avihpit@yahoo.com  https://github.com/avih/cdd.sh
# License: MIT

# These can be overridden before/after dotting this file, affect the next cd[d]
: ${CDHIST=~/.cd_hist}  # paths-list history file, recent at the top
: ${CDPERM=}        # if non-empty, search this file too, but never update it
: ${CDHISTSIZE=100} # number of unique recent successful cd-into paths to keep
: ${CDTHRESH=5}     # skip CDHIST update if $PWD is already in top CDTHRESH
: ${CDLOOKUP=}      # run "cdd STR" if "cd STR" fails
# ${CDGREP=}        # match with grep instead of shell. applied only at dotting

__cdd_help() {
    echo 'Usage: cdd [OPTIONS] ...'
    echo 'Perform "cd" to a matching recently-used path.'
    echo 'Paths are saved in a history file after successful "cd" or "cdd".'
    echo
    echo '  cdd -h | --help     Print basic help and exit.'
    echo '  cdd -hh             Print extended help and exit.'
    echo                     
    echo '  cdd STR             cd to the first stored path which contains STR.'
    echo '  cdd -p [STR]        Print all stored paths [which contain STR].'
    echo '  cdd -f              Flush - move $PWD now to the top of CDHIST.'
    echo
    echo '  - When cdd succeeds and changes-dir, the path is printed to stdout.'
    echo '  - When cd or cdd succeed, $PWD is moved to the top of $CDHIST file'
    echo "    (def: ~/.cd_hist), except if it's already near the top. See info"
    echo '    in extended help. CDHIST holds up to $CDHISTSIZE paths (def: 100).'
    echo '  - Set CDLOOKUP=1 to automatically run "cdd STR" if "cd STR" fails.'
    echo '  - Set CDHIST=  (set+empty) to disable recording/lookup in this file.'
    echo '  - If $CDPERM is set, this file is searched [too], but never updated.'
e&& echo '    CDPERM matches at the -p output begin with ": ".'
    echo
e&& echo '  If both CDHIST and CDPERM exist, CDHIST is searched first.'
e&& echo '  CDHIST is not created/searched/updated if $CDHIST is set and empty.'
e&& echo '  (new paths are never saved, cdd only searches CDPERM, no updates)'
e&& echo "  CDHIST is not created if its directory doesn't exist (cdd fails)."
e&& echo '  CDHIST is not updated if the path was matched using CDPERM file.'
e&& echo '  CDHIST is not updated if the path is $HOME or contains newline.'
e&& echo
e&& echo '  CDHIST is also not updated if the path is already within the top'
e&& echo '  $CDTHRESH paths (default: 5) at CDHIST, to avoid frequent rewrites.'
e&& echo '  This means that a matched path is not necessarily the actual most'
e&& echo "  recent, but usually that's OK. Use cdd -f to move \$PWD to the top"
e&& echo '  regardless of $CDTHRESH, or set CDTHRESH=0 to always update CDHIST.'
e&& echo
e&& echo '  Uses shell for search, which may be slow-ish with big CDHISTSIZE.'
e&& echo '  Set CDGREP=1 to use to grep instead (requires re-dot of cdd.sh).'
e&& echo
    echo 'Requires: POSIX shell or zsh, touch, mv, optionally grep/sed/head.'
    echo 'Copyright 2024 Avi Halachmi  Home page: https://github.com/avih/cdd.sh'
}

if [ -z "${CDGREP-}" ]; then
    __cdd_list2() {  # print input lines which contain $1, add $2 prefix
        while IFS= read -r cdd; do
            case $cdd in *"$1"*) echo "$2$cdd"; esac
        done
    }
    __cdd_list() {  # print input lines which contain $1
        __cdd_list2 "$1" ""
    }
    __cdd_match() {  # set $cdd to the first line which contains $1, or fail
        while IFS= read -r cdd; do
            case $cdd in *"$1"*) return 0; esac
        done && false
    }
    __cdd_istop() {  # succeed if one of the top $1 (>=0) input lines is $PWD
        __cdd_n=$1
        while [ "$((__cdd_n--))" != 0 ] && IFS= read -r cdd; do
            [ "$cdd" = "$PWD" ] && return
        done && false
    }
    __cdd_update() {  # print up to $1 (>=0) input lines which are not $PWD
        __cdd_n=$1
        while [ "$((__cdd_n--))" != 0 ] && IFS= read -r cdd; do
            [ "$cdd" = "$PWD" ] && : $((++__cdd_n)) || echo "$cdd"
        done
    }
else
    __cdd_list()   { grep -F -- "$1" || :; }  # succeed
    __cdd_list2()  { __cdd_list "$1" | sed "s/^/$2/"; }  # $2 must be valid
    __cdd_match()  { cdd=$(__cdd_list "$1" | head -n 1); [ "$cdd" ]; }
    __cdd_istop()  { head -n "$1" | grep -F -x -q -- "$PWD"; }
    __cdd_update() { grep -F -x -v -- "$PWD" | head -n "$1"; }
fi

[ "${ZSH_VERSION-}" ] &&  # run a shell-builtin
    __cdd_builtin() { builtin "$@"; } ||
    __cdd_builtin() { command "$@"; }

__cdd_hist_ok() { [ -f "$CDHIST" ] || touch -- "$CDHIST"; }
__cdd_err()     { >&2 echo "cdd: ${2-error: }$1"; false; }
__cdd_LF="
"

# [$1: alternative CDTHRESH to use]. maybe update CDHIST (assumed exists)
__cdd_success() {
    # check whether we should update CDHIST
    case "$PWD" in "${HOME-}" | *"$__cdd_LF"*) return 0; esac
    [ "${1-$CDTHRESH}" -gt 0 ] && __cdd_istop "$CDTHRESH" < "$CDHIST" && return

    # move/add $PWD to the top of CDHIST, clip to CDHISTSIZE
    [ "$CDHISTSIZE" -gt 0 ] || __cdd_err "bad \$CDHISTSIZE -- $CDHISTSIZE" \
    &&  echo "$PWD" > "$CDHIST.$$.tmp" \
    &&  __cdd_update "$((CDHISTSIZE-1))" < "$CDHIST" >> "$CDHIST.$$.tmp" \
    &&  mv -- "$CDHIST.$$.tmp" "$CDHIST"  # atomic, just in case
}

cd() {
    if [ "${CDLOOKUP-}" ] && [ "$#" = 1 ] && case $1 in -*) false; esac; then
        __cdd_builtin cd "$1" 2>/dev/null || { cdd "$1"; return; }
    else
        __cdd_builtin cd "$@" || return
    fi
    [ -z "$CDHIST" ] || { __cdd_hist_ok && __cdd_success; }
}

cdd() {
    cdd=  # eat at most one option, maybe '--'
    case ${1-} in -[!-]*|--?*) cdd=$1; shift; esac
    case ${1-} in --) shift;;  -?*) false; esac &&
    case $cdd in
    -h|--help) (e() { false; }; __cdd_help); return ;;
          -hh) (e() { true;  }; __cdd_help); return ;;
           '') [ "$#" = 1 ] ;;
           -f) [ "$#" = 0 ] ;;
           -p) [ "$#" -le 1 ] ;;
            *) __cdd_err "illegal option -- $cdd" '' ;;
    esac || { >&2 echo "Usage: cdd  STR | -p [STR] | -f | -h"; return 1; }

    [ "$CDHIST$CDPERM" ] || { __cdd_err 'empty $CDHIST+$CDPERM'; return; }
    [ -z "$CDHIST" ] || __cdd_hist_ok || return

    case $cdd in
    -f) [ "$CDHIST" ] || __cdd_err 'empty $CDHIST' && __cdd_success 0
        ;;
    -p) [ -z "$CDHIST" ] || __cdd_list "${1-}" < "$CDHIST"
        [ -z "$CDPERM" ] || __cdd_list2 "${1-}" ": " < "$CDPERM"
        ;;
     *) if [ "$CDHIST" ] && __cdd_match "$1" < "$CDHIST"; then
            __cdd_builtin cd -- "$cdd" && echo "$cdd" && __cdd_success
        elif [ "$CDPERM" ] && __cdd_match "$1" < "$CDPERM"; then
            __cdd_builtin cd -- "$cdd" && echo "$cdd"
        else
            __cdd_err "match not found -- $1" ''
        fi
    esac
}
