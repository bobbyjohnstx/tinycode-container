# Extract testable functions from entrypoint.sh for unit testing.
# We source specific functions rather than the whole script to avoid
# executing the entrypoint's main logic.

# sanitize_url function from entrypoint.sh
sanitize_url() {
  echo "$1" | sed -E 's|://[^@]*@|://***@|g'
}

# VLLM model validation regex (from entrypoint.sh config.json block)
validate_vllm_model() {
  echo "$1" | grep -qE '^[a-zA-Z0-9/_:@. -]+$'
}

# OC version validation (from entrypoint.sh)
validate_oc_version() {
  case "$1" in
    stable|latest|fast|candidate) return 0 ;;
    [0-9]*.[0-9]*.[0-9]*) return 0 ;;
    *) return 1 ;;
  esac
}
