#!/usr/bin/env bats

load test_helper

@test "tag adds a single tag to an alarm" {
  run_nag at "tomorrow 3pm" "test alarm"
  run_nag tag 1 work
  [ "${status}" -eq 0 ]
  local _tags
  _tags="$(cut -f2 "${NAG_DIR}/alarms")"
  [ "${_tags}" = "work" ]
}

@test "tag adds multiple tags to an alarm" {
  run_nag at "tomorrow 3pm" "test alarm"
  run_nag tag 1 work meetings
  [ "${status}" -eq 0 ]
  local _tags
  _tags="$(cut -f2 "${NAG_DIR}/alarms")"
  [ "${_tags}" = "work,meetings" ]
}

@test "tag merges with existing tags without duplicates" {
  run_nag at "tomorrow 3pm" "test alarm"
  run_nag tag 1 work
  run_nag tag 1 meetings work
  [ "${status}" -eq 0 ]
  local _tags
  _tags="$(cut -f2 "${NAG_DIR}/alarms")"
  [ "${_tags}" = "work,meetings" ]
}

@test "tag rejects pure integer tag names" {
  run_nag at "tomorrow 3pm" "test alarm"
  run_nag tag 1 123
  [ "${status}" -eq 1 ]
}

@test "tag with nonexistent ID fails" {
  run_nag tag 99 work
  [ "${status}" -eq 1 ]
}

@test "tag without arguments fails" {
  run_nag tag
  [ "${status}" -eq 1 ]
}

@test "tag with non-numeric arg lists matching alarms" {
  run_nag at "tomorrow 3pm" "work task"
  run_nag tag 1 work
  run_nag at "tomorrow 4pm" "personal task"
  run_nag tag work
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "work task" ]]
  [[ ! "${output}" =~ "personal task" ]]
}

@test "tag list shows no matches message" {
  run_nag at "tomorrow 3pm" "test alarm"
  run_nag tag nonexistent
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "No alarms tagged" ]]
}
