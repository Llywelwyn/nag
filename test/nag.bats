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
