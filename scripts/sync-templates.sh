#!/usr/bin/env bash
#
# sync-templates.sh - Copy and customize chronoboiler templates to a target repository
#
# USAGE:
#   ./sync-templates.sh <target-repo-path> [language-config]
#   ./sync-templates.sh ../my-project python
#   ./sync-templates.sh ../my-project typescript
#   ./sync-templates.sh ../my-project
#
# ARGUMENTS:
#   target-repo-path  - Path to the target repository (required)
#   language-config   - Language config name (optional)
#                       Options: rust, typescript, swift, forth, assembly-6502, python, unrealscript
#
# EXIT CODES:
#   0 - Success
#   1 - Error or user aborted
#
# DEPENDENCIES:
#   bash 4.0+, sed, awk, grep
#   yq (optional)

set -euo pipefail

# =============================================================================
# CONSTANTS - ANSI escape sequences
# =============================================================================

readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[1;33m'
readonly BLUE=$'\033[0;34m'
readonly CYAN=$'\033[0;36m'
readonly RESET=$'\033[0m'

# Script and directory paths (declare first, assign second per SC2155)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
CHRONOBOILER_DIR="${SCRIPT_DIR%/*}"  # Parameter expansion for dirname
readonly CHRONOBOILER_DIR
readonly TEMPLATES_DIR="${CHRONOBOILER_DIR}/templates"
readonly CONFIGS_DIR="${CHRONOBOILER_DIR}/configs"

# Version constant (synced with repo-config.yaml)
readonly VERSION="1.0.0"

# Default values as simple variables (avoiding associative array issues with set -u)
readonly DEFAULT_BUILD_CMD="make build"
readonly DEFAULT_TEST_CMD="make test"
readonly DEFAULT_BENCH_CMD="make bench"
readonly DEFAULT_LINT_CMD="make lint"
readonly DEFAULT_CDE_ROLE="simulation"
readonly DEFAULT_COMPLEXITY_PROFILE="hpc"
readonly DEFAULT_COVERAGE_THRESHOLD="80"
readonly DEFAULT_REGRESSION_THRESHOLD="5"
readonly DEFAULT_COMPLEXITY_PROVEN="true"
readonly DEFAULT_BENCHMARKS_ENFORCED="true"

# Template file manifest: source|destination|mode (yes=replace, manual=skip, no=copy)
# Using $'...' for embedded newlines
readonly TEMPLATE_MANIFEST=$'README.template.md|README.md|yes
ARCHITECTURE.template.md|ARCHITECTURE.md|yes
PERFORMANCE.template.md|PERFORMANCE.md|yes
CONTRIBUTING.template.md|CONTRIBUTING.md|yes
repo-config.template.yaml|repo-config.yaml|yes
github/SOLID_CHECKLIST.md|.github/SOLID_CHECKLIST.md|yes
github/pull_request_template.md|.github/pull_request_template.md|yes
github/workflows/ci.template.yml|.github/workflows/ci.yml|manual'

# =============================================================================
# GLOBAL STATE - Configuration variables (set during execution)
# =============================================================================

declare TARGET_DIR="" PROJECT_NAME="" PROJECT_DESCRIPTION=""
declare LANGUAGE="" LANGUAGE_VERSION=""
declare BUILD_CMD="" TEST_CMD="" BENCH_CMD="" LINT_CMD=""
declare CDE_ROLE="" COMPLEXITY_PROFILE=""
declare COMPLEXITY_PROVEN="" BENCHMARKS_ENFORCED=""

# =============================================================================
# UTILITY FUNCTIONS - Output and formatting
# =============================================================================

# Emit styled output with icon
# Usage: emit <level> <message>
emit() {
    local -r level="$1" message="$2"
    case "$level" in
        pass) printf '  %s✓%s %s\n' "${GREEN}" "${RESET}" "$message" ;;
        fail) printf '  %s✗%s %s\n' "${RED}" "${RESET}" "$message" ;;
        warn) printf '  %s⚠%s %s\n' "${YELLOW}" "${RESET}" "$message" ;;
        info) printf '  %sℹ%s %s\n' "${BLUE}" "${RESET}" "$message" ;;
    esac
}

# Draw a styled header box using printf and brace expansion
draw_header() {
    local -r title="$1" subtitle="$2"
    local -r line=$(printf '═%.0s' {1..60})

    printf '%s╔%s╗\n' "${BLUE}" "$line"
    printf '%s║%s  %-56s  %s║\n' "${BLUE}" "${RESET}" "$title" "${BLUE}"
    printf '%s║%s  %-56s  %s║\n' "${BLUE}" "${RESET}" "$subtitle" "${BLUE}"
    printf '%s╚%s╝%s\n' "${BLUE}" "$line" "${RESET}"
}

# Print usage with here-doc (clean multi-line output)
usage() {
    cat << 'USAGE_EOF'
Usage: sync-templates.sh <target-repo-path> [language-config]

Arguments:
  target-repo-path   Path to the target repository (required)
  language-config    Language configuration (optional)
                     Options: python, typescript, rust, assembly-6502, unrealscript, forth

Examples:
  ./sync-templates.sh ../my-project python
  ./sync-templates.sh ../my-project typescript
  ./sync-templates.sh ../my-project

USAGE_EOF

    # List available configs using find + awk pipeline
    if [[ -d "$CONFIGS_DIR" ]]; then
        printf 'Available language configs:\n'
        find "$CONFIGS_DIR" -name "*.yaml" -print0 |
            xargs -0 -I{} basename {} .yaml |
            awk '{ printf "  - %s\n", $0 }'
    fi
    exit 1
}

# =============================================================================
# YAML PARSING - Demonstrating awk mastery for config extraction
# =============================================================================

# Extract value from YAML using awk state machine
# Handles nested keys with proper depth tracking
# Usage: yaml_extract <file> <key_path>
# Example: yaml_extract config.yaml "language.name" -> "Python"
yaml_extract() {
    local -r file="$1" key_path="$2"

    awk -F': ' -v path="$key_path" '
    BEGIN {
        # Split path into components (e.g., "language.name" -> ["language", "name"])
        n = split(path, keys, "\\.")
        depth = 0
        target_key = keys[1]
    }

    # Skip comments and empty lines
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }

    {
        # Calculate indent level (2-space standard)
        match($0, /^[[:space:]]*/)
        indent = int(RLENGTH / 2)

        # Extract key (everything before first colon)
        key = $1
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)

        # Extract value (everything after first colon, rejoin if value had colons)
        value = ""
        for (i = 2; i <= NF; i++) {
            value = value (i > 2 ? ":" : "") $i
        }
        gsub(/^[[:space:]]+|[[:space:]]+$|"/, "", value)

        # State machine: track position in key hierarchy
        if (indent == depth && key == target_key) {
            depth++
            if (depth == n && value != "") {
                print value
                exit
            }
            target_key = (depth < n) ? keys[depth + 1] : ""
        }
        # Reset depth if we backed out of indentation
        else if (indent < depth) {
            depth = indent
            target_key = (depth < n) ? keys[depth + 1] : keys[1]
        }
    }
    ' "$file" 2>/dev/null
}

# Load full config using yq (preferred) or awk fallback
# Usage: load_config <config_file>
load_config() {
    local -r config_file="$1"

    if command -v yq &>/dev/null; then
        # yq available - use direct extraction with null coalescing
        LANGUAGE=$(yq eval '.language.name // ""' "$config_file")
        LANGUAGE_VERSION=$(yq eval '.language.version // ""' "$config_file")
        BUILD_CMD=$(yq eval '.commands.build // ""' "$config_file")
        TEST_CMD=$(yq eval '.commands.test // ""' "$config_file")
        BENCH_CMD=$(yq eval '.commands.bench // ""' "$config_file")
        LINT_CMD=$(yq eval '.commands.lint // ""' "$config_file")
        CDE_ROLE=$(yq eval '.example.cde_role // ""' "$config_file")
        COMPLEXITY_PROFILE=$(yq eval '.example.complexity_profile // ""' "$config_file")
        COMPLEXITY_PROVEN=$(yq eval '.example.complexity_proven // ""' "$config_file")
        BENCHMARKS_ENFORCED=$(yq eval '.example.benchmarks_enforced // ""' "$config_file")
    else
        # Fallback: use our awk parser
        emit warn "yq not found, using awk parser (install: brew install yq)"

        LANGUAGE=$(yaml_extract "$config_file" "language.name")
        LANGUAGE_VERSION=$(yaml_extract "$config_file" "language.version")
        BUILD_CMD=$(yaml_extract "$config_file" "commands.build")
        TEST_CMD=$(yaml_extract "$config_file" "commands.test")
        BENCH_CMD=$(yaml_extract "$config_file" "commands.bench")
        LINT_CMD=$(yaml_extract "$config_file" "commands.lint")
        CDE_ROLE=$(yaml_extract "$config_file" "example.cde_role")
        COMPLEXITY_PROFILE=$(yaml_extract "$config_file" "example.complexity_profile")
        COMPLEXITY_PROVEN=$(yaml_extract "$config_file" "example.complexity_proven")
        BENCHMARKS_ENFORCED=$(yaml_extract "$config_file" "example.benchmarks_enforced")
    fi

    # Apply defaults using parameter expansion (${var:-default} syntax)
    BUILD_CMD="${BUILD_CMD:-$DEFAULT_BUILD_CMD}"
    TEST_CMD="${TEST_CMD:-$DEFAULT_TEST_CMD}"
    BENCH_CMD="${BENCH_CMD:-$DEFAULT_BENCH_CMD}"
    LINT_CMD="${LINT_CMD:-$DEFAULT_LINT_CMD}"
    CDE_ROLE="${CDE_ROLE:-$DEFAULT_CDE_ROLE}"
    COMPLEXITY_PROFILE="${COMPLEXITY_PROFILE:-$DEFAULT_COMPLEXITY_PROFILE}"
    COMPLEXITY_PROVEN="${COMPLEXITY_PROVEN:-$DEFAULT_COMPLEXITY_PROVEN}"
    BENCHMARKS_ENFORCED="${BENCHMARKS_ENFORCED:-$DEFAULT_BENCHMARKS_ENFORCED}"
}

# =============================================================================
# TEMPLATE PROCESSING - Demonstrating sed mastery
# =============================================================================

# Replace all placeholders in file using sed multi-expression
# Usage: replace_placeholders <file>
# Demonstrates: sed -e chaining, | delimiter to avoid path conflicts
replace_placeholders() {
    local -r file="$1"
    local temp_file
    temp_file=$(mktemp)

    # Chain all replacements in single sed invocation for efficiency
    # Use | as delimiter to safely handle paths/URLs in values
    sed \
        -e "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" \
        -e "s|{{PROJECT_DESCRIPTION}}|${PROJECT_DESCRIPTION}|g" \
        -e "s|{{ONE_SENTENCE_DESCRIPTION}}|${PROJECT_DESCRIPTION}|g" \
        -e "s|{{LANGUAGE}}|${LANGUAGE}|g" \
        -e "s|{{LANGUAGE_VERSION}}|${LANGUAGE_VERSION}|g" \
        -e "s|{{CHRONOBOILER_VERSION}}|${VERSION}|g" \
        -e "s|{{CDE_ROLE}}|${CDE_ROLE}|g" \
        -e "s|{{COMPLEXITY_PROFILE}}|${COMPLEXITY_PROFILE}|g" \
        -e "s|{{BUILD_COMMAND}}|${BUILD_CMD}|g" \
        -e "s|{{TEST_COMMAND}}|${TEST_CMD}|g" \
        -e "s|{{BENCH_COMMAND}}|${BENCH_CMD}|g" \
        -e "s|{{LINT_COMMAND}}|${LINT_CMD}|g" \
        -e "s|{{COVERAGE_THRESHOLD}}|${DEFAULT_COVERAGE_THRESHOLD}|g" \
        -e "s|{{REGRESSION_THRESHOLD}}|${DEFAULT_REGRESSION_THRESHOLD}|g" \
        -e "s|{{COMPLEXITY_PROVEN}}|${COMPLEXITY_PROVEN}|g" \
        -e "s|{{BENCHMARKS_ENFORCED}}|${BENCHMARKS_ENFORCED}|g" \
        "$file" > "$temp_file"

    # Atomic move for consistency
    mv "$temp_file" "$file"
}

# Sync a single template file
# Usage: sync_template <src> <dst> <mode>
sync_template() {
    local -r src="$1" dst="$2" mode="$3"
    local -r src_path="${TEMPLATES_DIR}/${src}"
    local -r dst_path="${TARGET_DIR}/${dst}"

    # Ensure destination directory exists (parameter expansion for dirname)
    mkdir -p "${dst_path%/*}"

    if [[ -f "$dst_path" ]]; then
        emit warn "Skipping (exists): ${dst}"
        return 0
    fi

    cp "$src_path" "$dst_path"

    case "$mode" in
        yes)
            replace_placeholders "$dst_path"
            emit pass "Created: ${dst}"
            ;;
        manual)
            emit warn "Created: ${dst} (requires manual placeholder replacement)"
            ;;
        no)
            emit pass "Created: ${dst}"
            ;;
    esac
}

# Sync coherence file (no templating needed)
# Usage: sync_coherence_file <src> <dst> <name>
sync_coherence_file() {
    local -r src="$1" dst="$2" name="$3"

    if [[ -f "$dst" ]]; then
        emit warn "Skipping (exists): ${name}"
    else
        cp "$src" "$dst"
        emit pass "Created: ${name}"
    fi
}

# =============================================================================
# USER INTERACTION - Input prompts with defaults
# =============================================================================

# Prompt for value with optional default
# Usage: prompt <message> [default]
prompt() {
    local -r message="$1" default="${2:-}"
    local value

    if [[ -n "$default" ]]; then
        read -rp "$(printf '%s?%s %s [%s]: ' "${BLUE}" "${RESET}" "$message" "$default")" value
        printf '%s' "${value:-$default}"
    else
        read -rp "$(printf '%s?%s %s: ' "${BLUE}" "${RESET}" "$message")" value
        printf '%s' "$value"
    fi
}

# Print configuration summary using awk for aligned output
print_config_summary() {
    printf '\n%sConfiguration Summary:%s\n' "${BLUE}" "${RESET}"

    # Use awk for consistent column alignment
    awk -v cyan="${CYAN}" -v reset="${RESET}" '
    {
        # Split on first space to get label and value
        label = $1
        $1 = ""
        value = substr($0, 2)
        printf "  %-12s %s%s%s\n", label, cyan, value, reset
    }
    ' << EOF
Project: $PROJECT_NAME
Description: $PROJECT_DESCRIPTION
Language: $LANGUAGE $LANGUAGE_VERSION
Build: $BUILD_CMD
Test: $TEST_CMD
Benchmark: $BENCH_CMD
Lint: $LINT_CMD
EOF
    echo ""
}

# =============================================================================
# MAIN ORCHESTRATION
# =============================================================================

main() {
    # Argument validation
    (( $# < 1 )) && usage

    local -r target_arg="$1"
    local -r lang_config="${2:-}"

    # Validate target exists
    [[ ! -d "$target_arg" ]] && {
        printf '%sError: Target directory does not exist: %s%s\n' \
            "${RED}" "$target_arg" "${RESET}" >&2
        exit 1
    }

    # Set globals (parameter expansion for basename)
    TARGET_DIR="$(cd "$target_arg" && pwd)"
    PROJECT_NAME="${TARGET_DIR##*/}"

    # Draw header
    draw_header "Chronoboiler Template Sync" "Version: ${VERSION}"
    printf '\nTarget: %s%s%s\n\n' "${CYAN}" "$TARGET_DIR" "${RESET}"

    # Load configuration (file-based or interactive)
    if [[ -n "$lang_config" ]]; then
        local -r config_file="${CONFIGS_DIR}/${lang_config}.yaml"

        [[ ! -f "$config_file" ]] && {
            printf '%sError: Config not found: %s%s\n' \
                "${RED}" "$config_file" "${RESET}" >&2
            printf 'Available configs:\n'
            find "$CONFIGS_DIR" -name "*.yaml" -exec basename {} .yaml \; |
                awk '{ printf "  - %s\n", $0 }'
            exit 1
        }

        emit info "Loading configuration from: ${config_file}"
        load_config "$config_file"
        PROJECT_DESCRIPTION=$(prompt "Project description" "A ${LANGUAGE} project")
    else
        printf '%sInteractive mode - please provide values:%s\n\n' \
            "${YELLOW}" "${RESET}"

        PROJECT_DESCRIPTION=$(prompt "Project description")
        LANGUAGE=$(prompt "Primary language")
        LANGUAGE_VERSION=$(prompt "Language version")
        BUILD_CMD=$(prompt "Build command" "$DEFAULT_BUILD_CMD")
        TEST_CMD=$(prompt "Test command" "$DEFAULT_TEST_CMD")
        BENCH_CMD=$(prompt "Benchmark command" "$DEFAULT_BENCH_CMD")
        LINT_CMD=$(prompt "Lint command" "$DEFAULT_LINT_CMD")
        CDE_ROLE=$(prompt "CDE role" "$DEFAULT_CDE_ROLE")
        COMPLEXITY_PROFILE=$(prompt "Complexity profile" "$DEFAULT_COMPLEXITY_PROFILE")
        COMPLEXITY_PROVEN=$(prompt "Complexity proven (true/false)" "$DEFAULT_COMPLEXITY_PROVEN")
        BENCHMARKS_ENFORCED=$(prompt "Benchmarks enforced (true/false)" "$DEFAULT_BENCHMARKS_ENFORCED")
    fi

    print_config_summary

    # Confirmation prompt
    local confirm
    read -rp "$(printf '%sProceed with template sync? [y/N]: %s' "${YELLOW}" "${RESET}")" confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && { echo "Aborted."; exit 0; }

    # Sync templates using manifest (pipe-delimited spec, here-string iteration)
    printf '\n%sSyncing templates...%s\n' "${BLUE}" "${RESET}"

    while IFS='|' read -r src dst mode; do
        [[ -z "$src" ]] && continue
        sync_template "$src" "$dst" "$mode"
    done <<< "$TEMPLATE_MANIFEST"

    # Sync coherence files
    sync_coherence_file "${CHRONOBOILER_DIR}/.editorconfig" "${TARGET_DIR}/.editorconfig" ".editorconfig"
    sync_coherence_file "${CHRONOBOILER_DIR}/.gitattributes" "${TARGET_DIR}/.gitattributes" ".gitattributes"

    # Special handling for .gitignore (may need merging)
    if [[ ! -f "${TARGET_DIR}/.gitignore" ]]; then
        cp "${CHRONOBOILER_DIR}/.gitignore" "${TARGET_DIR}/.gitignore"
        emit pass "Created: .gitignore"
    else
        emit warn "Skipping (exists): .gitignore (consider merging manually)"
    fi

    # Print next steps using here-doc
    cat << NEXT_EOF

${GREEN}Template sync complete!${RESET}

${BLUE}Next steps:${RESET}
  1. Review and customize the generated files
  2. Replace remaining {{PLACEHOLDER}} values in templates
  3. Update .github/workflows/ci.yml with language-specific settings
  4. Run: ./scripts/validate-repo.sh ${TARGET_DIR}

NEXT_EOF
}

main "$@"
