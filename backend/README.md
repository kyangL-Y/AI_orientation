# training-agent-master

## 概述
`training-agent-master` 是管理端与后端主仓库，包含：
- Spring Boot 多模块后端（RuoYi 体系）
- 管理端前端 `RuoYi-Vue3`
- 业务 SQL 与验收脚本

## 关键目录
```text
training-agent-master/
├─ ruoyi-admin/         # Web入口、Controller、配置
├─ ruoyi-framework/     # 安全与框架能力
├─ ruoyi-system/        # 用户/角色/菜单等系统域
├─ ruoyi-common/        # 公共组件
├─ RuoYi-Vue3/          # 管理端前端
├─ scripts/             # 验收脚本（含 PERM-3 动态验收）
└─ docs/                # 安全与权限验收文档
```

## 构建与运行
### 后端编译
```powershell
cd E:\training_agent\training-agent-master
mvn -q -DskipTests compile
```

### 管理端前端
```powershell
cd E:\training_agent\training-agent-master\RuoYi-Vue3
npm install
npm run dev
```

## 配置说明
主要配置文件：
- `ruoyi-admin/src/main/resources/application.yml`
- `ruoyi-admin/src/main/resources/application-druid.yml`

敏感项通过环境变量注入（示例）：
- `DB_MASTER_USERNAME` / `DB_MASTER_PASSWORD`
- `DB_SLAVE_USERNAME` / `DB_SLAVE_PASSWORD`
- `REDIS_PASSWORD`
- `MAIL_USERNAME` / `MAIL_PASSWORD`

## 当前安全与权限状态（摘要）
- `@Anonymous` 已大幅收敛，仅保留必要公开接口。
- 考试管理权限链已改为 method-level 控制 + 前端按钮权限对齐。
- 角色/用户权限变更后会话强制失效机制已落地。
- 详见 `docs/` 与根目录问题清单、验收证据文档。

