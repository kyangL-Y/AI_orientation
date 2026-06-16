# 用户学习时长 - 数据权限修复（待打包）

## 📝 修改说明

**文件**: `ruoyi-admin/src/main/java/com/ruoyi/web/controller/train/TrainUserStatsController.java`

**问题**: 集团管理员可以看到其他集团的用户学习数据

**原因**: SQL查询没有过滤 `tenant_id`（集团ID）

---

## 🔧 需要修改的代码

### 修改1: list() 方法（第52-55行）

**查找这段代码**:
```java
        try {
            logger.info("📊 获取用户学习时长统计列表 - userName: {}, deptId: {}, beginTime: {}, endTime: {}", 
                       userName, deptId, beginTime, endTime);
```

**替换为**:
```java
        try {
            // 获取当前登录用户的集团ID
            String currentTenantId = getLoginUser().getUser().getTenantId();
            logger.info("📊 获取用户学习时长统计列表 - tenantId: {}, userName: {}, deptId: {}, beginTime: {}, endTime: {}",
                       currentTenantId, userName, deptId, beginTime, endTime);
```

### 修改2: list() 方法的WHERE子句（第141-145行）

**查找这段代码**:
```java
            sql.append("  GROUP BY user_id")
               .append(") answer_stats ON u.user_id = answer_stats.user_id ")
               .append("WHERE u.del_flag = '0' ")
               // 至少有一种学习记录
               .append("AND (page_stats.user_id IS NOT NULL OR course_stats.user_id IS NOT NULL OR answer_stats.user_id IS NOT NULL) ");
```

**替换为**:
```java
            sql.append("  GROUP BY user_id")
               .append(") answer_stats ON u.user_id = answer_stats.user_id ")
               .append("WHERE u.del_flag = '0' ")
               .append("AND u.tenant_id = ? ")  // 【修复】只查询当前集团的用户
               // 至少有一种学习记录
               .append("AND (page_stats.user_id IS NOT NULL OR course_stats.user_id IS NOT NULL OR answer_stats.user_id IS NOT NULL) ");

            // 添加集团过滤参数
            params.add(currentTenantId);
```

### 修改3: export() 方法（第411-412行）

**查找这段代码**:
```java
        try {
            logger.info("📤 导出用户学习时长统计 - userName: {}, deptId: {}", userName, deptId);
```

**替换为**:
```java
        try {
            // 获取当前登录用户的集团ID
            String currentTenantId = getLoginUser().getUser().getTenantId();
            logger.info("📤 导出用户学习时长统计 - tenantId: {}, userName: {}, deptId: {}", currentTenantId, userName, deptId);
```

### 修改4: export() 方法的WHERE子句（第483-485行）

**查找这段代码**:
```java
            sql.append("  GROUP BY user_id) answer_stats ON u.user_id = answer_stats.user_id ")
               .append("WHERE u.del_flag = '0' ")
               .append("AND (page_stats.user_id IS NOT NULL OR course_stats.user_id IS NOT NULL OR answer_stats.user_id IS NOT NULL) ");
```

**替换为**:
```java
            sql.append("  GROUP BY user_id) answer_stats ON u.user_id = answer_stats.user_id ")
               .append("WHERE u.del_flag = '0' ")
               .append("AND u.tenant_id = ? ")  // 【修复】只导出当前集团的用户
               .append("AND (page_stats.user_id IS NOT NULL OR course_stats.user_id IS NOT NULL OR answer_stats.user_id IS NOT NULL) ");

            // 添加集团过滤参数
            params.add(currentTenantId);
```

---

## 📦 重新打包

修改完成后，执行以下命令重新打包：

```bash
cd /e/training_agent/training-agent-master
mvn clean package -DskipTests -pl ruoyi-admin -am
```

生成的jar包位置：`ruoyi-admin/target/ruoyi-admin.jar`

---

## 🧪 测试验证

1. 使用集团A的管理员账号登录
2. 访问：学员统计 → 用户学习时长
3. **验证**：只显示集团A的用户
4. 使用集团B的管理员账号登录
5. **验证**：只显示集团B的用户

---

## 📋 修改总结

**总共修改4处**：
1. list() 方法 - 获取当前集团ID（1处）
2. list() 方法 - WHERE子句添加tenant_id过滤（1处）
3. export() 方法 - 获取当前集团ID（1处）
4. export() 方法 - WHERE子句添加tenant_id过滤（1处）

**核心逻辑**：
- 通过 `getLoginUser().getUser().getTenantId()` 获取当前用户的集团ID
- 在SQL的WHERE子句中添加 `AND u.tenant_id = ?` 条件
- 将集团ID添加到SQL参数列表

---

**修改时间**: 2026-06-15 18:05
**状态**: ✅ 代码已修改，等待重新打包部署
**注意**: 由于项目中存在其他文件的编译错误，需要在可编译的环境中重新打包
