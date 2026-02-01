#!/usr/bin/env bash
# detect.sh - OS and architecture detection

# Detect the operating system
detect_os() {
    local os
    os="$(uname -s)"

    case "$os" in
        Darwin)
            echo "macos"
            ;;
        Linux)
            echo "linux"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Detect the CPU architecture
detect_arch() {
    local arch
    arch="$(uname -m)"

    case "$arch" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        arm64|aarch64)
            echo "arm64"
            ;;
        *)
            echo "$arch"
            ;;
    esac
}

# Get macOS version (e.g., "14.0" for Sonoma)
get_macos_version() {
    if [[ "$(detect_os)" == "macos" ]]; then
        sw_vers -productVersion
    else
        echo ""
    fi
}

# Get macOS major version number
get_macos_major_version() {
    local version
    version="$(get_macos_version)"
    echo "${version%%.*}"
}

# Get macOS name (e.g., "Sonoma", "Ventura")
get_macos_name() {
    local major_version
    major_version="$(get_macos_major_version)"

    case "$major_version" in
        26) echo "Tahoe" ;;
        15) echo "Sequoia" ;;
        14) echo "Sonoma" ;;
        13) echo "Ventura" ;;
        12) echo "Monterey" ;;
        11) echo "Big Sur" ;;
        *)  echo "macOS $major_version" ;;
    esac
}

# Check if running on Apple Silicon
is_apple_silicon() {
    [[ "$(detect_os)" == "macos" ]] && [[ "$(detect_arch)" == "arm64" ]]
}

# Check if running on Intel Mac
is_intel_mac() {
    [[ "$(detect_os)" == "macos" ]] && [[ "$(detect_arch)" == "x86_64" ]]
}

# Get Linux distribution name
get_linux_distro() {
    if [[ "$(detect_os)" != "linux" ]]; then
        echo ""
        return
    fi

    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "${ID:-unknown}"
    elif command -v lsb_release &>/dev/null; then
        lsb_release -si | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

# Print system information
print_system_info() {
    local os arch
    os="$(detect_os)"
    arch="$(detect_arch)"

    log_info "Operating System: $os"
    log_info "Architecture: $arch"

    case "$os" in
        macos)
            log_info "macOS Version: $(get_macos_version) ($(get_macos_name))"
            if is_apple_silicon; then
                log_info "Processor: Apple Silicon"
            else
                log_info "Processor: Intel"
            fi
            ;;
        linux)
            log_info "Distribution: $(get_linux_distro)"
            ;;
    esac
}

# Check minimum macOS version
check_macos_version() {
    local required_version="$1"
    local current_version
    current_version="$(get_macos_major_version)"

    if [[ "$current_version" -lt "$required_version" ]]; then
        return 1
    fi
    return 0
}
