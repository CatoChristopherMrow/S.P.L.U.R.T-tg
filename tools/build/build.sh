#!/bin/sh
set -e
cd "$(dirname "$0")/../.."
if [ -f "dynamic_modules.toml" ] && [ -f "tools/dynamic_modules/prepare.py" ]; then
	python3 tools/dynamic_modules/prepare.py
fi
cd "tools/build"
exec ../bootstrap/javascript.sh build.ts "$@"
