/**
 * 配置数据迁移工具
 * 将旧版配置格式转换为新版动态模块格式
 * Requirements: 11.1
 */

import { 
  ModuleType, 
  createDefaultGlobalStyles,
  createPageModule 
} from '@/types/showcase'
import logger from '@/utils/logger'

/**
 * 检测配置是否为新版模块格式
 * @param {Object} config 配置对象
 * @returns {boolean}
 */
export function isNewModuleFormat(config) {
  // 检查是否有 modules 数组且不为空
  const hasModules = config && 
         config.modules && 
         Array.isArray(config.modules) && 
         config.modules.length > 0
  
  // 检查是否有 globalStyles 对象
  const hasGlobalStyles = config && 
         config.globalStyles && 
         typeof config.globalStyles === 'object'
  
  // 新版格式必须同时有 modules 和 globalStyles
  const isNew = hasModules && hasGlobalStyles
  
  logger.debug('isNewModuleFormat 检测:', {
    hasModules,
    hasGlobalStyles,
    isNew,
    modulesCount: config?.modules?.length || 0
  })
  
  return isNew
}

/**
 * 检测配置是否为旧版格式
 * @param {Object} config 配置对象
 * @returns {boolean}
 */
export function isOldFormat(config) {
  return config && 
         (config.hotelName !== undefined || 
          config.features !== undefined || 
          config.sections !== undefined)
}

/**
 * 将旧版配置迁移为新版模块格式
 * @param {Object} oldConfig 旧版配置
 * @returns {Object} 新版PageConfig格式
 */
export function migrateOldConfig(oldConfig) {
  if (!oldConfig) {
    return {
      globalStyles: createDefaultGlobalStyles(),
      modules: []
    }
  }

  // 如果已经是新格式，直接返回
  if (isNewModuleFormat(oldConfig)) {
    return oldConfig
  }

  const modules = []
  const oldStyles = oldConfig.styles || {}
  const sections = oldConfig.sections || []

  // 创建全局样式
  const globalStyles = {
    pageBackgroundColor: oldStyles.pageBackgroundColor || '#f5f5f7',
    defaultTitleFontSize: oldStyles.titleFontSize || 24,
    defaultTitleColor: oldStyles.titleColor || '#1a1a1a',
    defaultTitleFontWeight: oldStyles.titleFontWeight || '600',
    defaultContentFontSize: oldStyles.contentFontSize || 16,
    defaultContentColor: oldStyles.contentColor || '#666666',
    defaultLineHeight: oldStyles.lineHeight || 1.6,
    defaultModuleMargin: oldStyles.sectionMargin || 20,
    defaultModulePadding: oldStyles.sectionPadding || 30,
    defaultBorderRadius: oldStyles.imageBorderRadius || 12,
    defaultShadow: oldStyles.imageShadow !== false
  }

  // 根据sections顺序创建模块
  for (const section of sections) {
    if (!section.visible) continue

    switch (section.id) {
      case 'hero':
        if (oldConfig.heroImage) {
          modules.push(createHeroModule(oldConfig, oldStyles))
        }
        break
      case 'intro':
        if (oldConfig.hotelIntro) {
          modules.push(createIntroModule(oldConfig))
        }
        break
      case 'companyIntro':
        if (oldConfig.companyIntro?.visible !== false) {
          modules.push(createCompanyIntroModule(oldConfig.companyIntro))
        }
        break
      case 'foundingTeam':
        if (oldConfig.foundingTeam?.visible !== false) {
          modules.push(createFoundingTeamModule(oldConfig.foundingTeam))
        }
        break
      case 'features':
        if (oldConfig.features && oldConfig.features.length > 0) {
          for (const feature of oldConfig.features) {
            if (feature.visible !== false) {
              modules.push(createFeatureModule(feature, oldStyles))
            }
          }
        }
        break
      case 'promise':
        if (oldConfig.promise) {
          modules.push(createPromiseModule(oldConfig.promise))
        }
        break
      case 'contact':
        if (oldConfig.contact) {
          modules.push(createContactModule(oldConfig.contact))
        }
        break
    }
  }

  return { globalStyles, modules }
}

/**
 * 创建Hero模块
 */
function createHeroModule(oldConfig, oldStyles) {
  const module = createPageModule(ModuleType.HERO)
  module.titleCn = oldConfig.hotelName || ''
  module.titleEn = oldConfig.hotelSubtitle || ''
  module.images = [{ url: oldConfig.heroImage, alt: '', overlayText: '', link: '' }]
  module.size.height = oldStyles.heroImageHeight || 450
  module.size.minHeight = 320
  module.typeConfig = {
    overlayColor: 'rgba(0,0,0,0.4)',
    overlayOpacity: 0.4,
    textPosition: 'bottom',
    parallax: false
  }
  return module
}

/**
 * 创建介绍模块
 */
function createIntroModule(oldConfig) {
  const module = createPageModule(ModuleType.TEXT_ONLY)
  module.titleCn = `欢迎来到${oldConfig.hotelName || ''}`
  module.description = oldConfig.hotelIntro || ''
  module.layout.textAlign = 'center'
  return module
}

/**
 * 创建集团简介模块
 */
function createCompanyIntroModule(companyIntro) {
  if (!companyIntro) return null
  const module = createPageModule(companyIntro.image ? ModuleType.TEXT_IMAGE : ModuleType.TEXT_ONLY)
  module.titleCn = companyIntro.title || '集团简介'
  module.titleEn = companyIntro.titleEn || 'Group Introduction'
  module.description = companyIntro.content || ''
  if (companyIntro.image) {
    module.images = [{ url: companyIntro.image, alt: '', overlayText: '', link: '' }]
  }
  return module
}

/**
 * 创建创始团队模块
 */
function createFoundingTeamModule(foundingTeam) {
  if (!foundingTeam) return null
  const module = createPageModule(foundingTeam.image ? ModuleType.TEXT_IMAGE : ModuleType.TEXT_ONLY)
  module.titleCn = foundingTeam.title || '创始团队'
  module.titleEn = foundingTeam.titleEn || 'Founding Team'
  module.description = foundingTeam.content || ''
  if (foundingTeam.image) {
    module.images = [{ url: foundingTeam.image, alt: '', overlayText: '', link: '' }]
  }
  return module
}

/**
 * 创建特色模块
 */
function createFeatureModule(feature, oldStyles) {
  // 判断是轮播还是图文
  const hasGallery = feature.hasGallery && feature.galleryImages?.length > 0
  const type = hasGallery ? ModuleType.CAROUSEL : ModuleType.TEXT_IMAGE
  
  const module = createPageModule(type)
  module.titleCn = feature.titleCn || ''
  module.titleEn = feature.titleEn || ''
  module.description = feature.description || ''
  
  if (hasGallery) {
    module.images = feature.galleryImages.map(url => ({
      url,
      alt: '',
      overlayText: '',
      link: ''
    }))
    module.typeConfig = {
      autoplay: true,
      interval: 3000,
      showIndicators: true,
      indicatorStyle: 'thumbnails',
      showArrows: true
    }
  } else if (feature.image) {
    module.images = [{
      url: feature.image,
      alt: '',
      overlayText: feature.overlayText || '',
      link: ''
    }]
  }
  
  module.size.imageHeight = oldStyles.featureImageHeight || 300
  return module
}

/**
 * 创建品牌承诺模块
 */
function createPromiseModule(promise) {
  const module = createPageModule(ModuleType.TEXT_ONLY)
  module.titleCn = '品牌承诺'
  module.titleEn = 'Brand Promise'
  module.description = `${promise.mainText || ''}\n${promise.subText || ''}`
  module.layout.textAlign = 'center'
  module.styles.backgroundColor = '#f6f8fb'
  return module
}

/**
 * 创建联系模块
 */
function createContactModule(contact) {
  const module = createPageModule(ModuleType.CONTACT)
  module.titleCn = '联系我们'
  module.titleEn = 'Contact Us'
  module.typeConfig = {
    phone: contact.phone || '',
    email: contact.email || '',
    address: contact.address || '',
    qrCodeUrl: contact.qrCode || '',
    mapUrl: '',
    showIcons: true
  }
  module.styles.backgroundColor = '#1a1a1a'
  module.styles.titleColor = '#ffffff'
  module.styles.contentColor = 'rgba(255,255,255,0.9)'
  return module
}

export default {
  isNewModuleFormat,
  isOldFormat,
  migrateOldConfig
}
