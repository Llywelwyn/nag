#!/usr/bin/env bats

load test_helper

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
