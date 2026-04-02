#!/usr/bin/env bats

load test_helper

@test "at creates a one-shot alarm" {
  run_nag at "tomorrow 3pm" "take a break"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "[1] Tomorrow, 3pm — take a break" ]]
  [ -f "${NAG_DIR}/alarms" ]
  [ "$(wc -l < "${NAG_DIR}/alarms")" -eq 1 ]
  # Verify TSV structure: id<TAB><empty-tags><TAB>timestamp<TAB><empty-rule><TAB>message
  local _line
  _line="$(cat "${NAG_DIR}/alarms")"
  [[ "${_line}" =~ ^1$'\t'$'\t'[0-9]+$'\t'$'\t'take\ a\ break$ ]]
}

@test "at is the implicit subcommand" {
  run_nag "tomorrow 3pm" "take a break"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "[1]" ]]
  [[ "${output}" =~ "take a break" ]]
}

@test "at with invalid time fails" {
  run_nag at "notavalidtime" "some message"
  [ "${status}" -eq 1 ]
}

@test "at rejects yesterday" {
  run_nag at "yesterday 3pm" "too late"
  [ "${status}" -eq 1 ]
  [[ "${output}" =~ "past" ]]
}

@test "at rejects ago" {
  run_nag at "2 hours ago" "too late"
  [ "${status}" -eq 1 ]
  [[ "${output}" =~ "past" ]]
}

@test "at rejects last" {
  run_nag at "last friday" "too late"
  [ "${status}" -eq 1 ]
  [[ "${output}" =~ "past" ]]
}

@test "invalid time with ago says invalid, not past" {
  run_nag at "sdjkfhskdjfh ago" "nope"
  [ "${status}" -eq 1 ]
  [[ "${output}" =~ "Invalid time" ]]
}

@test "invalid time with yesterday says invalid, not past" {
  run_nag at "sdjkfh yesterday blah" "nope"
  [ "${status}" -eq 1 ]
  [[ "${output}" =~ "Invalid time" ]]
}

@test "invalid time with last says invalid, not past" {
  run_nag at "last sdjkfh" "nope"
  [ "${status}" -eq 1 ]
  [[ "${output}" =~ "Invalid time" ]]
}

@test "at rolls past date forward to next year" {
  local _last_month
  _last_month="$(date -d "last month" "+%B %-d")"
  run_nag at "${_last_month}" "annual thing"
  [ "${status}" -eq 0 ]
  local _ts
  _ts="$(cut -f3 "${NAG_DIR}/alarms")"
  local _ts_year _next_year
  _ts_year="$(date -d "@${_ts}" +%Y)"
  _next_year="$(date -d "+1 year" +%Y)"
  [ "${_ts_year}" = "${_next_year}" ]
}

@test "-f flag suppresses prompts" {
  run "${_NAG}" -f at "tomorrow 3pm" "flagged alarm"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "flagged alarm" ]]
}

@test "at creates alarm with 5-field TSV (empty tags)" {
  run_nag at "tomorrow 3pm" "tagged test"
  [ "${status}" -eq 0 ]
  local _line
  _line="$(cat "${NAG_DIR}/alarms")"
  [[ "${_line}" =~ ^1$'\t'$'\t'[0-9]+$'\t'$'\t'tagged\ test$ ]]
}

@test "at without message fails" {
  run_nag at "tomorrow 3pm"
  [ "${status}" -eq 1 ]
}
