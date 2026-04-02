#!/usr/bin/env bats

load test_helper

@test "list with no alarms prints nothing-to-nag message" {
  run_nag
  [ "${status}" -eq 0 ]
  [ "${output}" = "Nothing to nag about." ]
}

@test "list is the default subcommand" {
  run_nag
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Nothing to nag about" ]]
}

@test "list shows formatted alarms with smart dates" {
  run_nag at "tomorrow 3pm" "take a break"
  run_nag
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "[1] Tomorrow, 3pm — take a break" ]]
}

@test "list shows empty message after stopping all alarms" {
  run_nag at "tomorrow 3pm" "test alarm"
  run_nag stop 1
  [ "${status}" -eq 0 ]
  run_nag
  [[ "${output}" =~ "Nothing to nag about" ]]
}

@test "list shows repeating alarm with rule in parens" {
  run_nag every weekday "tomorrow 3pm" standup
  run_nag
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "(weekday)" ]]
  [[ "${output}" =~ "standup" ]]
}

@test "list sorts alarms by time" {
  run_nag at "tomorrow 3pm" "take a break"
  run_nag at "tomorrow 9am" "standup"
  run_nag
  [ "${status}" -eq 0 ]
  # 9am should come before 3pm in output.
  local _first_line _second_line
  _first_line="$(printf "%s\n" "${output}" | head -1)"
  _second_line="$(printf "%s\n" "${output}" | sed -n '2p')"
  [[ "${_first_line}" =~ "standup" ]]
  [[ "${_second_line}" =~ "take a break" ]]
}

@test "list formats multiple alarms correctly" {
  run_nag at "tomorrow 3pm" "first alarm"
  run_nag at "tomorrow 9am" "second alarm"
  run_nag at "tomorrow 5pm" "third alarm"
  run_nag
  [ "${status}" -eq 0 ]
  local _first _second _third
  _first="$(printf "%s\n" "${output}" | sed -n '1p')"
  _second="$(printf "%s\n" "${output}" | sed -n '2p')"
  _third="$(printf "%s\n" "${output}" | sed -n '3p')"
  [[ "${_first}" =~ "Tomorrow, 9am" ]]
  [[ "${_first}" =~ "second alarm" ]]
  [[ "${_second}" =~ "Tomorrow, 3pm" ]]
  [[ "${_second}" =~ "first alarm" ]]
  [[ "${_third}" =~ "Tomorrow, 5pm" ]]
  [[ "${_third}" =~ "third alarm" ]]
}

@test "list shows Today for alarm due today" {
  local _ts=$(( $(date -d "$(date +%Y-%m-%d)" +%s) + 82800 ))
  write_alarm "$(printf '1\t\t%s\t\ttoday alarm' "${_ts}")"
  run_nag
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Today,".*"today alarm" ]]
}

@test "list shows Tomorrow for alarm due tomorrow" {
  local _ts=$(( $(date -d "$(date +%Y-%m-%d)" +%s) + 86400 + 43200 ))
  write_alarm "$(printf '1\t\t%s\t\ttomorrow alarm' "${_ts}")"
  run_nag
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Tomorrow,".*"tomorrow alarm" ]]
}

@test "list shows This <day> for alarm 3 days away" {
  local _ts=$(( $(date -d "$(date +%Y-%m-%d)" +%s) + 86400 * 3 + 43200 ))
  local _day="$(date -d "@${_ts}" +%A)"
  write_alarm "$(printf '1\t\t%s\t\tthis alarm' "${_ts}")"
  run_nag
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "This ${_day},".*"this alarm" ]]
}

@test "list shows Next <day> for alarm 10 days away" {
  local _ts=$(( $(date -d "$(date +%Y-%m-%d)" +%s) + 86400 * 10 + 43200 ))
  local _day="$(date -d "@${_ts}" +%A)"
  write_alarm "$(printf '1\t\t%s\t\tnext alarm' "${_ts}")"
  run_nag
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Next ${_day},".*"next alarm" ]]
}

@test "list shows date for alarm 30 days away" {
  local _ts=$(( $(date -d "$(date +%Y-%m-%d)" +%s) + 86400 * 30 + 43200 ))
  local _date="$(date -d "@${_ts}" "+%a %b %-d")"
  write_alarm "$(printf '1\t\t%s\t\tfar alarm' "${_ts}")"
  run_nag
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "${_date},".*"far alarm" ]]
}
