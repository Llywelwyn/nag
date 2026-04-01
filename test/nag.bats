#!/usr/bin/env bats

load test_helper

@test "list with no alarms prints nothing-to-nag message" {
  run_nag
  [ "${status}" -eq 0 ]
  [ "${output}" = "Nothing to nag about." ]
}

@test "help shows usage" {
  run_nag help
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "<time> <message...>" ]]
  [[ "${output}" =~ "every <rules> <time> <message...>" ]]
  [[ "${output}" =~ "stop <id>" ]]
  [[ "${output}" =~ "skip <id>" ]]
  [[ "${output}" =~ "check" ]]
  [[ "${output}" =~ "help [<subcommand>]" ]]
  [[ "${output}" =~ "Options:" ]]
}

@test "help list shows list usage" {
  run_nag help list
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Usage:" ]]
  [[ "${output}" =~ "nag list" ]]
}

@test "help at shows at usage" {
  run_nag help at
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Usage:" ]]
  [[ "${output}" =~ "[at] <time> <message...>" ]]
}

@test "help version shows version usage" {
  run_nag help version
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Usage:" ]]
  [[ "${output}" =~ "( version | --version )" ]]
}

@test "version shows current version" {
  run_nag version
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+\.[0-9]+(_[a-zA-Z0-9]+)*$ ]]
}

@test "at creates a one-shot alarm" {
  run_nag at "tomorrow 3pm" "take a break"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "[1] Tomorrow, 3pm — take a break" ]]
  [ -f "${NAG_DIR}/alarms" ]
  [ "$(wc -l < "${NAG_DIR}/alarms")" -eq 1 ]
  # Verify TSV structure: id<TAB>timestamp<TAB><TAB>message
  local _line
  _line="$(cat "${NAG_DIR}/alarms")"
  [[ "${_line}" =~ ^1$'\t'[0-9]+$'\t'$'\t'take\ a\ break$ ]]
}

@test "at is the implicit subcommand" {
  run_nag "tomorrow 3pm" "take a break"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "[1]" ]]
  [[ "${output}" =~ "take a break" ]]
}

@test "at with invalid time fails" {
  run_nag at "notavalidtime" "some message"
  [ "${status}" -eq 1 ]
}

@test "at with explicit past date fails" {
  run_nag at "yesterday 3pm" "too late"
  [ "${status}" -eq 1 ]
}

@test "at without message fails" {
  run_nag at "tomorrow 3pm"
  [ "${status}" -eq 1 ]
}

@test "list is the default subcommand" {
  run_nag
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Nothing to nag about" ]]
}

@test "NAG_DEFAULT overrides the default subcommand" {
  NAG_DEFAULT="version" run_nag
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+\.[0-9]+(_[a-zA-Z0-9]+)*$ ]]
}

@test "list shows formatted alarms with smart dates" {
  run_nag at "tomorrow 3pm" "take a break"
  run_nag
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "[1] Tomorrow, 3pm — take a break" ]]
}

@test "list shows empty message after stopping all alarms" {
  run_nag at "tomorrow 3pm" "test alarm"
  run_nag stop 1
  [ "${status}" -eq 0 ]
  run_nag
  [[ "${output}" =~ "Nothing to nag about" ]]
}

@test "help stop shows stop usage" {
  run_nag help stop
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Usage:" ]]
  [[ "${output}" =~ "stop <id>" ]]
}

@test "stop removes an alarm by ID" {
  run_nag at "tomorrow 3pm" "take a break"
  run_nag stop 1
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Stopped alarm 1" ]]
  run_nag
  [[ "${output}" =~ "Nothing to nag about" ]]
}

@test "stop removes only the targeted alarm" {
  run_nag at "tomorrow 3pm" "first"
  run_nag at "tomorrow 4pm" "second"
  run_nag at "tomorrow 5pm" "third"
  run_nag stop 2
  [ "${status}" -eq 0 ]
  run_nag
  [[ "${output}" =~ "first" ]]
  [[ ! "${output}" =~ "second" ]]
  [[ "${output}" =~ "third" ]]
}

@test "stop with nonexistent ID fails" {
  run_nag stop 99
  [ "${status}" -eq 1 ]
}

@test "stop without ID fails" {
  run_nag stop
  [ "${status}" -eq 1 ]
}

@test "help every shows every usage" {
  run_nag help every
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Usage:" ]]
  [[ "${output}" =~ "every <rules> <time> <message...>" ]]
}

@test "every creates a repeating alarm" {
  run_nag every weekday "tomorrow 3pm" standup meeting
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "[1]" ]]
  [[ "${output}" =~ "(weekday)" ]]
  [[ "${output}" =~ "standup meeting" ]]
  # Verify TSV has rule in field 3.
  local _rule
  _rule="$(cut -f3 "${NAG_DIR}/alarms")"
  [ "${_rule}" = "weekday" ]
}

@test "every with comma-separated rules" {
  run_nag every "tuesday,thursday" "tomorrow 3pm" standup
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "(tue, thu)" ]]
  grep -q "tue,thu" "${NAG_DIR}/alarms"
}

@test "every snaps to next matching day" {
  # "weekend 3pm" should snap to Saturday or Sunday, not a weekday.
  run_nag every weekend "tomorrow 3pm" relax
  [ "${status}" -eq 0 ]
  local _ts _dow
  _ts="$(cut -f2 "${NAG_DIR}/alarms")"
  _dow="$(date -d "@${_ts}" +%u)"
  # Day-of-week should be 6 (Sat) or 7 (Sun).
  [[ "${_dow}" == "6" || "${_dow}" == "7" ]]
}

@test "every with invalid rule fails" {
  run_nag every "invalid_rule" "tomorrow 3pm" some message
  [ "${status}" -eq 1 ]
}

@test "every without message fails" {
  run_nag every weekday "tomorrow 3pm"
  [ "${status}" -eq 1 ]
}

@test "list shows repeating alarm with rule in parens" {
  run_nag every weekday "tomorrow 3pm" standup
  run_nag
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "(weekday)" ]]
  [[ "${output}" =~ "standup" ]]
}

@test "list sorts alarms by time" {
  run_nag at "tomorrow 3pm" "take a break"
  run_nag at "tomorrow 9am" "standup"
  run_nag
  [ "${status}" -eq 0 ]
  # 9am should come before 3pm in output.
  local _first_line _second_line
  _first_line="$(printf "%s\n" "${output}" | head -1)"
  _second_line="$(printf "%s\n" "${output}" | sed -n '2p')"
  [[ "${_first_line}" =~ "standup" ]]
  [[ "${_second_line}" =~ "take a break" ]]
}

# check #######################################################################

# Helper: write a raw alarm line directly to the alarms file.
write_alarm() {
  mkdir -p "${NAG_DIR}"
  printf "%s\\n" "$1" >> "${NAG_DIR}/alarms"
}

@test "check fires expired one-shot and removes it" {
  local _past_ts=$(( $(date +%s) - 60 ))
  write_alarm "$(printf "1\t%s\t\tpast alarm" "${_past_ts}")"

  # Record what was fired.
  local _fired="${NAG_DIR}/fired"
  export NAG_CMD="${NAG_DIR}/recorder"
  cat > "${NAG_CMD}" <<'SCRIPT'
#!/usr/bin/env bash
printf "%s\n" "$2" >> "${NAG_DIR}/fired"
SCRIPT
  chmod +x "${NAG_CMD}"

  run_nag check
  [ "${status}" -eq 0 ]

  # Alarm should have been removed.
  [[ ! -s "${NAG_DIR}/alarms" ]] || [ "$(wc -l < "${NAG_DIR}/alarms")" -eq 0 ]

  # Notification should have fired.
  grep -q "past alarm" "${_fired}"
}

@test "check reschedules expired repeating alarm" {
  local _past_ts=$(( $(date +%s) - 60 ))
  write_alarm "$(printf "1\t%s\tday\tdaily alarm" "${_past_ts}")"

  run_nag check
  [ "${status}" -eq 0 ]

  # Alarm should still exist with a future timestamp.
  [ -s "${NAG_DIR}/alarms" ]
  local _new_ts
  _new_ts="$(cut -f2 "${NAG_DIR}/alarms" | head -1)"
  local _now
  _now="$(date +%s)"
  (( _new_ts > _now ))
}

@test "check does not fire future alarms" {
  local _future_ts=$(( $(date +%s) + 3600 ))
  write_alarm "$(printf "1\t%s\t\tfuture alarm" "${_future_ts}")"

  run_nag check
  [ "${status}" -eq 0 ]

  # Alarm should still be there, unchanged.
  [ -s "${NAG_DIR}/alarms" ]
  grep -q "future alarm" "${NAG_DIR}/alarms"
}

@test "check fires all missed alarms" {
  local _past1=$(( $(date +%s) - 120 ))
  local _past2=$(( $(date +%s) - 60 ))
  write_alarm "$(printf "1\t%s\t\tmissed one" "${_past1}")"
  write_alarm "$(printf "2\t%s\t\tmissed two" "${_past2}")"

  local _fired="${NAG_DIR}/fired"
  export NAG_CMD="${NAG_DIR}/recorder"
  cat > "${NAG_CMD}" <<'SCRIPT'
#!/usr/bin/env bash
printf "%s\n" "$2" >> "${NAG_DIR}/fired"
SCRIPT
  chmod +x "${NAG_CMD}"

  run_nag check
  [ "${status}" -eq 0 ]

  # Both should have fired.
  grep -q "missed one" "${_fired}"
  grep -q "missed two" "${_fired}"

  # Both should be removed (one-shots).
  [[ ! -s "${NAG_DIR}/alarms" ]] || [ "$(wc -l < "${NAG_DIR}/alarms")" -eq 0 ]
}

@test "check silently drops stale one-shot (older than 15 min)" {
  local _stale_ts=$(( $(date +%s) - 1800 ))  # 30 minutes ago
  write_alarm "$(printf "1\t%s\t\tstale alarm" "${_stale_ts}")"

  local _fired="${NAG_DIR}/fired"
  export NAG_CMD="${NAG_DIR}/recorder"
  cat > "${NAG_CMD}" <<'SCRIPT'
#!/usr/bin/env bash
printf "%s\n" "$2" >> "${NAG_DIR}/fired"
SCRIPT
  chmod +x "${NAG_CMD}"

  run_nag check
  [ "${status}" -eq 0 ]

  # Should NOT have fired.
  [ ! -f "${_fired}" ]

  # Should still be removed.
  [[ ! -s "${NAG_DIR}/alarms" ]] || [ "$(wc -l < "${NAG_DIR}/alarms")" -eq 0 ]
}

@test "check silently reschedules stale repeating alarm" {
  local _stale_ts=$(( $(date +%s) - 1800 ))  # 30 minutes ago
  write_alarm "$(printf "1\t%s\tday\tstale repeater" "${_stale_ts}")"

  local _fired="${NAG_DIR}/fired"
  export NAG_CMD="${NAG_DIR}/recorder"
  cat > "${NAG_CMD}" <<'SCRIPT'
#!/usr/bin/env bash
printf "%s\n" "$2" >> "${NAG_DIR}/fired"
SCRIPT
  chmod +x "${NAG_CMD}"

  run_nag check
  [ "${status}" -eq 0 ]

  # Should NOT have fired.
  [ ! -f "${_fired}" ]

  # Should be rescheduled to a future time.
  [ -s "${NAG_DIR}/alarms" ]
  local _new_ts
  _new_ts="$(cut -f2 "${NAG_DIR}/alarms" | head -1)"
  (( _new_ts > $(date +%s) ))
}

@test "help check shows check usage" {
  run_nag help check
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Usage:" ]]
  [[ "${output}" =~ "check" ]]
}

# mute/unmute #################################################################

@test "mute creates muted file" {
  run_nag mute
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "muted" ]]
  [ -f "${NAG_DIR}/muted" ]
}

@test "unmute removes muted file" {
  run_nag mute
  run_nag unmute
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "unmuted" ]]
  [ ! -f "${NAG_DIR}/muted" ]
}

@test "unmute when not muted says so" {
  run_nag unmute
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "not muted" ]]
}
