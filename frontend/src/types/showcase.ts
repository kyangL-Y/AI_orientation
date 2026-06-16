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
};

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
};

/**
 * 文本对齐方式
 */
export const TextAlign = {
  LEFT: 'left',
  CENTER: 'center',
  RIGHT: 'right'
};

/**
 * 宽度模式
 */
export const WidthMode = {
  /** 全宽 */
  FULL: 'full',
  /** 容器宽度 */
  CONTAINER: 'container'
};

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
};

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
};

/**
 * 文本位置
 */
export const TextPosition = {
  CENTER: 'center',
  LEFT: 'left',
  RIGHT: 'right',
  BOTTOM: 'bottom'
};

// ============================================
// 基础配置接口 (Basic Configuration Interfaces)
// ============================================

/**
 * 图片配置接口
 * @description 单张图片的完整配置
 */
export interface ImageConfig {
  /** 图片URL */
  url: string;
  /** 图片替代文本 */
  alt: string;
  /** 覆盖在图片上的文字 */
  overlayText: string;
  /** 点击图片跳转的链接 */
  link: string;
}

/**
 * 布局配置接口
 * @description 模块内容的布局设置
 */
export interface LayoutConfig {
  /** 布局类型 */
  type: string;
  /** 图片占比 (0-100) */
  imageRatio: number;
  /** 文本对齐方式 */
  textAlign: 'left' | 'center' | 'right';
  /** 移动端布局类型 */
  mobileLayout: string;
}

/**
 * 尺寸配置接口
 * @description 模块的尺寸设置
 */
export interface SizeConfig {
  /** 模块高度，可以是数字(px)或'auto' */
  height: number | 'auto';
  /** 最小高度(px) */
  minHeight: number;
  /** 图片高度(px) */
  imageHeight: number;
  /** 内边距(px) */
  padding: number;
  /** 宽度模式：全宽或容器宽度 */
  widthMode: 'full' | 'container';
  /** 移动端高度 */
  mobileHeight: number | 'auto';
  /** 移动端图片高度(px) */
  mobileImageHeight: number;
}

/**
 * 模块样式配置接口
 * @description 模块的视觉样式设置，可覆盖全局样式
 */
export interface ModuleStyles {
  /** 背景颜色 */
  backgroundColor: string;
  /** 背景图片URL */
  backgroundImage: string;
  /** 标题颜色 */
  titleColor: string;
  /** 标题字号(px) */
  titleFontSize: number;
  /** 正文颜色 */
  contentColor: string;
  /** 正文字号(px) */
  contentFontSize: number;
  /** 圆角大小(px) */
  borderRadius: number;
  /** 是否显示阴影 */
  shadow: boolean;
  /** 边框样式 */
  border: string;
}

// ============================================
// 类型特有配置接口 (Type-Specific Configuration Interfaces)
// ============================================

/**
 * 顶部大图特有配置
 * @description Hero模块的特殊配置项
 */
export interface HeroConfig {
  /** 遮罩颜色 */
  overlayColor: string;
  /** 遮罩透明度 (0-1) */
  overlayOpacity: number;
  /** 文字位置 */
  textPosition: 'center' | 'left' | 'right' | 'bottom';
  /** 是否启用视差效果 */
  parallax: boolean;
}

/**
 * 轮播特有配置
 * @description Carousel模块的特殊配置项
 */
export interface CarouselConfig {
  /** 是否自动播放 */
  autoplay: boolean;
  /** 切换间隔时间(ms) */
  interval: number;
  /** 是否显示指示器 */
  showIndicators: boolean;
  /** 指示器样式 */
  indicatorStyle: 'dots' | 'numbers' | 'thumbnails';
  /** 是否显示箭头 */
  showArrows: boolean;
}

/**
 * 多图展示特有配置
 * @description Gallery模块的特殊配置项
 */
export interface GalleryConfig {
  /** 列数 */
  columns: number;
  /** 图片间距(px) */
  gap: number;
  /** 悬停效果 */
  hoverEffect: 'zoom' | 'fade' | 'none';
}

/**
 * 联系卡片特有配置
 * @description Contact模块的特殊配置项
 */
export interface ContactConfig {
  /** 电话号码 */
  phone: string;
  /** 邮箱地址 */
  email: string;
  /** 地址 */
  address: string;
  /** 二维码图片URL */
  qrCodeUrl: string;
  /** 地图链接URL */
  mapUrl: string;
  /** 是否显示图标 */
  showIcons: boolean;
}

/**
 * 自定义HTML配置
 * @description CustomHTML模块的特殊配置项
 */
export interface CustomHtmlConfig {
  /** HTML内容 */
  htmlContent: string;
  /** 是否允许脚本执行 */
  allowScripts: boolean;
}

/**
 * 类型特有配置联合类型
 */
export type TypeConfig = HeroConfig | CarouselConfig | GalleryConfig | ContactConfig | CustomHtmlConfig | null;

// ============================================
// 页面模块接口 (Page Module Interface)
// ============================================

/**
 * 页面模块接口
 * @description 单个模块的完整配置结构
 */
export interface PageModule {
  /** 唯一标识符 */
  id: string;
  /** 模块类型 */
  type: string;
  /** 是否显示 */
  visible: boolean;
  /** 移动端是否显示 */
  mobileVisible: boolean;
  
  // 基础信息
  /** 中文标题 */
  titleCn: string;
  /** 英文标题 */
  titleEn: string;
  /** 描述/正文内容 */
  description: string;
  
  // 图片配置
  /** 图片列表 */
  images: ImageConfig[];
  
  // 布局配置
  /** 布局设置 */
  layout: LayoutConfig;
  
  // 尺寸配置
  /** 尺寸设置 */
  size: SizeConfig;
  
  // 样式配置（覆盖全局样式）
  /** 样式设置 */
  styles: ModuleStyles;
  
  // 类型特有配置
  /** 类型特有配置，根据type不同而不同 */
  typeConfig: TypeConfig;
}

// ============================================
// 全局样式接口 (Global Styles Interface)
// ============================================

/**
 * 全局样式配置接口
 * @description 页面级别的默认样式设置
 */
export interface GlobalStyles {
  // 页面背景
  /** 页面背景颜色 */
  pageBackgroundColor: string;
  
  // 默认标题样式
  /** 默认标题字号(px) */
  defaultTitleFontSize: number;
  /** 默认标题颜色 */
  defaultTitleColor: string;
  /** 默认标题字重 */
  defaultTitleFontWeight: string;
  
  // 默认正文样式
  /** 默认正文字号(px) */
  defaultContentFontSize: number;
  /** 默认正文颜色 */
  defaultContentColor: string;
  /** 默认行高 */
  defaultLineHeight: number;
  
  // 默认间距
  /** 默认模块外边距(px) */
  defaultModuleMargin: number;
  /** 默认模块内边距(px) */
  defaultModulePadding: number;
  
  // 默认圆角和阴影
  /** 默认圆角大小(px) */
  defaultBorderRadius: number;
  /** 默认是否显示阴影 */
  defaultShadow: boolean;
}

// ============================================
// 页面配置接口 (Page Configuration Interface)
// ============================================

/**
 * 页面配置接口
 * @description 完整的页面配置结构，包含全局样式和模块列表
 */
export interface PageConfig {
  /** 全局样式配置 */
  globalStyles: GlobalStyles;
  /** 模块列表（按顺序渲染） */
  modules: PageModule[];
}

// ============================================
// 工厂函数 (Factory Functions)
// ============================================

/**
 * 创建默认的图片配置
 */
export function createDefaultImageConfig(): ImageConfig {
  return {
    url: '',
    alt: '',
    overlayText: '',
    link: ''
  };
}

/**
 * 创建默认的布局配置
 */
export function createDefaultLayoutConfig(): LayoutConfig {
  return {
    type: LayoutType.TOP_IMAGE,
    imageRatio: 50,
    textAlign: 'center',
    mobileLayout: LayoutType.TOP_IMAGE
  };
}

/**
 * 创建默认的尺寸配置
 */
export function createDefaultSizeConfig(): SizeConfig {
  return {
    height: 'auto',
    minHeight: 200,
    imageHeight: 300,
    padding: 20,
    widthMode: 'container',
    mobileHeight: 'auto',
    mobileImageHeight: 200
  };
}

/**
 * 创建默认的模块样式配置
 */
export function createDefaultModuleStyles(): ModuleStyles {
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
  };
}

/**
 * 创建默认的全局样式配置
 */
export function createDefaultGlobalStyles(): GlobalStyles {
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
  };
}

/**
 * 创建默认的Hero配置
 */
export function createDefaultHeroConfig(): HeroConfig {
  return {
    overlayColor: 'rgba(0,0,0,0.4)',
    overlayOpacity: 0.4,
    textPosition: 'center',
    parallax: false
  };
}

/**
 * 创建默认的轮播配置
 */
export function createDefaultCarouselConfig(): CarouselConfig {
  return {
    autoplay: true,
    interval: 3000,
    showIndicators: true,
    indicatorStyle: 'dots',
    showArrows: true
  };
}

/**
 * 创建默认的多图展示配置
 */
export function createDefaultGalleryConfig(): GalleryConfig {
  return {
    columns: 3,
    gap: 16,
    hoverEffect: 'zoom'
  };
}

/**
 * 创建默认的联系卡片配置
 */
export function createDefaultContactConfig(): ContactConfig {
  return {
    phone: '',
    email: '',
    address: '',
    qrCodeUrl: '',
    mapUrl: '',
    showIcons: true
  };
}

/**
 * 根据模块类型创建默认的类型特有配置
 * @param type 模块类型
 */
export function createDefaultTypeConfig(type: string): TypeConfig {
  switch (type) {
    case ModuleType.HERO:
      return createDefaultHeroConfig();
    case ModuleType.CAROUSEL:
      return createDefaultCarouselConfig();
    case ModuleType.GALLERY:
      return createDefaultGalleryConfig();
    case ModuleType.CONTACT:
      return createDefaultContactConfig();
    default:
      return null;
  }
}

/**
 * 创建新的页面模块
 * @param type 模块类型
 * @param id 可选的模块ID，不提供则自动生成
 */
export function createPageModule(type: string, id?: string): PageModule {
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
  };
}

/**
 * 创建默认的页面配置
 */
export function createDefaultPageConfig(): PageConfig {
  return {
    globalStyles: createDefaultGlobalStyles(),
    modules: []
  };
}

// ============================================
// 工具函数 (Utility Functions)
// ============================================

/**
 * 验证模块类型是否有效
 * @param type 要验证的类型
 */
export function isValidModuleType(type: string): boolean {
  return Object.values(ModuleType).includes(type);
}

/**
 * 验证布局类型是否有效
 * @param type 要验证的布局类型
 */
export function isValidLayoutType(type: string): boolean {
  return Object.values(LayoutType).includes(type);
}

/**
 * 获取模块类型的显示名称
 * @param type 模块类型
 */
export function getModuleTypeName(type: string): string {
  const names: Record<string, string> = {
    [ModuleType.HERO]: '顶部大图',
    [ModuleType.TEXT_IMAGE]: '图文混排',
    [ModuleType.TEXT_ONLY]: '纯文字',
    [ModuleType.CAROUSEL]: '图片轮播',
    [ModuleType.GALLERY]: '多图展示',
    [ModuleType.CONTACT]: '联系卡片',
    [ModuleType.CUSTOM_HTML]: '自定义HTML'
  };
  return names[type] || '未知类型';
}

/**
 * 获取布局类型的显示名称
 * @param type 布局类型
 */
export function getLayoutTypeName(type: string): string {
  const names: Record<string, string> = {
    [LayoutType.LEFT_IMAGE]: '左图右文',
    [LayoutType.RIGHT_IMAGE]: '右图左文',
    [LayoutType.TOP_IMAGE]: '上图下文',
    [LayoutType.BOTTOM_IMAGE]: '下图上文',
    [LayoutType.FULL_WIDTH]: '全宽图片',
    [LayoutType.CENTER_TEXT]: '居中文字'
  };
  return names[type] || '未知布局';
}

/**
 * 深拷贝页面配置
 * @param config 要拷贝的配置
 */
export function clonePageConfig(config: PageConfig): PageConfig {
  return JSON.parse(JSON.stringify(config));
}

/**
 * 深拷贝页面模块
 * @param module 要拷贝的模块
 * @param newId 是否生成新ID
 */
export function clonePageModule(module: PageModule, newId: boolean = true): PageModule {
  const cloned = JSON.parse(JSON.stringify(module));
  if (newId) {
    cloned.id = `module_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  return cloned;
}

/**
 * 合并模块样式与全局样式
 * @param moduleStyles 模块样式
 * @param globalStyles 全局样式
 * @returns 合并后的样式对象
 */
export function mergeStyles(moduleStyles: ModuleStyles, globalStyles: GlobalStyles): Record<string, any> {
  return {
    backgroundColor: moduleStyles.backgroundColor || globalStyles.pageBackgroundColor,
    titleColor: moduleStyles.titleColor || globalStyles.defaultTitleColor,
    titleFontSize: moduleStyles.titleFontSize || globalStyles.defaultTitleFontSize,
    contentColor: moduleStyles.contentColor || globalStyles.defaultContentColor,
    contentFontSize: moduleStyles.contentFontSize || globalStyles.defaultContentFontSize,
    borderRadius: moduleStyles.borderRadius || globalStyles.defaultBorderRadius,
    shadow: moduleStyles.shadow !== undefined ? moduleStyles.shadow : globalStyles.defaultShadow
  };
}

/**
 * 序列化页面配置为JSON字符串
 * @param config 页面配置
 */
export function serializePageConfig(config: PageConfig): string {
  return JSON.stringify(config);
}

/**
 * 从JSON字符串反序列化页面配置
 * @param json JSON字符串
 */
export function deserializePageConfig(json: string): PageConfig {
  return JSON.parse(json);
}

/**
 * 验证页面配置的有效性
 * @param config 要验证的配置
 */
export function validatePageConfig(config: any): config is PageConfig {
  if (!config || typeof config !== 'object') return false;
  if (!config.globalStyles || typeof config.globalStyles !== 'object') return false;
  if (!Array.isArray(config.modules)) return false;
  
  // 验证每个模块
  for (const module of config.modules) {
    if (!module.id || typeof module.id !== 'string') return false;
    if (!module.type || !isValidModuleType(module.type)) return false;
    if (typeof module.visible !== 'boolean') return false;
  }
  
  return true;
}
