# test/test_helper.bash
# Shared setup/teardown for nag tests.

_NAG="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)/nag"

setup() {
  export NAG_DIR
  NAG_DIR="$(mktemp -d)"
  export NAG_CMD="true"
  export NAG_SOUND=""
}

teardown() {
  rm -rf "${NAG_DIR}"
}

run_nag() {
  run "${_NAG}" --yes "$@"
}

write_alarm() {
  mkdir -p "${NAG_DIR}"
  printf "%s\\n" "$1" >> "${NAG_DIR}/alarms"
}
