#!/usr/bin/env bats

load test_helper

@test "edit creates alarms file if missing" {
  [[ ! -f "${NAG_DIR}/alarms" ]]
  EDITOR="true" run_nag edit
  [[ "$status" -eq 0 ]]
  [[ -f "${NAG_DIR}/alarms" ]]
}

@test "edit opens the alarms file in EDITOR" {
  write_alarm "1		9999999999		test alarm"
  EDITOR="cat" run_nag edit
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"test alarm"* ]]
}

@test "-e flag invokes edit" {
  write_alarm "1		9999999999		test alarm"
  EDITOR="cat" run_nag -e
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"test alarm"* ]]
}

