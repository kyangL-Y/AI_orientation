/**
 * 属性测试 - 配置序列化round-trip正确性
 * Property-Based Test - Configuration Serialization Round-Trip Correctness
 * 
 * **Feature: module-customization, Property 8: 配置保存round-trip正确性**
 * **Validates: Requirements 11.1**
 * 
 * @description 验证任何有效的PageConfig对象，序列化后保存再读取反序列化，应得到等价的PageConfig对象
 */

import { describe, it, expect } from 'vitest'
import * as fc from 'fast-check'
import {
  ModuleType,
  LayoutType,
  PageConfig,
  PageModule,
  GlobalStyles,
  ImageConfig,
  LayoutConfig,
  SizeConfig,
  ModuleStyles,
  HeroConfig,
  CarouselConfig,
  GalleryConfig,
  ContactConfig,
  serializePageConfig,
  deserializePageConfig,
  createDefaultPageConfig,
  createPageModule,
  validatePageConfig
} from './showcase'

// ============================================
// Arbitrary Generators (生成器)
// ============================================

/**
 * 生成有效的模块类型
 */
const moduleTypeArb = fc.constantFrom(
  ModuleType.HERO,
  ModuleType.TEXT_IMAGE,
  ModuleType.TEXT_ONLY,
  ModuleType.CAROUSEL,
  ModuleType.GALLERY,
  ModuleType.CONTACT,
  ModuleType.CUSTOM_HTML
)

/**
 * 生成有效的布局类型
 */
const layoutTypeArb = fc.constantFrom(
  LayoutType.LEFT_IMAGE,
  LayoutType.RIGHT_IMAGE,
  LayoutType.TOP_IMAGE,
  LayoutType.BOTTOM_IMAGE,
  LayoutType.FULL_WIDTH,
  LayoutType.CENTER_TEXT
)

/**
 * 生成有效的文本对齐方式
 */
const textAlignArb = fc.constantFrom('left', 'center', 'right') as fc.Arbitrary<'left' | 'center' | 'right'>

/**
 * 生成有效的宽度模式
 */
const widthModeArb = fc.constantFrom('full', 'container') as fc.Arbitrary<'full' | 'container'>

/**
 * 生成有效的指示器样式
 */
const indicatorStyleArb = fc.constantFrom('dots', 'numbers', 'thumbnails') as fc.Arbitrary<'dots' | 'numbers' | 'thumbnails'>

/**
 * 生成有效的悬停效果
 */
const hoverEffectArb = fc.constantFrom('zoom', 'fade', 'none') as fc.Arbitrary<'zoom' | 'fade' | 'none'>

/**
 * 生成有效的文本位置
 */
const textPositionArb = fc.constantFrom('center', 'left', 'right', 'bottom') as fc.Arbitrary<'center' | 'left' | 'right' | 'bottom'>

/**
 * 生成有效的颜色字符串
 */
const colorArb = fc.oneof(
  fc.constant(''),
  fc.stringMatching(/^[0-9a-f]{6}$/).map(s => `#${s}`),
  fc.tuple(fc.integer({ min: 0, max: 255 }), fc.integer({ min: 0, max: 255 }), fc.integer({ min: 0, max: 255 }))
    .map(([r, g, b]) => `rgb(${r},${g},${b})`)
)

/**
 * 生成有效的URL字符串
 */
const urlArb = fc.oneof(
  fc.constant(''),
  fc.webUrl(),
  fc.string({ minLength: 1, maxLength: 50 }).map(s => `/images/${s}.jpg`)
)

/**
 * 生成ImageConfig
 */
const imageConfigArb: fc.Arbitrary<ImageConfig> = fc.record({
  url: urlArb,
  alt: fc.string({ maxLength: 100 }),
  overlayText: fc.string({ maxLength: 200 }),
  link: urlArb
})

/**
 * 生成LayoutConfig
 */
const layoutConfigArb: fc.Arbitrary<LayoutConfig> = fc.record({
  type: layoutTypeArb,
  imageRatio: fc.integer({ min: 0, max: 100 }),
  textAlign: textAlignArb,
  mobileLayout: layoutTypeArb
})

/**
 * 生成SizeConfig
 */
const sizeConfigArb: fc.Arbitrary<SizeConfig> = fc.record({
  height: fc.oneof(fc.constant('auto' as const), fc.integer({ min: 50, max: 1000 })),
  minHeight: fc.integer({ min: 0, max: 500 }),
  imageHeight: fc.integer({ min: 50, max: 800 }),
  padding: fc.integer({ min: 0, max: 100 }),
  widthMode: widthModeArb,
  mobileHeight: fc.oneof(fc.constant('auto' as const), fc.integer({ min: 50, max: 800 })),
  mobileImageHeight: fc.integer({ min: 50, max: 500 })
})

/**
 * 生成ModuleStyles
 */
const moduleStylesArb: fc.Arbitrary<ModuleStyles> = fc.record({
  backgroundColor: colorArb,
  backgroundImage: urlArb,
  titleColor: colorArb,
  titleFontSize: fc.integer({ min: 0, max: 72 }),
  contentColor: colorArb,
  contentFontSize: fc.integer({ min: 0, max: 36 }),
  borderRadius: fc.integer({ min: 0, max: 50 }),
  shadow: fc.boolean(),
  border: fc.string({ maxLength: 50 })
})

/**
 * 生成HeroConfig
 */
const heroConfigArb: fc.Arbitrary<HeroConfig> = fc.record({
  overlayColor: colorArb,
  overlayOpacity: fc.float({ min: 0, max: 1, noNaN: true }),
  textPosition: textPositionArb,
  parallax: fc.boolean()
})

/**
 * 生成CarouselConfig
 */
const carouselConfigArb: fc.Arbitrary<CarouselConfig> = fc.record({
  autoplay: fc.boolean(),
  interval: fc.integer({ min: 1000, max: 10000 }),
  showIndicators: fc.boolean(),
  indicatorStyle: indicatorStyleArb,
  showArrows: fc.boolean()
})

/**
 * 生成GalleryConfig
 */
const galleryConfigArb: fc.Arbitrary<GalleryConfig> = fc.record({
  columns: fc.integer({ min: 1, max: 6 }),
  gap: fc.integer({ min: 0, max: 50 }),
  hoverEffect: hoverEffectArb
})

/**
 * 生成ContactConfig
 */
const contactConfigArb: fc.Arbitrary<ContactConfig> = fc.record({
  phone: fc.string({ maxLength: 20 }),
  email: fc.emailAddress(),
  address: fc.string({ maxLength: 200 }),
  qrCodeUrl: urlArb,
  mapUrl: urlArb,
  showIcons: fc.boolean()
})

/**
 * 根据模块类型生成对应的typeConfig
 */
function typeConfigArb(type: string): fc.Arbitrary<any> {
  switch (type) {
    case ModuleType.HERO:
      return heroConfigArb
    case ModuleType.CAROUSEL:
      return carouselConfigArb
    case ModuleType.GALLERY:
      return galleryConfigArb
    case ModuleType.CONTACT:
      return contactConfigArb
    default:
      return fc.constant(null)
  }
}

/**
 * 生成PageModule
 */
const pageModuleArb: fc.Arbitrary<PageModule> = moduleTypeArb.chain(type =>
  fc.record({
    id: fc.uuid(),
    type: fc.constant(type),
    visible: fc.boolean(),
    mobileVisible: fc.boolean(),
    titleCn: fc.string({ maxLength: 100 }),
    titleEn: fc.string({ maxLength: 100 }),
    description: fc.string({ maxLength: 1000 }),
    images: fc.array(imageConfigArb, { maxLength: 10 }),
    layout: layoutConfigArb,
    size: sizeConfigArb,
    styles: moduleStylesArb,
    typeConfig: typeConfigArb(type)
  })
)

/**
 * 生成GlobalStyles
 */
const globalStylesArb: fc.Arbitrary<GlobalStyles> = fc.record({
  pageBackgroundColor: colorArb,
  defaultTitleFontSize: fc.integer({ min: 12, max: 48 }),
  defaultTitleColor: colorArb,
  defaultTitleFontWeight: fc.constantFrom('400', '500', '600', '700', 'normal', 'bold'),
  defaultContentFontSize: fc.integer({ min: 12, max: 24 }),
  defaultContentColor: colorArb,
  defaultLineHeight: fc.float({ min: 1, max: 2.5, noNaN: true }),
  defaultModuleMargin: fc.integer({ min: 0, max: 100 }),
  defaultModulePadding: fc.integer({ min: 0, max: 100 }),
  defaultBorderRadius: fc.integer({ min: 0, max: 50 }),
  defaultShadow: fc.boolean()
})

/**
 * 生成PageConfig
 */
const pageConfigArb: fc.Arbitrary<PageConfig> = fc.record({
  globalStyles: globalStylesArb,
  modules: fc.array(pageModuleArb, { maxLength: 20 })
})

// ============================================
// Property-Based Tests
// ============================================

describe('Showcase Types - Property-Based Tests', () => {
  /**
   * **Feature: module-customization, Property 8: 配置保存round-trip正确性**
   * **Validates: Requirements 11.1**
   * 
   * *For any* 有效的PageConfig对象，序列化后保存再读取反序列化，应得到等价的PageConfig对象
   */
  describe('Property 8: 配置保存round-trip正确性', () => {
    it('should preserve PageConfig through serialization round-trip', () => {
      fc.assert(
        fc.property(pageConfigArb, (config) => {
          // 序列化
          const serialized = serializePageConfig(config)
          
          // 反序列化
          const deserialized = deserializePageConfig(serialized)
          
          // 验证等价性
          expect(deserialized).toEqual(config)
        }),
        { numRuns: 100 }
      )
    })

    it('should produce valid JSON when serializing', () => {
      fc.assert(
        fc.property(pageConfigArb, (config) => {
          const serialized = serializePageConfig(config)
          
          // 验证是有效的JSON字符串
          expect(() => JSON.parse(serialized)).not.toThrow()
        }),
        { numRuns: 100 }
      )
    })

    it('should maintain module order through round-trip', () => {
      fc.assert(
        fc.property(pageConfigArb, (config) => {
          const serialized = serializePageConfig(config)
          const deserialized = deserializePageConfig(serialized)
          
          // 验证模块数量相同
          expect(deserialized.modules.length).toBe(config.modules.length)
          
          // 验证模块顺序相同
          for (let i = 0; i < config.modules.length; i++) {
            expect(deserialized.modules[i].id).toBe(config.modules[i].id)
          }
        }),
        { numRuns: 100 }
      )
    })

    it('should preserve all module properties through round-trip', () => {
      fc.assert(
        fc.property(pageModuleArb, (module) => {
          const config: PageConfig = {
            globalStyles: {
              pageBackgroundColor: '#ffffff',
              defaultTitleFontSize: 24,
              defaultTitleColor: '#000000',
              defaultTitleFontWeight: '600',
              defaultContentFontSize: 16,
              defaultContentColor: '#666666',
              defaultLineHeight: 1.6,
              defaultModuleMargin: 20,
              defaultModulePadding: 30,
              defaultBorderRadius: 12,
              defaultShadow: true
            },
            modules: [module]
          }
          
          const serialized = serializePageConfig(config)
          const deserialized = deserializePageConfig(serialized)
          
          // 验证模块属性完全相同
          expect(deserialized.modules[0]).toEqual(module)
        }),
        { numRuns: 100 }
      )
    })

    it('should preserve globalStyles through round-trip', () => {
      fc.assert(
        fc.property(globalStylesArb, (globalStyles) => {
          const config: PageConfig = {
            globalStyles,
            modules: []
          }
          
          const serialized = serializePageConfig(config)
          const deserialized = deserializePageConfig(serialized)
          
          // 验证全局样式完全相同
          expect(deserialized.globalStyles).toEqual(globalStyles)
        }),
        { numRuns: 100 }
      )
    })
  })

  describe('Validation Functions', () => {
    it('should validate correctly generated PageConfig objects', () => {
      fc.assert(
        fc.property(pageConfigArb, (config) => {
          expect(validatePageConfig(config)).toBe(true)
        }),
        { numRuns: 100 }
      )
    })

    it('should reject invalid objects', () => {
      expect(validatePageConfig(null)).toBe(false)
      expect(validatePageConfig(undefined)).toBe(false)
      expect(validatePageConfig({})).toBe(false)
      expect(validatePageConfig({ globalStyles: {} })).toBe(false)
      expect(validatePageConfig({ globalStyles: {}, modules: 'not-array' })).toBe(false)
    })
  })

  describe('Factory Functions', () => {
    it('should create valid modules for all module types', () => {
      fc.assert(
        fc.property(moduleTypeArb, (type) => {
          const module = createPageModule(type)
          
          expect(module.type).toBe(type)
          expect(module.id).toBeTruthy()
          expect(typeof module.visible).toBe('boolean')
          expect(typeof module.mobileVisible).toBe('boolean')
        }),
        { numRuns: 50 }
      )
    })

    it('should create unique IDs for each module', () => {
      fc.assert(
        fc.property(fc.array(moduleTypeArb, { minLength: 2, maxLength: 10 }), (types) => {
          const modules = types.map(type => createPageModule(type))
          const ids = modules.map(m => m.id)
          const uniqueIds = new Set(ids)
          
          expect(uniqueIds.size).toBe(ids.length)
        }),
        { numRuns: 50 }
      )
    })

    it('should create valid default PageConfig', () => {
      const config = createDefaultPageConfig()
      expect(validatePageConfig(config)).toBe(true)
      expect(config.modules).toEqual([])
      expect(config.globalStyles).toBeDefined()
    })
  })
})
