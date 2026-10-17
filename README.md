# invoice-svc · Session 4 practice

A tiny invoice API (`/health`, `/version`, `/invoices/:id`) and the Session 4 "Nothing Ships by Hand" pipeline.

```
npm ci && npm test && npm run build && npm start   # http://localhost:3000
```

## The pipeline

| Stage | Where | Corrective action |
|---|---|---|
| Build & test on every push and PR | `ci.yml` → `build-test` | CA-2 |
| Dependency gate (Trivy, HIGH/CRITICAL fails) | `ci.yml` → `dependency-scan` | CA-3 |
| Pull requests only, checks required | branch protection (below) | CA-1, CA-3 |
| Build once on a runner + SHA-256 | `release.yml` → `build` | CA-4, CA-5 |
| Deploy only from the pipeline | `release.yml` → `deploy` | CA-6, CA-7 |
| Health check + automatic rollback | `deploy/release.sh` on web-01 | CA-6 |

Trivy is pinned to v0.75.0, and the tarball's SHA-256 is checked before it runs.

## Turn the checks into a gate (Lab 4)

Settings → Branches → add a classic branch protection rule for `main`:

1. Require a pull request before merging (untick "Require approvals" if you work solo)
2. Require status checks to pass: `build-test` and `dependency-scan`
3. Do not allow bypassing the above settings

The checks only appear in the search box after they have run once. On GitHub Free this needs a public repo.

## Enable the deploy job (Lab 7)

`deploy` is skipped until `WEB01_HOST` is set.

1. `ssh-keygen -t ed25519 -f pipeline` (no passphrase); put `pipeline.pub` as the only line in `/home/deploy/.ssh/authorized_keys` on web-01
2. On web-01: install `deploy/release.sh` as `/usr/local/bin/release`, `deploy/invoice.service` as the systemd unit, and the sudoers rule from the top of `release.sh`
3. Settings → Environments → `production`: deployment branches = `main` only
   - secret `DEPLOY_KEY` = contents of `pipeline` (then delete the local file)
   - variable `WEB01_HOST` = web-01's address
   - variable `WEB01_HOSTKEY` = output of `ssh-keyscan <WEB01_HOST>`, run from a network you trust
4. Merge anything to `main`, then `curl http://<WEB01_HOST>/version`

## Try it

- **Red build:** change an expected total in `test/invoice.test.js`
- **Red gate:** `npm install lodash@4.17.20` → CVE-2021-23337 fails `dependency-scan`
- **Rollback:** set the port to 3001 in `src/config.js`; tests pass, the health check fails, `release` rolls back
- **Finale race:** the invoice footer says "Acme Corp"; it should say "Acme Ltd"
