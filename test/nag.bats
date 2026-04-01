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

@test "version shows version" {
  run_nag version
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+\.[0-9]+(_[a-zA-Z0-9]+)*$ ]]
}
