#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# example.sh — helper script invoked by SKILL.md (example-skill).
#
# Generates a minimal NestJS-style resource scaffold (controller, service,
# module, DTOs, spec) for a given resource name under a target directory.
#
# This is a deliberately small example of "how a skill shells out." Replace
# the body with whatever your skill actually does. Keep the I/O contract
# (flags below, exit codes below, stdout shape below) stable so SKILL.md's
# steps stay correct.
#
# Usage:
#   example.sh --target <dir> --name <PascalCase> [--variant minimal|full] [--dry-run]
#
# Exit codes:
#   0  success
#   1  bad inputs (caller's fault)
#   2  filesystem error (target dir missing, name collision, etc.)
#   3  internal error (template missing, unexpected state)
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Default flags ───────────────────────────────────────────────────────────
TARGET=""
NAME=""
VARIANT="minimal"
DRY_RUN=0

# ── Parse args ──────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)   TARGET="${2:?--target needs a value}"; shift 2 ;;
    --name)     NAME="${2:?--name needs a value}";     shift 2 ;;
    --variant)  VARIANT="${2:?--variant needs a value}"; shift 2 ;;
    --dry-run)  DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '4,20p' "$0"
      exit 0
      ;;
    *)  echo "error: unknown flag $1" >&2; exit 1 ;;
  esac
done

# ── Validate inputs ─────────────────────────────────────────────────────────
if [[ -z "${TARGET}" || -z "${NAME}" ]]; then
  echo "error: --target and --name are required" >&2
  exit 1
fi

if [[ ! "${NAME}" =~ ^[A-Z][A-Za-z0-9]+$ ]]; then
  echo "error: --name must be PascalCase (matched against ^[A-Z][A-Za-z0-9]+\$)" >&2
  exit 1
fi

if [[ "${VARIANT}" != "minimal" && "${VARIANT}" != "full" ]]; then
  echo "error: --variant must be 'minimal' or 'full'" >&2
  exit 1
fi

if [[ ! -d "${TARGET}" ]]; then
  echo "error: target directory does not exist: ${TARGET}" >&2
  exit 2
fi

# Lowercase name for filenames.
NAME_LOWER="$(echo "${NAME}" | tr '[:upper:]' '[:lower:]')"

# Files we would create. Keep this list in sync with SKILL.md's Steps §3.
FILES=(
  "${TARGET}/${NAME_LOWER}.controller.ts"
  "${TARGET}/${NAME_LOWER}.service.ts"
  "${TARGET}/${NAME_LOWER}.module.ts"
  "${TARGET}/dto/create-${NAME_LOWER}.dto.ts"
  "${TARGET}/dto/update-${NAME_LOWER}.dto.ts"
)
if [[ "${VARIANT}" == "full" ]]; then
  FILES+=(
    "${TARGET}/entities/${NAME_LOWER}.entity.ts"
    "${TARGET}/${NAME_LOWER}.repository.ts"
  )
fi
# Always include a spec.
TEST_FILE="tests/${NAME_LOWER}/${NAME_LOWER}.service.spec.ts"
FILES+=("${TEST_FILE}")

# ── Dry-run path: print and exit ────────────────────────────────────────────
if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "would create (${#FILES[@]} files):"
  for f in "${FILES[@]}"; do
    echo "  + ${f}"
  done
  exit 0
fi

# ── Real path: collision check, create dirs, write files ────────────────────
for f in "${FILES[@]}"; do
  if [[ -e "${f}" ]]; then
    echo "error: refusing to overwrite existing file: ${f}" >&2
    exit 2
  fi
done

# Templates are inlined here for simplicity. In a real skill, prefer a
# templates/ subdir of files you copy + sed.
write_controller () {
  cat > "${TARGET}/${NAME_LOWER}.controller.ts" <<EOF
import { Controller } from "@nestjs/common";
import { ${NAME}Service } from "./${NAME_LOWER}.service";

@Controller("${NAME_LOWER}")
export class ${NAME}Controller {
  constructor(private readonly service: ${NAME}Service) {}
}
EOF
}

write_service () {
  cat > "${TARGET}/${NAME_LOWER}.service.ts" <<EOF
import { Injectable } from "@nestjs/common";

@Injectable()
export class ${NAME}Service {
  // TODO: implement
}
EOF
}

write_module () {
  cat > "${TARGET}/${NAME_LOWER}.module.ts" <<EOF
import { Module } from "@nestjs/common";
import { ${NAME}Controller } from "./${NAME_LOWER}.controller";
import { ${NAME}Service } from "./${NAME_LOWER}.service";

@Module({
  controllers: [${NAME}Controller],
  providers: [${NAME}Service],
})
export class ${NAME}Module {}
EOF
}

write_dto () {
  mkdir -p "${TARGET}/dto"
  cat > "${TARGET}/dto/create-${NAME_LOWER}.dto.ts" <<EOF
export class Create${NAME}Dto {
  // TODO: fields
}
EOF
  cat > "${TARGET}/dto/update-${NAME_LOWER}.dto.ts" <<EOF
export class Update${NAME}Dto {
  // TODO: fields
}
EOF
}

write_spec () {
  mkdir -p "$(dirname "${TEST_FILE}")"
  cat > "${TEST_FILE}" <<EOF
import { ${NAME}Service } from "../../src/${NAME_LOWER}/${NAME_LOWER}.service";

describe("${NAME}Service", () => {
  it("constructs", () => {
    const svc = new ${NAME}Service();
    expect(svc).toBeDefined();
  });
});
EOF
}

write_controller
write_service
write_module
write_dto
if [[ "${VARIANT}" == "full" ]]; then
  mkdir -p "${TARGET}/entities"
  cat > "${TARGET}/entities/${NAME_LOWER}.entity.ts" <<EOF
export class ${NAME} {
  id!: string;
}
EOF
  cat > "${TARGET}/${NAME_LOWER}.repository.ts" <<EOF
import { Injectable } from "@nestjs/common";
import { ${NAME} } from "./entities/${NAME_LOWER}.entity";

@Injectable()
export class ${NAME}Repository {
  // TODO: data access
}
EOF
fi
write_spec

echo "created ${#FILES[@]} files:"
for f in "${FILES[@]}"; do
  echo "  + ${f}"
done
