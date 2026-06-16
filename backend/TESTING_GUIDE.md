# 🚀 启动和测试指南

## 第2步：启动服务并测试

### 1. 启动 Python 多智能体服务

打开 **终端1**（Git Bash 或 CMD）：

```bash
cd E:\training_agent\training-agent-muti_agent\multi_agent_system

# 激活虚拟环境
venv\Scripts\activate

# 启动服务
python main.py
```

**预期输出**：
```
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

**测试**：
```bash
curl http://localhost:8000/health
```

**预期响应**：
```json
{
  "status": "healthy",
  "redis": "connected",
  "database": "connected"
}
```

---

### 2. 启动 Java 后端

打开 **终端2**：

```bash
cd E:\training_agent\training-agent-muti_agent

# 使用 Maven 启动
mvn spring-boot:run

# 或者在 IDEA 中直接运行
```

**预期输出**：
```
Started RuoYiApplication in X.XXX seconds
```

**测试**：
```bash
curl http://localhost:8080/train/report/multi-agent/health
```

**预期响应**：
```json
{
  "code": 200,
  "msg": "多智能体服务运行正常"
}
```

---

### 3. 启动用户端前端

打开 **终端3**：

```bash
cd E:\training_agent\training-agent-user-muti_agent

# 安装依赖（首次）
npm install

# 启动开发服务器
npm run dev
```

**预期输出**：
```
VITE ready in XXXms
Local:   http://localhost:5173/
```

---

### 4. 运行集成测试

打开 **终端4**（所有服务启动后）：

```bash
cd E:\training_agent\training-agent-muti_agent
bash test_integration.sh
```

**预期输出**：
```
======================================
多智能体学习报告系统 - 集成测试
======================================

[1/5] 测试 Python 多智能体服务...
✅ Python 服务运行正常

[2/5] 测试 Java 后端服务...
✅ Java 服务运行正常

[3/5] 测试报告生成接口...
✅ 报告生成接口可访问

[4/5] 测试用户端前端...
✅ 用户端前端运行正常

[5/5] 检查配置...
✅ Python 配置文件存在
✅ DashScope API Key 已配置

======================================
测试完成
======================================
```

---

### 5. 手动测试完整流程

#### 5.1 访问用户端
1. 打开浏览器
2. 访问 `http://localhost:5173`
3. 登录系统（使用你的账号）

#### 5.2 进入学习报告页面
1. 点击左侧菜单 **学习报告**
2. 查看页面顶部是否有 `🤖 AI多智能体` 开关

#### 5.3 测试标准报告
1. 确保开关是**关闭**状态（标准报告）
2. 点击 **生成新报告** 按钮
3. 观察生成时间（约 10-15 秒）
4. 查看报告内容

#### 5.4 测试多智能体报告
1. 点击开关，**开启** `🤖 AI多智能体`
2. 点击 **生成新报告** 按钮
3. 观察生成时间（约 8-10 秒）⚡
4. 查看报告内容（应该有 AI 智能分析）

#### 5.5 预期差异

**标准报告**：
- 基础统计数据
- 简单图表

**多智能体报告**：
- ✅ AI 执行摘要
- ✅ 学习画像（⭐评价）
- ✅ 薄弱知识点分析
- ✅ AI 推荐复习内容
- ✅ 个性化课程推荐
- ✅ 学习计划建议
- ✅ 生成时间更短（30%+提升）

---

## 🐛 故障排查

### 问题1：Python 服务启动失败

```bash
# 检查依赖
pip list | grep langgraph

# 重新安装
pip install -r requirements.txt

# 检查配置
cat .env | grep DASHSCOPE_API_KEY
```

### 问题2：Java 服务启动失败

```bash
# 检查端口占用
netstat -ano | findstr "8080"

# 重新编译
mvn clean package -DskipTests
```

### 问题3：用户端连接失败

```bash
# 检查后端是否启动
curl http://localhost:8080/health

# 检查代理配置
# 查看 vite.config.js 中的 proxy 设置
```

### 问题4：多智能体服务不可用

```bash
# 检查 Python 服务
curl http://localhost:8000/health

# 检查 Java 配置
# application.yml 中的 multi.agent.enabled 是否为 true

# 检查 Python 日志
# 查看 Python 终端输出是否有错误
```

---

## 📞 测试完成后

### 如果测试成功 ✅
1. 截图保存效果
2. 继续第3步：推送代码到 GitHub

### 如果测试失败 ❌
1. 查看错误日志
2. 参考故障排查部分
3. 或者告诉我具体错误信息，我来帮你解决

---

**现在请按照上面的步骤启动服务并测试！** 🚀
