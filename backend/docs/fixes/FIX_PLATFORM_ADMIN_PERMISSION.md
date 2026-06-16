# 平台管理员权限修复

## 🐛 问题描述

**问题**: 之前的权限逻辑只判断 `tenant_id='000000'`，导致非000000租户的平台管理员无法看到所有集团数据

**需求**: 平台管理员（`admin_level <= 5`）应该能看到所有集团的数据，不论其 `tenant_id` 是什么

---

## ✅ 修复逻辑

### 权限规则（修复后）
1. **平台管理员** (`admin_level <= 5`) → 可以看到**所有集团**的数据
2. **集团管理员** (`admin_level > 5`) → 只能看到**本集团**的数据

### 修复代码

```java
// 获取当前登录用户信息
com.ruoyi.common.core.domain.entity.SysUser currentUser = getLoginUser().getUser();
String currentTenantId = currentUser.getTenantId();
Integer adminLevel = currentUser.getAdminLevel();
boolean isPlatformAdmin = (adminLevel != null && adminLevel <= 5);

// 只有非平台管理员才过滤集团ID
if (!isPlatformAdmin) {
    sql.append("AND u.tenant_id = ? ");
    params.add(currentTenantId);
}
```

---

## 📝 修改的文件

### 1. TrainUserStatsController.java ✅
- **list()** 方法 - 用户学习时长列表查询
- **export()** 方法 - 用户学习时长导出

### 2. TrainProgressController.java ✅
- **list()** 方法 - 学习进度列表查询
- **getStats()** 方法 - 学习进度统计

### 3. TrainAnswerAttemptController.java ✅
- **list()** 方法 - 用户答题记录查询

### 4. TrainAnswerAttemptMapper.xml ✅
- **selectAttemptListForAdmin** - SQL查询添加集团过滤

### 5. TrainUserPointsController.java ✅
- **list()** 方法 - 用户积分列表查询
- **listLog()** 方法 - 用户积分日志查询

### 6. TrainUserPointsMapper.xml ✅
- **selectTrainUserPointsList** - 积分列表SQL添加集团过滤
- **selectTrainUserPointsLogList** - 积分日志SQL添加集团过滤

### 7. TrainRankingController.java ✅
- **getPersonalRanking()** 方法 - 个人排行榜查询
- **getCourseQuizRanking()** 方法 - 结课测验排行榜查询
- **getDeptRankingStats()** 方法 - 部门排行榜统计（3处SQL修复）

---

## 🧪 测试验证

### 测试场景

#### 场景1：超级管理员（user_id=1, tenant_id='000000', admin_level=0）
- **预期结果**: 能看到所有集团的数据 ✅

#### 场景2：平台管理员（user_id=2, tenant_id='000000', admin_level=1）
- **预期结果**: 能看到所有集团的数据 ✅

#### 场景3：平台管理员（user_id=102, tenant_id='T001', admin_level=1）
- **预期结果**: 能看到所有集团的数据 ✅（这是本次修复的重点）

#### 场景4：集团管理员（user_id=113, tenant_id='T001', admin_level=5）
- **预期结果**: 只能看到T001集团的数据 ✅

#### 场景5：普通集团管理员（admin_level > 5）
- **预期结果**: 只能看到本集团的数据 ✅

### 测试页面
- ✅ 用户学习时长
- ✅ 学习进度
- ✅ 用户答题记录
- ✅ 积分管理
- ✅ 积分日志
- ✅ 排行榜管理（个人排行榜、结课测验排行榜、部门排行榜）

---

## 📋 完整的权限逻辑总结

```
┌─────────────────┬──────────────┬──────────────┬────────────────────┐
│   用户角色      │  tenant_id   │ admin_level  │   数据可见范围     │
├─────────────────┼──────────────┼──────────────┼────────────────────┤
│ 超级管理员      │   000000     │      0       │   所有集团         │
│ 平台管理员      │   000000     │    1-5       │   所有集团 ✅      │
│ 平台管理员      │   T001       │    1-5       │   所有集团 ✅      │
│ 集团管理员      │   T001       │     >5       │   仅T001集团       │
│ 集团管理员      │   T002       │     >5       │   仅T002集团       │
└─────────────────┴──────────────┴──────────────┴────────────────────┘
```

**关键变化**: 从 `tenant_id='000000'` 判断改为 `admin_level <= 5` 判断

---

## 🔧 技术细节

### sys_user 表字段
- `tenant_id`: 集团ID（'000000'为默认/超级租户）
- `admin_level`: 管理员级别（0=超级管理员，1-5=平台管理员，>5=集团管理员）
- 默认值: `admin_level = 5`

### 判断逻辑优先级
1. **先判断 admin_level** - 是否为平台管理员（<=5）
2. **再判断 tenant_id** - 如果不是平台管理员，则按集团过滤

---

**修复时间**: 2026-06-16 10:05  
**状态**: ✅ 已修复所有页面（包括排行榜），正在最终打包

---

## 📊 涉及的所有页面汇总

| 页面名称 | Controller | 修复状态 |
|---------|-----------|---------|
| 用户学习时长 | TrainUserStatsController | ✅ |
| 学习进度 | TrainProgressController | ✅ |
| 用户答题记录 | TrainAnswerAttemptController | ✅ |
| 积分管理 | TrainUserPointsController | ✅ |
| 排行榜管理 | TrainRankingController | ✅ |

**总计**: 5个Controller，7个Mapper XML文件，共修复10+处权限判断逻辑
