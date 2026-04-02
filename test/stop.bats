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

@test "stop by tag requires -f" {
  run_nag at "tomorrow 3pm" "tagged alarm"
  run_nag tag 1 work
  run "${_NAG}" stop work
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Would stop" ]]
  [[ "${output}" =~ "-f" ]]
  [ -s "${NAG_DIR}/alarms" ]
}

@test "stop by tag with -f removes matching alarms" {
  run_nag at "tomorrow 3pm" "work alarm"
  run_nag tag 1 work
  run_nag at "tomorrow 4pm" "personal alarm"
  run "${_NAG}" -f stop work
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Stopped" ]]
  [[ "${output}" =~ "work alarm" ]]
  run_nag
  [[ "${output}" =~ "personal alarm" ]]
  [[ ! "${output}" =~ "work alarm" ]]
}

@test "stop by tag with no matches fails" {
  run_nag at "tomorrow 3pm" "test alarm"
  run "${_NAG}" -f stop work
  [ "${status}" -eq 1 ]
}
