#!/usr/bin/env bash
# prompt.sh - User interaction helpers

# Display a menu and get user selection
# Usage: select_option "prompt" option1 option2 option3
# Returns: selected option (0-indexed) in $REPLY
select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    local choice

    # If not interactive, return first option
    if [[ ! -t 0 ]]; then
        REPLY=0
        return 0
    fi

    echo -e "\n${BOLD}$prompt${RESET}"
    for i in "${!options[@]}"; do
        echo -e "  ${CYAN}$((i + 1))${RESET}) ${options[$i]}"
    done

    while true; do
        read -r -p "Enter choice [1-${#options[@]}]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#options[@]}" ]]; then
            REPLY=$((choice - 1))
            return 0
        fi
        echo "Invalid choice. Please enter a number between 1 and ${#options[@]}."
    done
}

# Simple yes/no prompt
# Usage: yes_no "Question?" [default: y/n]
# Returns: 0 for yes, 1 for no
yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response

    if [[ "${FORCE:-false}" == "true" ]]; then
        return 0
    fi

    local yn_prompt
    if [[ "$default" == "y" ]]; then
        yn_prompt="${GREEN}Y${RESET}/n"
    else
        yn_prompt="y/${GREEN}N${RESET}"
    fi

    while true; do
        read -r -p "$(echo -e "${BOLD}$prompt${RESET} [$yn_prompt] ")" response
        response="${response:-$default}"

        case "$response" in
            [Yy]|[Yy]es) return 0 ;;
            [Nn]|[Nn]o)  return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# Prompt for text input
# Usage: prompt_input "Prompt" [default_value]
# Returns: user input in $REPLY
prompt_input() {
    local prompt="$1"
    local default="$2"

    if [[ -n "$default" ]]; then
        read -r -p "$(echo -e "${BOLD}$prompt${RESET} [$default]: ")" REPLY
        REPLY="${REPLY:-$default}"
    else
        read -r -p "$(echo -e "${BOLD}$prompt${RESET}: ")" REPLY
    fi
}

# Prompt for profile selection
# Usage: select_profile
# Returns: selected profile name in $REPLY
select_profile() {
    local profiles=()
    local profile_dir
    profile_dir="$(get_repo_root)/config/profiles"

    # Find all .conf files in profiles directory
    for conf in "$profile_dir"/*.conf; do
        if [[ -f "$conf" ]]; then
            profiles+=("$(basename "$conf" .conf)")
        fi
    done

    if [[ ${#profiles[@]} -eq 0 ]]; then
        log_error "No profiles found in $profile_dir"
        return 1
    fi

    if [[ ${#profiles[@]} -eq 1 ]]; then
        REPLY="${profiles[0]}"
        log_info "Using only available profile: $REPLY"
        return 0
    fi

    echo ""
    log_step "Select a profile"
    select_option "Which profile would you like to use?" "${profiles[@]}"
    REPLY="${profiles[$REPLY]}"
}

# Display a progress spinner
# Usage: spinner $PID "message"
spinner() {
    local pid=$1
    local message="$2"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${CYAN}%s${RESET} %s" "${spin:i++%${#spin}:1}" "$message"
        sleep 0.1
    done

    printf "\r"
}

# Display a countdown
# Usage: countdown 5 "Starting in"
countdown() {
    local seconds=$1
    local message="${2:-Starting in}"

    for ((i=seconds; i>0; i--)); do
        printf "\r${YELLOW}%s %d...${RESET}" "$message" "$i"
        sleep 1
    done
    printf "\r%-$((${#message} + 10))s\r" " "
}
