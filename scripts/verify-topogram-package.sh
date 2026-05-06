#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_ROOT="$ROOT_DIR/.tmp/topogram-package"
NPM_CACHE_DIR="$ROOT_DIR/.tmp/npm-cache"
default_cli_package_spec() {
  local version
  version="$(cat "$ROOT_DIR/topogram-cli.version")"
  if [[ -z "$version" ]]; then
    echo "topogram-cli.version must contain the Topogram CLI version used by package verification." >&2
    exit 1
  fi
  echo "@topogram/cli@$version"
}

CLI_PACKAGE_SPEC="${TOPOGRAM_CLI_PACKAGE_SPEC:-$(default_cli_package_spec)}"

if [[ -d "$ROOT_DIR/implementation" ]]; then
  echo "Pure topogram packages must not contain implementation/." >&2
  exit 1
fi

mkdir -p "$WORK_ROOT" "$NPM_CACHE_DIR"
export npm_config_cache="$NPM_CACHE_DIR"

RUN_DIR="$(mktemp -d "$WORK_ROOT/run.XXXXXX")"
PACK_DIR="$RUN_DIR/pack"
UNPACK_DIR="$RUN_DIR/unpacked"
CONSUMER_DIR="$RUN_DIR/consumer"
FAKE_BIN_DIR="$RUN_DIR/fake-bin"
CATALOG_FILE="$RUN_DIR/topograms.catalog.json"
COPY_TARGET="$RUN_DIR/copied-hello"
mkdir -p "$PACK_DIR" "$UNPACK_DIR" "$CONSUMER_DIR" "$FAKE_BIN_DIR"

echo "Packing @topogram/topogram-hello..."
PACK_NAME="$(cd "$ROOT_DIR" && npm pack --silent --pack-destination "$PACK_DIR" | tail -n 1)"
PACKAGE_TARBALL="$PACK_DIR/$PACK_NAME"

if [[ ! -f "$PACKAGE_TARBALL" ]]; then
  echo "Expected package tarball was not created: $PACKAGE_TARBALL" >&2
  exit 1
fi

if tar -tzf "$PACKAGE_TARBALL" | awk -F/ '{ print $NF }' | grep -E '^(\.env.*|\.npmrc|\.DS_Store|.*\.(pem|key|p8|p12|pfx)|id_(rsa|dsa|ecdsa|ed25519)(\.pub)?|secrets\..*|credentials\..*)$' >/tmp/topogram-hello-env-files.$$; then
  echo "Topogram package must not publish restricted local or secret files:" >&2
  cat /tmp/topogram-hello-env-files.$$ >&2
  rm -f /tmp/topogram-hello-env-files.$$
  exit 1
fi
rm -f /tmp/topogram-hello-env-files.$$

tar -xzf "$PACKAGE_TARBALL" -C "$UNPACK_DIR"
PACKAGE_ROOT="$UNPACK_DIR/package"

if [[ -d "$PACKAGE_ROOT/implementation" ]]; then
  echo "Packed package must not contain implementation/." >&2
  exit 1
fi
if [[ ! -d "$PACKAGE_ROOT/topogram" ]]; then
  echo "Packed package is missing topogram/." >&2
  exit 1
fi
if [[ ! -f "$PACKAGE_ROOT/topogram.project.json" ]]; then
  echo "Packed package is missing topogram.project.json." >&2
  exit 1
fi

cat > "$CATALOG_FILE" <<'JSON'
{
  "version": "0.1",
  "entries": [
    {
      "id": "hello",
      "kind": "topogram",
      "package": "@topogram/topogram-hello",
      "defaultVersion": "0.1.1",
      "description": "Neutral Hello/Greeting Topogram package.",
      "tags": ["hello", "greeting", "topogram"],
      "trust": {
        "scope": "@topogram",
        "includesExecutableImplementation": false
      }
    }
  ]
}
JSON

cat > "$FAKE_BIN_DIR/npm" <<'JS'
#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
const args = process.argv.slice(2);

function packageNameFromSpec(spec) {
  if (spec.startsWith("@")) {
    const [scope, rest] = spec.split("/");
    const versionIndex = rest.indexOf("@");
    return path.join(scope, versionIndex >= 0 ? rest.slice(0, versionIndex) : rest);
  }
  const versionIndex = spec.indexOf("@");
  return versionIndex >= 0 ? spec.slice(0, versionIndex) : spec;
}

if (args[0] === "install") {
  const prefix = args[args.indexOf("--prefix") + 1];
  const spec = args[args.length - 1];
  if (spec !== "@topogram/topogram-hello@0.1.1") {
    process.stderr.write(`Unexpected fake npm install spec: ${spec}\n`);
    process.exit(1);
  }
  const source = process.env.FAKE_TOPOGRAM_HELLO_PACKAGE_ROOT;
  const target = path.join(prefix, "node_modules", packageNameFromSpec(spec));
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.cpSync(source, target, { recursive: true });
  process.exit(0);
}

process.stderr.write(`Unexpected fake npm command: ${args.join(" ")}\n`);
process.exit(1);
JS
chmod +x "$FAKE_BIN_DIR/npm"

echo "Installing Topogram CLI ($CLI_PACKAGE_SPEC) into a consumer project..."
(
	  cd "$CONSUMER_DIR"
	  npm init -y >/dev/null
	  npm install "$CLI_PACKAGE_SPEC" >/dev/null
	)

TOPOGRAM_BIN="$CONSUMER_DIR/node_modules/.bin/topogram"
if [[ ! -x "$TOPOGRAM_BIN" ]]; then
  echo "Expected topogram binary was not installed: $TOPOGRAM_BIN" >&2
  exit 1
fi

echo "Checking source package project config..."
"$TOPOGRAM_BIN" check "$ROOT_DIR" >/dev/null

echo "Checking local catalog fixture..."
"$TOPOGRAM_BIN" catalog check "$CATALOG_FILE" >/dev/null

echo "Copying topogram package through catalog..."
PATH="$FAKE_BIN_DIR:$PATH" \
FAKE_TOPOGRAM_HELLO_PACKAGE_ROOT="$PACKAGE_ROOT" \
  "$TOPOGRAM_BIN" catalog copy hello "$COPY_TARGET" --catalog "$CATALOG_FILE" >/dev/null

if [[ ! -d "$COPY_TARGET/topogram" ]]; then
  echo "Expected copied topogram/ directory." >&2
  exit 1
fi
if [[ ! -f "$COPY_TARGET/topogram.project.json" ]]; then
  echo "Expected copied topogram.project.json." >&2
  exit 1
fi
if [[ -d "$COPY_TARGET/implementation" ]]; then
  echo "Catalog copy must not create implementation/." >&2
  exit 1
fi

"$TOPOGRAM_BIN" check "$COPY_TARGET" >/dev/null

echo
echo "Topogram package smoke passed: $PACKAGE_TARBALL"
