# 变更记录

## [3.9.4] - 2026-04-15

### 修复
- **[ruoyi-system]**: 调整培训 AI 对话链路，回答外部专业知识时先融合企业文化、服务理念、内部SOP和标准话术，再联网搜索补充门店执行建议，并收紧无结构化来源时的表述 — by 刘洋
  - 方案: [202604151812_ai-culture-websearch-context](archive/2026-04/202604151812_ai-culture-websearch-context/)
  - 决策: ai-culture-websearch-context#D001(强制联网搜索场景采用内部知识+外部搜索二次融合生成)

## [3.9.3] - 2026-04-13

### 快速修改
- **[ruoyi-system]**: 修复租户会员上限与根部门会员名额未同步导致部门分配时被错误提示“当前部门最多还能分配 0 个会员名额”的问题，并在管理端根部门界面改为只读提示避免重复配置 — by 刘洋
  - 类型: 快速修改（无方案包）
  - 文件: ruoyi-system/src/main/java/com/ruoyi/system/service/impl/SysTenantServiceImpl.java, ruoyi-system/src/main/java/com/ruoyi/system/service/impl/SysDeptServiceImpl.java, ruoyi-system/src/main/java/com/ruoyi/system/mapper/SysDeptMapper.java, ruoyi-system/src/main/resources/mapper/system/SysDeptMapper.xml, ruoyi-system/src/test/java/com/ruoyi/system/service/impl/SysTenantServiceImplTest.java, RuoYi-Vue3/src/views/system/dept/index.vue
- **[ruoyi-system]**: 修复个人中心学习报告生成后提示成功但刷新后查不到的问题，学习报告写操作统一切回 MASTER 数据源，并补充回归测试锁定数据源配置 — by 刘洋
  - 类型: 快速修改（无方案包）
  - 文件: ruoyi-system/src/main/java/com/ruoyi/train/service/impl/TrainLearningReportServiceImpl.java, ruoyi-system/src/test/java/com/ruoyi/train/service/impl/TrainLearningReportServiceImplTest.java

## [3.9.2] - 2026-03-30

### 修复
- **[training-agent-master]**: 执行后端根工程打包校验，使用 `mvn -q -DskipTests clean package` 刷新 `ruoyi-admin/target/ruoyi-admin.jar` 产物并确认输出成功 — by 刘洋
  - 方案: [202603301038_backend-package-build](archive/2026-03/202603301038_backend-package-build/)
  - 决策: backend-package-build#D001(默认只执行后端根工程 Maven 打包)

## [3.9.1] - 2026-03-30

### 修复
- **[ruoyi-framework]**: 降低管理端匿名请求触发的 token 噪音日志，将 `TokenService.getLoginUser()` 中“请求未携带Token”由 `WARN` 调整为 `DEBUG`，同时保留异常 token 与 Redis miss 的告警语义 — by 刘洋
  - 方案: [202603301032_token-missing-log-noise](archive/2026-03/202603301032_token-missing-log-noise/)
  - 决策: token-missing-log-noise#D001(空 token 分支只降日志级别，不改过滤器路径)
