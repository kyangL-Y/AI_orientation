# PERM-3 Dynamic Acceptance Report

- Time: 2026-02-22T15:42:11
- Base URL: http://127.0.0.1:9090
- API Prefix: ``
- Target User: `孙琳` (ID: 114)
- Role ID: 100
- Expected Permission: `train:deptCourse:list`
- Overall: PASS

| Step | Expected | Actual | Pass |
|---|---|---|---|
| reset_target_user_password | reset user password API succeeds | http=200, code=200, msg=操作成功 | PASS |
| before_grant_denied | before grant, target user request is denied | http=200, code=403, msg=没有权限，请联系管理员授权 | PASS |
| grant_role | grant role API succeeds | http=200, code=200, msg=操作成功 | PASS |
| old_token_denied_after_grant | after grant, old token is invalid/denied | http=200, code=401, msg=请求访问：/train/dept-course/list，认证失败，无法访问系统资源 | PASS |
| relogin_effective_after_grant | after re-login, access restored and expected permission exists | probe(http=200, code=200, denied=False), perm_exists=True | PASS |
| revoke_role | revoke role API succeeds | http=200, code=200, msg=操作成功 | PASS |
| old_token_denied_after_revoke | after revoke, old token is invalid/denied | http=200, code=401, msg=请求访问：/train/dept-course/list，认证失败，无法访问系统资源 | PASS |
| relogin_denied_after_revoke | after re-login post-revoke, access denied and expected permission removed | probe(http=200, code=403, denied=True), perm_removed=True | PASS |
