# 数据同步任务日志优化

## 问题描述
后端日志中出现大量"切换到MASTER数据源"和"切换到SLAVE数据源"的INFO日志，导致日志文件快速增长，影响日志可读性。

## 问题原因

### 定时任务配置
系统配置了3个数据同步定时任务，**每10分钟执行一次**：

| 任务ID | 任务名称 | Cron表达式 | 执行频率 | 状态 |
|--------|---------|-----------|---------|------|
| 100 | 用户快照同步 | `0 0/10 * * * ?` | 每10分钟 | 启用 |
| 101 | 部门快照同步 | `0 0/10 * * * ?` | 每10分钟 | 启用 |
| 102 | 角色快照同步 | `0 0/10 * * * ?` | 每10分钟 | 启用 |

### 数据源切换逻辑
每个任务执行时会进行多次数据源切换：
1. 切换到MASTER数据源（读取主库数据）
2. 切换到SLAVE数据源（写入从库）
3. 可能再次切换回MASTER

每次切换都会输出INFO级别日志：
```java
log.info("切换到{}数据源", dsType);
```

### 日志频率计算
- 3个任务 × 每10分钟 = 每小时18次任务执行
- 每个任务至少2次数据源切换 = 每小时36条日志
- 每天 = 864条数据源切换日志

## 解决方案

### ✅ 方案1：降低日志级别（已实施）

#### 1.1 修改代码日志级别
**文件**: `training-agent-master/ruoyi-framework/src/main/java/com/ruoyi/framework/datasource/DynamicDataSourceContextHolder.java`

```java
// 修改前
log.info("切换到{}数据源", dsType);

// 修改后
log.debug("切换到{}数据源", dsType);
```

#### 1.2 配置logback过滤
**文件**: `training-agent-master/ruoyi-admin/src/main/resources/logback.xml`

添加配置：
```xml
<!-- 数据源切换日志级别控制（降低到WARN，减少日志输出） -->
<logger name="com.ruoyi.framework.datasource.DynamicDataSourceContextHolder" level="warn" />
```

**效果**：
- ✅ 数据源切换日志不再输出到控制台和日志文件
- ✅ 保持定时任务的执行频率不变
- ✅ 如需调试，可临时将级别改为DEBUG

### 方案2：调整定时任务频率（可选）

如果数据不需要如此频繁同步，可以调整Cron表达式：

**SQL脚本**: `training-agent-master/sql/adjust_sync_task_frequency.sql`

```sql
-- 改为每小时执行一次
UPDATE sys_job 
SET cron_expression = '0 0 * * * ?'
WHERE job_id IN (100, 101, 102);

-- 或改为每30分钟执行一次
UPDATE sys_job 
SET cron_expression = '0 0/30 * * * ?'
WHERE job_id IN (100, 101, 102);

-- 或改为每天凌晨2点执行一次
UPDATE sys_job 
SET cron_expression = '0 0 2 * * ?'
WHERE job_id IN (100, 101, 102);
```

### 方案3：暂停不必要的任务（可选）

如果某些同步任务不需要，可以暂停：

```sql
-- 暂停指定任务
UPDATE sys_job 
SET status = '1'  -- 1=暂停, 0=正常
WHERE job_id IN (100, 101, 102);
```

## Cron表达式说明

| 表达式 | 说明 | 执行频率 |
|--------|------|---------|
| `0 0/10 * * * ?` | 每10分钟 | 每小时6次 |
| `0 0/30 * * * ?` | 每30分钟 | 每小时2次 |
| `0 0 * * * ?` | 每小时整点 | 每小时1次 |
| `0 0 2 * * ?` | 每天凌晨2点 | 每天1次 |
| `0 0 2 * * 1` | 每周一凌晨2点 | 每周1次 |

## 实施建议

### 推荐配置（已实施）
✅ **方案1**：降低日志级别到DEBUG/WARN
- 优点：不影响功能，立即生效
- 缺点：无

### 可选优化
根据业务需求选择：

1. **数据实时性要求高**：保持10分钟同步
2. **数据实时性要求中等**：改为30分钟或1小时
3. **数据实时性要求低**：改为每天同步

## 验证方法

### 1. 检查日志输出
重启应用后，观察日志：
```bash
# 应该看不到数据源切换日志
tail -f logs/sys-info.log | grep "切换到"
```

### 2. 检查定时任务执行
在管理端查看：
- 系统管理 → 定时任务
- 查看任务执行日志

### 3. 验证数据同步
检查从库数据是否正常同步：
```sql
-- 检查从库快照表
SELECT COUNT(*) FROM hotel_training.train_users_ref;
SELECT COUNT(*) FROM hotel_training.train_depts_ref;
SELECT COUNT(*) FROM hotel_training.train_roles_ref;
```

## 相关文件

### 修改的文件
1. `training-agent-master/ruoyi-framework/src/main/java/com/ruoyi/framework/datasource/DynamicDataSourceContextHolder.java`
   - 将 `log.info` 改为 `log.debug`

2. `training-agent-master/ruoyi-admin/src/main/resources/logback.xml`
   - 添加数据源切换日志级别控制

### 相关文件（未修改）
- `training-agent-master/ruoyi-quartz/src/main/java/com/ruoyi/quartz/task/TrainSyncTask.java` - 同步任务实现
- `sys_job` 表 - 定时任务配置

## 注意事项

1. **需要重启应用**：修改logback配置后需要重启后端服务才能生效
2. **保留任务日志**：TrainSyncTask中的业务日志（如"fetched users from master: 45"）仍会正常输出
3. **调试时恢复**：如需调试数据源切换问题，可临时将日志级别改为DEBUG

## 总结

通过降低数据源切换日志级别，成功解决了日志过多的问题，同时保持了系统功能不变。如果后续发现数据同步频率过高，可以考虑调整定时任务的Cron表达式。

---
**优化日期**: 2026-01-23  
**影响范围**: 后端日志输出  
**需要重启**: ✅ 是
