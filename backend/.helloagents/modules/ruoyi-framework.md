# ruoyi-framework

## 职责

- 提供 Spring Security、JWT 过滤器、TokenService 等基础安全能力。
- 负责请求登录态提取、token 校验、会话续期与认证上下文注入。

## 行为规范

- `JwtAuthenticationTokenFilter` 会对进入安全链的请求统一调用 `TokenService.getLoginUser()`。
- 空 token 请求允许直接返回 `null` 继续后续链路，不应作为告警噪音输出。
- 异常 token、Redis 中找不到登录态等真实认证问题需要保留告警或错误日志，便于排查。

## 本次变更

- 将 `TokenService.getLoginUser()` 中“请求未携带Token”从 `WARN` 调整为 `DEBUG`。
- DEBUG 日志附带请求方法与 URI，保留匿名接口的排查上下文。
- 未调整 token 解析失败与 Redis miss 分支的日志级别和认证行为。

## 依赖关系

- 依赖 `ruoyi-common` 中的 `StringUtils`、`ServletUtils`、`LoginUser` 与 Redis 封装。
- 被 `JwtAuthenticationTokenFilter` 调用，用于每次请求的登录态解析。
