#!/usr/bin/env bats

load test_helper

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
