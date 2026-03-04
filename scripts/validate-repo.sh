#!/usr/bin/env bash
# shellcheck disable=SC2034  # Variables used for color output
#
# validate-repo.sh - Validate repository compliance with chronoboiler standards
#
# USAGE:
#   ./validate-repo.sh [path-to-repo]
#   ./validate-repo.sh .
#   ./validate-repo.sh ../myrepo
#
# EXIT CODES:
#   0 - All checks passed
#   1 - One or more checks failed
#
# DEPENDENCIES:
#   bash 4.0+, awk, sed, grep
#   yq (optional, for YAML validation)

set -euo pipefail

# =============================================================================
# CONSTANTS - ANSI escape sequences
# =============================================================================

readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[1;33m'
readonly BLUE=$'\033[0;34m'
readonly CYAN=$'\033[0;36m'
readonly BOLD=$'\033[1m'
readonly RESET=$'\033[0m'

# Thresholds - using arithmetic context for type safety
declare -ri MIN_DOC_LINES=20
declare -ri MIN_WORKFLOW_COUNT=1

# File specifications as newline-delimited strings (enables elegant iteration via <<<)
# Using $'...' ANSI-C quoting for embedded newlines
readonly STRUCTURE_FILES=$'README.md\nARCHITECTURE.md\nPERFORMANCE.md\nCONTRIBUTING.md\nrepo-config.yaml'
readonly COHERENCE_FILES=$'.editorconfig\n.gitignore\n.gitattributes'
readonly VALIDATION_FILES=$'.github/SOLID_CHECKLIST.md\n.github/pull_request_template.md'

# YAML field specifications: path|description|required/optional
# Pipe-delimited format enables clean awk/IFS parsing
readonly YAML_FIELDS=$'.repository.name|repository.name defined|required
.repository.language|repository.language defined|required
.semantics.build_cmd|semantics.build_cmd defined|optional
.semantics.test_cmd|semantics.test_cmd defined|optional'

# =============================================================================
# GLOBAL STATE - Explicitly typed mutable counters
# =============================================================================

declare -i PASSED=0 FAILED=0 WARNINGS=0

# =============================================================================
# CORE OUTPUT FUNCTIONS - Using printf for precise formatting
# =============================================================================

# Emit styled output with automatic counter management
# Usage: emit <level> <message> [extra_info]
# Demonstrates: case pattern matching, printf formatting, arithmetic expansion
emit() {
    local -r level="${1}" message="${2}" extra="${3:-}"
    local color icon

    # Pattern matching for level -> (color, icon, counter) mapping
    case "${level}" in
        pass)    color="${GREEN}"  icon="✓" ; PASSED=$((PASSED + 1))     ;;
        fail)    color="${RED}"    icon="✗" ; FAILED=$((FAILED + 1))     ;;
        warn)    color="${YELLOW}" icon="⚠" ; WARNINGS=$((WARNINGS + 1)) ;;
        info)    color="${BLUE}"   icon="ℹ" ;;
        section) color="${BLUE}"   icon="─" ;;
        *)       color="${RESET}"  icon=" " ;;
    esac

    if [[ "${level}" == "section" ]]; then
        printf '\n%s── %s ──%s\n' "${color}" "${message}" "${RESET}"
    else
        # Use printf %s for safe string interpolation (no format injection)
        printf '  %s%s%s %s%s\n' "${color}" "${icon}" "${RESET}" \
            "${message}" "${extra:+ (${extra})}"
    fi
}

# Draw header box using here-doc and printf
# Demonstrates: printf width specifiers, seq for repetition
draw_box() {
    local -r title="${1}" width="${2:-60}"

    # Generate horizontal line using printf and brace expansion
    local -r line=$(printf '═%.0s' $(seq 1 "$width"))

    printf '%s╔%s╗\n' "${BLUE}" "$line"
    printf '%s║%s  %-*s  %s║%s\n' "${BLUE}" "${RESET}" $((width - 4)) "$title" "${BLUE}" "${RESET}"
    printf '%s╚%s╝%s\n' "${BLUE}" "$line" "${RESET}"
}

# =============================================================================
# FILE ANALYSIS FUNCTIONS - Demonstrating grep/awk/sed mastery
# =============================================================================

# Check files from newline-delimited list using here-string (<<<)
# Usage: check_files <file_list> <target_dir> <on_missing:fail|warn>
# Demonstrates: here-string iteration, parameter expansion
check_files() {
    local -r file_list="${1}" target_dir="${2}" on_missing="${3:-fail}"

    # Iterate using here-string - no subshell, preserves variable modifications
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        if [[ -f "${target_dir}/${file}" ]]; then
            emit pass "Found: ${file}"
        else
            emit "${on_missing}" "Missing: ${file}"
        fi
    done <<< "$file_list"
}

# Extract YAML value using pure awk state machine
# Handles nested keys via depth tracking
# Usage: yaml_get <file> <key_path>
# Example: yaml_get config.yaml "repository.name"
# Demonstrates: awk BEGIN/pattern/END, associative arrays, regex matching
yaml_get() {
    local -r file="$1" key_path="$2"

    awk -F': ' -v path="$key_path" '
    BEGIN {
        # Split dotted path into array of keys
        n = split(path, keys, "\\.")
        depth = 0
        target = keys[1]
    }

    # Skip YAML comments and empty lines
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }

    {
        # Calculate indent depth (assumes 2-space indentation)
        match($0, /^[[:space:]]*/)
        indent = int(RLENGTH / 2)

        # Extract key (before colon)
        key = $1
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)

        # Extract value (after colon, strip quotes)
        value = ""
        for (i = 2; i <= NF; i++) {
            value = value (i > 2 ? ":" : "") $i
        }
        gsub(/^[[:space:]]+|[[:space:]]+$|"/, "", value)

        # State machine: track position in key hierarchy
        if (indent == depth && key == target) {
            depth++
            if (depth == n && value != "") {
                print value
                exit
            }
            target = (depth < n) ? keys[depth + 1] : ""
        }
        # Reset if we have backed out of current nesting
        else if (indent < depth) {
            depth = indent
            target = (depth < n) ? keys[depth + 1] : keys[1]
        }
    }
    ' "$file" 2>/dev/null
}

# Validate YAML structure using grep pipeline with extended regex
# Usage: validate_yaml_structure <file>
# Demonstrates: grep -E, sed transformation, pipeline composition
validate_yaml_structure() {
    local -r file="$1"

    # Extract top-level keys using grep + sed pipeline:
    # 1. grep: match lines starting with letter/underscore followed by colon
    # 2. sed: remove everything after colon
    # 3. tr: convert newlines to | for pattern
    local -r found_keys=$(grep -E '^[a-z_]+:' "$file" 2>/dev/null |
        sed 's/:.*$//' |
        tr '\n' '|' |
        sed 's/|$//')

    # Check for required sections using extended regex alternation
    echo "$found_keys" | grep -qE 'repository.*semantics|semantics.*repository'
}

# Analyze YAML fields with spec-driven validation
# Usage: analyze_yaml_fields <file> <field_specs>
# Demonstrates: IFS-based field parsing, here-string iteration
analyze_yaml_fields() {
    local -r file="$1" field_specs="$2"

    while IFS='|' read -r path desc requirement; do
        [[ -z "$path" ]] && continue

        local value

        # Prefer yq for accuracy, fallback to awk parser
        if command -v yq &>/dev/null; then
            value=$(yq eval "$path" "$file" 2>/dev/null)
        else
            # Strip leading dot and use pure awk parser
            value=$(yaml_get "$file" "${path#.}")
        fi

        # Emit result based on value presence and requirement level
        if [[ -n "$value" && "$value" != "null" ]]; then
            # Show language value inline for context
            if [[ "$path" == *".language" ]]; then
                emit pass "repo-config.yaml: ${desc}" "$value"
            else
                emit pass "repo-config.yaml: ${desc}"
            fi
        else
            emit "${requirement/optional/warn}" "repo-config.yaml: ${desc} missing"
        fi
    done <<< "$field_specs"
}

# Count workflow files using find with awk post-processing
# Usage: count_workflows <dir>
# Demonstrates: find -print0 for safety, awk RS for null-delimited input
count_workflows() {
    local -r dir="$1"

    find "$dir" \( -name "*.yml" -o -name "*.yaml" \) -print0 2>/dev/null |
        awk -v RS='\0' 'END { print NR }'
}

# Analyze documentation quality using awk for multi-file statistics
# Usage: analyze_docs <target_dir> <min_lines>
# Demonstrates: awk END block, conditional formatting
analyze_docs() {
    local -r target_dir="$1"
    local -ri min_lines="$2"

    local doc filepath lines
    for doc in README.md ARCHITECTURE.md PERFORMANCE.md CONTRIBUTING.md; do
        filepath="${target_dir}/${doc}"
        [[ ! -f "$filepath" ]] && continue

        # Use awk for efficient line counting (faster than wc for small files)
        lines=$(awk 'END { print NR }' "$filepath")

        if (( lines >= min_lines )); then
            emit pass "${doc}: ${lines} lines" "meets minimum"
        else
            emit warn "${doc}: Only ${lines} lines" "minimum: ${min_lines}"
        fi
    done
}

# =============================================================================
# SUMMARY GENERATION - Demonstrating awk for report formatting
# =============================================================================

# Generate final summary using awk for aligned output
# Demonstrates: awk -v variable passing, printf formatting, floating-point math
print_summary() {
    local -ri p="$PASSED" f="$FAILED" w="$WARNINGS"
    local -ri total=$((p + f + w))

    # Calculate pass rate using awk (bash lacks floating-point)
    local pass_rate
    pass_rate=$(awk -v p="$p" -v t="$total" \
        'BEGIN { printf "%.1f", (t > 0) ? (p/t)*100 : 0 }')

    echo ""
    printf '%s╔════════════════════════════════════════════════════════════╗%s\n' "${BLUE}" "${RESET}"
    printf '%s║%s  VALIDATION SUMMARY                                         %s║%s\n' "${BLUE}" "${RESET}" "${BLUE}" "${RESET}"
    printf '%s╠════════════════════════════════════════════════════════════╣%s\n' "${BLUE}" "${RESET}"

    # Use awk for aligned numeric formatting with ANSI colors
    awk -v green="${GREEN}" -v red="${RED}" -v yellow="${YELLOW}" \
        -v blue="${BLUE}" -v reset="${RESET}" \
        -v p="$p" -v f="$f" -v w="$w" -v rate="$pass_rate" '
    BEGIN {
        fmt = blue "║" reset "  %s%-9s" reset " %-44s " blue "║" reset "\n"
        printf fmt, green, "Passed:", p " (" rate "%)"
        printf fmt, red, "Failed:", f
        printf fmt, yellow, "Warnings:", w
    }'

    printf '%s╚════════════════════════════════════════════════════════════╝%s\n' "${BLUE}" "${RESET}"
}

# =============================================================================
# MAIN EXECUTION - Orchestrating all validation dimensions
# =============================================================================

main() {
    # Argument handling with parameter expansion for default value
    local target_dir="${1:-.}"

    # Validate target directory exists
    [[ ! -d "$target_dir" ]] && {
        printf '%sError: Directory does not exist: %s%s\n' \
            "${RED}" "$target_dir" "${RESET}" >&2
        exit 1
    }

    # Resolve to absolute path using subshell cd
    target_dir="$(cd "$target_dir" && pwd)"

    # Extract repo name using parameter expansion (avoids spawning basename)
    local -r repo_name="${target_dir##*/}"

    # Header
    draw_box "Chronoboiler Standardization Validator"
    printf '  Repository: %s%s%s\n' "${CYAN}" "$repo_name" "${RESET}"

    # =========================================================================
    # DIMENSION 1: STRUCTURE - Required documentation files
    # =========================================================================
    emit section "STRUCTURE: Required Files"
    check_files "$STRUCTURE_FILES" "$target_dir" "fail"

    # =========================================================================
    # DIMENSION 2: COHERENCE - Configuration consistency files
    # =========================================================================
    emit section "COHERENCE: Configuration Files"
    check_files "$COHERENCE_FILES" "$target_dir" "fail"

    # =========================================================================
    # DIMENSION 3: AUTOMATION - CI/CD pipeline presence
    # =========================================================================
    emit section "AUTOMATION: CI/CD"

    local -r workflows_dir="${target_dir}/.github/workflows"

    if [[ -d "$workflows_dir" ]]; then
        emit pass "Found: .github/workflows/"

        local -ri wf_count=$(count_workflows "$workflows_dir")

        if (( wf_count >= MIN_WORKFLOW_COUNT )); then
            emit pass "Found ${wf_count} workflow file(s)"
        else
            emit fail "No workflow files found in .github/workflows/"
        fi
    else
        emit fail "Missing: .github/workflows/"
    fi

    # =========================================================================
    # DIMENSION 4: VALIDATION - SOLID principles and review infrastructure
    # =========================================================================
    emit section "VALIDATION: SOLID & Complexity"
    check_files "$VALIDATION_FILES" "$target_dir" "warn"

    # =========================================================================
    # DIMENSION 5: SEMANTICS - Configuration schema validation
    # =========================================================================
    emit section "SEMANTICS: Configuration Validation"

    local -r config_file="${target_dir}/repo-config.yaml"

    if [[ -f "$config_file" ]]; then
        # Validate YAML syntax using yq or grep-based structure check
        if command -v yq &>/dev/null; then
            if yq eval '.' "$config_file" &>/dev/null; then
                emit pass "repo-config.yaml: Valid YAML syntax"
                analyze_yaml_fields "$config_file" "$YAML_FIELDS"
            else
                emit fail "repo-config.yaml: Invalid YAML syntax"
            fi
        elif validate_yaml_structure "$config_file"; then
            emit pass "repo-config.yaml: Basic structure valid"
            analyze_yaml_fields "$config_file" "$YAML_FIELDS"
            emit info "Install yq for full YAML validation: brew install yq"
        else
            emit fail "repo-config.yaml: Missing required sections"
        fi
    else
        emit fail "Cannot validate semantics: repo-config.yaml missing"
    fi

    # =========================================================================
    # DOCUMENTATION QUALITY ANALYSIS
    # =========================================================================
    emit section "DOCUMENTATION: Quality Checks"
    analyze_docs "$target_dir" "$MIN_DOC_LINES"

    # =========================================================================
    # SUMMARY AND EXIT
    # =========================================================================
    print_summary

    if (( FAILED == 0 )); then
        printf '\n%s✓ All required checks passed!%s\n' "${GREEN}" "${RESET}"
        exit 0
    else
        printf '\n%s✗ %d check(s) failed. Please address the issues above.%s\n' \
            "${RED}" "$FAILED" "${RESET}"
        exit 1
    fi
}

# Execute with all arguments
main "$@"
