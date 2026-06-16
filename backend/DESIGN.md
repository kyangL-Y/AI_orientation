# training-agent-master 设计说明

## 1. 模块设计
后端按 RuoYi 标准多模块拆分：
- `ruoyi-admin`：控制层与应用启动
- `ruoyi-framework`：Spring Security、JWT、拦截器、TokenService
- `ruoyi-system`：用户、角色、权限、菜单、租户等系统域
- `ruoyi-common`：通用工具与基础能力

管理端前端位于 `RuoYi-Vue3`，通过权限指令与路由守卫进行页面侧控制。

## 2. 认证与会话
- 登录后由后端签发 token，登录态与权限缓存受 Redis 管理。
- 用户角色/状态/密码变更，以及角色授权/撤权后，目标用户会话会被强制失效。
- 设计目标：避免“已授权但旧会话权限未刷新”。

## 3. 权限控制策略
- 接口级：`@PreAuthorize(...)` 为主，避免过宽 `permitAll`。
- 菜单与按钮：`v-hasPermi` 与权限串一致。
- 管理查询路径与用户查询路径分离，降低越权误用概率。

## 4. 安全设计
- 配置层不再固化明文凭据，统一读取环境变量。
- 匿名接口最小化，保留认证/注册/验证码等必要公开入口。
- 富文本预览口接入 `sanitizeHtml`，对 HTML 标签与危险属性做清洗。

## 5. 验收策略
- 静态验收：`mvn -q -DskipTests compile`、`npm run lint`
- 安全验收：`verify-security` 需保持 `critical=0`、`high=0`
- 权限动态验收：`scripts/perm3_dynamic_acceptance.py` 输出报告到 `docs/`

