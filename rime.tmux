#!/usr/bin/env bash
set -u

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tmux_option() {
  local name="$1" default="$2" value
  value="$(tmux show-options -gqv "$name" 2>/dev/null)"
  [ -n "$value" ] && echo "$value" || echo "$default"
}

shell_escape() {
  printf "%s" "$1" | sed "s/'/'\\\\''/g"
}

check_tmux_version() {
  local ver major minor
  ver="$(tmux -V 2>/dev/null | sed -En 's/^tmux ([0-9]+)\.([0-9]+).*/\1.\2/p')"
  major="${ver%%.*}"
  minor="${ver##*.}"
  if [ -z "$major" ] || [ "$major" -lt 3 ] || { [ "$major" -eq 3 ] && [ "${minor:-0}" -lt 3 ]; }; then
    tmux display-message "rime.vim: tmux >= 3.3 required for display-popup (found ${ver:-unknown})"
    return 1
  fi
  return 0
}

resolve_wrapper() {
  local wrapper="$CURRENT_DIR/scripts/rime-tmux"
  if [ ! -x "$wrapper" ]; then
    tmux display-message "rime.vim: $wrapper not found or not executable"
    return 1
  fi
  echo "$wrapper"
}

escape_bind_key() {
  local key="$1"
  [ "$key" = ";" ] && echo '\;' || echo "$key"
}

build_popup_command() {
  local bin="$1" socket="$2" wrapper="$3"
  local ascii_punct="$4" traditional="$5"
  printf "RIME_BIN='%s' RIME_SOCKET='%s' '%s' --target #{pane_id}" \
    "$(shell_escape "$bin")" "$(shell_escape "$socket")" "$(shell_escape "$wrapper")"
  [ -n "$ascii_punct" ] && printf " --ascii-punct %s" "$ascii_punct"
  [ -n "$traditional" ] && printf " --traditional %s" "$traditional"
}

bind_with_popup() {
  local bind_key="$1" popup_opts="$2" popup_cmd="$3"
  if [ -n "$popup_opts" ]; then
    tmux bind-key -T prefix "$bind_key" run-shell \
      "tmux display-popup $popup_opts \"${popup_cmd}\""
  else
    tmux bind-key -T prefix "$bind_key" run-shell \
      "tmux display-popup -w80% -h8 -xC -yC -E -T ㄓ \"${popup_cmd}\""
  fi
}

main() {
  check_tmux_version || return 0

  local wrapper
  wrapper="$(resolve_wrapper)" || return 0

  local key bin socket popup_opts bind_key popup_cmd
  local ascii_punct traditional
  key="$(tmux_option "@rime_key" ";")"
  bin="$(tmux_option "@rime_bin" "rime-query")"
  socket="$(tmux_option "@rime_socket" "")"
  popup_opts="$(tmux_option "@rime_popup" "")"
  ascii_punct="$(tmux_option "@rime_option_ascii_punct" "")"
  traditional="$(tmux_option "@rime_option_traditional" "")"

  bind_key="$(escape_bind_key "$key")"
  popup_cmd="$(build_popup_command "$bin" "$socket" "$wrapper" "$ascii_punct" "$traditional")"

  bind_with_popup "$bind_key" "$popup_opts" "$popup_cmd"
}

main "$@"
