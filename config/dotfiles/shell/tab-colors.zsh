# ============================================
# Tab Color Functions for Ghostty
# ============================================
# Uses iTerm2's OSC 6 escape sequence (supported by Ghostty)

# Set tab color from hex (e.g., tab-color "#FF6B6B")
tab-color() {
  local hex="${1#\#}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  printf '\033]6;1;bg;red;brightness;%d\a' "$r"
  printf '\033]6;1;bg;green;brightness;%d\a' "$g"
  printf '\033]6;1;bg;blue;brightness;%d\a' "$b"
}

# Reset tab color to default
tab-reset() {
  printf '\033]6;1;bg;*;default\a'
}

# ============================================
# Preset Colors (Vesper theme inspired)
# ============================================
tab-work()    { tab-color "#FFC799"; }  # Orange/amber
tab-dev()     { tab-color "#A8C97F"; }  # Green
tab-server()  { tab-color "#E06C75"; }  # Red/coral
tab-docs()    { tab-color "#61AFEF"; }  # Blue

# ============================================
# Auto-Color by Directory
# ============================================
_auto_tab_color_dir() {
  case "$PWD" in
    */work/*)      tab-color "#FFC799" ;;  # Work projects = orange
    */Developer/*) tab-color "#A8C97F" ;;  # Dev projects = green
    *)             ;;  # Keep current color for other dirs
  esac
}

# Register hook (uncomment to enable)
# chpwd_functions+=(_auto_tab_color_dir)

# ============================================
# Auto-Color by SSH Host
# ============================================
ssh() {
  local host="$1"
  case "$host" in
    *prod*|*production*) tab-color "#E06C75" ;;  # Production = red
    *staging*|*stage*)   tab-color "#FFC799" ;;  # Staging = orange
    *dev*|*development*) tab-color "#A8C97F" ;;  # Dev = green
  esac
  command ssh "$@"
  tab-reset  # Reset after SSH session ends
}
