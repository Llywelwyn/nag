#!/usr/bin/env bats

load test_helper

@test "skip reschedules a repeating alarm" {
  run_nag every day "tomorrow 3pm" daily task
  run_nag skip 1
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Skipped" ]]
  [ -s "${NAG_DIR}/alarms" ]
  local _ts _now
  _ts="$(cut -f3 "${NAG_DIR}/alarms")"
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

@test "skip by tag requires -f" {
  run_nag every day "tomorrow 3pm" "daily work"
  run_nag tag 1 work
  run "${_NAG}" skip work < /dev/null
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Skip" ]]
  [[ "${output}" =~ "-f" ]]
}

@test "skip by tag with -f reschedules matching alarms" {
  run_nag every day "tomorrow 3pm" "daily work"
  run_nag tag 1 work
  local _old_ts
  _old_ts="$(cut -f3 "${NAG_DIR}/alarms")"
  run "${_NAG}" -f skip work
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Skipped" ]]
  [[ "${output}" =~ "daily work" ]]
  local _new_ts
  _new_ts="$(cut -f3 "${NAG_DIR}/alarms")"
  (( _new_ts > _old_ts ))
}

@test "skip by tag with no matches fails" {
  run_nag at "tomorrow 3pm" "test alarm"
  run "${_NAG}" -f skip work
  [ "${status}" -eq 1 ]
}
