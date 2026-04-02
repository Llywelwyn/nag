#!/usr/bin/env bats

load test_helper

@test "mute creates muted file" {
  run_nag mute
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "muted" ]]
  [ -f "${NAG_DIR}/muted" ]
}

@test "unmute removes muted file" {
  run_nag mute
  run_nag unmute
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "unmuted" ]]
  [ ! -f "${NAG_DIR}/muted" ]
}

@test "unmute when not muted says so" {
  run_nag unmute
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "not muted" ]]
}
