#!/usr/bin/env bats

load test_helper

@test "check fires expired one-shot and removes it" {
  local _past_ts=$(( $(date +%s) - 60 ))
  write_alarm "$(printf "1\t\t%s\t\tpast alarm" "${_past_ts}")"

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
  write_alarm "$(printf "1\t\t%s\tday\tdaily alarm" "${_past_ts}")"

  run_nag check
  [ "${status}" -eq 0 ]

  # Alarm should still exist with a future timestamp.
  [ -s "${NAG_DIR}/alarms" ]
  local _new_ts
  _new_ts="$(cut -f3 "${NAG_DIR}/alarms" | head -1)"
  local _now
  _now="$(date +%s)"
  (( _new_ts > _now ))
}

@test "check does not fire future alarms" {
  local _future_ts=$(( $(date +%s) + 3600 ))
  write_alarm "$(printf "1\t\t%s\t\tfuture alarm" "${_future_ts}")"

  run_nag check
  [ "${status}" -eq 0 ]

  # Alarm should still be there, unchanged.
  [ -s "${NAG_DIR}/alarms" ]
  grep -q "future alarm" "${NAG_DIR}/alarms"
}

@test "check fires all missed alarms" {
  local _past1=$(( $(date +%s) - 120 ))
  local _past2=$(( $(date +%s) - 60 ))
  write_alarm "$(printf "1\t\t%s\t\tmissed one" "${_past1}")"
  write_alarm "$(printf "2\t\t%s\t\tmissed two" "${_past2}")"

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
  write_alarm "$(printf "1\t\t%s\t\tstale alarm" "${_stale_ts}")"

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
  write_alarm "$(printf "1\t\t%s\tday\tstale repeater" "${_stale_ts}")"

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
  _new_ts="$(cut -f3 "${NAG_DIR}/alarms" | head -1)"
  (( _new_ts > $(date +%s) ))
}

@test "check skips snoozed alarm and does not fire it" {
  local _past_ts=$(( $(date +%s) - 60 ))
  write_alarm "$(printf "1\t\t%s\t\tsnoozed alarm" "${_past_ts}")"
  printf "1\\n" > "${NAG_DIR}/snoozed"

  local _fired="${NAG_DIR}/fired"
  export NAG_CMD="${NAG_DIR}/recorder"
  cat > "${NAG_CMD}" <<'SCRIPT'
#!/usr/bin/env bash
printf "%s\n" "$2" >> "${NAG_DIR}/fired"
SCRIPT
  chmod +x "${NAG_CMD}"

  run_nag check
  [ "${status}" -eq 0 ]
  [ ! -f "${_fired}" ]
  [ -s "${NAG_DIR}/alarms" ]
  grep -q "snoozed alarm" "${NAG_DIR}/alarms"
}

@test "check skips alarm snoozed with expiry" {
  local _past_ts=$(( $(date +%s) - 60 ))
  local _future_expiry=$(( $(date +%s) + 3600 ))
  write_alarm "$(printf "1\t\t%s\t\tsnoozed alarm" "${_past_ts}")"
  printf "1\t%s\\n" "${_future_expiry}" > "${NAG_DIR}/snoozed"

  local _fired="${NAG_DIR}/fired"
  export NAG_CMD="${NAG_DIR}/recorder"
  cat > "${NAG_CMD}" <<'SCRIPT'
#!/usr/bin/env bash
printf "%s\n" "$2" >> "${NAG_DIR}/fired"
SCRIPT
  chmod +x "${NAG_CMD}"

  run_nag check
  [ "${status}" -eq 0 ]
  [ ! -f "${_fired}" ]
  [ -s "${NAG_DIR}/alarms" ]
}

@test "check sweeps expired snooze entries" {
  local _future_ts=$(( $(date +%s) + 3600 ))
  write_alarm "$(printf "1\t\t%s\t\talarm" "${_future_ts}")"
  local _past_expiry=$(( $(date +%s) - 60 ))
  printf "1\t%s\\n" "${_past_expiry}" > "${NAG_DIR}/snoozed"

  run_nag check
  [ "${status}" -eq 0 ]

  if [ -f "${NAG_DIR}/snoozed" ]; then
    [ ! -s "${NAG_DIR}/snoozed" ] || ! grep -q "^1" "${NAG_DIR}/snoozed"
  fi
}

@test "check fires alarm after snooze expires" {
  local _past_ts=$(( $(date +%s) - 60 ))
  local _past_expiry=$(( $(date +%s) - 120 ))
  write_alarm "$(printf "1\t\t%s\t\texpired snooze" "${_past_ts}")"
  printf "1\t%s\\n" "${_past_expiry}" > "${NAG_DIR}/snoozed"

  local _fired="${NAG_DIR}/fired"
  export NAG_CMD="${NAG_DIR}/recorder"
  cat > "${NAG_CMD}" <<'SCRIPT'
#!/usr/bin/env bash
printf "%s\n" "$2" >> "${NAG_DIR}/fired"
SCRIPT
  chmod +x "${NAG_CMD}"

  run_nag check
  [ "${status}" -eq 0 ]
  grep -q "expired snooze" "${_fired}"
}
