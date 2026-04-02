#!/usr/bin/env bats

load test_helper

@test "mute with no args creates mute file with global entry" {
  run_nag mute
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Muted all." ]]
  [ -f "${NAG_DIR}/mute" ]
  grep -q "^\*$" "${NAG_DIR}/mute"
}

@test "mute tag adds tag to mute file" {
  run_nag mute work
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Muted [work]." ]]
  grep -q "^work$" "${NAG_DIR}/mute"
}

@test "mute tag skips if global mute already set" {
  run_nag mute
  run_nag mute work
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Muted [work]." ]]
  [ "$(wc -l < "${NAG_DIR}/mute")" -eq 1 ]
}

@test "unmute with no args deletes mute file" {
  run_nag mute
  run_nag unmute
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Unmuted all." ]]
  [ ! -f "${NAG_DIR}/mute" ]
}

@test "unmute when not muted says so" {
  run_nag unmute
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "not muted" ]]
}

@test "unmute tag adds !tag when global mute is set" {
  run_nag mute
  run_nag unmute work
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Unmuted [work]." ]]
  grep -q "^!work$" "${NAG_DIR}/mute"
}

@test "unmute tag removes tag entry when individually muted" {
  run_nag mute work
  run_nag unmute work
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Unmuted [work]." ]]
  ! grep -q "^work$" "${NAG_DIR}/mute"
}
