#!/usr/bin/env bash
# Install on web-01 as /usr/local/bin/release (owned by root, mode 755).
# The pipeline calls: ssh deploy@web-01 release <sha>
# deploy needs one sudoers rule:  deploy ALL=(root) NOPASSWD: /usr/bin/systemctl restart invoice
set -euo pipefail

SHA="${1:?usage: release <commit-sha>}"
[[ "$SHA" =~ ^[0-9a-f]{7,40}$ ]] || { echo "release: bad sha '$SHA'" >&2; exit 2; }

APP=/srv/invoice
NEW="$APP/releases/$SHA"
PREV="$(readlink -f "$APP/current" 2>/dev/null || true)"
HEALTH="http://localhost:${PORT:-3000}/health"

cd /tmp
sha256sum -c invoice.tar.gz.sha256
echo "release: sha256 OK"

mkdir -p "$NEW"
tar xzf invoice.tar.gz -C "$NEW"
echo "release: unpacked ${SHA:0:7} -> $NEW"

ln -sfn "$NEW" "$APP/current"
echo "release: current -> releases/${SHA:0:7}, restarting"
sudo /usr/bin/systemctl restart invoice

for i in $(seq 1 10); do
	if curl -fsS "$HEALTH" >/dev/null; then
		echo "release: healthy on ${SHA:0:7}"
		rm -f /tmp/invoice.tar.gz /tmp/invoice.tar.gz.sha256
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
