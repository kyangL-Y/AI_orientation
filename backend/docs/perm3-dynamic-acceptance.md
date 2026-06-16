# PERM-3 Dynamic Acceptance Guide

This guide validates the permission refresh lifecycle for role grant/revoke.

## Scope

The script checks all required closure points:

1. Before grant, target user cannot call protected endpoint.
2. Grant role succeeds.
3. Old user token is denied after grant (forced logout effective).
4. Re-login after grant restores access.
5. Revoke role succeeds.
6. Old user token is denied after revoke (forced logout effective).
7. Re-login after revoke is denied again.

## Script

- `scripts/perm3_dynamic_acceptance.py`
- Env template: `scripts/perm3_dynamic_acceptance.env.example`

## Prerequisites

1. Backend is reachable.
2. You have:
   - admin credentials (or admin token),
   - target user credentials (or initial token),
   - role selector (`roleId` preferred).
3. If captcha is enabled, use token mode:
   - set `PERM3_ADMIN_TOKEN`,
   - set `PERM3_USER_TOKEN`.

## Quick Start

1. Copy template and fill values:

```powershell
Copy-Item scripts/perm3_dynamic_acceptance.env.example scripts/perm3_dynamic_acceptance.env
```

2. Load env and run:

```powershell
Get-Content scripts/perm3_dynamic_acceptance.env | ForEach-Object {
  if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
  $parts = $_.Split('=', 2)
  if ($parts.Count -eq 2) { [Environment]::SetEnvironmentVariable($parts[0], $parts[1], 'Process') }
}

python scripts/perm3_dynamic_acceptance.py
```

## Output

- JSON report: `docs/perm3_dynamic_report.json`
- Markdown report: `docs/perm3_dynamic_report.md`

`RESULT: PASS` means PERM-3 dynamic closure is complete.

## Recommended Probe Endpoint

Default probe (safe read):

- `GET /train/exam/admin/list?pageNum=1&pageSize=1`

If you need strict verification for a specific permission, override:

- `PERM3_PROBE_METHOD`
- `PERM3_PROBE_PATH`
- `PERM3_PROBE_BODY`
- `PERM3_EXPECTED_PERM`

## Notes

- The script does not print tokens.
- If login fails with captcha enabled, switch to token mode.
