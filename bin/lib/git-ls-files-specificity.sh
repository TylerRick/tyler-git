#!/usr/bin/env bash

# ------------------------------------------
# git-ls-files-by-specificity
# Usage: git-ls-files-by-specificity [--name-only] [--detect] [<commit>] [<specificity>]
# Lists each path in the commit with its specificity, aligned into columns.
# Options:
#   --name-only : only print matching file paths (no status or specificity)\#   --detect    : run git-detect-file-specificity before listing
#   <commit>    : commit ref (default HEAD)
#   <specificity>: filter to only that value: common, specific, mixed
# ------------------------------------------
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  return
fi

set -euo pipefail
name_only=false; detect=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name-only) name_only=true; shift ;; 
    --detect)    detect=true; shift ;;
    --help)      echo "Usage: $0 [--name-only] [--detect] [<commit>] [<specificity>]" >&2; exit 0 ;;
    --*)         echo "Unknown option $1" >&2; exit 1 ;;
    *) break ;;
  esac
done
commit=HEAD; specificity_filter=""
if [[ $# -ge 1 ]]; then commit=$1; shift; fi
if [[ $# -ge 1 ]]; then specificity_filter=$1; shift; fi

# gather git show lines
mapfile -t raw < <(git show --name-status --oneline "$commit")
summary="${raw[0]}"

declare -a entries
maxlen=0
# choose spec function
specfunc=git-get-file-specificity
$detect && specfunc=git-detect-file-specificity

for i in "${raw[@]:1}"; do
  [[ -z "$i" ]] && continue
  read -r status rest <<< "$i"
  # skip deletes
  [[ "$status" == D* ]] && continue
  if [[ "$status" == R* ]]; then
    # rest: old new
    read -r oldpath newpath <<< "$rest"
    path="$newpath"
    display="$status  $oldpath  $newpath"
  else
    path="$rest"
    display="$status  $rest"
  fi
  # get specificity
  spec=$($specfunc "$path" 2>/dev/null || true)
  # filter
  if [[ -n "$specificity_filter" && "$spec" != "$specificity_filter" ]]; then
    continue
  fi
  if $name_only; then
    entries+=("$path|")
  else
    len=${#display}
    (( len > maxlen )) && maxlen=$len
    entries+=("$display|$spec")
  fi
done

# output
if ! $name_only; then
  echo "$summary"
  for e in "${entries[@]}"; do
    IFS='|' read -r disp spec <<< "$e"
    printf "%-${maxlen}s %s
" "$disp" "$spec"
done
else
  for e in "${entries[@]}"; do
    IFS='|' read -r path _ <<< "$e"
    echo "$path"
done
fi

