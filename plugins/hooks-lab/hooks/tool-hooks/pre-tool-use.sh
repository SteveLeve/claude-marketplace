#!/usr/bin/env bash
#
# PreToolUse Hook - Demonstrates tool interception and validation
#
# Learning Objectives:
# 1. Understand when tools are about to execute
# 2. Inspect tool parameters before execution
# 3. Validate tool inputs
# 4. Make decisions to allow/block tool execution
#

set -euo pipefail

# Get script directory and source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/logger.sh"
source "${SCRIPT_DIR}/../lib/context-builder.sh"

# Read the hook context from stdin
hook_context=$(cat)

# Start logging
log_hook_event "PreToolUse" "Tool Interception" "A tool is about to be used"

# Log what we're learning
log_message "LEARNING" "${COLOR_CYAN}" "━━━ LEARNING: PreToolUse Hook ━━━"
log_message "LEARNING" "${COLOR_CYAN}" "This hook runs BEFORE any tool executes"
log_message "LEARNING" "${COLOR_CYAN}" "Use it to: validate inputs, log intentions, block dangerous operations"
log_separator

# Parse the tool information
log_message "STEP" "${COLOR_BLUE}" "Step 1: Parsing tool use context"
if command -v jq &> /dev/null; then
    tool_name=$(echo "${hook_context}" | jq -r '.tool // "unknown"')
    tool_params=$(echo "${hook_context}" | jq -c '.parameters // {}')

    log_context "Tool Name" "${tool_name}"
    log_message "INFO" "${COLOR_GRAY}" "Tool Parameters:"
    echo "${tool_params}" | jq -C '.' >&2

    # Record tool usage
    analyze_tool_usage "${tool_name}"
else
    log_message "WARNING" "${COLOR_YELLOW}" "jq not available - limited parsing"
    tool_name="unknown"
fi
log_separator

# Demonstrate validation logic
log_message "STEP" "${COLOR_BLUE}" "Step 2: Applying validation rules"

# Example: Check for potentially dangerous operations
case "${tool_name}" in
    "Bash")
        log_message "VALIDATION" "${COLOR_YELLOW}" "Bash tool detected - checking command"

        # Extract command if available
        if command -v jq &> /dev/null; then
            bash_command=$(echo "${hook_context}" | jq -r '.parameters.command // ""')

            # Check for dangerous patterns (this is just for demonstration)
            if echo "${bash_command}" | grep -qE "(rm -rf /|mkfs|dd if=)"; then
                log_error "Potentially dangerous command detected!"
                log_decision "BLOCKED" "Command contains dangerous patterns"
                log_separator

                # In a real scenario, you could block here by exiting with non-zero
                # For learning purposes, we just log and allow
                log_message "NOTE" "${COLOR_CYAN}" "In production, this could block execution"
            else
                log_decision "ALLOWED" "Command appears safe"
            fi

            log_context "Command Preview" "${bash_command:0:100}..."
        fi
        ;;

    "Write"|"Edit")
        log_message "VALIDATION" "${COLOR_YELLOW}" "File modification tool detected"

        if command -v jq &> /dev/null; then
            file_path=$(echo "${hook_context}" | jq -r '.parameters.file_path // ""')
            log_context "Target File" "${file_path}"

            # Check if modifying critical files
            if echo "${file_path}" | grep -qE "(/etc/|/sys/|/proc/)"; then
                log_error "Attempting to modify system file!"
                log_decision "WARNING" "Modifying system files can be dangerous"
            else
                log_decision "ALLOWED" "File path appears safe"
            fi
        fi
        ;;

    "Grep"|"Read"|"Glob")
        log_message "VALIDATION" "${COLOR_GREEN}" "Read-only tool - safe operation"
        log_decision "ALLOWED" "Read operations are generally safe"
        ;;

    *)
        log_message "VALIDATION" "${COLOR_BLUE}" "Unknown or unvalidated tool"
        log_decision "ALLOWED" "No specific validation rules for this tool"
        ;;
esac
log_separator

# Log transparency information
log_message "STEP" "${COLOR_BLUE}" "Step 3: Logging transparency information"
log_context "Timestamp" "$(date -Iseconds)"
log_context "Working Directory" "${PWD}"
log_context "User" "${USER}"
log_separator

# Demonstrate context injection (advanced)
log_message "STEP" "${COLOR_BLUE}" "Step 4: Context injection (advanced pattern)"
log_message "INFO" "${COLOR_CYAN}" "PreToolUse can inject additional context or modify parameters"
log_message "INFO" "${COLOR_CYAN}" "This enables patterns like:"
log_message "INFO" "${COLOR_GRAY}" "  • Adding safety checks automatically"
log_message "INFO" "${COLOR_GRAY}" "  • Injecting environment-specific configuration"
log_message "INFO" "${COLOR_GRAY}" "  • Modifying tool behavior based on context"
log_separator

# Summary
log_hook_event "PreToolUse" "Complete" "Tool validation and logging complete"
log_message "SUMMARY" "${COLOR_GREEN}" "Tool: ${tool_name}"
log_message "SUMMARY" "${COLOR_GREEN}" "Decision: ALLOWED (learning mode)"
log_message "SUMMARY" "${COLOR_CYAN}" "Full logs: ${LOG_FILE}"

echo ""
echo -e "${COLOR_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
echo -e "${COLOR_GREEN}🧪 Hooks Lab: PreToolUse hook executed${COLOR_RESET}"
echo -e "${COLOR_GRAY}Tool validation and transparency logging complete${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
echo ""

# Always allow in learning mode (exit 0)
# To block a tool, you would exit with non-zero: exit 1
exit 0
