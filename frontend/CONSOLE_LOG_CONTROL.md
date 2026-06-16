# 控制台日志控制说明

## 概述

为了保护用户隐私和提升生产环境的安全性，我们实现了控制台日志控制系统，可以：

1. **生产环境完全禁用控制台日志**
2. **自动过滤敏感信息**（验证码、手机号、邮箱、密码等）
3. **开发环境保留调试能力**

## 实现方式

### 1. 日志工具 (`src/utils/logger.js`)

提供了统一的日志接口，替代原生 `console` 方法：

```javascript
import logger from '@/utils/logger'

// 普通日志（生产环境不输出，开发环境会过滤敏感信息）
logger.log('用户登录成功')

// 敏感信息日志（生产环境完全不输出，开发环境会标记）
logger.sensitive('验证码:', code)

// 调试日志（仅开发环境）
logger.debug('调试信息:', data)

// 警告和错误（开发环境输出，生产环境不输出）
logger.warn('警告信息')
logger.error('错误信息')
```

**重要说明：**
- 开发环境不会禁用原生 `console`，以免影响 Vue DevTools 和调试
- logger 工具会自动根据环境过滤敏感信息
- 生产环境构建时，所有 logger 方法都不会输出

### 2. 自动过滤敏感信息

日志工具会自动检测并过滤以下敏感信息：

- 验证码相关：`验证码`、`code`、`captcha`、`verification`
- 手机号相关：`手机`、`phone`、`mobile`、`tel`
- 邮箱相关：`邮箱`、`email`、`mail`
- 密码相关：`密码`、`password`、`pwd`
- 认证相关：`token`、`authorization`、`auth`

**示例：**

```javascript
// 开发环境输出：[敏感信息已过滤]
logger.log('验证码是:', '123456')

// 生产环境：完全不输出
```

### 3. 生产环境禁用所有日志

在 `src/main.js` 中，生产环境会自动禁用所有 `console` 方法：

```javascript
import { disableConsoleLogs } from './utils/logger.js'

// 在生产环境禁用控制台日志
if (process.env.NODE_ENV === 'production') {
  disableConsoleLogs()
}
```

## 紧急调试

如果在生产环境需要紧急调试，可以在浏览器控制台输入：

```javascript
// 恢复控制台日志
window.__restoreConsole()

// 使用原始 console 方法
window.__originalConsole.log('调试信息')
```

## 当前状态

### ✅ 已完成

1. **日志工具创建** - `src/utils/logger.js`
2. **主入口集成** - `src/main.js` 已集成日志控制
3. **生产环境禁用** - 生产环境会自动禁用所有控制台日志
4. **敏感信息过滤** - 自动检测和过滤敏感信息

### 📝 建议后续优化

如果需要更彻底的日志控制，可以考虑：

1. **批量替换 console 调用**
   - 将项目中的 `console.log` 替换为 `logger.log`
   - 将包含敏感信息的日志替换为 `logger.sensitive`

2. **重点文件**
   - `src/components/modals/LoginModal.vue` - 登录相关日志
   - `src/components/modals/RegisterModal.vue` - 注册和验证码日志
   - `src/views/AIinterview.vue` - AI 对话日志
   - `src/views/PersonalCenter.vue` - 个人信息日志

3. **示例替换**

```javascript
// 原代码
console.log('发送验证码到:', email)
console.log('验证码:', code)

// 替换为
logger.sensitive('发送验证码到:', email)
logger.sensitive('验证码:', code)
```

## 环境说明

- **开发环境** (`NODE_ENV=development`)
  - 所有日志正常输出
  - 敏感信息会被标记但仍可见
  - 便于调试

- **生产环境** (`NODE_ENV=production`)
  - 所有 `console` 方法被禁用
  - 敏感信息完全不输出
  - 保护用户隐私

## 测试方法

### 开发环境测试

```bash
cd training-agent-user
pnpm dev
```

打开浏览器控制台，应该能看到正常的日志输出。

### 生产环境测试

```bash
cd training-agent-user
pnpm build
# 部署 dist 目录到服务器
```

打开浏览器控制台，应该看到：
```
🔒 生产环境：控制台日志已禁用
如需调试，请在控制台输入: window.__originalConsole.log("test")
```

之后所有 `console.log/warn/error` 都不会输出任何内容。

## 注意事项

1. **不影响错误追踪**
   - 虽然控制台日志被禁用，但 JavaScript 错误仍会被浏览器捕获
   - 可以集成第三方错误追踪服务（如 Sentry）

2. **紧急调试**
   - 生产环境保留了 `window.__originalConsole` 用于紧急调试
   - 使用 `window.__restoreConsole()` 可以临时恢复日志

3. **性能影响**
   - 禁用日志后，所有 `console` 调用变成空函数
   - 对性能几乎没有影响

## 相关文件

- `src/utils/logger.js` - 日志工具实现
- `src/main.js` - 日志控制集成
- `CONSOLE_LOG_CONTROL.md` - 本文档

---

**更新时间**: 2026-01-23  
**状态**: ✅ 已完成并生效
