source "$(dirname $0)"/lib/colors.sh

normalize_specificity() {
  if [ -z "${1-}" ]; then
    return
  fi

  # Strip ANSI color codes
  input=$(echo -e "$1" | sed -E 's/\x1B\[[0-9;]*[mK]//g')

  if [[ "$input" == *$'\n'* ]]; then
    echo >&2 "❌ Error! specificity string contains multiple lines!:"
    echo >&2 "$input"
    echo >&2 "If this is from notes on a commit, git may have combined (concatenated) notes during a rebase. This can happen if using the default config for notes.rewriteMode, which is concatenate. You can run git-ls-notes-specificity to fix those."
    #exit 1
  fi

  case "${input,,}" in
    c*) echo "common" ;;
    m*) echo "mixed" ;;
    s*) echo "specific" ;;
    *)
      echo "Unrecognized specificity abbreviation: '$specificity'. Expected 'common', 'mixed', or 'specific' (or any abbreviation starting with 'c', 'm', or 's')." >&2
      exit 1
      ;;
  esac
}

colorize_specificity() {
  specificity=${1:-unknown}; shift
  message=${*:-$specificity}
  case "$specificity" in
    common) _green "$message" ;;
    mixed) _yellow "$message" ;;
    specific) _red "$message" ;;
    *)    _magenta "$message" ;;
  esac
}

log_oneline_with_commit_specificity() {
  GIT_NOTES_DISPLAY_REF=refs/notes/specificity git log-oneline-notes "$@"
}
