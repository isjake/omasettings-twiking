#!/bin/bash
# Regression for bt_addresses: metadata is not a Bluetooth device.
# Run from any directory: bash tests/bluetooth-addresses.sh
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$root/lib/bluetooth.sh"

# Replace the external reader with representative noisy bluetoothctl output.
# The real production parser runs for every supported list filter.
capture() {
  [[ $1 == bluetoothctl && $2 == devices ]] || return 1
  case ${3:-} in ''|Paired|Connected) ;; *) return 1 ;; esac
  cat <<'OUTPUT'
Device Information
Device Name
	UUID: Device Information (0000180a-0000-1000-8000-00805f9b34fb)
[NEW] Media /org/bluez/hci0
Device 00:11:22:33:44:55 Test Mouse
Device aa:bb:cc:dd:ee:ff Lowercase Device
Device GG:11:22:33:44:55 Invalid hex
Device 00:11:22:33:44 Short address
Device 00:11:22:33:44:55:66 Long address
Device x00:11:22:33:44:55 Prefixed address
Device 00:11:22:33:44:55x Suffixed address
OUTPUT
}
expected=$'00:11:22:33:44:55\tTest Mouse\naa:bb:cc:dd:ee:ff\tLowercase Device'
for filter in '' Paired Connected; do
  actual=$(bt_addresses "$filter")
  if [[ $actual != "$expected" ]]; then
    printf 'FAIL: list filter %s emitted wrong device rows\n%s\n' "${filter:-all}" "$actual" >&2
    exit 1
  fi
done

capture() { return 0; }
[[ -z $(bt_addresses) ]] || { echo 'FAIL: empty list' >&2; exit 1; }
echo 'PASS: all/Paired/Connected filter metadata and malformed addresses; names and empty list preserved'
