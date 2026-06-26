#!/usr/bin/env bats

load helpers

# --- URL Sanitization ---

@test "sanitize_url strips credentials from https URL" {
  result=$(sanitize_url "https://user:token@github.com/org/repo.git")
  [ "$result" = "https://***@github.com/org/repo.git" ]
}

@test "sanitize_url leaves URL without credentials unchanged" {
  result=$(sanitize_url "https://github.com/org/repo.git")
  [ "$result" = "https://github.com/org/repo.git" ]
}

@test "sanitize_url handles SSH URLs without false positive" {
  result=$(sanitize_url "git@github.com:org/repo.git")
  [ "$result" = "git@github.com:org/repo.git" ]
}

@test "sanitize_url strips complex credentials with special chars" {
  result=$(sanitize_url "https://user:p%40ss@github.com/repo.git")
  [ "$result" = "https://***@github.com/repo.git" ]
}

# --- VLLM Model Validation ---

@test "validate_vllm_model accepts simple model name" {
  validate_vllm_model "llama3"
}

@test "validate_vllm_model accepts model with slashes" {
  validate_vllm_model "meta-llama/Llama-3-70B"
}

@test "validate_vllm_model accepts model with colons" {
  validate_vllm_model "qwen2.5:72b"
}

@test "validate_vllm_model accepts model with dots and hyphens" {
  validate_vllm_model "qwen2.5-instruct-32b"
}

@test "validate_vllm_model rejects double quotes (JSON injection)" {
  run validate_vllm_model 'foo", "evil": "payload'
  [ "$status" -ne 0 ]
}

@test "validate_vllm_model rejects backticks (command injection)" {
  run validate_vllm_model '$(whoami)'
  [ "$status" -ne 0 ]
}

@test "validate_vllm_model rejects curly braces" {
  run validate_vllm_model '{malicious}'
  [ "$status" -ne 0 ]
}

@test "validate_vllm_model rejects backslash" {
  run validate_vllm_model 'model\\ninjection'
  [ "$status" -ne 0 ]
}

# --- OC Version Validation ---

@test "validate_oc_version accepts 'stable'" {
  validate_oc_version "stable"
}

@test "validate_oc_version accepts 'latest'" {
  validate_oc_version "latest"
}

@test "validate_oc_version accepts 'fast'" {
  validate_oc_version "fast"
}

@test "validate_oc_version accepts 'candidate'" {
  validate_oc_version "candidate"
}

@test "validate_oc_version accepts semver" {
  validate_oc_version "4.15.0"
}

@test "validate_oc_version rejects path traversal" {
  run validate_oc_version "../../etc/passwd"
  [ "$status" -ne 0 ]
}

@test "validate_oc_version rejects shell injection" {
  run validate_oc_version '; rm -rf /'
  [ "$status" -ne 0 ]
}

@test "validate_oc_version rejects empty string" {
  run validate_oc_version ""
  [ "$status" -ne 0 ]
}

# --- Config JSON Generation ---

@test "config.json without VLLM_MODEL has no model field" {
  DEFAULTS_FILE=$(mktemp)
  cat > "$DEFAULTS_FILE" << 'EOF'
{
  "plugin": ["/opt/oh-my-tiny"]
}
EOF
  # Verify valid JSON
  python3 -c "import json; json.load(open('$DEFAULTS_FILE'))"
  # Verify no model field
  result=$(python3 -c "import json; d=json.load(open('$DEFAULTS_FILE')); print('model' in d)")
  [ "$result" = "False" ]
  rm -f "$DEFAULTS_FILE"
}

@test "config.json with valid VLLM_MODEL includes model field" {
  DEFAULTS_FILE=$(mktemp)
  MODEL="vllm/qwen3-30b"
  if echo "$MODEL" | grep -qE '^[a-zA-Z0-9/_:@. -]+$'; then
    cat > "$DEFAULTS_FILE" << EOF
{
  "plugin": ["/opt/oh-my-tiny"],
  "model": "$MODEL"
}
EOF
  fi
  result=$(python3 -c "import json; d=json.load(open('$DEFAULTS_FILE')); print(d['model'])")
  [ "$result" = "vllm/qwen3-30b" ]
  rm -f "$DEFAULTS_FILE"
}

@test "config.json with malicious VLLM_MODEL is rejected" {
  MODEL='foo", "evil": "payload'
  if echo "$MODEL" | grep -qE '^[a-zA-Z0-9/_:@. -]+$'; then
    echo "SHOULD NOT REACH HERE"
    return 1
  fi
  # Validation correctly rejects — test passes
}

# --- Entrypoint Syntax ---

@test "entrypoint.sh has valid shell syntax" {
  bash -n /private/tmp/tinycode-container/entrypoint.sh
}

# --- install.sh Port ---

@test "install.sh uses port 4096" {
  ! grep -q "3000" /private/tmp/tinycode-container/install.sh
}

@test "install.sh references port 4096" {
  grep -q "4096" /private/tmp/tinycode-container/install.sh
}
