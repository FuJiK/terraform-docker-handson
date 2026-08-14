#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_DIR="${ROOT_DIR}/test-results"
REPORT_FILE="${REPORT_DIR}/report.txt"
JSON_FILE="${REPORT_DIR}/report.json"

mkdir -p "${REPORT_DIR}"
cd "${ROOT_DIR}"

pass=0
fail=0
skip=0

record() {
  local status="$1"
  local name="$2"
  local detail="${3:-}"

  case "${status}" in
    PASS) pass=$((pass + 1)) ;;
    FAIL) fail=$((fail + 1)) ;;
    SKIP) skip=$((skip + 1)) ;;
  esac

  printf '[%s] %s' "${status}" "${name}" >> "${REPORT_FILE}"
  if [[ -n "${detail}" ]]; then
    printf ' - %s' "${detail}" >> "${REPORT_FILE}"
  fi
  printf '\n' >> "${REPORT_FILE}"
}

run_step() {
  local name="$1"
  shift

  if "$@"; then
    record PASS "${name}"
  else
    record FAIL "${name}"
    return 1
  fi
}

: > "${REPORT_FILE}"

if ! docker info >/dev/null 2>&1; then
  record SKIP "docker daemon" "Docker is not running"
  echo "Docker is required for integration tests." >&2
  exit 1
fi

run_step "terraform fmt -check" terraform fmt -check -recursive
run_step "terraform init -backend=false" terraform init -input=false
run_step "terraform validate" terraform validate

if terraform test -json > "${JSON_FILE}.raw" 2>"${REPORT_DIR}/terraform-test.stderr"; then
  record PASS "terraform test"
else
  record FAIL "terraform test" "see test-results/terraform-test.stderr"
fi

terraform apply -auto-approve -input=false >/dev/null

if curl -fsS -o /dev/null "http://localhost:8080"; then
  record PASS "http://localhost:8080 returns 200"
else
  record FAIL "http://localhost:8080 returns 200"
fi

if docker exec web_server ping -c 1 cache_server >/dev/null 2>&1; then
  record PASS "web_server resolves cache_server"
else
  record FAIL "web_server resolves cache_server"
fi

running_count="$(docker ps --format '{{.Names}}' | rg -x 'web_server|cache_server' | wc -l | tr -d ' ')"
if [[ "${running_count}" -eq 2 ]]; then
  record PASS "expected containers are running"
else
  record FAIL "expected containers are running" "found ${running_count}"
fi

terraform output -json > "${REPORT_DIR}/outputs.json"
terraform destroy -auto-approve -input=false >/dev/null

total=$((pass + fail + skip))
if [[ "${total}" -gt 0 ]]; then
  coverage=$((pass * 100 / total))
else
  coverage=0
fi

cat >> "${REPORT_FILE}" <<EOF

Summary
-------
PASS: ${pass}
FAIL: ${fail}
SKIP: ${skip}
Coverage: ${coverage}%

Coverage note
-------------
This is requirements/test coverage for the handson checklist, not source line coverage.
EOF

python3 - <<'PY' "${REPORT_FILE}" "${JSON_FILE}" "${pass}" "${fail}" "${skip}" "${coverage}"
import json
import pathlib
import sys

report_file, json_file, passed, failed, skipped, coverage = sys.argv[1:7]
raw = pathlib.Path(json_file + ".raw")
entries = []
if raw.exists() and raw.read_text().strip():
    for line in raw.read_text().splitlines():
        entries.append(json.loads(line))

pathlib.Path(json_file).write_text(
    json.dumps(
        {
            "summary": {
                "pass": int(passed),
                "fail": int(failed),
                "skip": int(skipped),
                "coverage_percent": int(coverage),
                "coverage_type": "requirements",
            },
            "terraform_test_events": entries,
            "report": pathlib.Path(report_file).read_text(),
        },
        indent=2,
        ensure_ascii=False,
    )
    + "\n"
)
PY

cat "${REPORT_FILE}"

if [[ "${fail}" -gt 0 ]]; then
  exit 1
fi
