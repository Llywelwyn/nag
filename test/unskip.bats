#!/usr/bin/env bats

load test_helper

@test "unskip resets repeating alarm to next natural occurrence" {
  run_nag every day "tomorrow 3pm" "daily task"
  run_nag skip 1
  run_nag skip 1
  local _skipped_ts
  _skipped_ts="$(cut -f3 "${NAG_DIR}/alarms")"

  run_nag unskip 1
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Unskipped [1]" ]]
  [[ "${output}" =~ "daily task" ]]

  local _new_ts
  _new_ts="$(cut -f3 "${NAG_DIR}/alarms")"
  (( _new_ts < _skipped_ts ))
  (( _new_ts > $(date +%s) ))
}

@test "unskip one-shot alarm fails" {
  run_nag at "tomorrow 3pm" "one-shot"
  run_nag unskip 1
  [ "${status}" -eq 1 ]
  [[ "${output}" =~ "one-shot" ]]
}

@test "unskip with nonexistent ID fails" {
  run_nag unskip 99
  [ "${status}" -eq 1 ]
}

@test "unskip without args fails" {
  run_nag unskip
  [ "${status}" -eq 1 ]
}

@test "unskip by tag requires -f" {
  run_nag every day "tomorrow 3pm" "daily work"
  run_nag tag 1 work
  run_nag skip 1
  run "${_NAG}" unskip work < /dev/null
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Unskip" ]]
  [[ "${output}" =~ "-f" ]]
}

@test "unskip by tag with -f resets matching alarms" {
  run_nag every day "tomorrow 3pm" "daily work"
  run_nag tag 1 work
  run_nag skip 1
  run_nag skip 1
  local _skipped_ts
  _skipped_ts="$(cut -f3 "${NAG_DIR}/alarms")"

  run "${_NAG}" -f unskip work
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Unskipped" ]]

  local _new_ts
  _new_ts="$(cut -f3 "${NAG_DIR}/alarms")"
  (( _new_ts < _skipped_ts ))
}

@test "unskip by tag with no repeating alarms fails" {
  run_nag at "tomorrow 3pm" "one-shot"
  run_nag tag 1 work
  run "${_NAG}" -f unskip work
  [ "${status}" -eq 1 ]
  [[ "${output}" =~ "No repeating" ]]
}

@test "unskip by tag with no matching tag fails" {
  run_nag every day "tomorrow 3pm" "daily task"
  run "${_NAG}" -f unskip nonexistent
  [ "${status}" -eq 1 ]
}

@test "unskip all resets all repeating alarms" {
  run_nag every day "tomorrow 3pm" "daily one"
  run_nag every day "tomorrow 4pm" "daily two"
  run_nag skip 1
  run_nag skip 1
  run_nag skip 2
  run_nag skip 2

  run "${_NAG}" -f unskip all
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Unskipped [1]" ]]
  [[ "${output}" =~ "Unskipped [2]" ]]
}

@test "unskip yearly alarm preserves month and day" {
  # Create a yearly alarm for a future date in the current year.
  local _target_month=$(( $(date +%-m) + 1 ))
  local _target_year=$(date +%Y)
  if (( _target_month > 12 )); then
    _target_month=1
    _target_year=$((_target_year + 1))
  fi
  local _target_date="$(printf "%04d-%02d-15 14:00:00" "${_target_year}" "${_target_month}")"
  local _target_ts="$(date -d "${_target_date}" +%s)"

  # Write alarm directly: yearly rule, timestamp in the future.
  write_alarm "$(printf "1\t\t%s\tyear\tyearly event" "${_target_ts}")"

  # Skip it twice to push it 2 years out.
  run_nag skip 1
  run_nag skip 1
  local _skipped_ts
  _skipped_ts="$(cut -f3 "${NAG_DIR}/alarms")"

  run_nag unskip 1
  [ "${status}" -eq 0 ]

  # Should come back to the original month/day, not today's date.
  local _new_ts _new_month _new_day
  _new_ts="$(cut -f3 "${NAG_DIR}/alarms")"
  _new_month="$(date -d "@${_new_ts}" +%-m)"
  _new_day="$(date -d "@${_new_ts}" +%-d)"
  [ "${_new_month}" -eq "${_target_month}" ]
  [ "${_new_day}" -eq 15 ]
  (( _new_ts > $(date +%s) ))
  (( _new_ts < _skipped_ts ))
}

@test "unskip monthly alarm preserves day of month" {
  # Create a monthly alarm for the 20th at 2pm.
  local _now_day=$(date +%-d)
  local _target_day=20
  local _target_ts

  # If today is past the 20th, set it for the 20th next month.
  if (( _now_day >= _target_day )); then
    _target_ts="$(date -d "$(date +%Y-%m-${_target_day}) + 1 month 14:00:00" +%s)"
  else
    _target_ts="$(date -d "$(date +%Y-%m-${_target_day}) 14:00:00" +%s)"
  fi

  write_alarm "$(printf "1\t\t%s\tmonth\tmonthly event" "${_target_ts}")"

  run_nag skip 1
  run_nag skip 1
  local _skipped_ts
  _skipped_ts="$(cut -f3 "${NAG_DIR}/alarms")"

  run_nag unskip 1
  [ "${status}" -eq 0 ]

  local _new_ts _new_day
  _new_ts="$(cut -f3 "${NAG_DIR}/alarms")"
  _new_day="$(date -d "@${_new_ts}" +%-d)"
  [ "${_new_day}" -eq "${_target_day}" ]
  (( _new_ts > $(date +%s) ))
  (( _new_ts < _skipped_ts ))
}

@test "unskip weekday alarm lands on a weekday" {
  run_nag every weekday "tomorrow 9am" "standup"
  run_nag skip 1
  run_nag skip 1
  run_nag skip 1

  run_nag unskip 1
  [ "${status}" -eq 0 ]

  local _new_ts _dow
  _new_ts="$(cut -f3 "${NAG_DIR}/alarms")"
  _dow="$(date -d "@${_new_ts}" +%u)"
  # 1-5 = weekday
  (( _dow >= 1 && _dow <= 5 ))
  (( _new_ts > $(date +%s) ))
}

@test "unskip all with no repeating alarms fails" {
  run_nag at "tomorrow 3pm" "one-shot"
  run "${_NAG}" -f unskip all
  [ "${status}" -eq 1 ]
}
