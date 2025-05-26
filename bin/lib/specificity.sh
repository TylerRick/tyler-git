source "$(dirname $0)"/lib/colors.sh

#════════════════════════════════════════════════════════════════════════════════════════════════════
# Config

# By default this is a hidden repo-specific config dir stored _outside_ of your repos, similar to
# .git/info/exclude or .git/hooks. But if you want to commit this config as _part_ of your repo, you
# could configure it to .git_file_specificity, for example, similar to .gitignore/.githooks/.husky.

# TODO: Support reading multiple lists, so that each specific repo can use the common list that is
# defined in the common repo, and the specific/mixed lists defined in their own repo. Or just make
# everyone symlink their specific repo's common _file_ to point to the common list in common repo.

file_specificity_dir=$(git config split-branch.fileSpecificityDir ||
	echo ".git/file_specificity")

#════════════════════════════════════════════════════════════════════════════════════════════════════
# Helpers

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

ensure_file_specificity_dir_exists() {
  if ! [ -d $file_specificity_dir ]; then
    echo >&2 "$file_specificity_dir does not exist."
    echo >&2 "Hint: Configure with \`git config split-branch.fileSpecificityDir\` if it is located someplace else."
    exit 64 # EX_USAGE
  fi
}

rebase_seq__set_instructionFormat_to_include_notes() {
  # %N for notes (not natively supported here); %d for branch names
  default_instructionFormat="[%N]%d %s [%as %an]"
  current_instructionFormat="$(git config rebase.instructionFormat)"
  if ! [ "$current_instructionFormat" = "$default_instructionFormat" ]; then
    git config rebase.instructionFormat "$default_instructionFormat"
  fi
  git config rebase.instructionFormat-backup "$current_instructionFormat"
}

rebase_exec__restore_instructionFormat() {
  cat <<-End | sed 's/^[[:space:]]*//'
  exec sh -c 'git-rebase-seq-add-specificity--restore-instruction-format'
End
}

