#!/bin/zsh
# lint-all-repos.sh - Unified linting for all Chrono* repositories
# Run from any directory; auto-detects sibling chrono* repos
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Track results (zsh associative array)
typeset -A RESULTS
TOTAL_ERRORS=0

# Find the repositories directory (parent of chronoboiler)
SCRIPT_DIR="${0:A:h}"
REPOS_DIR="${SCRIPT_DIR:h:h}"

# Repositories to lint
REPOS=(
  "chronoboiler"
  "chronoengine"
  "chronoboids"
  "chronoforth"
  "chronosat"
  "chronoquit"
  "chronoscribe"
)

# Logging functions
log_header() {
  echo -e "\n${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${BLUE}  $1${NC}"
  echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_repo() {
  echo -e "\n${CYAN}▸ $1${NC}"
}

log_check() {
  echo -e "  ${YELLOW}⦿${NC} $1"
}

log_pass() {
  echo -e "  ${GREEN}✓${NC} $1"
}

log_fail() {
  echo -e "  ${RED}✗${NC} $1"
  TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
}

log_skip() {
  echo -e "  ${YELLOW}○${NC} $1 (skipped)"
}

# Check if a command exists
has_cmd() {
  command -v "$1" &>/dev/null
}

# Run a linter, capturing result
run_linter() {
  local name="$1"
  shift
  local cmd=("$@")

  log_check "$name"
  if "${cmd[@]}" 2>&1 | head -20; then
    log_pass "$name passed"
    return 0
  else
    log_fail "$name failed"
    return 1
  fi
}

# Lint YAML files in a repo
lint_yaml() {
  local repo_path="$1"
  local config_file="$repo_path/.yamllint.yml"

  if [[ ! -f "$config_file" ]]; then
    config_file="$REPOS_DIR/chronoboiler/.yamllint.yml"
  fi

  if has_cmd yamllint; then
    # Find all YAML files, excluding node_modules and venv
    local yaml_files
    yaml_files=$(find "$repo_path" \
      -name "*.yaml" -o -name "*.yml" \
      2>/dev/null | grep -v node_modules | grep -v venv | grep -v ".git" || true)

    if [[ -n "$yaml_files" ]]; then
      if echo "$yaml_files" | xargs yamllint -c "$config_file" -s 2>&1 | head -20; then
        log_pass "yamllint passed"
      else
        log_fail "yamllint failed"
      fi
    else
      log_skip "yamllint (no YAML files)"
    fi
  else
    log_skip "yamllint (not installed)"
  fi
}

# Lint Markdown files
lint_markdown() {
  local repo_path="$1"
  local config_file="$repo_path/.markdownlint.yaml"

  if [[ ! -f "$config_file" ]]; then
    config_file="$REPOS_DIR/chronoboiler/.markdownlint.yaml"
  fi

  if has_cmd markdownlint; then
    local md_files
    md_files=$(find "$repo_path" -name "*.md" 2>/dev/null | \
      grep -v node_modules | grep -v venv | grep -v ".git" | grep -v ".pytest_cache" | grep -v ".mypy_cache" | \
      grep -v "\.template\.md" | grep -v "output/" || true)

    if [[ -n "$md_files" ]]; then
      if echo "$md_files" | xargs markdownlint -c "$config_file" 2>&1 | head -20; then
        log_pass "markdownlint passed"
      else
        log_fail "markdownlint failed"
      fi
    else
      log_skip "markdownlint (no Markdown files)"
    fi
  else
    log_skip "markdownlint (not installed)"
  fi
}

# Lint GitHub Actions workflows
lint_actions() {
  local repo_path="$1"
  local workflows_dir="$repo_path/.github/workflows"

  if [[ -d "$workflows_dir" ]]; then
    if has_cmd actionlint; then
      if actionlint "$workflows_dir"/*.yml 2>&1 | head -20; then
        log_pass "actionlint passed"
      else
        log_fail "actionlint failed"
      fi
    else
      log_skip "actionlint (not installed)"
    fi
  else
    log_skip "actionlint (no workflows directory)"
  fi
}

# Check editorconfig compliance
lint_editorconfig() {
  local repo_path="$1"

  if [[ -f "$repo_path/.editorconfig" ]]; then
    if has_cmd editorconfig-checker; then
      if (cd "$repo_path" && editorconfig-checker -exclude '(node_modules|venv|\.git|build|dist|target|\.d64|\.prg|\.mypy_cache|\.pytest_cache|\.ruff_cache|\.egg-info|xcuserdata|DerivedData|__pycache__|\.plist$|\.gltf$|\.xcworkspacedata$|\.pyc$|\.txt$|\.md$|CHANGELOG|\.template\.|Cargo\.toml$|\.rs$|\.js$|\.ts$|\.swift$|\.mermaid$|\.fs$|\.entitlements$|\.asm$|\.py$|\.toml$|\.css$|\.html$|\.yml$|\.yaml$|\.json$|\.sh$|\.svg$|\.adoc$|\.d64$|\.prg$|package-lock|Makefile)' 2>&1 | head -20); then
        log_pass "editorconfig-checker passed"
      else
        log_fail "editorconfig-checker failed"
      fi
    else
      log_skip "editorconfig-checker (not installed)"
    fi
  else
    log_skip "editorconfig-checker (no .editorconfig)"
  fi
}

# Lint shell scripts
lint_shell() {
  local repo_path="$1"

  local shell_files
  shell_files=$(find "$repo_path" -name "*.sh" 2>/dev/null | \
    grep -v node_modules | grep -v venv | grep -v ".git" || true)

  # Filter out zsh scripts (shellcheck doesn't support zsh)
  local bash_files=""
  for f in ${(f)shell_files}; do
    if [[ -f "$f" ]] && ! head -1 "$f" | grep -q "#!/bin/zsh"; then
      bash_files="$bash_files $f"
    fi
  done

  if [[ -n "$bash_files" ]]; then
    if has_cmd shellcheck; then
      if echo "$bash_files" | xargs shellcheck 2>&1 | head -30; then
        log_pass "shellcheck passed"
      else
        log_fail "shellcheck failed"
      fi
    else
      log_skip "shellcheck (not installed)"
    fi
  else
    log_skip "shellcheck (no bash scripts)"
  fi
}

# Lint Rust code
lint_rust() {
  local repo_path="$1"

  if [[ -f "$repo_path/Cargo.toml" ]]; then
    log_check "Rust linting"
    (
      cd "$repo_path"
      export PATH="/opt/homebrew/opt/rustup/bin:$PATH"

      # Check formatting
      if cargo fmt --all --check 2>&1 | head -10; then
        log_pass "cargo fmt passed"
      else
        log_fail "cargo fmt failed"
      fi

      # Run clippy
      if cargo clippy --workspace --all-targets -- -D warnings 2>&1 | tail -20; then
        log_pass "cargo clippy passed"
      else
        log_fail "cargo clippy failed"
      fi
    )
  fi
}

# Lint TypeScript/JavaScript
lint_typescript() {
  local repo_path="$1"

  if [[ -f "$repo_path/package.json" ]]; then
    log_check "TypeScript/JavaScript linting"
    (
      cd "$repo_path"

      # Check if eslint script exists
      if grep -q '"lint"' package.json; then
        if npm run lint 2>&1 | head -20; then
          log_pass "eslint passed"
        else
          log_fail "eslint failed"
        fi
      fi

      # Check formatting
      if grep -q '"format:check"' package.json; then
        if npm run format:check 2>&1 | head -20; then
          log_pass "prettier passed"
        else
          log_fail "prettier failed"
        fi
      fi

      # Type check
      if grep -q '"typecheck"' package.json; then
        if npm run typecheck 2>&1 | head -20; then
          log_pass "tsc passed"
        else
          log_fail "tsc failed"
        fi
      fi
    )
  fi
}

# Lint Python code
lint_python() {
  local repo_path="$1"

  if [[ -f "$repo_path/pyproject.toml" ]] || [[ -f "$repo_path/requirements.txt" ]]; then
    log_check "Python linting"

    local python_dirs
    python_dirs=$(find "$repo_path" -maxdepth 1 -type d -name "*_*" | \
      grep -v __pycache__ | grep -v ".git" | grep -v venv || true)

    # Also check for standard Python package directories
    for dir in "$repo_path/src" "$repo_path/hocr_clean"; do
      if [[ -d "$dir" ]]; then
        python_dirs="$dir"
        break
      fi
    done

    if [[ -n "$python_dirs" ]]; then
      export PATH="$HOME/.local/bin:$PATH"

      if has_cmd ruff; then
        if ruff check $python_dirs 2>&1 | head -20; then
          log_pass "ruff passed"
        else
          log_fail "ruff failed"
        fi
      else
        log_skip "ruff (not installed)"
      fi

      if has_cmd mypy; then
        local mypy_output
        mypy_output=$(mypy $python_dirs --strict 2>&1)
        local mypy_exit=$?
        echo "$mypy_output" | head -20
        if [[ $mypy_exit -eq 0 ]]; then
          log_pass "mypy passed"
        else
          log_fail "mypy failed"
        fi
      else
        log_skip "mypy (not installed)"
      fi
    fi
  fi
}

# Lint Swift code
lint_swift() {
  local repo_path="$1"

  if [[ -f "$repo_path"/*.xcodeproj/project.pbxproj ]] 2>/dev/null; then
    if has_cmd swiftlint; then
      log_check "Swift linting"
      if (cd "$repo_path" && swiftlint lint --quiet 2>&1 | head -20); then
        log_pass "swiftlint passed"
      else
        log_fail "swiftlint failed"
      fi
    else
      log_skip "swiftlint (not installed)"
    fi
  fi
}

# Main linting function for a repository
lint_repo() {
  local repo_name="$1"
  local repo_path="$REPOS_DIR/$repo_name"

  if [[ ! -d "$repo_path" ]]; then
    echo -e "  ${YELLOW}⚠${NC} Repository not found: $repo_path"
    RESULTS[$repo_name]="missing"
    return
  fi

  log_repo "$repo_name"

  local repo_errors=$TOTAL_ERRORS

  # Universal linters
  lint_yaml "$repo_path"
  lint_markdown "$repo_path"
  lint_actions "$repo_path"
  lint_editorconfig "$repo_path"
  lint_shell "$repo_path"

  # Language-specific linters
  case "$repo_name" in
    chronoengine)
      lint_rust "$repo_path"
      ;;
    chronoboids)
      lint_typescript "$repo_path"
      # Also has wasm-physics Rust crate
      if [[ -d "$repo_path/wasm-physics" ]]; then
        lint_rust "$repo_path/wasm-physics"
      fi
      ;;
    chronoscribe)
      lint_python "$repo_path"
      ;;
    chronoquit)
      lint_swift "$repo_path"
      ;;
  esac

  # Record result
  if [[ $TOTAL_ERRORS -eq $repo_errors ]]; then
    RESULTS[$repo_name]="pass"
  else
    RESULTS[$repo_name]="fail"
  fi
}

# Print summary
print_summary() {
  log_header "SUMMARY"

  local passed=0
  local failed=0
  local missing=0

  for repo in "${REPOS[@]}"; do
    local repo_status="${RESULTS[$repo]:-unknown}"
    case "$repo_status" in
      pass)
        echo -e "  ${GREEN}✓${NC} $repo"
        passed=$((passed + 1))
        ;;
      fail)
        echo -e "  ${RED}✗${NC} $repo"
        failed=$((failed + 1))
        ;;
      missing)
        echo -e "  ${YELLOW}○${NC} $repo (not found)"
        missing=$((missing + 1))
        ;;
      *)
        echo -e "  ${YELLOW}?${NC} $repo (unknown)"
        ;;
    esac
  done

  echo ""
  echo -e "${BOLD}Results:${NC} ${GREEN}$passed passed${NC}, ${RED}$failed failed${NC}, ${YELLOW}$missing missing${NC}"
  echo -e "${BOLD}Total errors:${NC} $TOTAL_ERRORS"

  if [[ $failed -gt 0 ]] || [[ $TOTAL_ERRORS -gt 0 ]]; then
    echo -e "\n${RED}${BOLD}Some linting checks failed!${NC}"
    return 1
  else
    echo -e "\n${GREEN}${BOLD}All linting checks passed!${NC}"
    return 0
  fi
}

# Check for required tools
check_tools() {
  log_header "TOOL CHECK"

  local tools=(
    "shellcheck:Shell script linting"
    "yamllint:YAML validation"
    "actionlint:GitHub Actions linting"
    "markdownlint:Markdown linting"
    "editorconfig-checker:EditorConfig compliance"
  )

  for tool_info in "${tools[@]}"; do
    local tool="${tool_info%%:*}"
    local desc="${tool_info#*:}"

    if has_cmd "$tool"; then
      echo -e "  ${GREEN}✓${NC} $tool - $desc"
    else
      echo -e "  ${RED}✗${NC} $tool - $desc (not installed)"
    fi
  done

  # Language-specific tools
  echo ""
  echo -e "  ${CYAN}Language-specific:${NC}"

  if has_cmd cargo; then
    echo -e "  ${GREEN}✓${NC} cargo (Rust)"
  else
    echo -e "  ${YELLOW}○${NC} cargo (Rust) - optional"
  fi

  if has_cmd npm; then
    echo -e "  ${GREEN}✓${NC} npm (Node.js)"
  else
    echo -e "  ${YELLOW}○${NC} npm (Node.js) - optional"
  fi

  export PATH="$HOME/.local/bin:$PATH"
  if has_cmd ruff; then
    echo -e "  ${GREEN}✓${NC} ruff (Python)"
  else
    echo -e "  ${YELLOW}○${NC} ruff (Python) - optional"
  fi

  if has_cmd swiftlint; then
    echo -e "  ${GREEN}✓${NC} swiftlint (Swift)"
  else
    echo -e "  ${YELLOW}○${NC} swiftlint (Swift) - optional"
  fi
}

# Main
main() {
  log_header "CHRONO* REPOSITORY LINTING"
  echo -e "  ${CYAN}Repositories directory:${NC} $REPOS_DIR"

  check_tools

  for repo in "${REPOS[@]}"; do
    lint_repo "$repo"
  done

  print_summary
}

main "$@"

