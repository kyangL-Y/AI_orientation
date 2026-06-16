#!/usr/bin/env python3
"""
PERM-3 dynamic acceptance checker.

This script validates the permission refresh lifecycle:
1) Before grant, target user cannot access the protected endpoint.
2) Grant role -> old token is invalid.
3) Re-login -> access is restored.
4) Revoke role -> old token is invalid again.
5) Re-login -> access is denied again.

Notes:
- If captcha is enabled, credential login is not supported automatically.
  Use token mode in that case.
- Designed for Python 3.8+ (no third-party dependencies).
"""

import argparse
import datetime as dt
import json
import os
import socket
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass, asdict
from typing import Any, Dict, List, Optional


@dataclass
class HttpResult:
    method: str
    path: str
    url: str
    http_status: int
    json_code: Optional[int]
    json_msg: str
    body_text: str
    error: str = ""


@dataclass
class StepResult:
    name: str
    expected: str
    passed: bool
    actual: str
    evidence: Dict[str, Any]


@dataclass
class RedisConfig:
    host: str = "127.0.0.1"
    port: int = 6379
    db: int = 0
    password: str = ""
    timeout: int = 5
    captcha_key_prefix: str = "captcha_codes:"


def env_bool(name: str, default: bool = False) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "y", "on"}


def normalize_path(prefix: str, path: str) -> str:
    if path.startswith("http://") or path.startswith("https://"):
        return path
    pfx = ""
    if prefix:
        pfx = "/" + prefix.strip("/")
    return pfx + "/" + path.lstrip("/")


def build_url(base_url: str, path: str) -> str:
    if path.startswith("http://") or path.startswith("https://"):
        return path
    return base_url.rstrip("/") + path


def call_api(
    base_url: str,
    method: str,
    path: str,
    token: Optional[str] = None,
    payload: Optional[Dict[str, Any]] = None,
    timeout: int = 15,
) -> HttpResult:
    max_body = int(os.getenv("PERM3_MAX_BODY", "200000") or "200000")
    url = build_url(base_url, path)
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token

    data = None
    if payload is not None:
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    elif method.upper() in {"POST", "PUT", "PATCH"}:
        data = b""

    req = urllib.request.Request(url=url, data=data, headers=headers, method=method.upper())
    raw = ""
    http_status = 0
    err = ""
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            http_status = int(resp.getcode())
            raw = resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as e:
        http_status = int(e.code)
        raw = e.read().decode("utf-8", errors="replace")
        err = str(e)
    except Exception as e:  # noqa: BLE001
        err = str(e)

    body = None
    json_code = None
    json_msg = ""
    if raw:
        try:
            body = json.loads(raw)
            if isinstance(body, dict):
                code_val = body.get("code")
                if isinstance(code_val, int):
                    json_code = code_val
                elif isinstance(code_val, str) and code_val.isdigit():
                    json_code = int(code_val)
                msg_val = body.get("msg")
                if msg_val is not None:
                    json_msg = str(msg_val)
        except Exception:  # noqa: BLE001
            pass

    if body is None:
        json_msg = json_msg or raw[:200]

    return HttpResult(
        method=method.upper(),
        path=path,
        url=url,
        http_status=http_status,
        json_code=json_code,
        json_msg=json_msg,
        body_text=raw[:max_body],
        error=err,
    )


def is_business_success(resp: HttpResult) -> bool:
    if resp.error and resp.http_status == 0:
        return False
    if resp.http_status not in (200, 201, 204):
        return False
    if resp.json_code is None:
        return True
    return resp.json_code == 200


def is_auth_denied(resp: HttpResult) -> bool:
    if resp.http_status in (401, 403):
        return True
    if resp.json_code in (401, 403):
        return True
    msg = (resp.json_msg or "").lower()
    denial_markers = ["权限", "forbidden", "unauthorized", "认证失败", "token", "未登录"]
    return any(marker in msg for marker in denial_markers) and not is_business_success(resp)


def parse_rows(resp: HttpResult) -> List[Dict[str, Any]]:
    try:
        body = json.loads(resp.body_text)
    except Exception:  # noqa: BLE001
        return []
    if not isinstance(body, dict):
        return []
    rows = body.get("rows")
    return rows if isinstance(rows, list) else []


def parse_token(resp: HttpResult) -> Optional[str]:
    try:
        body = json.loads(resp.body_text)
    except Exception:  # noqa: BLE001
        return None
    if not isinstance(body, dict):
        return None
    token = body.get("token")
    if isinstance(token, str) and token:
        return token
    data = body.get("data")
    if isinstance(data, dict):
        token = data.get("token")
        if isinstance(token, str) and token:
            return token
    return None


def parse_permissions(resp: HttpResult) -> List[str]:
    try:
        body = json.loads(resp.body_text)
    except Exception:  # noqa: BLE001
        return []
    if not isinstance(body, dict):
        return []
    perms = body.get("permissions")
    if isinstance(perms, list):
        return [str(p) for p in perms]
    if isinstance(perms, set):
        return [str(p) for p in perms]
    return []


def parse_json_dict(resp: HttpResult) -> Dict[str, Any]:
    try:
        body = json.loads(resp.body_text)
    except Exception:  # noqa: BLE001
        return {}
    return body if isinstance(body, dict) else {}


def _redis_encode_cmd(args: List[str]) -> bytes:
    parts = [a.encode("utf-8") for a in args]
    out = f"*{len(parts)}\r\n".encode("ascii")
    for p in parts:
        out += f"${len(p)}\r\n".encode("ascii") + p + b"\r\n"
    return out


def _redis_readline(fp) -> bytes:
    line = fp.readline()
    if not line:
        raise RuntimeError("redis: unexpected EOF")
    if not line.endswith(b"\r\n"):
        raise RuntimeError("redis: invalid line ending")
    return line[:-2]


def _redis_parse_reply(fp) -> Any:
    lead = fp.read(1)
    if not lead:
        raise RuntimeError("redis: empty reply")
    if lead == b"+":
        return _redis_readline(fp).decode("utf-8", errors="replace")
    if lead == b"-":
        raise RuntimeError(_redis_readline(fp).decode("utf-8", errors="replace"))
    if lead == b":":
        return int(_redis_readline(fp))
    if lead == b"$":
        n = int(_redis_readline(fp))
        if n == -1:
            return None
        data = fp.read(n)
        if len(data) != n:
            raise RuntimeError("redis: short read")
        tail = fp.read(2)
        if tail != b"\r\n":
            raise RuntimeError("redis: invalid bulk tail")
        return data
    if lead == b"*":
        n = int(_redis_readline(fp))
        if n == -1:
            return None
        return [_redis_parse_reply(fp) for _ in range(n)]
    raise RuntimeError(f"redis: unknown reply type: {lead!r}")


def redis_get(conf: RedisConfig, key: str) -> Optional[str]:
    sock = socket.create_connection((conf.host, conf.port), timeout=conf.timeout)
    sock.settimeout(conf.timeout)
    fp = sock.makefile("rb")
    try:
        if conf.password:
            sock.sendall(_redis_encode_cmd(["AUTH", conf.password]))
            _redis_parse_reply(fp)  # OK
        if conf.db:
            sock.sendall(_redis_encode_cmd(["SELECT", str(conf.db)]))
            _redis_parse_reply(fp)  # OK
        sock.sendall(_redis_encode_cmd(["GET", key]))
        reply = _redis_parse_reply(fp)
        if reply is None:
            return None
        if isinstance(reply, bytes):
            return reply.decode("utf-8", errors="replace")
        if isinstance(reply, str):
            return reply
        return str(reply)
    finally:
        try:
            fp.close()
        except Exception:  # noqa: BLE001
            pass
        try:
            sock.close()
        except Exception:  # noqa: BLE001
            pass


def solve_captcha_via_redis(base_url: str, captcha_path: str, redis_conf: RedisConfig) -> Dict[str, str]:
    resp = call_api(base_url, "GET", captcha_path)
    if not is_business_success(resp):
        raise RuntimeError(f"captcha fetch failed: {resp.http_status}/{resp.json_code} {resp.json_msg or resp.error}")
    body = parse_json_dict(resp)
    uuid = body.get("uuid") or ""
    if not isinstance(uuid, str) or not uuid:
        data = body.get("data")
        if isinstance(data, dict):
            uuid = str(data.get("uuid") or "")
    if not uuid:
        raise RuntimeError("captcha fetch failed: uuid missing")
    key = redis_conf.captcha_key_prefix + uuid
    code = redis_get(redis_conf, key)
    if not code:
        raise RuntimeError(f"captcha code not found in redis for uuid={uuid}")
    # RedisTemplate may serialize String as JSON, storing quotes in Redis (e.g. "\"1234\"").
    # Normalize it back to the plain captcha code expected by validateCaptcha().
    code = code.strip()
    if len(code) >= 2 and code[0] == '"' and code[-1] == '"':
        try:
            code = str(json.loads(code))
        except Exception:  # noqa: BLE001
            code = code.strip('"')
    return {"uuid": uuid, "code": code}


def get_captcha_status(base_url: str, captcha_path: str) -> Optional[bool]:
    resp = call_api(base_url, "GET", captcha_path)
    if not is_business_success(resp):
        return None
    try:
        body = json.loads(resp.body_text)
    except Exception:  # noqa: BLE001
        return None
    if isinstance(body, dict) and "captchaEnabled" in body:
        return bool(body.get("captchaEnabled"))
    return None


def login_by_password(
    base_url: str,
    login_path: str,
    captcha_path: str,
    username: str,
    password: str,
    tenant_id: str = "",
    captcha_solver: str = "none",
    redis_conf: Optional[RedisConfig] = None,
) -> str:
    captcha_enabled = get_captcha_status(base_url, captcha_path)

    payload: Dict[str, Any] = {
        "username": username,
        "password": password,
        "code": "",
        "uuid": "",
    }
    if tenant_id:
        payload["tenantId"] = tenant_id
    solver = (captcha_solver or "none").strip().lower()

    # First try: no captcha (some deployments intentionally skip captcha validation if code/uuid are absent).
    resp = call_api(base_url, "POST", login_path, payload=payload)
    token = parse_token(resp)
    if token:
        return token

    # Second try: fetch captcha and solve via Redis (when enforced).
    if captcha_enabled and solver == "redis":
        if redis_conf is None:
            raise RuntimeError("captcha solver=redis requires redis config")
        solved = solve_captcha_via_redis(base_url, captcha_path, redis_conf)
        payload["code"] = solved["code"]
        payload["uuid"] = solved["uuid"]
        resp = call_api(base_url, "POST", login_path, payload=payload)
        token = parse_token(resp)
        if token:
            return token

    raise RuntimeError(
        f"login failed: status={resp.http_status}, code={resp.json_code}, msg={resp.json_msg or resp.error}"
    )


def reset_user_password(
    base_url: str,
    api_prefix: str,
    admin_token: str,
    user_id: int,
    new_password: str,
    reset_path: str,
) -> HttpResult:
    path = normalize_path(api_prefix, reset_path)
    payload = {"userId": user_id, "password": new_password}
    return call_api(base_url, "PUT", path, token=admin_token, payload=payload)


def resolve_user_id(base_url: str, api_prefix: str, admin_token: str, username: str) -> int:
    q = urllib.parse.urlencode({"pageNum": 1, "pageSize": 50, "userName": username})
    path = normalize_path(api_prefix, "/system/user/list") + "?" + q
    resp = call_api(base_url, "GET", path, token=admin_token)
    if not is_business_success(resp):
        raise RuntimeError(f"query user list failed: {resp.http_status}/{resp.json_code} {resp.json_msg}")
    rows = parse_rows(resp)
    if not rows:
        raise RuntimeError(f"user not found: {username}")
    exact = [r for r in rows if str(r.get("userName", "")).strip() == username]
    target = exact[0] if exact else rows[0]
    user_id = target.get("userId")
    if not isinstance(user_id, int):
        raise RuntimeError(f"invalid userId for {username}: {user_id}")
    return user_id


def resolve_role_id(
    base_url: str,
    api_prefix: str,
    admin_token: str,
    role_id: int,
    role_key: str,
    role_name: str,
) -> int:
    if role_id > 0:
        return role_id

    query: Dict[str, Any] = {"pageNum": 1, "pageSize": 200}
    if role_key:
        query["roleKey"] = role_key
    if role_name:
        query["roleName"] = role_name
    path = normalize_path(api_prefix, "/system/role/list") + "?" + urllib.parse.urlencode(query)
    resp = call_api(base_url, "GET", path, token=admin_token)
    if not is_business_success(resp):
        raise RuntimeError(f"query role list failed: {resp.http_status}/{resp.json_code} {resp.json_msg}")
    rows = parse_rows(resp)
    if not rows:
        raise RuntimeError("no role matched; set --role-id or --role-key/--role-name")

    target = None
    if role_key:
        for row in rows:
            if str(row.get("roleKey", "")).strip() == role_key:
                target = row
                break
    if target is None and role_name:
        for row in rows:
            if str(row.get("roleName", "")).strip() == role_name:
                target = row
                break
    if target is None:
        target = rows[0]

    rid = target.get("roleId")
    if not isinstance(rid, int):
        raise RuntimeError(f"invalid roleId: {rid}")
    return rid


def compact(resp: HttpResult) -> Dict[str, Any]:
    return {
        "method": resp.method,
        "path": resp.path,
        "http_status": resp.http_status,
        "json_code": resp.json_code,
        "json_msg": resp.json_msg,
        "error": resp.error,
    }


def probe(
    base_url: str,
    api_prefix: str,
    token: str,
    method: str,
    path: str,
    body_text: str,
) -> HttpResult:
    payload = None
    if body_text:
        payload = json.loads(body_text)
    p = normalize_path(api_prefix, path)
    return call_api(base_url, method, p, token=token, payload=payload)


def write_report_json(path: str, data: Dict[str, Any]) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def write_report_md(path: str, data: Dict[str, Any]) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    lines = [
        "# PERM-3 Dynamic Acceptance Report",
        "",
        f"- Time: {data.get('time')}",
        f"- Base URL: {data.get('base_url')}",
        f"- API Prefix: `{data.get('api_prefix')}`",
        f"- Target User: `{data.get('target_username')}` (ID: {data.get('target_user_id')})",
        f"- Role ID: {data.get('role_id')}",
        f"- Expected Permission: `{data.get('expected_perm')}`",
        f"- Overall: {'PASS' if data.get('overall_passed') else 'FAIL'}",
        "",
        "| Step | Expected | Actual | Pass |",
        "|---|---|---|---|",
    ]
    for step in data.get("steps", []):
        ok = "PASS" if step.get("passed") else "FAIL"
        lines.append(
            f"| {step.get('name')} | {step.get('expected')} | {step.get('actual')} | {ok} |"
        )
    if data.get("fatal_error"):
        lines.extend(["", "## Fatal Error", "", f"`{data['fatal_error']}`"])
    lines.append("")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def main() -> int:
    parser = argparse.ArgumentParser(description="PERM-3 dynamic acceptance runner")
    parser.add_argument("--base-url", default=os.getenv("PERM3_BASE_URL", "http://127.0.0.1:9090"))
    parser.add_argument("--api-prefix", default=os.getenv("PERM3_API_PREFIX", ""))

    parser.add_argument("--admin-token", default=os.getenv("PERM3_ADMIN_TOKEN", ""))
    parser.add_argument("--admin-username", default=os.getenv("PERM3_ADMIN_USERNAME", ""))
    parser.add_argument("--admin-password", default=os.getenv("PERM3_ADMIN_PASSWORD", ""))
    parser.add_argument("--admin-tenant-id", default=os.getenv("PERM3_ADMIN_TENANT_ID", ""))
    parser.add_argument("--admin-login-path", default=os.getenv("PERM3_ADMIN_LOGIN_PATH", "/admin/login"))

    parser.add_argument("--user-token", default=os.getenv("PERM3_USER_TOKEN", ""))
    parser.add_argument("--user-username", default=os.getenv("PERM3_USER_USERNAME", ""))
    parser.add_argument("--user-password", default=os.getenv("PERM3_USER_PASSWORD", ""))
    parser.add_argument("--user-tenant-id", default=os.getenv("PERM3_USER_TENANT_ID", ""))
    parser.add_argument("--user-login-path", default=os.getenv("PERM3_USER_LOGIN_PATH", "/login"))

    parser.add_argument("--role-id", type=int, default=int(os.getenv("PERM3_ROLE_ID", "0") or "0"))
    parser.add_argument("--role-key", default=os.getenv("PERM3_ROLE_KEY", ""))
    parser.add_argument("--role-name", default=os.getenv("PERM3_ROLE_NAME", ""))

    parser.add_argument("--expected-perm", default=os.getenv("PERM3_EXPECTED_PERM", "train:exam:edit"))
    parser.add_argument(
        "--probe-path",
        default=os.getenv("PERM3_PROBE_PATH", "/train/exam/admin/list?pageNum=1&pageSize=1"),
    )
    parser.add_argument("--probe-method", default=os.getenv("PERM3_PROBE_METHOD", "GET"))
    parser.add_argument("--probe-body", default=os.getenv("PERM3_PROBE_BODY", ""))

    parser.add_argument(
        "--grant-path",
        default=os.getenv("PERM3_GRANT_PATH", "/system/role/authUser/selectAll"),
    )
    parser.add_argument(
        "--revoke-path",
        default=os.getenv("PERM3_REVOKE_PATH", "/system/role/authUser/cancelAll"),
    )
    parser.add_argument("--captcha-path", default=os.getenv("PERM3_CAPTCHA_PATH", "/captchaImage"))
    parser.add_argument("--getinfo-path", default=os.getenv("PERM3_GETINFO_PATH", "/getInfo"))
    parser.add_argument("--captcha-solver", default=os.getenv("PERM3_CAPTCHA_SOLVER", "none"))
    parser.add_argument("--redis-host", default=os.getenv("PERM3_REDIS_HOST", "127.0.0.1"))
    parser.add_argument("--redis-port", type=int, default=int(os.getenv("PERM3_REDIS_PORT", "6379") or "6379"))
    parser.add_argument("--redis-db", type=int, default=int(os.getenv("PERM3_REDIS_DB", "0") or "0"))
    parser.add_argument("--redis-password", default=os.getenv("PERM3_REDIS_PASSWORD", ""))
    parser.add_argument(
        "--redis-captcha-key-prefix",
        default=os.getenv("PERM3_REDIS_CAPTCHA_KEY_PREFIX", "captcha_codes:"),
    )
    parser.add_argument(
        "--reset-user-password",
        action="store_true",
        default=env_bool("PERM3_RESET_USER_PASSWORD", False),
        help="reset target user password via /system/user/resetPwd before login (uses --user-password)",
    )
    parser.add_argument(
        "--reset-user-password-path",
        default=os.getenv("PERM3_RESET_USER_PASSWORD_PATH", "/system/user/resetPwd"),
    )

    parser.add_argument(
        "--report-json",
        default=os.getenv(
            "PERM3_REPORT_JSON",
            "E:/training_agent/training-agent-master/docs/perm3_dynamic_report.json",
        ),
    )
    parser.add_argument(
        "--report-md",
        default=os.getenv(
            "PERM3_REPORT_MD",
            "E:/training_agent/training-agent-master/docs/perm3_dynamic_report.md",
        ),
    )

    args = parser.parse_args()

    steps: List[StepResult] = []
    fatal_error = ""
    target_user_id = 0
    role_id = 0
    redis_conf = RedisConfig(
        host=args.redis_host,
        port=args.redis_port,
        db=args.redis_db,
        password=args.redis_password,
        captcha_key_prefix=args.redis_captcha_key_prefix,
    )

    try:
        if not args.user_username:
            raise RuntimeError("missing --user-username (or PERM3_USER_USERNAME)")
        if not args.admin_token and not (args.admin_username and args.admin_password):
            raise RuntimeError(
                "missing admin auth. set --admin-token or (--admin-username and --admin-password)"
            )
        if not args.user_token and not (args.user_username and args.user_password):
            raise RuntimeError(
                "missing user auth. set --user-token or (--user-username and --user-password)"
            )
        if args.role_id <= 0 and not args.role_key and not args.role_name:
            raise RuntimeError("missing role selector. set --role-id or --role-key/--role-name")

        api_prefix = args.api_prefix
        captcha_path = normalize_path(api_prefix, args.captcha_path)

        admin_token = args.admin_token.strip()
        if not admin_token:
            admin_login_path = normalize_path(api_prefix, args.admin_login_path)
            admin_token = login_by_password(
                args.base_url,
                admin_login_path,
                captcha_path,
                args.admin_username,
                args.admin_password,
                args.admin_tenant_id,
                captcha_solver=args.captcha_solver,
                redis_conf=redis_conf,
            )

        target_user_id = resolve_user_id(args.base_url, api_prefix, admin_token, args.user_username)
        role_id = resolve_role_id(
            args.base_url,
            api_prefix,
            admin_token,
            args.role_id,
            args.role_key.strip(),
            args.role_name.strip(),
        )

        if args.reset_user_password:
            if not args.user_password:
                raise RuntimeError("reset-user-password requires --user-password")
            reset_resp = reset_user_password(
                args.base_url,
                api_prefix,
                admin_token,
                target_user_id,
                args.user_password,
                args.reset_user_password_path,
            )
            ok = is_business_success(reset_resp)
            steps.append(
                StepResult(
                    name="reset_target_user_password",
                    expected="reset user password API succeeds",
                    passed=ok,
                    actual=f"http={reset_resp.http_status}, code={reset_resp.json_code}, msg={reset_resp.json_msg}",
                    evidence={"resetPwd": compact(reset_resp)},
                )
            )
            if not ok:
                raise RuntimeError(
                    f"reset password failed: status={reset_resp.http_status}, "
                    f"code={reset_resp.json_code}, msg={reset_resp.json_msg or reset_resp.error}"
                )

        user_token_old = args.user_token.strip()
        if not user_token_old:
            user_login_path = normalize_path(api_prefix, args.user_login_path)
            user_token_old = login_by_password(
                args.base_url,
                user_login_path,
                captcha_path,
                args.user_username,
                args.user_password,
                args.user_tenant_id,
                captcha_solver=args.captcha_solver,
                redis_conf=redis_conf,
            )

        probe_before = probe(
            args.base_url,
            api_prefix,
            user_token_old,
            args.probe_method,
            args.probe_path,
            args.probe_body,
        )
        steps.append(
            StepResult(
                name="before_grant_denied",
                expected="before grant, target user request is denied",
                passed=is_auth_denied(probe_before),
                actual=f"http={probe_before.http_status}, code={probe_before.json_code}, msg={probe_before.json_msg}",
                evidence={"probe": compact(probe_before)},
            )
        )

        grant_query = urllib.parse.urlencode({"roleId": role_id, "userIds": target_user_id})
        grant_path = normalize_path(api_prefix, args.grant_path) + "?" + grant_query
        grant_resp = call_api(args.base_url, "PUT", grant_path, token=admin_token)
        steps.append(
            StepResult(
                name="grant_role",
                expected="grant role API succeeds",
                passed=is_business_success(grant_resp),
                actual=f"http={grant_resp.http_status}, code={grant_resp.json_code}, msg={grant_resp.json_msg}",
                evidence={"grant": compact(grant_resp)},
            )
        )

        probe_old_after_grant = probe(
            args.base_url,
            api_prefix,
            user_token_old,
            args.probe_method,
            args.probe_path,
            args.probe_body,
        )
        steps.append(
            StepResult(
                name="old_token_denied_after_grant",
                expected="after grant, old token is invalid/denied",
                passed=is_auth_denied(probe_old_after_grant),
                actual=(
                    f"http={probe_old_after_grant.http_status}, "
                    f"code={probe_old_after_grant.json_code}, msg={probe_old_after_grant.json_msg}"
                ),
                evidence={"probe_old_after_grant": compact(probe_old_after_grant)},
            )
        )

        user_login_path = normalize_path(api_prefix, args.user_login_path)
        user_token_after_grant = login_by_password(
            args.base_url,
            user_login_path,
            captcha_path,
            args.user_username,
            args.user_password,
            args.user_tenant_id,
            captcha_solver=args.captcha_solver,
            redis_conf=redis_conf,
        )

        probe_after_grant = probe(
            args.base_url,
            api_prefix,
            user_token_after_grant,
            args.probe_method,
            args.probe_path,
            args.probe_body,
        )
        getinfo_after_grant = call_api(
            args.base_url,
            "GET",
            normalize_path(api_prefix, args.getinfo_path),
            token=user_token_after_grant,
        )
        perms_after_grant = parse_permissions(getinfo_after_grant)
        perm_after_grant_ok = True
        if args.expected_perm:
            perm_after_grant_ok = args.expected_perm in perms_after_grant
        after_grant_ok = (not is_auth_denied(probe_after_grant)) and perm_after_grant_ok
        steps.append(
            StepResult(
                name="relogin_effective_after_grant",
                expected="after re-login, access restored and expected permission exists",
                passed=after_grant_ok,
                actual=(
                    f"probe(http={probe_after_grant.http_status}, code={probe_after_grant.json_code}, "
                    f"denied={is_auth_denied(probe_after_grant)}), "
                    f"perm_exists={perm_after_grant_ok}"
                ),
                evidence={
                    "probe_after_grant": compact(probe_after_grant),
                    "getinfo_after_grant": compact(getinfo_after_grant),
                    "permissions_after_grant_count": len(perms_after_grant),
                },
            )
        )

        revoke_query = urllib.parse.urlencode({"roleId": role_id, "userIds": target_user_id})
        revoke_path = normalize_path(api_prefix, args.revoke_path) + "?" + revoke_query
        revoke_resp = call_api(args.base_url, "PUT", revoke_path, token=admin_token)
        steps.append(
            StepResult(
                name="revoke_role",
                expected="revoke role API succeeds",
                passed=is_business_success(revoke_resp),
                actual=f"http={revoke_resp.http_status}, code={revoke_resp.json_code}, msg={revoke_resp.json_msg}",
                evidence={"revoke": compact(revoke_resp)},
            )
        )

        probe_old_after_revoke = probe(
            args.base_url,
            api_prefix,
            user_token_after_grant,
            args.probe_method,
            args.probe_path,
            args.probe_body,
        )
        steps.append(
            StepResult(
                name="old_token_denied_after_revoke",
                expected="after revoke, old token is invalid/denied",
                passed=is_auth_denied(probe_old_after_revoke),
                actual=(
                    f"http={probe_old_after_revoke.http_status}, "
                    f"code={probe_old_after_revoke.json_code}, msg={probe_old_after_revoke.json_msg}"
                ),
                evidence={"probe_old_after_revoke": compact(probe_old_after_revoke)},
            )
        )

        user_token_after_revoke = login_by_password(
            args.base_url,
            user_login_path,
            captcha_path,
            args.user_username,
            args.user_password,
            args.user_tenant_id,
            captcha_solver=args.captcha_solver,
            redis_conf=redis_conf,
        )
        probe_after_revoke = probe(
            args.base_url,
            api_prefix,
            user_token_after_revoke,
            args.probe_method,
            args.probe_path,
            args.probe_body,
        )
        getinfo_after_revoke = call_api(
            args.base_url,
            "GET",
            normalize_path(api_prefix, args.getinfo_path),
            token=user_token_after_revoke,
        )
        perms_after_revoke = parse_permissions(getinfo_after_revoke)
        perm_after_revoke_ok = True
        if args.expected_perm:
            perm_after_revoke_ok = args.expected_perm not in perms_after_revoke
        after_revoke_ok = is_auth_denied(probe_after_revoke) and perm_after_revoke_ok
        steps.append(
            StepResult(
                name="relogin_denied_after_revoke",
                expected="after re-login post-revoke, access denied and expected permission removed",
                passed=after_revoke_ok,
                actual=(
                    f"probe(http={probe_after_revoke.http_status}, code={probe_after_revoke.json_code}, "
                    f"denied={is_auth_denied(probe_after_revoke)}), "
                    f"perm_removed={perm_after_revoke_ok}"
                ),
                evidence={
                    "probe_after_revoke": compact(probe_after_revoke),
                    "getinfo_after_revoke": compact(getinfo_after_revoke),
                    "permissions_after_revoke_count": len(perms_after_revoke),
                },
            )
        )

    except Exception as e:  # noqa: BLE001
        fatal_error = str(e)

    overall = (len(steps) > 0) and all(step.passed for step in steps) and not fatal_error
    report = {
        "time": dt.datetime.now().isoformat(timespec="seconds"),
        "base_url": args.base_url,
        "api_prefix": args.api_prefix,
        "target_username": args.user_username,
        "target_user_id": target_user_id,
        "role_id": role_id,
        "expected_perm": args.expected_perm,
        "overall_passed": overall,
        "fatal_error": fatal_error,
        "steps": [asdict(s) for s in steps],
    }

    write_report_json(args.report_json, report)
    write_report_md(args.report_md, report)

    print("PERM-3 dynamic acceptance report generated:")
    print(f"  JSON: {args.report_json}")
    print(f"  MD  : {args.report_md}")
    print(f"  RESULT: {'PASS' if overall else 'FAIL'}")
    if fatal_error:
        print(f"  ERROR: {fatal_error}")
    return 0 if overall else 1


if __name__ == "__main__":
    sys.exit(main())
