# 多智能体系统 - 配置清单

## 📝 必填配置项

请按照以下步骤完成配置：

### 1. 复制环境变量文件

```bash
cd E:\training_agent\training-agent-muti_agent\multi_agent_system
copy .env.example .env
```

### 2. 编辑 .env 文件，填写以下配置

#### 🔴 必填项（不填系统无法启动）

```bash
# ==================== AI 模型配置 ====================
# DashScope API Key（必填）
# 获取方式：访问 https://dashscope.console.aliyun.com/
# 注册阿里云账号 → 开通 DashScope 服务 → 获取 API Key
DASHSCOPE_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# ==================== 数据库配置 ====================
# MySQL 数据库密码（必填）
DB_HOST=localhost
DB_PORT=3306
DB_NAME=hz-vue
DB_USER=root
DB_PASSWORD=你的数据库密码           # 必填！
```

#### 🟡 推荐配置项（可选但建议填写）

```bash
# ==================== Redis 缓存配置 ====================
# Redis 连接信息（推荐配置，可显著提升性能）
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=                      # 如果 Redis 没有密码则留空
REDIS_DB=0

# 是否启用缓存（强烈建议启用）
ENABLE_RESULT_CACHE=true
CACHE_DURATION_SECONDS=600
```

#### 🟢 可选配置项（使用默认值即可）

```bash
# ==================== AI 模型参数 ====================
AI_MODEL=qwen-plus                   # 推荐使用 qwen-plus
AI_TEMPERATURE=0.7                   # 创造性（0-1），0.7较平衡
AI_MAX_TOKENS=2000                   # 最大输出长度

# ==================== 性能优化配置 ====================
ENABLE_PARALLEL_EXECUTION=true       # 并行执行（建议开启）
AGENT_RETRY_MAX_ATTEMPTS=3           # 重试次数
AGENT_RETRY_BACKOFF_FACTOR=2         # 重试退避因子

# ==================== 日志配置 ====================
LOG_LEVEL=INFO                       # 日志级别：DEBUG/INFO/WARNING/ERROR
LOG_FORMAT=json                      # 日志格式：json/console
```

---

## 📋 详细配置说明

### 1. DashScope API Key（必填）⭐

**获取步骤：**

1. 访问 [阿里云 DashScope 控制台](https://dashscope.console.aliyun.com/)
2. 使用阿里云账号登录（没有则需注册）
3. 开通 **DashScope 服务**
4. 进入 **API-KEY管理**
5. 点击 **创建新的API-KEY**
6. 复制生成的 API Key（格式：`sk-xxxxx...`）
7. 粘贴到 `.env` 文件的 `DASHSCOPE_API_KEY=` 后面

**重要提示：**
- API Key 是敏感信息，请勿泄露
- 如果使用免费额度，注意监控用量
- 建议设置用量告警

**费用说明：**
- qwen-plus 模型：约 ¥0.004元/千tokens
- 每次报告生成约消耗 2000-5000 tokens
- 单次报告成本约：¥0.008-0.02元
- 月度500次报告约：¥4-10元

---

### 2. 数据库配置（必填）⭐

```bash
DB_HOST=localhost           # 数据库地址，本地开发使用 localhost
DB_PORT=3306               # MySQL 端口，默认 3306
DB_NAME=hz-vue             # 数据库名称，保持不变
DB_USER=root               # 数据库用户名
DB_PASSWORD=你的数据库密码   # ⚠️ 必填！你的 MySQL root 密码
```

**验证数据库连接：**
```bash
mysql -h localhost -u root -p hz-vue
# 输入密码后，如果能进入 MySQL 命令行，说明配置正确
```

---

### 3. Redis 配置（推荐）🔶

**为什么需要 Redis？**
- 缓存智能体执行结果，**避免重复计算**
- 缓存数据库查询，**减少DB压力**
- 缓存AI调用结果，**节省API费用**
- 性能提升：**60-70%**

**如果已经安装 Redis：**
```bash
# 检查 Redis 是否运行
redis-cli ping
# 如果返回 PONG，说明 Redis 正常运行

# 配置 .env
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=           # 如果设置了密码则填写，否则留空
ENABLE_RESULT_CACHE=true
```

**如果没有安装 Redis：**

**选项1：安装 Redis（推荐）**
```bash
# Windows - 使用 WSL 或下载 Redis for Windows
# https://github.com/tporadowski/redis/releases

# 下载后解压，运行 redis-server.exe
# 默认端口 6379，无密码
```

**选项2：临时不使用 Redis**
```bash
# 在 .env 中设置
ENABLE_RESULT_CACHE=false

# ⚠️ 注意：性能会降低，但系统仍可正常运行
```

---

### 4. Java 应用配置

编辑 `application.yml`（或 `application-dev.yml`）：

```yaml
# 在文件末尾添加
multi:
  agent:
    enabled: true                    # 启用多智能体系统
    service:
      url: http://localhost:8000     # Python 服务地址
      timeout: 60000                 # 超时时间（毫秒）
```

---

## ✅ 配置验证清单

完成配置后，请按照以下清单验证：

### Python 服务配置验证

```bash
# 1. 检查 .env 文件是否存在
cd E:\training_agent\training-agent-muti_agent\multi_agent_system
dir .env

# 2. 验证数据库连接
mysql -h localhost -u root -p hz-vue

# 3. 验证 Redis（如果启用）
redis-cli ping

# 4. 启动 Python 服务
python main.py

# 5. 检查健康状态
curl http://localhost:8000/health
```

**预期健康检查结果：**
```json
{
  "status": "healthy",
  "redis": "connected",      // 如果启用 Redis
  "database": "connected"
}
```

### Java 应用配置验证

```bash
# 1. 检查配置文件
notepad application.yml

# 2. 重启 Java 应用
# 在 IDEA 中重启，或者
mvn spring-boot:run
```

---

## 🚨 常见配置错误

### 错误1：DASHSCOPE_API_KEY 未填写
```
错误信息：KeyError: 'DASHSCOPE_API_KEY'
解决方案：在 .env 中添加有效的 API Key
```

### 错误2：数据库密码错误
```
错误信息：Access denied for user 'root'@'localhost'
解决方案：检查 DB_PASSWORD 是否正确
```

### 错误3：Redis 连接失败
```
错误信息：redis.exceptions.ConnectionError
解决方案：
- 选项1：启动 Redis 服务
- 选项2：设置 ENABLE_RESULT_CACHE=false
```

### 错误4：端口被占用
```
错误信息：Address already in use: 8000
解决方案：
- 修改端口：uvicorn main:app --port 8001
- 或者关闭占用 8000 端口的程序
```

---

## 📌 快速配置模板

### 最小配置（仅必填项）

```bash
# .env 最小配置
DASHSCOPE_API_KEY=sk-你的API密钥
DB_PASSWORD=你的数据库密码
ENABLE_RESULT_CACHE=false
```

### 推荐配置（含 Redis）

```bash
# .env 推荐配置
DASHSCOPE_API_KEY=sk-你的API密钥
DB_PASSWORD=你的数据库密码

REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
ENABLE_RESULT_CACHE=true
CACHE_DURATION_SECONDS=600

ENABLE_PARALLEL_EXECUTION=true
```

### 生产配置（完整优化）

```bash
# .env 生产配置
DASHSCOPE_API_KEY=sk-你的API密钥
DB_HOST=数据库地址
DB_PASSWORD=你的数据库密码

REDIS_HOST=Redis地址
REDIS_PORT=6379
REDIS_PASSWORD=Redis密码
ENABLE_RESULT_CACHE=true
CACHE_DURATION_SECONDS=600

AI_TEMPERATURE=0.7
ENABLE_PARALLEL_EXECUTION=true
AGENT_RETRY_MAX_ATTEMPTS=3

LOG_LEVEL=INFO
LOG_FORMAT=json
ENABLE_METRICS=true
```

---

## 🎯 下一步

配置完成后，请执行：

```bash
# 1. 启动 Python 服务
python main.py

# 2. 运行测试脚本
python tests/test_workflow.py

# 3. 查看日志
# 确认服务正常运行
```

如果测试通过，恭喜你！系统已经配置完成，可以开始使用了！🎉
