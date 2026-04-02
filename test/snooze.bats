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
