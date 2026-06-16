# 变更提案: token-missing-log-noise

## 元信息
```yaml
类型: 修复/优化
方案类型: implementation
优先级: P2
状态: 已确认
创建: 2026-03-30
```

---

## 1. 需求

### 背景
管理端后台频繁出现 `TokenService.getLoginUser()` 输出的“请求未携带Token”警告。现有 `JwtAuthenticationTokenFilter` 会对所有请求统一调用 `getLoginUser()`，包括登录、验证码和其他匿名接口，这些请求本来就允许不带 token，因此当前 `WARN` 日志属于噪音，容易淹没真正的认证异常。

### 目标
- 降低正常匿名请求触发的无意义告警日志。
- 保留真实认证异常的可观测性，包括 token 解析失败、Redis 中找不到登录态等情况。
- 不改变现有认证流程、接口权限判定和前端请求行为。

### 约束条件
```yaml
时间约束: 单次后端修复，避免扩大到前后端联调
性能约束: 不增加额外鉴权开销
兼容性约束: 不改变 JwtAuthenticationTokenFilter 的调用链和返回语义
业务约束: 登录、验证码、公开接口允许无 token 访问
```

### 验收标准
- [ ] 正常匿名请求不再输出“请求未携带Token”的 WARN 日志
- [ ] 携带异常 token 或登录态失效时，原有告警/错误日志仍保留
- [ ] 后端代码可通过编译验证

---

## 2. 方案

### 技术方案
在 `TokenService.getLoginUser(HttpServletRequest request)` 中，将“请求未携带Token”从 `WARN` 降为 `DEBUG` 级别，并补充请求方法与 URI 作为调试上下文。保留以下分支的原有日志级别:

- token 解析异常：继续 `ERROR`
- token 存在但 Redis 中找不到登录用户：继续 `WARN`

这样可以在不改动认证流程的前提下消除匿名请求带来的日志噪音。

### 影响范围
```yaml
涉及模块:
  - ruoyi-framework: 调整 TokenService 空 token 分支的日志策略
  - 管理端鉴权链路: 行为不变，仅日志输出变化
预计变更文件: 1
```

### 风险评估
| 风险 | 等级 | 应对 |
|------|------|------|
| 误伤真实问题日志 | 低 | 仅降低“空 token”分支日志级别，保留异常 token 与 Redis miss 的告警 |
| 调试信息不足 | 低 | 改为 DEBUG 并附带请求方法、URI，按需打开调试日志仍可排查 |

---

## 4. 核心场景

> 执行完成后同步到对应模块文档

### 场景: 匿名访问公开接口
**模块**: `TokenService` / `JwtAuthenticationTokenFilter`
**条件**: 请求未携带 `Authorization` token，且接口本身允许匿名访问
**行为**: 过滤器调用 `getLoginUser()`，返回 `null`
**结果**: 不输出 `WARN` 级别噪音日志，继续后续过滤链

### 场景: 携带无效 token 或登录态失效
**模块**: `TokenService`
**条件**: 请求携带 token，但 token 解析失败或 Redis 中无对应登录态
**行为**: 继续执行现有异常日志与失败返回逻辑
**结果**: 保持 `WARN/ERROR` 可观测性不变

---

## 5. 技术决策

> 本方案涉及的技术决策，归档后成为决策的唯一完整记录

### token-missing-log-noise#D001: 空 token 分支只降日志级别，不改过滤器路径
**日期**: 2026-03-30
**状态**: ✅采纳
**背景**: 匿名接口请求本来就不带 token，但当前被统一记录为 WARN，导致日志污染。
**选项分析**:
| 选项 | 优点 | 缺点 |
|------|------|------|
| A: 在 TokenService 中将空 token 改为 DEBUG | 改动最小，不影响认证流程，能快速消除噪音 | 仍会在 DEBUG 日志中出现 |
| B: 在 JwtAuthenticationTokenFilter 中先判断 token 再决定是否调用 TokenService | 语义更干净 | 需要改过滤器路径，影响面更大，回归点更多 |
**决策**: 选择方案 A
**理由**: 当前问题是日志级别不合理，不是认证链路错误。优先采用最小改动修复噪音，避免引入新的鉴权分支差异。
**影响**: 影响 `ruoyi-framework` 的日志输出，不影响接口权限、token 校验和前端调用方式
