# ------------------------------------------
# lib/git-ls-files-specificity.sh
# Common logic for listing files with recorded specificity
# ------------------------------------------

# Usage: source this file in a script that defines ls_files_cmd function
# Requires: git-get-file-specificity, git-detect-file-specificity

set -euo pipefail
trap 'echo "[ERR] at line $LINENO: $BASH_COMMAND"' ERR

source "$(dirname $0)"/lib/specificity.sh
source "$(dirname $0)"/git-get-file-specificity

function usage() {
  cat - >&2 <<End
Usage: $(basename "$0") [--name-only] [--detect] [<commit>] [<specificity>]

Options:

  --name-only
    List filenames only, instead of including change type prefix and adding the specificity after each filename

  --detect
    Run git-detect-file-specificity for each file. Useful to make sure all files in a commit have been classified and make sure none of them are showing as "unknown".

  --quiet
    Passes --quiet to git-detect-file-specificity.
End
  exit
}

#═══════════════════════════════════════════════════════════════════════════════════════════════════
# Parse options and args

quiet=false
name_only=false
color_name=true
detect=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet | -q) quiet=true; shift ;;  
    --name-only)  name_only=true; shift ;;  
    --detect)     detect=true;    shift ;;  
    --help | -h)  usage ;;  
    -*)           echo "Unknown option $1" >&2; exit 1 ;;  
    *) break ;;  
  esac
done

# Determine commit and optional specificity filter
if [[ $# -ge 1 && ! "$1" =~ ^(common|specific|mixed|unknown)$ ]]; then
  commit=$1; shift
fi
specificity_filter=""
if [[ $# -ge 1 ]]; then
  specificity_filter=$1; shift
fi

#═══════════════════════════════════════════════════════════════════════════════════════════════════

# If detect mode, run git-detect-file-specificity on each file first
if $detect; then
  # ls_files_cmd --name-only $commit
  while IFS=$'\t' read -r path; do
    #set -x # Show next command only
    git-detect-file-specificity $($quiet && echo '--quiet') ${commit} "$path" </dev/tty || true
    #{ set +x; } 2>/dev/null
  done < <(ls_files_cmd --name-only $commit)
  echo 'Done with detect'
fi

# Collect entries and measure display width
declare -a entries
maxlen=0
# Expect ls_files_cmd outputs "status<TAB>path<TAB>oldpath?"
while IFS=$'\t' read -r status path old; do
  if [[ "$status" == R* ]]; then
    disp="$status  $old -> $path"
  else
    disp="$status  $path"
  fi
  specificity=$(git-get-file-specificity "$path" 2>/dev/null || true)
  #echo >&2 "$status $path $specificity"
  [[ -n "$specificity_filter" && "${specificity:-unknown}" != "$specificity_filter" ]] && continue

  if $name_only; then
    entries+=("$path|")
  else
    if $color_name; then
      disp=$(colorize_specificity $specificity "$disp")
    fi
    len=${#disp}
    (( len > maxlen )) && maxlen=$len
    entries+=("$disp|$specificity")
  fi
  # Show some progress since this is really slow, unless --quiet (since it is likely being consumed
  # by script)
  if [[ $quiet = false ]]; then
    echo -n '.'
  fi
done < <(ls_files_cmd $commit)

if [[ $quiet = false ]]; then
  echo
fi

# Print results
if $name_only; then
  for e in "${entries[@]}"; do
    IFS='|' read -r path _ <<< "$e"
    echo "$path"
  done
else
  # header: commit hash and message
  if [[ $quiet = false ]] && [ -n "$commit" ]; then
    echo "$(git rev-parse --short "$commit") $(git log --format=%s -n1 "$commit")"
  fi
  for e in "${entries[@]}"; do
    IFS='|' read -r disp specificity <<< "$e"
    printf "%-${maxlen}s  %s\n" "$disp" "$(colorize_specificity $specificity $specificity)"
  done
fi
