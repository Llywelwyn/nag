#!/usr/bin/env bats

load test_helper

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
  [[ "${output}" =~ "( version | -v )" ]]
}

@test "help stop shows stop usage" {
  run_nag help stop
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Usage:" ]]
  [[ "${output}" =~ "stop <id>" ]]
}

@test "help skip shows skip usage" {
  run_nag help skip
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Usage:" ]]
  [[ "${output}" =~ "skip <id>" ]]
}

@test "help every shows every usage" {
  run_nag help every
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Usage:" ]]
  [[ "${output}" =~ "every <rules> <time> <message...>" ]]
}

@test "help check shows check usage" {
  run_nag help check
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ "Usage:" ]]
  [[ "${output}" =~ "check" ]]
}

@test "version shows current version" {
  run_nag version
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+\.[0-9]+(_[a-zA-Z0-9]+)*$ ]]
}

@test "NAG_DEFAULT overrides the default subcommand" {
  NAG_DEFAULT="version" run_nag
  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]+\.[0-9]+(_[a-zA-Z0-9]+)*$ ]]
}
