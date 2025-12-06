#!/usr/bin/env bash
#
# Context bundling utility for hooks-lab
# Analyzes and builds context information from hook payloads
#

# Source logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/logger.sh"

#
# Extract and log environment context
# Usage: log_environment_context
#
log_environment_context() {
    log_context "Working Directory" "${PWD}"
    log_context "User" "${USER}"
    log_context "Shell" "${SHELL}"

    # Check if in git repo
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        local status=$(git status --porcelain 2>/dev/null | wc -l)
        log_context "Git Branch" "${branch}"
        log_context "Modified Files" "${status}"
    else
        log_context "Git" "Not in a git repository"
    fi
}

#
# Parse and log JSON context from stdin
# Usage: echo "$JSON" | parse_json_context "ContextType"
#
parse_json_context() {
    local context_type="$1"
    local json_input=$(cat)

    log_hook_event "Context Parser" "Parsing ${context_type}" ""

    # Use jq if available, otherwise basic parsing
    if command -v jq &> /dev/null; then
        # Pretty print the JSON
        echo "${json_input}" | jq -C '.' >&2

        # Extract common fields
        local tool_name=$(echo "${json_input}" | jq -r '.tool // .name // "N/A"' 2>/dev/null)
        local event_type=$(echo "${json_input}" | jq -r '.event // .type // "N/A"' 2>/dev/null)

        if [[ "${tool_name}" != "N/A" ]]; then
            log_context "Tool" "${tool_name}"
        fi
        if [[ "${event_type}" != "N/A" ]]; then
            log_context "Event Type" "${event_type}"
        fi
    else
        # Basic logging without jq
        log_context "Raw Context" "${json_input:0:200}..."
        log_message "INFO" "${COLOR_YELLOW}" "Install 'jq' for better JSON parsing"
    fi

    # Return the JSON for further processing
    echo "${json_input}"
}

#
# Build session context bundle
# Usage: build_session_context
#
build_session_context() {
    local context_file="${HOME}/.claude/hooks-lab/session-context.json"
    mkdir -p "$(dirname "${context_file}")"

    cat > "${context_file}" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "working_directory": "${PWD}",
  "user": "${USER}",
  "git_branch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'N/A')",
  "git_status": "$(git status --porcelain 2>/dev/null | wc -l || echo '0')",
  "environment": {
    "shell": "${SHELL}",
    "term": "${TERM:-unknown}",
    "lang": "${LANG:-unknown}"
  }
}
EOF

    log_success "Session context bundle created at ${context_file}"

    # Return path for other hooks to use
    echo "${context_file}"
}

#
# Analyze tool usage patterns
# Usage: analyze_tool_usage "tool_name"
#
analyze_tool_usage() {
    local tool_name="$1"
    local usage_log="${HOME}/.claude/hooks-lab/tool-usage.log"

    # Append to usage log
    echo "$(date -Iseconds),${tool_name},${PWD}" >> "${usage_log}"

    # Count recent usage
    local count=$(grep -c "${tool_name}" "${usage_log}" 2>/dev/null || echo 0)
    log_context "Tool Usage Count" "${tool_name} has been used ${count} times total"
}

#
# Export functions
#
export -f log_environment_context
export -f parse_json_context
export -f build_session_context
export -f analyze_tool_usage
