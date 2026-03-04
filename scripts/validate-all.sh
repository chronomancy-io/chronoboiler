#!/usr/bin/env bash
#
# validate-all.sh - Validate multiple repositories
#
# USAGE:
#   ./validate-all.sh [repos-parent-directory]
#   ./validate-all.sh ~/Repositories
#   ./validate-all.sh
#
# EXIT CODES:
#   0 - All repositories passed
#   1 - One or more failed
#
# DEPENDENCIES:
#   bash 4.0+, validate-repo.sh

set -euo pipefail

# =============================================================================
# CONSTANTS - ANSI escape sequences
# =============================================================================

readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[1;33m'
readonly BLUE=$'\033[0;34m'
readonly CYAN=$'\033[0;36m'
readonly DIM=$'\033[2m'
readonly RESET=$'\033[0m'

# Script location (declare then assign per SC2155)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly VALIDATE_SCRIPT="${SCRIPT_DIR}/validate-repo.sh"

# Result status constants
readonly STATUS_PASS="PASS"
readonly STATUS_FAIL="FAIL"
readonly STATUS_MISSING="NOT_FOUND"

# =============================================================================
# GLOBAL STATE - Typed counters and result storage
# =============================================================================

# Associative array for per-repo results
declare -A RESULTS=()

# Integer counters with explicit typing
declare -i PASS_COUNT=0 FAIL_COUNT=0 MISSING_COUNT=0

# Timing
declare -i START_TIME=0 END_TIME=0

# =============================================================================
# OUTPUT FUNCTIONS - Box drawing and formatting
# =============================================================================

# Draw box with title using printf
draw_box() {
    local -r title="$1"
    local -ri width="${2:-68}"
    local line=""
    line=$(head -c "$width" < /dev/zero | tr '\0' '=')

    printf '%s+%s+\n' "${BLUE}" "$line"
    printf '%s|%s  %-*s  %s|%s\n' "${BLUE}" "${RESET}" $((width - 4)) "$title" "${BLUE}" "${RESET}"
    printf '%s+%s+%s\n' "${BLUE}" "$line" "${RESET}"
}

# Draw section separator for each repository
draw_separator() {
    local -r repo="$1"
    local line=""
    line=$(head -c 68 < /dev/zero | tr '\0' '-')

    printf '\n%s%s%s\n' "${BLUE}" "$line" "${RESET}"
    printf '%sRepository: %s%s\n' "${CYAN}" "$repo" "${RESET}"
    printf '%s%s%s\n' "${BLUE}" "$line" "${RESET}"
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Validate a single repository and store result
# Usage: validate_one <repo_name> <repo_path>
# Effects: Sets RESULTS[$repo_name] to status constant
validate_one() {
    local -r repo="$1" repo_path="$2"

    draw_separator "$repo"

    if [[ ! -d "$repo_path" ]]; then
        printf '  %s!%s Repository not found at: %s\n' \
            "${YELLOW}" "${RESET}" "$repo_path"
        RESULTS[$repo]="$STATUS_MISSING"
        return 0
    fi

    # Run validation, capture exit code (|| true prevents set -e trigger)
    if "$VALIDATE_SCRIPT" "$repo_path"; then
        RESULTS[$repo]="$STATUS_PASS"
    else
        RESULTS[$repo]="$STATUS_FAIL"
    fi
}

# Count results by status
# Effects: Updates PASS_COUNT, FAIL_COUNT, MISSING_COUNT globals
count_results() {
    # Reset counters
    PASS_COUNT=0 FAIL_COUNT=0 MISSING_COUNT=0

    local repo result
    for repo in "${!RESULTS[@]}"; do
        result="${RESULTS[$repo]}"
        case "$result" in
            "$STATUS_PASS")    PASS_COUNT=$((PASS_COUNT + 1)) ;;
            "$STATUS_FAIL")    FAIL_COUNT=$((FAIL_COUNT + 1)) ;;
            "$STATUS_MISSING") MISSING_COUNT=$((MISSING_COUNT + 1)) ;;
        esac
    done
}

# =============================================================================
# SUMMARY GENERATION
# =============================================================================

# Generate summary matrix with statistics
print_summary() {
    # Calculate statistics
    count_results
    local -ri total=$((PASS_COUNT + FAIL_COUNT + MISSING_COUNT))
    local -ri validated=$((total - MISSING_COUNT))

    # Calculate pass rate using awk for floating-point math
    local pass_rate
    pass_rate=$(awk -v p="$PASS_COUNT" -v v="$validated" \
        'BEGIN { printf "%.1f", (v > 0) ? (p/v)*100 : 0 }')

    # Calculate duration
    END_TIME=$(date +%s)
    local -ri duration=$((END_TIME - START_TIME))

    # Print summary header
    printf '\n'
    printf '%s+====================================================================+%s\n' "${BLUE}" "${RESET}"
    printf '%s|%s  VALIDATION SUMMARY                                               %s|%s\n' "${BLUE}" "${RESET}" "${BLUE}" "${RESET}"
    printf '%s+====================================================================+%s\n' "${BLUE}" "${RESET}"

    # Print each repository result
    local repo
    for repo in "${!RESULTS[@]}"; do
        local result="${RESULTS[$repo]:-UNKNOWN}"
        local icon color display_name

        case "$result" in
            "$STATUS_PASS")
                icon="+" color="${GREEN}" display_name="$repo"
                ;;
            "$STATUS_FAIL")
                icon="x" color="${RED}" display_name="$repo"
                ;;
            "$STATUS_MISSING")
                icon="?" color="${YELLOW}" display_name="${repo} (not found)"
                ;;
            *)
                icon="?" color="${DIM}" display_name="${repo} (unknown)"
                ;;
        esac

        printf '%s|%s  %s%s%s %-60s %s|%s\n' \
            "${BLUE}" "${RESET}" "$color" "$icon" "${RESET}" "$display_name" \
            "${BLUE}" "${RESET}"
    done

    # Statistics section
    printf '%s+--------------------------------------------------------------------+%s\n' "${BLUE}" "${RESET}"

    # Print totals line
    printf '%s|%s  Totals: %s%d passed%s | %s%d failed%s | %s%d missing%s               %s|%s\n' \
        "${BLUE}" "${RESET}" \
        "${GREEN}" "$PASS_COUNT" "${RESET}" \
        "${RED}" "$FAIL_COUNT" "${RESET}" \
        "${YELLOW}" "$MISSING_COUNT" "${RESET}" \
        "${BLUE}" "${RESET}"

    # Print pass rate and duration
    printf '%s|%s  Pass Rate: %s%.1f%%%s  |  Duration: %ds                           %s|%s\n' \
        "${BLUE}" "${RESET}" \
        "${GREEN}" "$pass_rate" "${RESET}" \
        "$duration" \
        "${BLUE}" "${RESET}"

    printf '%s+====================================================================+%s\n' "${BLUE}" "${RESET}"

    # Overall status message
    echo ""
    if (( FAIL_COUNT == 0 && MISSING_COUNT == 0 )); then
        printf '%s+ All repositories passed validation%s\n' "${GREEN}" "${RESET}"
    elif (( FAIL_COUNT == 0 )); then
        printf '%s! All found repositories passed. %d not found.%s\n' \
            "${YELLOW}" "$MISSING_COUNT" "${RESET}"
    else
        printf '%sx %d repository/repositories failed validation.%s\n' \
            "${RED}" "$FAIL_COUNT" "${RESET}"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    # Record start time for duration calculation
    START_TIME=$(date +%s)

    # Validate sibling script exists and is executable
    [[ ! -x "$VALIDATE_SCRIPT" ]] && {
        printf '%sError: validate-repo.sh not found or not executable at: %s%s\n' \
            "${RED}" "$VALIDATE_SCRIPT" "${RESET}" >&2
        exit 1
    }

    # Determine repos parent directory using parameter expansion
    local repos_dir="${1:-}"
    if [[ -z "$repos_dir" ]]; then
        repos_dir="${SCRIPT_DIR%/*}"  # Remove /scripts
        repos_dir="${repos_dir%/*}"    # Go up to parent
    fi

    # Validate repos directory
    [[ ! -d "$repos_dir" ]] && {
        printf '%sError: Repositories directory does not exist: %s%s\n' \
            "${RED}" "$repos_dir" "${RESET}" >&2
        exit 1
    }

    # Resolve to absolute path
    repos_dir="$(cd "$repos_dir" && pwd)"

    # Print header
    draw_box "Chronoboiler Multi-Repository Validator"
    printf '  Scanning: %s%s%s\n' "${CYAN}" "$repos_dir" "${RESET}"

    # Find and validate all directories that have a repo-config.yaml
    local repo_name repo_path
    for repo_path in "$repos_dir"/*/; do
        [[ ! -d "$repo_path" ]] && continue
        [[ ! -f "${repo_path}repo-config.yaml" ]] && continue

        repo_name="$(basename "$repo_path")"
        validate_one "$repo_name" "$repo_path"
    done

    # Print summary matrix
    print_summary

    # Exit with appropriate code
    (( FAIL_COUNT > 0 )) && exit 1
    exit 0
}

main "$@"
