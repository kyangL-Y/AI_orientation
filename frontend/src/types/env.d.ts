// Vite 环境变量类型声明补充
// 该文件为 Vue CLI 提供 import.meta.env 类型支持

declare const import: {
  meta: {
    env: ImportMetaEnv
  }
}

interface ImportMetaEnv {
  // Vue CLI 兼容配置 (从 .env.vite.* 读取)
  readonly VITE_BASE_API: string

  // 应用基础配置
  readonly VITE_APP_TITLE?: string
  readonly VITE_APP_ENV?: 'development' | 'staging' | 'production'
  readonly VITE_APP_BASE_API?: string

  // 构建相关
  readonly VITE_BUILD_COMPRESS?: 'gzip' | 'brotli' | 'none'
  readonly VITE_DROP_CONSOLE?: boolean
  readonly VITE_SOURCEMAP?: boolean

  // 开发相关
  readonly VITE_APP_MOCK?: boolean
  readonly VITE_APP_DEV_TOOLS?: boolean
  readonly VITE_APP_PORT?: number

  // CDN 配置
  readonly VITE_APP_CDN_URL?: string
  readonly VITE_APP_PUBLIC_PATH?: string

  // 第三方服务配置
  readonly VITE_APP_SENTRY_DSN?: string
  readonly VITE_APP_GA_ID?: string

  // WebSocket 配置
  readonly VITE_APP_WS_URL?: string

  // 文件上传配置
  readonly VITE_APP_UPLOAD_URL?: string
  readonly VITE_APP_MAX_FILE_SIZE?: string

  // API 版本
  readonly VITE_APP_API_VERSION?: string

  // 功能开关
  readonly VITE_APP_ENABLE_PWA?: boolean
  readonly VITE_APP_ENABLE_I18N?: boolean
  readonly VITE_APP_ENABLE_THEME?: boolean

  // 调试配置
  readonly VITE_APP_DEBUG_MODE?: boolean
  readonly VITE_APP_MOCK_API?: boolean
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}