#!/usr/bin/env bash
#
# SessionStart Hook - Demonstrates session initialization and context bundling
#
# Learning Objectives:
# 1. Understand when sessions begin
# 2. Capture initial environment context
# 3. Build context bundles for later use
# 4. Set up session-specific state
#

set -euo pipefail

# Get script directory and source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/logger.sh"
source "${SCRIPT_DIR}/../lib/context-builder.sh"

# Start logging
log_hook_event "SessionStart" "Session Initialization" "A new Claude Code session is beginning"

# Log what we're learning
log_message "LEARNING" "${COLOR_CYAN}" "━━━ LEARNING: SessionStart Hook ━━━"
log_message "LEARNING" "${COLOR_CYAN}" "This hook runs when Claude Code starts a new session"
log_message "LEARNING" "${COLOR_CYAN}" "Use it to: initialize state, capture context, set up environment"
log_separator

# Capture environment context
log_message "STEP" "${COLOR_BLUE}" "Step 1: Capturing environment context"
log_environment_context
log_separator

# Build session context bundle
log_message "STEP" "${COLOR_BLUE}" "Step 2: Building session context bundle"
context_file=$(build_session_context)
log_separator

# Check for project-specific configuration
log_message "STEP" "${COLOR_BLUE}" "Step 3: Checking for project configuration"
if [[ -f "${PWD}/.claude-plugin/plugin.json" ]]; then
    log_success "Found plugin.json - this appears to be a plugin project"
    plugin_name=$(jq -r '.name // "unknown"' "${PWD}/.claude-plugin/plugin.json" 2>/dev/null || echo "unknown")
    log_context "Plugin Name" "${plugin_name}"
elif [[ -f "${PWD}/package.json" ]]; then
    log_success "Found package.json - this appears to be a Node.js project"
    project_name=$(jq -r '.name // "unknown"' "${PWD}/package.json" 2>/dev/null || echo "unknown")
    log_context "Project Name" "${project_name}"
else
    log_context "Project Type" "Unknown - no recognizable project files found"
fi
log_separator

# Create session metadata
log_message "STEP" "${COLOR_BLUE}" "Step 4: Creating session metadata"
session_id="session-$(date +%s)"
session_meta="${HOME}/.claude/hooks-lab/sessions/${session_id}.json"
mkdir -p "$(dirname "${session_meta}")"

cat > "${session_meta}" <<EOF
{
  "session_id": "${session_id}",
  "started_at": "$(date -Iseconds)",
  "working_directory": "${PWD}",
  "context_bundle": "${context_file}",
  "hooks": {
    "session_start": {
      "executed": true,
      "timestamp": "$(date -Iseconds)"
    }
  }
}
EOF

log_success "Session metadata created: ${session_meta}"
log_separator

# Display summary
log_hook_event "SessionStart" "Complete" "Session initialization successful"
log_message "SUMMARY" "${COLOR_GREEN}" "Session ID: ${session_id}"
log_message "SUMMARY" "${COLOR_GREEN}" "Context Bundle: ${context_file}"
log_message "SUMMARY" "${COLOR_GREEN}" "Metadata: ${session_meta}"
log_message "SUMMARY" "${COLOR_CYAN}" "View logs at: ${LOG_FILE}"

echo ""
echo -e "${COLOR_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
echo -e "${COLOR_GREEN}🧪 Hooks Lab: SessionStart hook executed successfully${COLOR_RESET}"
echo -e "${COLOR_GRAY}Session initialized with context bundling and verbose logging${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
echo ""

# Success exit
exit 0
