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

@test "unsnooze by ID removes entry from snoozed file" {
  run_nag at "tomorrow 3pm" "take a break"
  run_nag snooze 1
  run_nag unsnooze 1
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Unsnoozed [1]" ]]
  ! grep -q "^1" "${NAG_DIR}/snoozed" 2>/dev/null
}

@test "unsnooze all removes snoozed file" {
  run_nag snooze all
  run_nag unsnooze all
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Unsnoozed all" ]]
  [ ! -f "${NAG_DIR}/snoozed" ]
}

@test "unsnooze all when nothing snoozed says so" {
  run_nag unsnooze all
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Nothing is snoozed" ]]
}

@test "unsnooze with no args fails" {
  run_nag unsnooze
  [ "${status}" -eq 1 ]
}

@test "unsnooze by tag removes tag entry" {
  run_nag at "tomorrow 3pm" "work task"
  run_nag tag 1 work
  run_nag snooze work
  run_nag unsnooze work
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Unsnoozed [work]" ]]
  ! grep -q "^work" "${NAG_DIR}/snoozed" 2>/dev/null
}

@test "unsnooze by tag requires -f" {
  run_nag at "tomorrow 3pm" "work task"
  run_nag tag 1 work
  run_nag snooze work
  run "${_NAG}" unsnooze work < /dev/null
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Unsnooze" ]]
  [[ "${output}" =~ "-f" ]]
}

@test "unsnooze nonexistent ID fails" {
  run_nag unsnooze 99
  [ "${status}" -eq 1 ]
}

@test "unsnooze tag that is not snoozed fails" {
  run_nag at "tomorrow 3pm" "work task"
  run_nag tag 1 work
  run "${_NAG}" -f unsnooze work
  [ "${status}" -eq 1 ]
  [[ "${output}" =~ "not snoozed" ]]
}
