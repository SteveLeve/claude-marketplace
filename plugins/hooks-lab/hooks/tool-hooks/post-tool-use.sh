#!/usr/bin/env bash
#
# PostToolUse Hook - Demonstrates post-execution analysis and logging
#
# Learning Objectives:
# 1. Understand when tools have finished executing
# 2. Analyze tool outputs and results
# 3. Detect patterns and issues
# 4. Trigger follow-up actions
#

set -euo pipefail

# Get script directory and source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/logger.sh"
source "${SCRIPT_DIR}/../lib/context-builder.sh"

# Read the hook context from stdin
hook_context=$(cat)

# Start logging
log_hook_event "PostToolUse" "Tool Completion" "A tool has finished executing"

# Log what we're learning
log_message "LEARNING" "${COLOR_CYAN}" "━━━ LEARNING: PostToolUse Hook ━━━"
log_message "LEARNING" "${COLOR_CYAN}" "This hook runs AFTER a tool completes"
log_message "LEARNING" "${COLOR_CYAN}" "Use it to: analyze results, log outputs, trigger follow-ups"
log_separator

# Parse the tool information
log_message "STEP" "${COLOR_BLUE}" "Step 1: Parsing tool execution result"
if command -v jq &> /dev/null; then
    tool_name=$(echo "${hook_context}" | jq -r '.tool // "unknown"')
    success=$(echo "${hook_context}" | jq -r '.success // false')
    output=$(echo "${hook_context}" | jq -r '.output // ""')
    error=$(echo "${hook_context}" | jq -r '.error // ""')

    log_context "Tool Name" "${tool_name}"
    log_context "Success" "${success}"

    if [[ "${success}" == "true" ]]; then
        log_success "Tool executed successfully"
    else
        log_error "Tool execution failed"
        if [[ -n "${error}" ]]; then
            log_context "Error" "${error:0:200}..."
        fi
    fi
else
    log_message "WARNING" "${COLOR_YELLOW}" "jq not available - limited parsing"
    tool_name="unknown"
    success="unknown"
fi
log_separator

# Analyze output patterns
log_message "STEP" "${COLOR_BLUE}" "Step 2: Analyzing output patterns"

case "${tool_name}" in
    "Bash")
        log_message "ANALYSIS" "${COLOR_BLUE}" "Analyzing Bash command output"

        if command -v jq &> /dev/null && [[ -n "${output}" ]]; then
            output_length=${#output}
            output_lines=$(echo "${output}" | wc -l)

            log_context "Output Length" "${output_length} characters"
            log_context "Output Lines" "${output_lines} lines"

            # Check for common patterns
            if echo "${output}" | grep -qi "error"; then
                log_message "PATTERN" "${COLOR_YELLOW}" "⚠ Output contains 'error' keyword"
            fi

            if echo "${output}" | grep -qi "warning"; then
                log_message "PATTERN" "${COLOR_YELLOW}" "⚠ Output contains 'warning' keyword"
            fi

            if echo "${output}" | grep -qi "success\|complete\|done"; then
                log_message "PATTERN" "${COLOR_GREEN}" "✓ Output indicates success"
            fi

            # Preview output
            log_message "INFO" "${COLOR_GRAY}" "Output preview (first 200 chars):"
            log_message "INFO" "${COLOR_GRAY}" "${output:0:200}..."
        fi
        ;;

    "Read")
        log_message "ANALYSIS" "${COLOR_BLUE}" "Analyzing file read operation"

        if command -v jq &> /dev/null; then
            file_path=$(echo "${hook_context}" | jq -r '.parameters.file_path // ""')
            log_context "File Read" "${file_path}"

            # Check output size
            if [[ -n "${output}" ]]; then
                output_length=${#output}
                log_context "File Size (approx)" "${output_length} characters"

                # Detect file type from extension
                extension="${file_path##*.}"
                case "${extension}" in
                    "json")
                        log_message "PATTERN" "${COLOR_CYAN}" "JSON file detected"
                        ;;
                    "md")
                        log_message "PATTERN" "${COLOR_CYAN}" "Markdown file detected"
                        ;;
                    "sh")
                        log_message "PATTERN" "${COLOR_CYAN}" "Shell script detected"
                        ;;
                    *)
                        log_message "PATTERN" "${COLOR_GRAY}" "File type: ${extension}"
                        ;;
                esac
            fi
        fi
        ;;

    "Write"|"Edit")
        log_message "ANALYSIS" "${COLOR_BLUE}" "Analyzing file modification operation"

        if command -v jq &> /dev/null; then
            file_path=$(echo "${hook_context}" | jq -r '.parameters.file_path // ""')
            log_context "File Modified" "${file_path}"

            if [[ "${success}" == "true" ]]; then
                log_success "File successfully modified"

                # Check if file exists and get size
                if [[ -f "${file_path}" ]]; then
                    file_size=$(wc -c < "${file_path}" 2>/dev/null || echo "unknown")
                    log_context "New File Size" "${file_size} bytes"
                fi
            fi
        fi
        ;;

    "Grep")
        log_message "ANALYSIS" "${COLOR_BLUE}" "Analyzing search operation"

        if command -v jq &> /dev/null && [[ -n "${output}" ]]; then
            # Count matches
            match_count=$(echo "${output}" | grep -c "^" || echo 0)
            log_context "Matches Found" "${match_count}"

            if [[ ${match_count} -gt 10 ]]; then
                log_message "PATTERN" "${COLOR_YELLOW}" "⚠ Large number of matches - consider refining search"
            elif [[ ${match_count} -eq 0 ]]; then
                log_message "PATTERN" "${COLOR_GRAY}" "No matches found"
            else
                log_message "PATTERN" "${COLOR_GREEN}" "✓ Manageable number of matches"
            fi
        fi
        ;;

    *)
        log_message "ANALYSIS" "${COLOR_GRAY}" "No specific analysis for tool: ${tool_name}"
        ;;
esac
log_separator

# Performance tracking
log_message "STEP" "${COLOR_BLUE}" "Step 3: Performance tracking"

# Log execution time if available
if command -v jq &> /dev/null; then
    duration_ms=$(echo "${hook_context}" | jq -r '.duration_ms // 0')
    if [[ ${duration_ms} -gt 0 ]]; then
        log_context "Execution Time" "${duration_ms}ms"

        # Warn on slow operations
        if [[ ${duration_ms} -gt 5000 ]]; then
            log_message "PERFORMANCE" "${COLOR_YELLOW}" "⚠ Slow operation (>5s)"
        elif [[ ${duration_ms} -gt 1000 ]]; then
            log_message "PERFORMANCE" "${COLOR_CYAN}" "Moderate duration (>1s)"
        else
            log_message "PERFORMANCE" "${COLOR_GREEN}" "Fast operation (<1s)"
        fi
    fi
fi
log_separator

# Log to usage database
log_message "STEP" "${COLOR_BLUE}" "Step 4: Recording to usage database"
usage_db="${HOME}/.claude/hooks-lab/tool-usage-detailed.jsonl"
mkdir -p "$(dirname "${usage_db}")"

# Append execution record
cat >> "${usage_db}" <<EOF
{"timestamp":"$(date -Iseconds)","tool":"${tool_name}","success":${success},"duration_ms":${duration_ms:-0},"working_dir":"${PWD}"}
EOF

log_success "Usage record appended to database"
log_separator

# Demonstrate follow-up actions
log_message "STEP" "${COLOR_BLUE}" "Step 5: Follow-up action opportunities"
log_message "INFO" "${COLOR_CYAN}" "PostToolUse can trigger follow-up actions like:"
log_message "INFO" "${COLOR_GRAY}" "  • Run tests after code changes"
log_message "INFO" "${COLOR_GRAY}" "  • Format code after Write operations"
log_message "INFO" "${COLOR_GRAY}" "  • Send notifications on failures"
log_message "INFO" "${COLOR_GRAY}" "  • Generate reports from analysis"
log_separator

# Summary
log_hook_event "PostToolUse" "Complete" "Tool result analysis complete"
log_message "SUMMARY" "${COLOR_GREEN}" "Tool: ${tool_name}"
log_message "SUMMARY" "${COLOR_GREEN}" "Status: ${success}"
log_message "SUMMARY" "${COLOR_CYAN}" "Full logs: ${LOG_FILE}"

echo ""
echo -e "${COLOR_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
echo -e "${COLOR_GREEN}🧪 Hooks Lab: PostToolUse hook executed${COLOR_RESET}"
echo -e "${COLOR_GRAY}Tool result analysis and logging complete${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
echo ""

# Success exit
exit 0
