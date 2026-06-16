# 部署指南 - 菜单问题完整解决方案

## 问题总结

1. **菜单重复折叠**：前端分组逻辑处理了后端已经分组的数据
2. **404错误（/system/ranking等）**：浏览器缓存了旧的菜单数据
3. **菜单类型错误**：刷题管理、考试管理的 menu_type 应该是 C 而不是 M

## 已完成的修复

### 数据库修复
1. ✅ 考试管理（menu_id=2002）：menu_type M→C
2. ✅ 刷题管理（menu_id=2001）：menu_type M→C

### 前端修复
1. ✅ 添加了分组检测逻辑（`normalizeTrainMenuTree`）
2. ✅ 添加了积分系统（points-system）到 TRAIN_GROUPS
3. ✅ 添加了所有 `/system/*` 到正确路径的重定向
4. ✅ 添加了详细的调试日志

### 后端修复
1. ✅ 添加了菜单数据日志输出（AdminMenuController）

## 部署步骤

### 1. 重新打包完整版本

```bash
# 停止所有服务
ps aux | grep "java.*ruoyi-admin" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null
ps aux | grep "vite\|npm" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null

# 构建前端
cd /e/training_agent/training-agent-master/RuoYi-Vue3
npm run build:prod

# 部署到后端resources
cd /e/training_agent/training-agent-master
rm -rf ruoyi-admin/src/main/resources/static/*
cp -r RuoYi-Vue3/dist/* ruoyi-admin/src/main/resources/static/

# 打包后端（包含前端）
cd ruoyi-admin
mvn clean package -DskipTests

# 新的 jar 包位置
# /e/training_agent/training-agent-master/ruoyi-admin/target/ruoyi-admin.jar
```

### 2. 启动服务

```bash
cd /e/training_agent/training-agent-master/ruoyi-admin/target
java -jar ruoyi-admin.jar
```

### 3. ⚠️ 清除浏览器缓存（重要！）

**必须清除缓存，否则会加载旧的菜单数据**：

1. 打开浏览器开发者工具（F12）
2. 右键点击地址栏的刷新按钮
3. 选择"清空缓存并硬性重新加载"

或者：

1. 按 Ctrl+Shift+Delete
2. 勾选以下选项：
   - ✅ 缓存的图片和文件
   - ✅ Cookie 和其他网站数据
   - ✅ 本地存储（localStorage）
3. 时间范围选"全部"
4. 点击"清除数据"

### 4. 重新登录测试

1. 访问：http://你的域名/admin/
2. 登录后检查：
   - ✅ 菜单是否正确分组（智囊阁、题库与练习、学员统计等）
   - ✅ 点击任何菜单是否都能正常访问（不再404）
   - ✅ 没有重复的嵌套分组

## 验证清单

- [ ] 菜单正确显示6个分组（智囊阁、题库与练习、课程与学习、考试与考核、学员统计、积分系统）
- [ ] 点击"排行榜管理"能正常打开（不再是 /system/ranking）
- [ ] 点击"用户学习时长"能正常打开
- [ ] 点击"考试管理"能正常打开
- [ ] 点击"刷题管理"能正常打开
- [ ] 所有菜单都能正常访问，没有404错误

## 调试日志

如果还有问题，查看浏览器控制台（F12 → Console）：

```
[Permission] ========== 后端返回的原始菜单数据 ==========
[normalizeTrainMenuTree] 已存在分组结构，跳过自动分组
[filterChildren] 处理子路由...
```

## 常见问题

### Q1: 菜单还是平铺的
**A**: 清除浏览器缓存并重新登录

### Q2: 还是出现404
**A**: 
1. 确认已部署最新的前端代码
2. 清除浏览器缓存
3. 检查浏览器Console中的路径拼接日志

### Q3: 集团管理员能看到其他集团数据
**A**: 需要检查具体是哪个页面，然后修复对应的后端Controller的数据权限过滤

## 文件清单

已修改的文件：
- `RuoYi-Vue3/src/store/modules/permission.js` - 菜单处理逻辑
- `RuoYi-Vue3/src/router/index.js` - 路由重定向
- `ruoyi-admin/src/main/java/com/ruoyi/web/controller/admin/AdminMenuController.java` - 菜单日志
- 数据库：sys_menu 表中的 menu_id=2001, 2002

## 联系方式

如果问题仍然存在，请提供：
1. 浏览器Console中的完整日志
2. 具体哪个菜单还有问题
3. 是否已清除缓存

生成时间：2026-06-15 17:10
