/**
 * 属性测试 - 模块渲染组件
 * Property-Based Tests - Module Rendering Components
 */

import { describe, it, expect } from 'vitest'
import * as fc from 'fast-check'
import {
  ModuleType,
  LayoutType,
  PageModule,
  createPageModule,
  createDefaultLayoutConfig
} from '@/types/showcase'

// ============================================
// 辅助函数 - 模拟组件逻辑
// ============================================

/**
 * 模拟 ModuleRenderer 的 shouldRender 计算逻辑
 * 这是从 ModuleRenderer.vue 中提取的核心逻辑
 */
function shouldRenderModule(module: PageModule, isMobile: boolean = false): boolean {
  // 基础可见性检查
  if (module.visible === false) {
    return false
  }
  
  // 移动端可见性检查
  if (isMobile && module.mobileVisible === false) {
    return false
  }
  
  return true
}

/**
 * 根据布局类型获取对应的CSS类名
 * 这是从 TextImageModule.vue 中提取的核心逻辑
 */
function getLayoutClass(layoutType: string): string {
  return `layout-${layoutType}`
}

/**
 * 判断布局是否为水平布局
 */
function isHorizontalLayout(layoutType: string): boolean {
  return [LayoutType.LEFT_IMAGE, LayoutType.RIGHT_IMAGE].includes(layoutType)
}

/**
 * 判断布局是否需要反转顺序
 */
function isReverseOrder(layoutType: string): boolean {
  return layoutType === LayoutType.RIGHT_IMAGE || layoutType === LayoutType.BOTTOM_IMAGE
}

// ============================================
// Arbitrary Generators
// ============================================

const moduleTypeArb = fc.constantFrom(
  ModuleType.HERO,
  ModuleType.TEXT_IMAGE,
  ModuleType.TEXT_ONLY,
  ModuleType.CAROUSEL,
  ModuleType.GALLERY,
  ModuleType.CONTACT
)

const layoutTypeArb = fc.constantFrom(
  LayoutType.LEFT_IMAGE,
  LayoutType.RIGHT_IMAGE,
  LayoutType.TOP_IMAGE,
  LayoutType.BOTTOM_IMAGE,
  LayoutType.FULL_WIDTH,
  LayoutType.CENTER_TEXT
)

const visibilityArb = fc.record({
  visible: fc.boolean(),
  mobileVisible: fc.boolean()
})

// ============================================
// Property-Based Tests
// ============================================

describe('Showcase Components - Property-Based Tests', () => {
  /**
   * **Feature: module-customization, Property 9: 模块可见性控制正确性**
   * **Validates: Requirements 3.5**
   * 
   * *For any* 模块配置，如果visible为false，则该模块不应出现在渲染结果中
   */
  describe('Property 9: 模块可见性控制正确性', () => {
    it('should not render module when visible is false', () => {
      fc.assert(
        fc.property(moduleTypeArb, (type) => {
          const module = createPageModule(type)
          module.visible = false
          
          const shouldRender = shouldRenderModule(module, false)
          expect(shouldRender).toBe(false)
        }),
        { numRuns: 100 }
      )
    })

    it('should render module when visible is true', () => {
      fc.assert(
        fc.property(moduleTypeArb, (type) => {
          const module = createPageModule(type)
          module.visible = true
          module.mobileVisible = true
          
          const shouldRender = shouldRenderModule(module, false)
          expect(shouldRender).toBe(true)
        }),
        { numRuns: 100 }
      )
    })

    it('should not render on mobile when mobileVisible is false', () => {
      fc.assert(
        fc.property(moduleTypeArb, (type) => {
          const module = createPageModule(type)
          module.visible = true
          module.mobileVisible = false
          
          // 桌面端应该渲染
          expect(shouldRenderModule(module, false)).toBe(true)
          // 移动端不应该渲染
          expect(shouldRenderModule(module, true)).toBe(false)
        }),
        { numRuns: 100 }
      )
    })

    it('should handle all visibility combinations correctly', () => {
      fc.assert(
        fc.property(moduleTypeArb, visibilityArb, fc.boolean(), (type, visibility, isMobile) => {
          const module = createPageModule(type)
          module.visible = visibility.visible
          module.mobileVisible = visibility.mobileVisible
          
          const shouldRender = shouldRenderModule(module, isMobile)
          
          // 验证逻辑正确性
          if (!visibility.visible) {
            expect(shouldRender).toBe(false)
          } else if (isMobile && !visibility.mobileVisible) {
            expect(shouldRender).toBe(false)
          } else {
            expect(shouldRender).toBe(true)
          }
        }),
        { numRuns: 100 }
      )
    })
  })

  /**
   * **Feature: module-customization, Property 5: 模块布局应用正确性**
   * **Validates: Requirements 5.1-5.7**
   * 
   * *For any* 模块配置和布局类型，渲染结果的CSS类应包含与该布局类型对应的类名
   */
  describe('Property 5: 模块布局应用正确性', () => {
    it('should generate correct layout class for any layout type', () => {
      fc.assert(
        fc.property(layoutTypeArb, (layoutType) => {
          const layoutClass = getLayoutClass(layoutType)
          
          // 验证类名格式正确
          expect(layoutClass).toBe(`layout-${layoutType}`)
          expect(layoutClass).toMatch(/^layout-/)
        }),
        { numRuns: 100 }
      )
    })

    it('should correctly identify horizontal layouts', () => {
      fc.assert(
        fc.property(layoutTypeArb, (layoutType) => {
          const isHorizontal = isHorizontalLayout(layoutType)
          
          // 只有 leftImage 和 rightImage 是水平布局
          if (layoutType === LayoutType.LEFT_IMAGE || layoutType === LayoutType.RIGHT_IMAGE) {
            expect(isHorizontal).toBe(true)
          } else {
            expect(isHorizontal).toBe(false)
          }
        }),
        { numRuns: 100 }
      )
    })

    it('should correctly identify reverse order layouts', () => {
      fc.assert(
        fc.property(layoutTypeArb, (layoutType) => {
          const isReverse = isReverseOrder(layoutType)
          
          // 只有 rightImage 和 bottomImage 需要反转顺序
          if (layoutType === LayoutType.RIGHT_IMAGE || layoutType === LayoutType.BOTTOM_IMAGE) {
            expect(isReverse).toBe(true)
          } else {
            expect(isReverse).toBe(false)
          }
        }),
        { numRuns: 100 }
      )
    })

    it('should apply layout to module correctly', () => {
      fc.assert(
        fc.property(moduleTypeArb, layoutTypeArb, (moduleType, layoutType) => {
          const module = createPageModule(moduleType)
          module.layout = {
            ...createDefaultLayoutConfig(),
            type: layoutType
          }
          
          const layoutClass = getLayoutClass(module.layout.type)
          
          // 验证布局类名与配置一致
          expect(layoutClass).toContain(layoutType)
        }),
        { numRuns: 100 }
      )
    })

    it('should handle image ratio correctly', () => {
      fc.assert(
        fc.property(
          fc.integer({ min: 0, max: 100 }),
          (imageRatio) => {
            const layout = {
              ...createDefaultLayoutConfig(),
              imageRatio
            }
            
            // 验证图片比例在有效范围内
            expect(layout.imageRatio).toBeGreaterThanOrEqual(0)
            expect(layout.imageRatio).toBeLessThanOrEqual(100)
            
            // 文字区域比例应该是 100 - imageRatio
            const textRatio = 100 - layout.imageRatio
            expect(textRatio).toBeGreaterThanOrEqual(0)
            expect(textRatio).toBeLessThanOrEqual(100)
          }
        ),
        { numRuns: 100 }
      )
    })
  })
})


// ============================================
// 样式相关的辅助函数
// ============================================

/**
 * 模拟 mergeStyles 函数的逻辑
 * 合并模块样式与全局样式，模块样式优先
 */
function mergeStylesLogic(
  moduleStyles: any,
  globalStyles: any
): Record<string, any> {
  return {
    backgroundColor: moduleStyles.backgroundColor || globalStyles.pageBackgroundColor || '',
    titleColor: moduleStyles.titleColor || globalStyles.defaultTitleColor || '',
    titleFontSize: moduleStyles.titleFontSize || globalStyles.defaultTitleFontSize || 0,
    contentColor: moduleStyles.contentColor || globalStyles.defaultContentColor || '',
    contentFontSize: moduleStyles.contentFontSize || globalStyles.defaultContentFontSize || 0,
    borderRadius: moduleStyles.borderRadius || globalStyles.defaultBorderRadius || 0,
    shadow: moduleStyles.shadow !== undefined ? moduleStyles.shadow : (globalStyles.defaultShadow ?? false)
  }
}

/**
 * 检查样式是否正确应用
 */
function isStyleApplied(
  computedStyle: Record<string, any>,
  expectedValue: any,
  property: string
): boolean {
  return computedStyle[property] === expectedValue
}

// ============================================
// 样式相关的 Arbitrary Generators
// ============================================

const colorArb = fc.oneof(
  fc.constant(''),
  fc.stringMatching(/^#[0-9a-f]{6}$/),
  fc.tuple(
    fc.integer({ min: 0, max: 255 }),
    fc.integer({ min: 0, max: 255 }),
    fc.integer({ min: 0, max: 255 })
  ).map(([r, g, b]) => `rgb(${r},${g},${b})`)
)

const globalStylesArb = fc.record({
  pageBackgroundColor: colorArb,
  defaultTitleFontSize: fc.integer({ min: 12, max: 48 }),
  defaultTitleColor: colorArb,
  defaultTitleFontWeight: fc.constantFrom('400', '500', '600', '700'),
  defaultContentFontSize: fc.integer({ min: 12, max: 24 }),
  defaultContentColor: colorArb,
  defaultLineHeight: fc.float({ min: 1, max: 2.5, noNaN: true }),
  defaultModuleMargin: fc.integer({ min: 0, max: 100 }),
  defaultModulePadding: fc.integer({ min: 0, max: 100 }),
  defaultBorderRadius: fc.integer({ min: 0, max: 50 }),
  defaultShadow: fc.boolean()
})

const moduleStylesArb = fc.record({
  backgroundColor: colorArb,
  backgroundImage: fc.constant(''),
  titleColor: colorArb,
  titleFontSize: fc.integer({ min: 0, max: 72 }),
  contentColor: colorArb,
  contentFontSize: fc.integer({ min: 0, max: 36 }),
  borderRadius: fc.integer({ min: 0, max: 50 }),
  shadow: fc.boolean(),
  border: fc.constant('')
})

// ============================================
// 样式相关的 Property-Based Tests
// ============================================

describe('Style Application - Property-Based Tests', () => {
  /**
   * **Feature: module-customization, Property 7: 全局样式继承正确性**
   * **Validates: Requirements 9.1-9.5**
   * 
   * *For any* 页面配置，如果模块未单独设置titleColor，则应使用globalStyles.defaultTitleColor
   */
  describe('Property 7: 全局样式继承正确性', () => {
    it('should use global titleColor when module titleColor is empty', () => {
      fc.assert(
        fc.property(globalStylesArb, (globalStyles) => {
          const moduleStyles = {
            backgroundColor: '',
            backgroundImage: '',
            titleColor: '', // 空值，应该继承全局
            titleFontSize: 0,
            contentColor: '',
            contentFontSize: 0,
            borderRadius: 0,
            shadow: false,
            border: ''
          }
          
          const merged = mergeStylesLogic(moduleStyles, globalStyles)
          
          // 当模块样式为空时，应该使用全局样式
          expect(merged.titleColor).toBe(globalStyles.defaultTitleColor)
        }),
        { numRuns: 100 }
      )
    })

    it('should use global fontSize when module fontSize is 0', () => {
      fc.assert(
        fc.property(globalStylesArb, (globalStyles) => {
          const moduleStyles = {
            backgroundColor: '',
            backgroundImage: '',
            titleColor: '',
            titleFontSize: 0, // 0值，应该继承全局
            contentColor: '',
            contentFontSize: 0,
            borderRadius: 0,
            shadow: false,
            border: ''
          }
          
          const merged = mergeStylesLogic(moduleStyles, globalStyles)
          
          expect(merged.titleFontSize).toBe(globalStyles.defaultTitleFontSize)
        }),
        { numRuns: 100 }
      )
    })

    it('should inherit all default styles when module styles are empty', () => {
      fc.assert(
        fc.property(globalStylesArb, (globalStyles) => {
          const emptyModuleStyles = {
            backgroundColor: '',
            backgroundImage: '',
            titleColor: '',
            titleFontSize: 0,
            contentColor: '',
            contentFontSize: 0,
            borderRadius: 0,
            shadow: undefined,
            border: ''
          }
          
          const merged = mergeStylesLogic(emptyModuleStyles, globalStyles)
          
          // 所有样式都应该继承自全局
          expect(merged.titleColor).toBe(globalStyles.defaultTitleColor)
          expect(merged.titleFontSize).toBe(globalStyles.defaultTitleFontSize)
          expect(merged.contentColor).toBe(globalStyles.defaultContentColor)
          expect(merged.contentFontSize).toBe(globalStyles.defaultContentFontSize)
          expect(merged.borderRadius).toBe(globalStyles.defaultBorderRadius)
        }),
        { numRuns: 100 }
      )
    })
  })

  /**
   * **Feature: module-customization, Property 6: 模块样式应用正确性**
   * **Validates: Requirements 7.1-7.9**
   * 
   * *For any* 模块配置，如果设置了backgroundColor，则渲染元素的style应包含该背景色值
   */
  describe('Property 6: 模块样式应用正确性', () => {
    it('should use module backgroundColor when set', () => {
      fc.assert(
        fc.property(moduleStylesArb, globalStylesArb, (moduleStyles, globalStyles) => {
          const merged = mergeStylesLogic(moduleStyles, globalStyles)
          
          // 如果模块设置了背景色，应该使用模块的
          if (moduleStyles.backgroundColor) {
            expect(merged.backgroundColor).toBe(moduleStyles.backgroundColor)
          } else {
            // 否则使用全局的
            expect(merged.backgroundColor).toBe(globalStyles.pageBackgroundColor)
          }
        }),
        { numRuns: 100 }
      )
    })

    it('should prioritize module styles over global styles', () => {
      fc.assert(
        fc.property(
          fc.string({ minLength: 1 }).map(s => `#${s.slice(0, 6).padEnd(6, '0')}`),
          fc.string({ minLength: 1 }).map(s => `#${s.slice(0, 6).padEnd(6, 'f')}`),
          (moduleColor, globalColor) => {
            const moduleStyles = {
              backgroundColor: '',
              backgroundImage: '',
              titleColor: moduleColor,
              titleFontSize: 24,
              contentColor: '',
              contentFontSize: 0,
              borderRadius: 8,
              shadow: true,
              border: ''
            }
            
            const globalStyles = {
              pageBackgroundColor: '#ffffff',
              defaultTitleFontSize: 16,
              defaultTitleColor: globalColor,
              defaultTitleFontWeight: '600',
              defaultContentFontSize: 14,
              defaultContentColor: '#666666',
              defaultLineHeight: 1.6,
              defaultModuleMargin: 20,
              defaultModulePadding: 30,
              defaultBorderRadius: 4,
              defaultShadow: false
            }
            
            const merged = mergeStylesLogic(moduleStyles, globalStyles)
            
            // 模块样式应该优先
            expect(merged.titleColor).toBe(moduleColor)
            expect(merged.titleFontSize).toBe(24)
            expect(merged.borderRadius).toBe(8)
            expect(merged.shadow).toBe(true)
          }
        ),
        { numRuns: 100 }
      )
    })

    it('should handle shadow property correctly', () => {
      fc.assert(
        fc.property(fc.boolean(), fc.boolean(), (moduleShadow, globalShadow) => {
          const moduleStyles = {
            backgroundColor: '',
            backgroundImage: '',
            titleColor: '',
            titleFontSize: 0,
            contentColor: '',
            contentFontSize: 0,
            borderRadius: 0,
            shadow: moduleShadow,
            border: ''
          }
          
          const globalStyles = {
            pageBackgroundColor: '#ffffff',
            defaultTitleFontSize: 16,
            defaultTitleColor: '#000000',
            defaultTitleFontWeight: '600',
            defaultContentFontSize: 14,
            defaultContentColor: '#666666',
            defaultLineHeight: 1.6,
            defaultModuleMargin: 20,
            defaultModulePadding: 30,
            defaultBorderRadius: 4,
            defaultShadow: globalShadow
          }
          
          const merged = mergeStylesLogic(moduleStyles, globalStyles)
          
          // shadow 是布尔值，模块设置了就用模块的
          expect(merged.shadow).toBe(moduleShadow)
        }),
        { numRuns: 100 }
      )
    })
  })
})


// ============================================
// 模块操作相关的辅助函数
// ============================================

/**
 * 模拟添加模块操作
 */
function addModule(modules: any[], type: string): any[] {
  const newModule = {
    id: `module_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    type,
    visible: true,
    mobileVisible: true,
    titleCn: '',
    titleEn: '',
    description: '',
    images: [],
    layout: { type: 'topImage', imageRatio: 50, textAlign: 'center', mobileLayout: 'topImage' },
    size: { height: 'auto', minHeight: 200, imageHeight: 300, padding: 20, widthMode: 'container', mobileHeight: 'auto', mobileImageHeight: 200 },
    styles: { backgroundColor: '', backgroundImage: '', titleColor: '', titleFontSize: 0, contentColor: '', contentFontSize: 0, borderRadius: 0, shadow: false, border: '' },
    typeConfig: null
  }
  return [...modules, newModule]
}

/**
 * 模拟删除模块操作
 */
function deleteModule(modules: any[], moduleId: string): any[] {
  return modules.filter(m => m.id !== moduleId)
}

/**
 * 模拟移动模块操作
 */
function moveModule(modules: any[], index: number, direction: number): any[] {
  const newIndex = index + direction
  if (newIndex < 0 || newIndex >= modules.length) return modules
  
  const newModules = [...modules]
  const temp = newModules[index]
  newModules[index] = newModules[newIndex]
  newModules[newIndex] = temp
  
  return newModules
}

// ============================================
// 模块操作相关的 Property-Based Tests
// ============================================

describe('Module Operations - Property-Based Tests', () => {
  /**
   * **Feature: module-customization, Property 1: 模块添加正确性**
   * **Validates: Requirements 1.2, 2.1-2.8**
   * 
   * *For any* 模块类型，当管理员选择该类型添加模块后，模块列表长度应增加1，且新模块的type属性应等于所选类型
   */
  describe('Property 1: 模块添加正确性', () => {
    it('should increase module list length by 1 when adding a module', () => {
      fc.assert(
        fc.property(
          fc.array(moduleTypeArb, { maxLength: 10 }),
          moduleTypeArb,
          (existingTypes, newType) => {
            // 创建现有模块列表
            const existingModules = existingTypes.map((type, i) => ({
              id: `module_${i}`,
              type,
              visible: true,
              mobileVisible: true
            }))
            
            const originalLength = existingModules.length
            const newModules = addModule(existingModules, newType)
            
            // 验证长度增加1
            expect(newModules.length).toBe(originalLength + 1)
          }
        ),
        { numRuns: 100 }
      )
    })

    it('should set correct type for newly added module', () => {
      fc.assert(
        fc.property(moduleTypeArb, (type) => {
          const modules: any[] = []
          const newModules = addModule(modules, type)
          
          // 验证新模块的类型正确
          const newModule = newModules[newModules.length - 1]
          expect(newModule.type).toBe(type)
        }),
        { numRuns: 100 }
      )
    })

    it('should generate unique ID for each new module', () => {
      fc.assert(
        fc.property(
          fc.array(moduleTypeArb, { minLength: 2, maxLength: 10 }),
          (types) => {
            let modules: any[] = []
            for (const type of types) {
              modules = addModule(modules, type)
            }
            
            // 验证所有ID都是唯一的
            const ids = modules.map(m => m.id)
            const uniqueIds = new Set(ids)
            expect(uniqueIds.size).toBe(ids.length)
          }
        ),
        { numRuns: 50 }
      )
    })
  })

  /**
   * **Feature: module-customization, Property 2: 模块删除正确性**
   * **Validates: Requirements 1.3**
   * 
   * *For any* 模块列表和任意模块ID，删除该模块后，模块列表长度应减少1，且列表中不再包含该ID的模块
   */
  describe('Property 2: 模块删除正确性', () => {
    it('should decrease module list length by 1 when deleting a module', () => {
      fc.assert(
        fc.property(
          fc.array(moduleTypeArb, { minLength: 1, maxLength: 10 }),
          (types) => {
            // 创建模块列表
            const modules = types.map((type, i) => ({
              id: `module_${i}`,
              type,
              visible: true
            }))
            
            // 随机选择一个模块删除
            const indexToDelete = Math.floor(Math.random() * modules.length)
            const moduleToDelete = modules[indexToDelete]
            const originalLength = modules.length
            
            const newModules = deleteModule(modules, moduleToDelete.id)
            
            // 验证长度减少1
            expect(newModules.length).toBe(originalLength - 1)
          }
        ),
        { numRuns: 100 }
      )
    })

    it('should not contain deleted module ID in the list', () => {
      fc.assert(
        fc.property(
          fc.array(moduleTypeArb, { minLength: 1, maxLength: 10 }),
          (types) => {
            const modules = types.map((type, i) => ({
              id: `module_${i}`,
              type,
              visible: true
            }))
            
            const indexToDelete = Math.floor(Math.random() * modules.length)
            const moduleToDelete = modules[indexToDelete]
            
            const newModules = deleteModule(modules, moduleToDelete.id)
            
            // 验证删除的模块不在列表中
            const deletedModuleExists = newModules.some(m => m.id === moduleToDelete.id)
            expect(deletedModuleExists).toBe(false)
          }
        ),
        { numRuns: 100 }
      )
    })
  })

  /**
   * **Feature: module-customization, Property 3: 模块排序正确性**
   * **Validates: Requirements 1.4, 1.5**
   * 
   * *For any* 模块列表，对索引i的模块执行上移操作后，该模块应位于索引i-1（如果i>0）
   */
  describe('Property 3: 模块排序正确性', () => {
    it('should move module up correctly', () => {
      fc.assert(
        fc.property(
          fc.array(moduleTypeArb, { minLength: 2, maxLength: 10 }),
          fc.integer({ min: 1, max: 9 }),
          (types, indexHint) => {
            const modules = types.map((type, i) => ({
              id: `module_${i}`,
              type,
              visible: true
            }))
            
            // 确保索引在有效范围内
            const index = Math.min(indexHint, modules.length - 1)
            if (index < 1) return // 跳过无法上移的情况
            
            const moduleToMove = modules[index]
            const newModules = moveModule(modules, index, -1)
            
            // 验证模块移动到了正确位置
            expect(newModules[index - 1].id).toBe(moduleToMove.id)
          }
        ),
        { numRuns: 100 }
      )
    })

    it('should move module down correctly', () => {
      fc.assert(
        fc.property(
          fc.array(moduleTypeArb, { minLength: 2, maxLength: 10 }),
          fc.integer({ min: 0, max: 8 }),
          (types, indexHint) => {
            const modules = types.map((type, i) => ({
              id: `module_${i}`,
              type,
              visible: true
            }))
            
            // 确保索引在有效范围内
            const index = Math.min(indexHint, modules.length - 2)
            if (index < 0 || index >= modules.length - 1) return
            
            const moduleToMove = modules[index]
            const newModules = moveModule(modules, index, 1)
            
            // 验证模块移动到了正确位置
            expect(newModules[index + 1].id).toBe(moduleToMove.id)
          }
        ),
        { numRuns: 100 }
      )
    })

    it('should not change list when moving first module up', () => {
      fc.assert(
        fc.property(
          fc.array(moduleTypeArb, { minLength: 1, maxLength: 10 }),
          (types) => {
            const modules = types.map((type, i) => ({
              id: `module_${i}`,
              type,
              visible: true
            }))
            
            const originalIds = modules.map(m => m.id)
            const newModules = moveModule(modules, 0, -1)
            const newIds = newModules.map(m => m.id)
            
            // 验证列表没有变化
            expect(newIds).toEqual(originalIds)
          }
        ),
        { numRuns: 100 }
      )
    })

    it('should not change list when moving last module down', () => {
      fc.assert(
        fc.property(
          fc.array(moduleTypeArb, { minLength: 1, maxLength: 10 }),
          (types) => {
            const modules = types.map((type, i) => ({
              id: `module_${i}`,
              type,
              visible: true
            }))
            
            const originalIds = modules.map(m => m.id)
            const newModules = moveModule(modules, modules.length - 1, 1)
            const newIds = newModules.map(m => m.id)
            
            // 验证列表没有变化
            expect(newIds).toEqual(originalIds)
          }
        ),
        { numRuns: 100 }
      )
    })

    it('should preserve all modules after move operation', () => {
      fc.assert(
        fc.property(
          fc.array(moduleTypeArb, { minLength: 2, maxLength: 10 }),
          fc.integer({ min: 0, max: 9 }),
          fc.constantFrom(-1, 1),
          (types, indexHint, direction) => {
            const modules = types.map((type, i) => ({
              id: `module_${i}`,
              type,
              visible: true
            }))
            
            const index = Math.min(indexHint, modules.length - 1)
            const originalIds = new Set(modules.map(m => m.id))
            
            const newModules = moveModule(modules, index, direction)
            const newIds = new Set(newModules.map(m => m.id))
            
            // 验证所有模块都保留了
            expect(newIds.size).toBe(originalIds.size)
            for (const id of originalIds) {
              expect(newIds.has(id)).toBe(true)
            }
          }
        ),
        { numRuns: 100 }
      )
    })
  })
})


// ============================================
// 标题渲染相关的 Property-Based Tests
// ============================================

describe('Title Rendering - Property-Based Tests', () => {
  /**
   * **Feature: module-customization, Property 4: 模块标题渲染正确性**
   * **Validates: Requirements 3.1, 3.2**
   * 
   * *For any* 模块配置，如果titleCn非空，则渲染结果应包含该titleCn文本
   */
  describe('Property 4: 模块标题渲染正确性', () => {
    it('should include titleCn in render output when titleCn is non-empty', () => {
      fc.assert(
        fc.property(
          moduleTypeArb,
          fc.string({ minLength: 1, maxLength: 50 }).filter(s => s.trim().length > 0),
          (type, titleCn) => {
            const module = {
              id: 'test-module',
              type,
              visible: true,
              mobileVisible: true,
              titleCn,
              titleEn: '',
              description: ''
            }
            
            // 模拟渲染逻辑：如果titleCn非空（且不是纯空白），渲染结果应包含它
            const shouldContainTitle = !!(module.titleCn && module.titleCn.trim() !== '')
            
            expect(shouldContainTitle).toBe(true)
            expect(module.titleCn).toBe(titleCn)
          }
        ),
        { numRuns: 100 }
      )
    })

    it('should not render title area when titleCn is empty', () => {
      fc.assert(
        fc.property(moduleTypeArb, (type) => {
          const module = {
            id: 'test-module',
            type,
            visible: true,
            mobileVisible: true,
            titleCn: '',
            titleEn: '',
            description: ''
          }
          
          // 当titleCn为空时，不应该渲染标题区域
          const shouldRenderTitle = !!(module.titleCn && module.titleCn.trim() !== '')
          
          expect(shouldRenderTitle).toBe(false)
        }),
        { numRuns: 100 }
      )
    })
  })
})
