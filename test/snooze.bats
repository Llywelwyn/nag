#!/usr/bin/env bats

load test_helper

@test "snooze by ID creates entry in snoozed file" {
  run_nag at "tomorrow 3pm" "take a break"
  run_nag snooze 1
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Snoozed [1]" ]]
  [ -f "${NAG_DIR}/snoozed" ]
  grep -q "^1$" "${NAG_DIR}/snoozed"
}

@test "snooze by ID shows alarm message in output" {
  run_nag at "tomorrow 3pm" "take a break"
  run_nag snooze 1
  [[ "${output}" =~ "take a break" ]]
}

@test "snooze with nonexistent ID fails" {
  run_nag snooze 99
  [ "${status}" -eq 1 ]
}

@test "snooze with no args fails" {
  run_nag snooze
  [ "${status}" -eq 1 ]
}

@test "snooze all creates global entry" {
  run_nag snooze all
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Snoozed all." ]]
  [ -f "${NAG_DIR}/snoozed" ]
  grep -q "^\*$" "${NAG_DIR}/snoozed"
}

@test "snooze all with duration sets expiry" {
  run_nag snooze all "tomorrow"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Snoozed all" ]]
  [[ "${output}" =~ "until" ]]
  local _line
  _line="$(cat "${NAG_DIR}/snoozed")"
  [[ "${_line}" == \*$'\t'* ]]
}

@test "snooze by tag creates entry in snoozed file" {
  run_nag at "tomorrow 3pm" "work task"
  run_nag tag 1 work
  run_nag snooze work
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Snoozed [work]" ]]
  grep -q "^work$" "${NAG_DIR}/snoozed"
}

@test "snooze by tag requires -f" {
  run_nag at "tomorrow 3pm" "work task"
  run_nag tag 1 work
  run "${_NAG}" snooze work < /dev/null
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Snooze" ]]
  [[ "${output}" =~ "-f" ]]
}

@test "snooze by tag with no matching alarms fails" {
  run_nag at "tomorrow 3pm" "test alarm"
  run "${_NAG}" -f snooze nonexistent
  [ "${status}" -eq 1 ]
}

@test "snooze by ID with duration sets expiry" {
  run_nag at "tomorrow 3pm" "take a break"
  run_nag snooze 1 "tomorrow"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Snoozed [1]" ]]
  [[ "${output}" =~ "until" ]]
  local _line
  _line="$(cat "${NAG_DIR}/snoozed")"
  [[ "${_line}" == 1$'\t'* ]]
}

@test "snooze by tag with duration sets expiry" {
  run_nag at "tomorrow 3pm" "work task"
  run_nag tag 1 work
  run_nag snooze work "tomorrow"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Snoozed [work]" ]]
  [[ "${output}" =~ "until" ]]
  local _line
  _line="$(cat "${NAG_DIR}/snoozed")"
  [[ "${_line}" == work$'\t'* ]]
}
