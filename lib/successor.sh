# Part of OmaSettings. Sourced by bin/omasettings; not run on its own.
#
# OmaSettings continues as OmaControl. This puts OmaControl on the machine and
# opens it; carrying the settings across is OmaControl's to do, from a button on
# its Overview page, because only the new window knows the shape it wants them
# in.

SUCCESSOR_ID="io.github.twiking.omacontrol"
SUCCESSOR_URL="https://github.com/twiking/omacontrol.git"
SUCCESSOR_LOG="$HOME_DIR/.local/state/omasettings/successor.log"

successor_cmd() {
  case ${1:-} in
    # Detached: adding a plugin makes the shell reload every plugin, this
    # window with them, and a child of the window would die part-way through
    # the clone.
    start)
      setsid bash "$OMASETTINGS_BIN" successor run >/dev/null 2>&1 &
      disown 2>/dev/null || true ;;
    run)
      local i
      mkdir -p "$(dirname "$SUCCESSOR_LOG")"
      if [[ -e $HOME_DIR/.config/omarchy/plugins/$SUCCESSOR_ID ]]; then
        omarchy-plugin-enable "$SUCCESSOR_ID" >"$SUCCESSOR_LOG" 2>&1
      else
        omarchy-plugin-add "$SUCCESSOR_URL" --yes --enable >"$SUCCESSOR_LOG" 2>&1 || return 1
      fi
      # The same wait as reopen_window: the shell may still be tearing down or
      # starting the plugins again, and a summon into that is lost. Asked by
      # the layer, since the IPC call answers nothing either way.
      for i in $(seq 1 60); do
        [[ -n $(omarchy-shell shell ping 2>/dev/null) ]] && break
        sleep 0.5
      done
      sleep 0.6
      for i in $(seq 1 40); do
        omarchy-shell omacontrol showPage overview >/dev/null 2>&1
        capture hyprctl layers -j | jq -e '..|select(.namespace? == "omacontrol")' >/dev/null 2>&1 && return 0
        sleep 0.5
      done ;;
    *) die "usage: omasettings successor start|run" ;;
  esac
}
