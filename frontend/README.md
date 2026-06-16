# training-agent-user

## 概述
`training-agent-user` 是面向员工学习场景的前端仓库，覆盖：
- 在线学习与课程浏览
- 考试/练习/错题复盘
- 知识库与企业文化内容
- 会员限制、积分、个人中心等

## 技术栈
- Vue 3
- Vue Router
- Element Plus
- Axios
- Quill（富文本）
- Vitest（测试）

## 目录结构
```text
training-agent-user/
├─ src/
│  ├─ api/
│  ├─ components/
│  ├─ modules/
│  ├─ utils/
│  └─ views/
├─ public/
└─ docs/
```

## 启动与校验
```powershell
cd E:\training_agent\training-agent-user
npm install
npm run dev
npm run lint
npm run test
```

## 配置文件
- `.env.development`
- `.env.production`
- `.env.staging`
- `.env.local`（本地覆盖）

## 安全约束（当前）
- 日志输出通过 `src/utils/logger.js` 统一封装，避免直接 `console.*`。
- 富文本与 HTML 渲染点逐步接入 `src/utils/security.js` 的 sanitize 边界。
- 详见根目录 `项目问题清单与改进计划.md`。

