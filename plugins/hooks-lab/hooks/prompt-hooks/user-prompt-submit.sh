#!/usr/bin/env bash
#
# UserPromptSubmit Hook - Demonstrates prompt interception and context injection
#
# Learning Objectives:
# 1. Understand when user submits prompts
# 2. Analyze prompt content and intent
# 3. Inject additional context
# 4. Transform or enhance prompts
#

set -euo pipefail

# Get script directory and source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/logger.sh"
source "${SCRIPT_DIR}/../lib/context-builder.sh"

# Read the hook context from stdin
hook_context=$(cat)

# Start logging
log_hook_event "UserPromptSubmit" "Prompt Interception" "User has submitted a prompt"

# Log what we're learning
log_message "LEARNING" "${COLOR_CYAN}" "━━━ LEARNING: UserPromptSubmit Hook ━━━"
log_message "LEARNING" "${COLOR_CYAN}" "This hook runs when user submits a prompt to Claude"
log_message "LEARNING" "${COLOR_CYAN}" "Use it to: analyze intent, inject context, enhance prompts"
log_separator

# Parse the prompt information
log_message "STEP" "${COLOR_BLUE}" "Step 1: Parsing user prompt"
if command -v jq &> /dev/null; then
    user_prompt=$(echo "${hook_context}" | jq -r '.prompt // ""')
    prompt_length=${#user_prompt}

    log_context "Prompt Length" "${prompt_length} characters"

    # Preview prompt (first 150 chars)
    log_message "INFO" "${COLOR_GRAY}" "Prompt preview:"
    log_message "INFO" "${COLOR_GRAY}" "${user_prompt:0:150}..."
else
    log_message "WARNING" "${COLOR_YELLOW}" "jq not available - limited parsing"
    user_prompt=""
fi
log_separator

# Analyze prompt intent
log_message "STEP" "${COLOR_BLUE}" "Step 2: Analyzing prompt intent"

# Detect intent patterns
declare -A intent_patterns=(
    ["code_request"]="write|create|implement|build|code|function|class"
    ["explanation"]="explain|what is|how does|why|understand"
    ["debugging"]="fix|debug|error|issue|problem|not working"
    ["refactor"]="refactor|improve|optimize|clean up"
    ["documentation"]="document|comment|readme|docs"
    ["testing"]="test|spec|unit test|integration test"
)

detected_intents=()
for intent in "${!intent_patterns[@]}"; do
    pattern="${intent_patterns[$intent]}"
    if echo "${user_prompt}" | grep -qiE "${pattern}"; then
        detected_intents+=("${intent}")
        log_message "INTENT" "${COLOR_CYAN}" "Detected: ${intent}"
    fi
done

if [[ ${#detected_intents[@]} -eq 0 ]]; then
    log_message "INTENT" "${COLOR_GRAY}" "No specific intent patterns detected"
fi
log_separator

# Context injection opportunities
log_message "STEP" "${COLOR_BLUE}" "Step 3: Identifying context injection opportunities"

# Check current environment context
log_environment_context

# Suggest contextual enhancements
log_message "INFO" "${COLOR_CYAN}" "Context injection opportunities:"

# Check if in a git repo
if git rev-parse --git-dir > /dev/null 2>&1; then
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    log_message "CONTEXT" "${COLOR_GREEN}" "✓ Could inject git branch context: ${current_branch}"

    # Check for uncommitted changes
    if [[ $(git status --porcelain 2>/dev/null | wc -l) -gt 0 ]]; then
        log_message "CONTEXT" "${COLOR_YELLOW}" "⚠ Could warn about uncommitted changes"
    fi
fi

# Check for project configuration files
if [[ -f "package.json" ]]; then
    log_message "CONTEXT" "${COLOR_GREEN}" "✓ Could inject Node.js project context"
elif [[ -f "Cargo.toml" ]]; then
    log_message "CONTEXT" "${COLOR_GREEN}" "✓ Could inject Rust project context"
elif [[ -f "go.mod" ]]; then
    log_message "CONTEXT" "${COLOR_GREEN}" "✓ Could inject Go project context"
fi

# Check for relevant documentation
if [[ -f "CLAUDE.md" ]]; then
    log_message "CONTEXT" "${COLOR_GREEN}" "✓ Could inject CLAUDE.md project guidelines"
fi

if [[ -f "README.md" ]]; then
    log_message "CONTEXT" "${COLOR_GREEN}" "✓ Could inject README.md project overview"
fi
log_separator

# Demonstrate prompt enhancement patterns
log_message "STEP" "${COLOR_BLUE}" "Step 4: Prompt enhancement patterns"
log_message "INFO" "${COLOR_CYAN}" "UserPromptSubmit enables advanced patterns:"
log_message "INFO" "${COLOR_GRAY}" "  • Auto-inject relevant documentation"
log_message "INFO" "${COLOR_GRAY}" "  • Add context about current file/directory"
log_message "INFO" "${COLOR_GRAY}" "  • Include recent git history for debugging"
log_message "INFO" "${COLOR_GRAY}" "  • Inject coding standards or conventions"
log_message "INFO" "${COLOR_GRAY}" "  • Add warnings about environment state"
log_separator

# Log prompt metadata
log_message "STEP" "${COLOR_BLUE}" "Step 5: Recording prompt metadata"
prompts_db="${HOME}/.claude/hooks-lab/prompts.jsonl"
mkdir -p "$(dirname "${prompts_db}")"

# Record prompt (with privacy considerations - only metadata)
cat >> "${prompts_db}" <<EOF
{"timestamp":"$(date -Iseconds)","length":${prompt_length},"intents":[$(printf '"%s",' "${detected_intents[@]}" | sed 's/,$//')"],"working_dir":"${PWD}"}
EOF

log_success "Prompt metadata recorded (prompt content not logged for privacy)"
log_separator

# Summary
log_hook_event "UserPromptSubmit" "Complete" "Prompt analysis and context injection complete"
log_message "SUMMARY" "${COLOR_GREEN}" "Prompt Length: ${prompt_length} chars"
log_message "SUMMARY" "${COLOR_GREEN}" "Detected Intents: ${#detected_intents[@]}"
log_message "SUMMARY" "${COLOR_CYAN}" "Full logs: ${LOG_FILE}"

echo ""
echo -e "${COLOR_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
echo -e "${COLOR_GREEN}🧪 Hooks Lab: UserPromptSubmit hook executed${COLOR_RESET}"
echo -e "${COLOR_GRAY}Prompt analysis and context injection opportunities identified${COLOR_RESET}"
echo -e "${COLOR_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
echo ""

# Success exit (allow prompt to proceed)
exit 0
