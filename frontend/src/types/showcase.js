/**
 * 酒店介绍页面动态模块自定义系统 - 类型定义
 * Hotel Showcase Dynamic Module Customization System - Type Definitions
 * 
 * @description 定义页面模块配置的所有接口和类型
 * @requirements 2.1-2.8
 */

// ============================================
// 枚举定义 (Enums)
// ============================================

/**
 * 模块类型枚举
 * @description 定义所有可用的模块展示类型
 */
export const ModuleType = {
  /** 顶部大图 */
  HERO: 'hero',
  /** 图文混排 */
  TEXT_IMAGE: 'textImage',
  /** 纯文字 */
  TEXT_ONLY: 'textOnly',
  /** 图片轮播 */
  CAROUSEL: 'carousel',
  /** 多图展示 */
  GALLERY: 'gallery',
  /** 联系卡片 */
  CONTACT: 'contact',
  /** 自定义HTML */
  CUSTOM_HTML: 'customHtml'
}

/**
 * 布局类型枚举
 * @description 定义模块内容的排列方式
 */
export const LayoutType = {
  /** 左图右文 */
  LEFT_IMAGE: 'leftImage',
  /** 右图左文 */
  RIGHT_IMAGE: 'rightImage',
  /** 上图下文 */
  TOP_IMAGE: 'topImage',
  /** 下图上文 */
  BOTTOM_IMAGE: 'bottomImage',
  /** 全宽图片 */
  FULL_WIDTH: 'fullWidth',
  /** 居中文字 */
  CENTER_TEXT: 'centerText'
}

/**
 * 文本对齐方式
 */
export const TextAlign = {
  LEFT: 'left',
  CENTER: 'center',
  RIGHT: 'right'
}

/**
 * 宽度模式
 */
export const WidthMode = {
  /** 全宽 */
  FULL: 'full',
  /** 容器宽度 */
  CONTAINER: 'container'
}

/**
 * 轮播指示器样式
 */
export const IndicatorStyle = {
  /** 圆点 */
  DOTS: 'dots',
  /** 数字 */
  NUMBERS: 'numbers',
  /** 缩略图 */
  THUMBNAILS: 'thumbnails'
}

/**
 * 悬停效果类型
 */
export const HoverEffect = {
  /** 放大 */
  ZOOM: 'zoom',
  /** 淡入淡出 */
  FADE: 'fade',
  /** 无效果 */
  NONE: 'none'
}

/**
 * 文本位置
 */
export const TextPosition = {
  CENTER: 'center',
  LEFT: 'left',
  RIGHT: 'right',
  BOTTOM: 'bottom'
}

// ============================================
// 工厂函数 (Factory Functions)
// ============================================

/**
 * 创建默认的图片配置
 */
export function createDefaultImageConfig() {
  return {
    url: '',
    alt: '',
    overlayText: '',
    link: ''
  }
}

/**
 * 创建默认的布局配置
 */
export function createDefaultLayoutConfig() {
  return {
    type: LayoutType.TOP_IMAGE,
    imageRatio: 50,
    textAlign: 'center',
    mobileLayout: LayoutType.TOP_IMAGE
  }
}


/**
 * 创建默认的尺寸配置
 */
export function createDefaultSizeConfig() {
  return {
    height: 'auto',
    minHeight: 200,
    imageHeight: 300,
    padding: 20,
    widthMode: 'container',
    mobileHeight: 'auto',
    mobileImageHeight: 200
  }
}

/**
 * 创建默认的模块样式配置
 */
export function createDefaultModuleStyles() {
  return {
    backgroundColor: '',
    backgroundImage: '',
    titleColor: '',
    titleFontSize: 0,
    contentColor: '',
    contentFontSize: 0,
    borderRadius: 0,
    shadow: false,
    border: ''
  }
}

/**
 * 创建默认的全局样式配置
 */
export function createDefaultGlobalStyles() {
  return {
    pageBackgroundColor: '#f5f5f7',
    defaultTitleFontSize: 24,
    defaultTitleColor: '#1a1a1a',
    defaultTitleFontWeight: '600',
    defaultContentFontSize: 16,
    defaultContentColor: '#666666',
    defaultLineHeight: 1.6,
    defaultModuleMargin: 20,
    defaultModulePadding: 30,
    defaultBorderRadius: 12,
    defaultShadow: true
  }
}

/**
 * 创建默认的Hero配置
 */
export function createDefaultHeroConfig() {
  return {
    overlayColor: 'rgba(0,0,0,0.4)',
    overlayOpacity: 0.4,
    textPosition: 'center',
    parallax: false
  }
}

/**
 * 创建默认的轮播配置
 */
export function createDefaultCarouselConfig() {
  return {
    autoplay: true,
    interval: 3000,
    showIndicators: true,
    indicatorStyle: 'dots',
    showArrows: true
  }
}

/**
 * 创建默认的多图展示配置
 */
export function createDefaultGalleryConfig() {
  return {
    columns: 3,
    gap: 16,
    hoverEffect: 'zoom'
  }
}

/**
 * 创建默认的联系卡片配置
 */
export function createDefaultContactConfig() {
  return {
    phone: '',
    email: '',
    address: '',
    qrCodeUrl: '',
    mapUrl: '',
    showIcons: true
  }
}

/**
 * 根据模块类型创建默认的类型特有配置
 * @param {string} type 模块类型
 */
export function createDefaultTypeConfig(type) {
  switch (type) {
    case ModuleType.HERO:
      return createDefaultHeroConfig()
    case ModuleType.CAROUSEL:
      return createDefaultCarouselConfig()
    case ModuleType.GALLERY:
      return createDefaultGalleryConfig()
    case ModuleType.CONTACT:
      return createDefaultContactConfig()
    default:
      return null
  }
}

/**
 * 创建新的页面模块
 * @param {string} type 模块类型
 * @param {string} [id] 可选的模块ID，不提供则自动生成
 */
export function createPageModule(type, id) {
  return {
    id: id || `module_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    type,
    visible: true,
    mobileVisible: true,
    titleCn: '',
    titleEn: '',
    description: '',
    images: [],
    layout: createDefaultLayoutConfig(),
    size: createDefaultSizeConfig(),
    styles: createDefaultModuleStyles(),
    typeConfig: createDefaultTypeConfig(type)
  }
}

/**
 * 创建默认的页面配置
 */
export function createDefaultPageConfig() {
  return {
    globalStyles: createDefaultGlobalStyles(),
    modules: []
  }
}

// ============================================
// 工具函数 (Utility Functions)
// ============================================

/**
 * 验证模块类型是否有效
 * @param {string} type 要验证的类型
 */
export function isValidModuleType(type) {
  return Object.values(ModuleType).includes(type)
}

/**
 * 验证布局类型是否有效
 * @param {string} type 要验证的布局类型
 */
export function isValidLayoutType(type) {
  return Object.values(LayoutType).includes(type)
}

/**
 * 获取模块类型的显示名称
 * @param {string} type 模块类型
 */
export function getModuleTypeName(type) {
  const names = {
    [ModuleType.HERO]: '顶部大图',
    [ModuleType.TEXT_IMAGE]: '图文混排',
    [ModuleType.TEXT_ONLY]: '纯文字',
    [ModuleType.CAROUSEL]: '图片轮播',
    [ModuleType.GALLERY]: '多图展示',
    [ModuleType.CONTACT]: '联系卡片',
    [ModuleType.CUSTOM_HTML]: '自定义HTML'
  }
  return names[type] || '未知类型'
}

/**
 * 获取布局类型的显示名称
 * @param {string} type 布局类型
 */
export function getLayoutTypeName(type) {
  const names = {
    [LayoutType.LEFT_IMAGE]: '左图右文',
    [LayoutType.RIGHT_IMAGE]: '右图左文',
    [LayoutType.TOP_IMAGE]: '上图下文',
    [LayoutType.BOTTOM_IMAGE]: '下图上文',
    [LayoutType.FULL_WIDTH]: '全宽图片',
    [LayoutType.CENTER_TEXT]: '居中文字'
  }
  return names[type] || '未知布局'
}

/**
 * 深拷贝页面配置
 * @param {Object} config 要拷贝的配置
 */
export function clonePageConfig(config) {
  return JSON.parse(JSON.stringify(config))
}

/**
 * 深拷贝页面模块
 * @param {Object} module 要拷贝的模块
 * @param {boolean} [newId=true] 是否生成新ID
 */
export function clonePageModule(module, newId = true) {
  const cloned = JSON.parse(JSON.stringify(module))
  if (newId) {
    cloned.id = `module_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  }
  return cloned
}

/**
 * 合并模块样式与全局样式
 * @param {Object} moduleStyles 模块样式
 * @param {Object} globalStyles 全局样式
 * @returns {Object} 合并后的样式对象
 */
export function mergeStyles(moduleStyles, globalStyles) {
  return {
    backgroundColor: moduleStyles.backgroundColor || globalStyles.pageBackgroundColor,
    titleColor: moduleStyles.titleColor || globalStyles.defaultTitleColor,
    titleFontSize: moduleStyles.titleFontSize || globalStyles.defaultTitleFontSize,
    contentColor: moduleStyles.contentColor || globalStyles.defaultContentColor,
    contentFontSize: moduleStyles.contentFontSize || globalStyles.defaultContentFontSize,
    borderRadius: moduleStyles.borderRadius || globalStyles.defaultBorderRadius,
    shadow: moduleStyles.shadow !== undefined ? moduleStyles.shadow : globalStyles.defaultShadow
  }
}

/**
 * 序列化页面配置为JSON字符串
 * @param {Object} config 页面配置
 */
export function serializePageConfig(config) {
  return JSON.stringify(config)
}

/**
 * 从JSON字符串反序列化页面配置
 * @param {string} json JSON字符串
 */
export function deserializePageConfig(json) {
  return JSON.parse(json)
}

/**
 * 验证页面配置的有效性
 * @param {Object} config 要验证的配置
 */
export function validatePageConfig(config) {
  if (!config || typeof config !== 'object') return false
  if (!config.globalStyles || typeof config.globalStyles !== 'object') return false
  if (!Array.isArray(config.modules)) return false
  
  // 验证每个模块
  for (const module of config.modules) {
    if (!module.id || typeof module.id !== 'string') return false
    if (!module.type || !isValidModuleType(module.type)) return false
    if (typeof module.visible !== 'boolean') return false
  }
  
  return true
}
