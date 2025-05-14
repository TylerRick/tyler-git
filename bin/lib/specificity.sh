source "$(dirname $0)"/lib/colors.sh

normalize_specificity() {
  case "${1,,}" in
    c*) echo "common" ;;
    m*) echo "mixed" ;;
    s*) echo "specific" ;;
    *)
      echo "Unrecognized specificity abbreviation: '$specificity'. Expected 'common', 'mixed', or 'specific' (or any abbreviation starting with 'c', 'm', or 's')."
      exit 1
      ;;
  esac
}

colorize_specificity() {
  specificity=$1; shift
  message=${*:-$specificity}
  case "$specificity" in
    common) _green "$message" ;;
    mixed) _yellow "$message" ;;
    specific) _red "$message" ;;
    *) ;;
  esac
}
