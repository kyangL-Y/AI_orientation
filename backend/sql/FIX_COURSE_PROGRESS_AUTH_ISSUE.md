# 修复课程进度接口认证问题

## 问题描述
用户端调用课程进度相关接口时报错：
```
com.ruoyi.common.exception.ServiceException: 获取用户ID异常
```

## 问题原因

### 根本原因
接口使用了 `@Anonymous` 注解（允许匿名访问），但方法内部调用了 `SecurityUtils.getUserId()`，这在未登录状态下会抛出 `ServiceException`。

### 问题代码
```java
@GetMapping("/course/progress-list")
@DataSource(DataSourceType.SLAVE)
@Anonymous  // ❌ 允许匿名访问
public AjaxResult getCourseProgressList() {
    Long userId = SecurityUtils.getUserId();  // ❌ 未登录时抛异常
    // ...
}
```

### 逻辑冲突
1. `@Anonymous` 表示接口可以匿名访问（不需要登录）
2. `SecurityUtils.getUserId()` 要求用户必须登录，否则抛出异常
3. 两者互相矛盾，导致接口调用失败

## 解决方案

### 修复方法
移除 `@Anonymous` 注解，要求用户必须登录才能访问这些接口。

### 修复的接口

#### 1. 获取课程进度列表
**文件**: `training-agent-master/ruoyi-admin/src/main/java/com/ruoyi/web/controller/train/TrainUserController.java`

**接口**: `GET /train/user/course/progress-list`

```java
// 修改前
@GetMapping("/course/progress-list")
@DataSource(DataSourceType.SLAVE)
@Anonymous  // ❌ 移除此注解
public AjaxResult getCourseProgressList() {
    Long userId = SecurityUtils.getUserId();
    // ...
}

// 修改后
@GetMapping("/course/progress-list")
@DataSource(DataSourceType.SLAVE)
public AjaxResult getCourseProgressList() {
    Long userId = SecurityUtils.getUserId();
    // ...
}
```

#### 2. 完成课程学习
**接口**: `POST /train/user/course/complete`

```java
// 修改前
@PostMapping("/course/complete")
@DataSource(DataSourceType.SLAVE)
@Anonymous  // ❌ 移除此注解
public AjaxResult completeCourse(@RequestBody Map<String, Object> params) {
    Long userId = SecurityUtils.getUserId();
    // ...
}

// 修改后
@PostMapping("/course/complete")
@DataSource(DataSourceType.SLAVE)
public AjaxResult completeCourse(@RequestBody Map<String, Object> params) {
    Long userId = SecurityUtils.getUserId();
    // ...
}
```

## 技术说明

### @Anonymous 注解的正确使用场景
`@Anonymous` 应该用于真正不需要登录的公开接口，例如：
- 登录接口 `/login`
- 注册接口 `/register`
- 公开的资讯页面
- 验证码获取接口

### SecurityUtils.getUserId() 的行为
```java
public static Long getUserId() {
    try {
        return getLoginUser().getUserId();
    } catch (Exception e) {
        throw new ServiceException("获取用户ID异常", HttpStatus.UNAUTHORIZED);
    }
}
```

- 从 Spring Security 上下文中获取当前登录用户
- 如果用户未登录，抛出 `ServiceException`
- HTTP 状态码：401 Unauthorized

## 影响范围

### 前端调用
用户端前端调用这些接口时，必须：
1. 用户已登录
2. 请求头中携带有效的 JWT Token：`Authorization: Bearer <token>`

### 错误处理
如果用户未登录或 Token 失效：
- HTTP 状态码：401
- 错误信息："获取用户ID异常"
- 前端应跳转到登录页面

## 验证方法

### 1. 测试登录状态下的调用
```bash
# 先登录获取 token
curl -X POST http://localhost:9090/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"123456"}'

# 使用 token 调用接口
curl -X GET http://localhost:9090/train/user/course/progress-list \
  -H "Authorization: Bearer <your-token>"
```

### 2. 测试未登录状态
```bash
# 不带 token 调用（应该返回 401）
curl -X GET http://localhost:9090/train/user/course/progress-list
```

### 3. 前端验证
1. 登录用户端
2. 访问课程学习页面
3. 查看课程进度列表是否正常显示
4. 完成课程后检查进度是否更新

## 相关文件

### 修改的文件
- `training-agent-master/ruoyi-admin/src/main/java/com/ruoyi/web/controller/train/TrainUserController.java`
  - 移除 `getCourseProgressList()` 方法的 `@Anonymous` 注解
  - 移除 `completeCourse()` 方法的 `@Anonymous` 注解

### 相关文件（未修改）
- `training-agent-master/ruoyi-common/src/main/java/com/ruoyi/common/utils/SecurityUtils.java` - 用户认证工具类
- `training-agent-master/ruoyi-framework/src/main/java/com/ruoyi/framework/security/` - Spring Security 配置

## 最佳实践

### 接口权限设计原则
1. **默认需要认证**：除非明确需要公开，否则所有接口都应该要求登录
2. **谨慎使用 @Anonymous**：只用于真正的公开接口
3. **一致性检查**：如果方法内使用了 `SecurityUtils.getUserId()`，就不应该使用 `@Anonymous`

### 代码审查清单
- [ ] 使用 `@Anonymous` 的接口是否真的需要公开访问？
- [ ] 接口内部是否调用了 `SecurityUtils.getUserId()` 等需要登录的方法？
- [ ] 是否有更好的方式处理可选登录的场景？

## 注意事项

1. **需要重启服务**：修改注解后需要重启后端服务才能生效
2. **前端 Token 管理**：确保前端正确存储和发送 JWT Token
3. **Token 过期处理**：前端需要处理 401 错误，引导用户重新登录

## 总结

通过移除不必要的 `@Anonymous` 注解，修复了课程进度接口的认证问题。现在这些接口正确地要求用户登录后才能访问，与 `SecurityUtils.getUserId()` 的行为保持一致。

---
**修复日期**: 2026-01-23  
**影响接口**: 
- `GET /train/user/course/progress-list`
- `POST /train/user/course/complete`  
**需要重启**: ✅ 是
