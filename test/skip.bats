#!/usr/bin/env bats

load test_helper

@test "skip reschedules a repeating alarm" {
  run_nag every day "tomorrow 3pm" daily task
  run_nag skip 1
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Skipped" ]]
  [ -s "${NAG_DIR}/alarms" ]
  local _ts _now
  _ts="$(cut -f2 "${NAG_DIR}/alarms")"
  _now="$(date +%s)"
  (( _ts > _now ))
}

@test "skip deletes a one-shot alarm" {
  run_nag at "tomorrow 3pm" "one-shot"
  run_nag skip 1
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Stopped" ]]
  run_nag
  [[ "${output}" =~ "Nothing to nag about" ]]
}

@test "skip with nonexistent ID fails" {
  run_nag skip 99
  [ "${status}" -eq 1 ]
}

@test "skip without ID fails" {
  run_nag skip
  [ "${status}" -eq 1 ]
}
