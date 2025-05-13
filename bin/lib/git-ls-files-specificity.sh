# ------------------------------------------
# lib/git-ls-files-specificity.sh
# Common logic for listing files with recorded specificity
# ------------------------------------------

# Usage: source this file in a script that defines ls_files_cmd function
# Requires: git-get-file-specificity, git-detect-file-specificity

set -euo pipefail

# Parse options
quiet=false
name_only=false
detect=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet | -q) quiet=true; shift ;;  
    --name-only) name_only=true; shift ;;  
    --detect)    detect=true;    shift ;;  
    --help)      echo "Usage: $(basename "$0") [--name-only] [--detect] [<commit>] [<specificity>]" >&2; exit 0 ;;  
    -*)         echo "Unknown option $1" >&2; exit 1 ;;  
    *) break ;;  
  esac
done

# Determine commit and optional specificity filter
if [[ $# -ge 1 && ! "$1" =~ ^(common|specific|mixed)$ ]]; then
  commit=$1; shift
fi
specificity_filter=""
if [[ $# -ge 1 ]]; then
  specificity_filter=$1; shift
fi

# If detect mode, run git-detect-file-specificity on each file first
if $detect; then
  # ls_files_cmd --name-only $commit
  while IFS=$'\t' read -r path; do
    #set -x # Show next command only
    git-detect-file-specificity ${commit} "$path" </dev/tty || true
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
  spec=$(git-get-file-specificity "$path" 2>/dev/null || true)
  [[ -n "$specificity_filter" && "$spec" != "$specificity_filter" ]] && continue
  if ! $name_only; then
    len=${#disp}
    (( len > maxlen )) && maxlen=$len
    entries+=("$disp|$spec")
  else
    entries+=("$path|")
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
if ! $name_only; then
  # header: commit hash and message
  if [[ $quiet = false ]]; then
    echo "$(git rev-parse --short "$commit") $(git log --format=%s -n1 "$commit")"
  fi
  for e in "${entries[@]}"; do
    IFS='|' read -r disp spec <<< "$e"
    printf "%-${maxlen}s  %s\n" "$disp" "$spec"
  done
else
  for e in "${entries[@]}"; do
    IFS='|' read -r path _ <<< "$e"
    echo "$path"
  done
fi
