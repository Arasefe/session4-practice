#!/usr/bin/env bash
# Install on web-01 as /usr/local/bin/release (owned by root, mode 755).
# The pipeline uploads to ~deploy/incoming/ (mode 700) and calls:
#   ssh deploy@web-01 release <commit-sha> <tarball-sha256>
# deploy needs one sudoers rule:  deploy ALL=(root) NOPASSWD: /usr/bin/systemctl restart invoice
set -euo pipefail

SHA="${1:?usage: release <commit-sha> <tarball-sha256>}"
EXPECTED="${2:?usage: release <commit-sha> <tarball-sha256>}"
[[ "$SHA" =~ ^[0-9a-f]{7,40}$ ]] || { echo "release: bad commit sha '$SHA'" >&2; exit 2; }
[[ "$EXPECTED" =~ ^[0-9a-f]{64}$ ]] || { echo "release: bad sha256 '$EXPECTED'" >&2; exit 2; }

APP=/srv/invoice
NEW="$APP/releases/$SHA"
PREV="$(readlink -f "$APP/current" 2>/dev/null || true)"
HEALTH="http://localhost:${PORT:-3000}/health"
INCOMING="$HOME/incoming"
UPLOAD="$INCOMING/invoice.tar.gz"

# Only accept a regular file, owned by us, in a directory only we can open.
[[ -d "$INCOMING" && ! -L "$INCOMING" && "$(stat -c '%U %a' "$INCOMING")" == "$(id -un) 700" ]] \
	|| { echo "release: $INCOMING must be a real directory owned by $(id -un), mode 700" >&2; exit 2; }
[[ -f "$UPLOAD" && ! -L "$UPLOAD" && "$(stat -c %U "$UPLOAD")" == "$(id -un)" ]] \
	|| { echo "release: $UPLOAD missing, a symlink, or not owned by $(id -un)" >&2; exit 2; }

# Check and unpack the same private copy, so nothing can swap it in between.
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cp "$UPLOAD" "$WORK/invoice.tar.gz"
rm -f "$UPLOAD"
echo "$EXPECTED  $WORK/invoice.tar.gz" | sha256sum -c --status \
	|| { echo "release: sha256 mismatch, refusing to release" >&2; exit 1; }
echo "release: sha256 OK"

mkdir -p "$NEW"
tar xzf "$WORK/invoice.tar.gz" -C "$NEW"
echo "release: unpacked ${SHA:0:7} -> $NEW"

ln -sfn "$NEW" "$APP/current"
echo "release: current -> releases/${SHA:0:7}, restarting"
sudo /usr/bin/systemctl restart invoice

for i in $(seq 1 10); do
	if curl -fsS "$HEALTH" >/dev/null; then
		echo "release: healthy on ${SHA:0:7}"
		exit 0
	fi
	sleep 2
done

echo "release: health check failed 10/10 ($HEALTH)" >&2
if [[ -n "$PREV" && -d "$PREV" ]]; then
	ln -sfn "$PREV" "$APP/current"
	echo "release: rolling back -> releases/$(basename "$PREV")" >&2
	sudo /usr/bin/systemctl restart invoice
fi
exit 1
