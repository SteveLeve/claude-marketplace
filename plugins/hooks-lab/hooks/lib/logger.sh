#!/usr/bin/env bash
#
# Verbose logging utility for hooks-lab
# Provides color-coded, structured logging for learning and transparency
#

# Colors for different log levels (check if already defined)
if [[ -z "${COLOR_RESET:-}" ]]; then
    readonly COLOR_RESET="\033[0m"
    readonly COLOR_BLUE="\033[0;34m"
    readonly COLOR_GREEN="\033[0;32m"
    readonly COLOR_YELLOW="\033[0;33m"
    readonly COLOR_RED="\033[0;31m"
    readonly COLOR_MAGENTA="\033[0;35m"
    readonly COLOR_CYAN="\033[0;36m"
    readonly COLOR_GRAY="\033[0;90m"
fi

# Log file location
LOG_DIR="${HOME}/.claude/hooks-lab/logs"
LOG_FILE="${LOG_DIR}/$(date +%Y-%m-%d).log"

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

#
# Log a message with timestamp and color
# Usage: log_message "LEVEL" "COLOR" "Message"
#
log_message() {
    local level="$1"
    local color="$2"
    local message="$3"
    local timestamp=$(date +"%H:%M:%S.%3N")

    # Console output with color
    echo -e "${color}[${timestamp}] [${level}]${COLOR_RESET} ${message}" >&2

    # File output without color
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"
}

#
# Log hook lifecycle event
# Usage: log_hook_event "HOOK_NAME" "EVENT" "Details"
#
log_hook_event() {
    local hook_name="$1"
    local event="$2"
    local details="$3"

    log_message "HOOK" "${COLOR_MAGENTA}" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_message "HOOK" "${COLOR_MAGENTA}" "Hook: ${hook_name}"
    log_message "HOOK" "${COLOR_CYAN}" "Event: ${event}"
    if [[ -n "${details}" ]]; then
        log_message "HOOK" "${COLOR_GRAY}" "Details: ${details}"
    fi
}

#
# Log context information
# Usage: log_context "Key" "Value"
#
log_context() {
    local key="$1"
    local value="$2"
    log_message "CONTEXT" "${COLOR_BLUE}" "${key}: ${value}"
}

#
# Log decision or action taken by hook
# Usage: log_decision "Decision made" "Reason"
#
log_decision() {
    local decision="$1"
    local reason="$2"
    log_message "DECISION" "${COLOR_YELLOW}" "${decision}"
    if [[ -n "${reason}" ]]; then
        log_message "REASON" "${COLOR_GRAY}" "  → ${reason}"
    fi
}

#
# Log success
#
log_success() {
    local message="$1"
    log_message "SUCCESS" "${COLOR_GREEN}" "✓ ${message}"
}

#
# Log error
#
log_error() {
    local message="$1"
    log_message "ERROR" "${COLOR_RED}" "✗ ${message}"
}

#
# Log separator
#
log_separator() {
    log_message "─────" "${COLOR_GRAY}" "────────────────────────────────────────"
}

#
# Export functions for use in other scripts
#
export -f log_message
export -f log_hook_event
export -f log_context
export -f log_decision
export -f log_success
export -f log_error
export -f log_separator
