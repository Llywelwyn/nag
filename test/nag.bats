#!/usr/bin/env bats

load test_helper

@test "list with no alarms prints nothing-to-nag message" {
  run_nag
  [ "${status}" -eq 0 ]
  [ "${output}" = "Nothing to nag about." ]
}

@test "help shows usage" {
  run_nag help
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "<time> <message...>" ]]
  [[ "${output}" =~ "every <rules> <time> <message...>" ]]
  [[ "${output}" =~ "stop <id>" ]]
  [[ "${output}" =~ "skip <id>" ]]
  [[ "${output}" =~ "check" ]]
  [[ "${output}" =~ "help [<subcommand>]" ]]
  [[ "${output}" =~ "Options:" ]]
}

@test "help list shows list usage" {
  run_nag help list
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Usage:" ]]
  [[ "${output}" =~ "nag list" ]]
}

@test "help at shows at usage" {
  run_nag help at
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Usage:" ]]
  [[ "${output}" =~ "[at] <time> <message...>" ]]
}

@test "help version shows version usage" {
  run_nag help version
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Usage:" ]]
  [[ "${output}" =~ "( version | --version )" ]]
}

@test "version shows current version" {
  run_nag version
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+\.[0-9]+(_[a-zA-Z0-9]+)*$ ]]
}

@test "at creates a one-shot alarm" {
  run_nag at "tomorrow 3pm" "take a break"
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "[1] Tomorrow, 3pm — take a break" ]]
  [ -f "${NAG_PATH}" ]
  [ "$(wc -l < "${NAG_PATH}")" -eq 1 ]
  # Verify TSV structure: id<TAB>timestamp<TAB><TAB>message
  local _line
  _line="$(cat "${NAG_PATH}")"
  [[ "${_line}" =~ ^1$'\t'[0-9]+$'\t'$'\t'take\ a\ break$ ]]
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

@test "at with explicit past date fails" {
  run_nag at "yesterday 3pm" "too late"
  [ "${status}" -eq 1 ]
}

@test "at without message fails" {
  run_nag at "tomorrow 3pm"
  [ "${status}" -eq 1 ]
}

@test "list is the default subcommand" {
  run_nag
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Nothing to nag about" ]]
}

@test "NAG_DEFAULT overrides the default subcommand" {
  NAG_DEFAULT="version" run_nag
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+\.[0-9]+(_[a-zA-Z0-9]+)*$ ]]
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

@test "help stop shows stop usage" {
  run_nag help stop
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Usage:" ]]
  [[ "${output}" =~ "stop <id>" ]]
}

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

@test "help every shows every usage" {
  run_nag help every
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Usage:" ]]
  [[ "${output}" =~ "every <rules> <time> <message...>" ]]
}

@test "every creates a repeating alarm" {
  run_nag every weekday "tomorrow 3pm" standup meeting
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "[1]" ]]
  [[ "${output}" =~ "(weekday)" ]]
  [[ "${output}" =~ "standup meeting" ]]
  # Verify TSV has rule in field 3.
  local _rule
  _rule="$(cut -f3 "${NAG_PATH}")"
  [ "${_rule}" = "weekday" ]
}

@test "every with comma-separated rules" {
  run_nag every "tuesday,thursday" "tomorrow 3pm" standup
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "(tuesday, thursday)" ]]
  grep -q "tuesday,thursday" "${NAG_PATH}"
}

@test "every snaps to next matching day" {
  # "weekend 3pm" should snap to Saturday or Sunday, not a weekday.
  run_nag every weekend "tomorrow 3pm" relax
  [ "${status}" -eq 0 ]
  local _ts _dow
  _ts="$(cut -f2 "${NAG_PATH}")"
  _dow="$(date -d "@${_ts}" +%u)"
  # Day-of-week should be 6 (Sat) or 7 (Sun).
  [[ "${_dow}" == "6" || "${_dow}" == "7" ]]
}

@test "every with invalid rule fails" {
  run_nag every "invalid_rule" "tomorrow 3pm" some message
  [ "${status}" -eq 1 ]
}

@test "every without message fails" {
  run_nag every weekday "tomorrow 3pm"
  [ "${status}" -eq 1 ]
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
