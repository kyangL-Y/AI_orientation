# 任务清单: admin_authority_unify

```yaml
@feature: admin_authority_unify
@created: 2026-03-20
@status: completed
@mode: R3
```

<!-- LIVE_STATUS_BEGIN -->
状态: completed | 进度: 10/10 (100%) | 更新: 2026-03-20 11:05:00
当前: 后端/前端构建通过，管理员权限链路已统一
<!-- LIVE_STATUS_END -->

## 进度概览

| 完成 | 失败 | 跳过 | 总数 |
|------|------|------|------|
| 10 | 0 | 0 | 10 |

---

## 任务列表

### 1. 后端统一管理员模型

- [√] 1.1 在 `ruoyi-common/.../SysUser.java` 中实现最高管理员级别、后台访问、全租户能力的统一判断 | depends_on: []
- [√] 1.2 在 `ruoyi-admin/.../SysLoginController.java`、`ruoyi-framework/.../AdminAccessInterceptor.java`、`PermissionService.java` 中改为消费统一能力方法 | depends_on: [1.1]

### 2. 后端管理员功能收敛

- [√] 2.1 在 `SysUserController.java`、`SysUserServiceImpl.java`、`SysRoleServiceImpl.java` 中统一管理员层级与可操作范围逻辑 | depends_on: [1.1]
- [√] 2.2 在 `AdminMenuServiceImpl.java`、`TenantCustomizationController.java`、`SysNoticeController.java` 中修复全租户/高权限判断 | depends_on: [1.1]
- [√] 2.3 在训练后台关键控制器与服务中替换 `SysUser.isAdmin(userId)` 等超管专用旧判断 | depends_on: [1.1]

### 3. 前端管理员口径收敛

- [√] 3.1 在 `RuoYi-Vue3/src/store/modules/user.js` 与前端 helper 中统一管理员状态字段 | depends_on: [1.2]
- [√] 3.2 在路由守卫、管理员菜单加载和关键后台页面中替换 `userId===1/adminLevel/roles` 拼凑判断 | depends_on: [3.1,2.2]

### 4. 验证与收尾

- [√] 4.1 执行后端编译/打包与后台前端构建，确认无编译错误 | depends_on: [2.3,3.2]
- [√] 4.2 复核管理员问题清单与修复结果，整理本轮高风险遗留项 | depends_on: [4.1]

---

## 执行日志

| 时间 | 任务 | 状态 | 备注 |
|------|------|------|------|
| 2026-03-20 10:52 | 方案设计 | completed | 完成管理员权限模型与受影响范围梳理 |
| 2026-03-20 10:59 | 后端统一改造 | completed | 收敛 `SysUser`、登录、权限、菜单、关键控制器 |
| 2026-03-20 11:02 | 前端统一改造 | completed | 新增 `adminAuth` helper，替换关键页面判断 |
| 2026-03-20 11:03 | 编译构建 | completed | `mvn package` 与 `npm run build:prod` 均通过 |

---

## 执行备注

> 记录执行过程中的重要说明、决策变更、风险提示等

- 历史 `can_access_admin=1` 但无明确管理员角色的账号仍保留后台访问资格，但不会自动升级为全租户管理员。
- `SysMenuServiceImpl` 保留了对历史 `userId==1` 的回退兼容，但当前登录态优先采用统一管理员能力模型。
