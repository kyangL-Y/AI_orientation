# 用户学习时长 - 数据权限修复

## 🐛 问题描述

**页面**: 学员统计 → 用户学习时长

**问题**: 集团管理员可以看到其他集团的用户学习数据

**原因**: `TrainUserStatsController` 中的SQL查询没有过滤 `tenant_id`（集团ID），导致查询了所有集团的用户数据

---

## ✅ 修复内容

### 修改文件
`ruoyi-admin/src/main/java/com/ruoyi/web/controller/train/TrainUserStatsController.java`

### 修复点

#### 1. list() 方法 - 列表查询
**修复前**:
```java
sql.append("WHERE u.del_flag = '0' ")
   .append("AND (page_stats.user_id IS NOT NULL ...) ");
```

**修复后**:
```java
// 获取当前登录用户的集团ID
String currentTenantId = getLoginUser().getUser().getTenantId();

sql.append("WHERE u.del_flag = '0' ")
   .append("AND u.tenant_id = ? ")  // 【修复】只查询当前集团的用户
   .append("AND (page_stats.user_id IS NOT NULL ...) ");

params.add(currentTenantId);  // 添加集团过滤参数
```

#### 2. export() 方法 - 导出功能
同样的修复逻辑，确保导出时也只导出当前集团的数据。

---

## 🔍 修复逻辑

1. 通过 `getLoginUser().getUser().getTenantId()` 获取当前登录用户所属的集团ID
2. 在SQL的WHERE子句中添加 `u.tenant_id = ?` 条件
3. 将 `currentTenantId` 添加到参数列表中

---

## 📊 涉及的数据表

- `hz-vue.sys_user` - 用户表（包含 `tenant_id` 字段）
- `hotel_training.train_page_visit` - 页面访问记录
- `hotel_training.train_progress` - 课程学习进度
- `hotel_training.train_answer_attempt` - 答题记录

---

## 🧪 测试验证

### 测试步骤
1. 使用集团A的管理员账号登录
2. 访问：学员统计 → 用户学习时长
3. 确认只显示集团A的用户数据
4. 使用集团B的管理员账号登录
5. 确认只显示集团B的用户数据

### 预期结果
- ✅ 集团管理员只能看到本集团的用户学习数据
- ✅ 导出功能也只导出本集团的数据
- ✅ 不会看到其他集团的用户信息

---

## 📝 其他需要检查的页面

建议检查以下页面是否也存在类似问题：

1. **学员统计 → 用户答题记录** (`/train/admin/answerRecords`)
2. **学员统计 → 学习进度** (`/train/admin/progress`)
3. **学员统计 → 排行榜管理** (`/train/admin/ranking`)

如果这些页面也能看到其他集团的数据，需要采用相同的修复方式。

---

## 🚀 部署

### 1. 重新打包
```bash
cd /e/training_agent/training-agent-master
mvn package -DskipTests -pl ruoyi-admin -am
```

### 2. 停止旧服务
```bash
# 找到进程ID
ps aux | grep ruoyi-admin.jar
# 停止
kill -9 <进程ID>
```

### 3. 启动新服务
```bash
cd ruoyi-admin/target
java -jar ruoyi-admin.jar
```

### 4. 测试验证
使用不同集团的管理员账号登录测试

---

**修复时间**: 2026-06-15 18:00
**修复人员**: Claude Code
**状态**: ✅ 已修复，等待打包部署
