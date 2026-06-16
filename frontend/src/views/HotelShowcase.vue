<template>
  <div class="hotel-page" :style="pageStyle">
    <HeaderBar />
    <div class="w-full h-[56px] md:h-[80px]"></div>
    
    <!-- 新版动态模块渲染 -->
    <div v-if="useNewModuleSystem && pageConfig.modules.length > 0" class="hotel-showcase-new" :style="contentBackgroundStyle">
      <ModuleRenderer
        v-for="module in pageConfig.modules"
        :key="module.id"
        :module="module"
        :globalStyles="pageConfig.globalStyles"
        :isMobile="isMobile"
      />
    </div>
    
    <!-- 旧版兼容渲染 -->
    <div v-else-if="orderedSections && orderedSections.length > 0" class="hotel-showcase mt-4 md:mt-4" :style="contentBackgroundStyle">
      <template v-for="section in orderedSections" :key="section.id">
        <!-- 顶部大图 -->
        <div v-if="section.id === 'hero' && section.visible && config.heroImage" class="hero-section" :style="heroSectionStyle">
          <img :src="getImageUrl(config.heroImage)" :alt="config.hotelName" class="hero-image">
          <div class="hero-overlay">
            <div class="hotel-title-group">
              <h1 class="hotel-name-modern" :style="titleStyle">{{ config.hotelName }}</h1>
              <div class="hotel-subtitle">
                <span class="subtitle-text" :style="subtitleStyle">{{ config.hotelSubtitle }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- 酒店介绍 -->
        <section v-if="section.id === 'intro' && section.visible" class="intro-section">
          <div class="intro-content">
            <h2 class="text-3xl md:text-4xl font-light tracking-wide text-gray-900 mb-6">欢迎来到{{ config.hotelName }}</h2>
            <div class="w-16 h-1 bg-blue-600 mx-auto mb-8"></div>
            <p class="text-lg leading-relaxed max-w-3xl mx-auto" :style="contentStyle">{{ config.hotelIntro }}</p>
          </div>
        </section>

        <!-- 集团简介 -->
        <section v-if="section.id === 'companyIntro' && section.visible && config.companyIntro?.visible !== false" class="features-section">
          <div class="feature-module">
            <div class="art-title-wrapper">
              <h2 class="art-title-cn">{{ config.companyIntro?.title || '集团简介' }}</h2>
              <span class="art-title-en">{{ config.companyIntro?.titleEn || 'Group Introduction' }}</span>
            </div>
            <div v-if="config.companyIntro?.image && config.companyIntro.image.trim()" class="feature-image-wrapper rounded-xl overflow-hidden mb-6" :style="featureImageStyle">
              <img :src="getImageUrl(config.companyIntro.image)" :alt="config.companyIntro.title" class="transform hover:scale-105 transition-transform duration-700">
            </div>
            <p class="feature-description mt-6 text-lg font-light" :style="contentStyle">{{ config.companyIntro?.content }}</p>
          </div>
        </section>

        <!-- 创始团队 -->
        <section v-if="section.id === 'foundingTeam' && section.visible && config.foundingTeam?.visible !== false" class="features-section">
          <div class="feature-module">
            <div class="art-title-wrapper">
              <h2 class="art-title-cn">{{ config.foundingTeam?.title || '创始团队' }}</h2>
              <span class="art-title-en">{{ config.foundingTeam?.titleEn || 'Founding Team' }}</span>
            </div>
            <div v-if="config.foundingTeam?.image && config.foundingTeam.image.trim()" class="feature-image-wrapper rounded-xl overflow-hidden mb-6" :style="featureImageStyle">
              <img :src="getImageUrl(config.foundingTeam.image)" :alt="config.foundingTeam.title" class="transform hover:scale-105 transition-transform duration-700">
            </div>
            <p class="feature-description mt-6 text-lg font-light" :style="contentStyle">{{ config.foundingTeam?.content }}</p>
          </div>
        </section>

        <!-- 特色模块 -->
        <section v-if="section.id === 'features' && section.visible && visibleFeatures.length > 0" class="features-section">
          <template v-for="(feature, index) in visibleFeatures" :key="index">
            <div class="feature-module">
              <div class="art-title-wrapper">
                <h2 class="art-title-cn">{{ feature.titleCn || '未命名模块' }}</h2>
                <span class="art-title-en" v-if="feature.titleEn">{{ feature.titleEn }}</span>
              </div>
              
              <!-- 轮播图模式 -->
              <div v-if="feature.hasGallery && getValidGalleryImages(feature).length > 0" class="image-gallery">
                <div class="gallery-main rounded-xl overflow-hidden mb-4" :style="galleryImageStyle">
                  <img :src="getImageUrl(getValidGalleryImages(feature)[galleryIndexes[index] || 0])" :alt="feature.titleCn" class="w-full h-full object-cover">
                </div>
                <div class="gallery-thumbs flex justify-center gap-3">
                  <img v-for="(img, i) in getValidGalleryImages(feature)" :key="i" :src="getImageUrl(img)" :alt="feature.titleCn + (i+1)"
                    :class="{ 'ring-2 ring-offset-2 ring-blue-500 opacity-100 scale-105': (galleryIndexes[index] || 0) === i, 'opacity-60 hover:opacity-100': (galleryIndexes[index] || 0) !== i }"
                    @click="galleryIndexes[index] = i"
                    class="thumb w-20 h-16 object-cover rounded-lg cursor-pointer transition-all duration-300">
                </div>
              </div>
              
              <!-- 单图模式 -->
              <div v-else-if="feature.image && feature.image.trim()" class="feature-image-wrapper rounded-xl overflow-hidden" :style="featureImageStyle">
                <img :src="getImageUrl(feature.image)" :alt="feature.titleCn" class="transform hover:scale-105 transition-transform duration-700">
                <div v-if="feature.overlayText" class="feature-overlay backdrop-blur-sm bg-black/40">
                  <p class="overlay-text font-medium tracking-wider">{{ feature.overlayText }}</p>
                </div>
              </div>
              
              <p v-if="feature.description && feature.description.trim()" class="feature-description mt-6 text-lg font-light" :style="contentStyle">{{ feature.description }}</p>
            </div>
          </template>
        </section>

        <!-- 品牌承诺 -->
        <section v-if="section.id === 'promise' && section.visible" class="features-section">
          <div class="feature-module">
            <div class="art-title-wrapper">
              <h2 class="art-title-cn">品牌承诺</h2>
              <span class="art-title-en">Brand Promise</span>
            </div>
            <div class="promise-section bg-gradient-to-br from-gray-50 to-white rounded-2xl shadow-inner p-12 border border-gray-100">
              <div class="promise-content">
                <div class="w-20 h-20 bg-blue-50 rounded-full flex items-center justify-center mx-auto mb-6">
                  <i class="fa fa-shield promise-icon text-4xl text-blue-600"></i>
                </div>
                <p class="promise-text text-2xl text-gray-800 font-light mb-2">{{ config.promise?.mainText }}</p>
                <div class="w-12 h-1 bg-blue-600 mx-auto my-4 rounded-full"></div>
                <p class="promise-sub text-gray-500 text-lg">{{ config.promise?.subText }}</p>
              </div>
            </div>
          </div>
        </section>

        <!-- 底部联系方式 -->
        <footer v-if="section.id === 'contact' && section.visible" class="contact-section">
          <div class="contact-content">
            <div class="contact-info">
              <h3>联系我们</h3>
              <div class="contact-item"><i class="fa fa-phone"></i><span>预订热线：{{ config.contact?.phone }}</span></div>
              <div class="contact-item"><i class="fa fa-envelope"></i><span>邮箱：{{ config.contact?.email }}</span></div>
              <div class="contact-item"><i class="fa fa-map-marker"></i><span>地址：{{ config.contact?.address }}</span></div>
            </div>
            <div class="qr-section">
              <div class="qr-code">
                <img v-if="config.contact?.qrCode" :src="getImageUrl(config.contact.qrCode)" class="qr-image" />
                <div v-else class="qr-placeholder"><i class="fa fa-qrcode"></i></div>
                <p>扫码关注</p>
              </div>
            </div>
          </div>
          <div class="copyright"><p>© 2024 {{ config.hotelName }} 版权所有</p></div>
        </footer>
        
      </template>
    </div>
    
    <!-- 如果没有内容，显示提示 -->
    <div v-else style="min-height: 60vh;"></div>
  </div>
</template>

<script setup>
import logger from '@/utils/logger';
import { onMounted, ref, reactive, computed } from 'vue';
import HeaderBar from '@/components/HeaderBar.vue';
import ModuleRenderer from '@/components/showcase/ModuleRenderer.vue';
import { getMyCustomization, getDefaultCustomization } from '@/api/customization';
import { createDefaultPageConfig, createDefaultGlobalStyles, validatePageConfig } from '@/types/showcase';
import { isNewModuleFormat, isOldFormat, migrateOldConfig } from '@/utils/configMigration';
import { getTenantId } from '@/utils/tenantContext';

const galleryIndexes = reactive({});

// 是否使用新的模块系统
const useNewModuleSystem = ref(false);

// 是否为移动端
const isMobile = ref(false);

// 新版页面配置
const pageConfig = ref(createDefaultPageConfig());

const isConfigLoading = ref(true);

// 默认的sections配置（旧版兼容）
const defaultSections = [
  { id: 'hero', name: '顶部大图', visible: true },
  { id: 'intro', name: '酒店介绍', visible: true },
  { id: 'companyIntro', name: '集团简介', visible: true },
  { id: 'foundingTeam', name: '创始团队', visible: true },
  { id: 'features', name: '特色模块', visible: true },
  { id: 'promise', name: '品牌承诺', visible: true },
  { id: 'contact', name: '联系方式', visible: true }
];

const defaultConfig = {
  hotelName: '酒店及度假村',
  hotelSubtitle: '',
  hotelIntro: '',
  heroImage: '',
  features: [],
  companyIntro: { title: '集团简介', titleEn: 'Group Introduction', content: '', image: '', visible: true },
  foundingTeam: { title: '创始团队', titleEn: 'Founding Team', content: '', image: '', visible: true },
  promise: { mainText: '', subText: '' },
  contact: { phone: '', email: '', address: '', qrCode: '' },
  styles: {
    titleFontSize: 38, titleColor: '#1a1a1a', titleFontWeight: '700',
    subtitleFontSize: 15, subtitleColor: 'rgba(255,255,255,0.9)',
    contentFontSize: 18, contentColor: '#666', lineHeight: 1.6,
    heroImageHeight: 450, featureImageHeight: 300, galleryImageHeight: 350,
    imageBorderRadius: 12, imageShadow: true,
    sectionMargin: 20, sectionPadding: 30,
    pageBackgroundColor: '#f5f5f7', contentBackgroundColor: '#ffffff'
  }
};

const config = ref(null);

// 样式计算属性
const pageStyle = computed(() => {
  if (useNewModuleSystem.value) {
    return { backgroundColor: pageConfig.value.globalStyles.pageBackgroundColor || '#f5f5f7' };
  }
  return { backgroundColor: config.value?.styles?.pageBackgroundColor || '#f5f5f7' };
});

const heroSectionStyle = computed(() => {
  const height = config.value?.styles?.heroImageHeight || 450;
  return { height: `${height}px`, minHeight: `${height}px`, maxHeight: `${height}px` };
});

const titleStyle = computed(() => {
  const styles = config.value?.styles || {};
  return {
    fontSize: styles.titleFontSize ? `${styles.titleFontSize}px` : '38px',
    color: styles.titleColor || '#fff',
    fontWeight: styles.titleFontWeight || '700'
  };
});

const subtitleStyle = computed(() => {
  const styles = config.value?.styles || {};
  return {
    fontSize: styles.subtitleFontSize ? `${styles.subtitleFontSize}px` : '0.95rem',
    color: styles.subtitleColor || 'rgba(255,255,255,0.9)'
  };
});

const contentStyle = computed(() => {
  const styles = config.value?.styles || {};
  return {
    fontSize: styles.contentFontSize ? `${styles.contentFontSize}px` : '18px',
    color: styles.contentColor || '#666',
    lineHeight: styles.lineHeight || 1.6
  };
});

const featureImageStyle = computed(() => {
  const styles = config.value?.styles || {};
  return {
    height: `${styles.featureImageHeight || 300}px`,
    borderRadius: `${styles.imageBorderRadius || 12}px`,
    boxShadow: styles.imageShadow !== false ? '0 2px 30px rgba(0,0,0,0.08)' : 'none'
  };
});

const galleryImageStyle = computed(() => {
  const styles = config.value?.styles || {};
  return {
    height: `${styles.galleryImageHeight || 350}px`,
    borderRadius: `${styles.imageBorderRadius || 12}px`,
    boxShadow: styles.imageShadow !== false ? '0 2px 30px rgba(0,0,0,0.08)' : 'none'
  };
});

const contentBackgroundStyle = computed(() => {
  if (useNewModuleSystem.value) {
    const gs = pageConfig.value.globalStyles;
    return {
      backgroundColor: '#ffffff',
      margin: `${gs.defaultModuleMargin || 20}px auto`,
      padding: `${gs.defaultModulePadding || 30}px 20px`
    };
  }
  const styles = config.value?.styles || {};
  return {
    backgroundColor: styles.contentBackgroundColor || '#ffffff',
    margin: `${styles.sectionMargin || 20}px auto`,
    padding: `${styles.sectionPadding || 30}px 20px`
  };
});

const orderedSections = computed(() => {
  if (isConfigLoading.value || !config.value) return [];
  return (config.value?.sections && Array.isArray(config.value.sections)) 
    ? config.value.sections : defaultSections;
});

const visibleFeatures = computed(() => {
  if (!config.value?.features || !Array.isArray(config.value.features)) return [];
  return config.value.features.filter(f => f.visible !== false);
});

function getValidGalleryImages(feature) {
  if (!feature?.galleryImages || !Array.isArray(feature.galleryImages)) return [];
  return feature.galleryImages.filter(img => img && img.trim());
}

const BACKEND_URL = 'http://127.0.0.1:9090';

function getImageUrl(url) {
  if (!url || !url.trim()) return '';
  const trimmedUrl = url.trim();
  if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) return trimmedUrl;
  if (trimmedUrl.startsWith('/profile/')) return BACKEND_URL + trimmedUrl;
  return trimmedUrl;
}

function isLoggedIn() {
  return !!localStorage.getItem('authToken');
}

function checkMobile() {
  isMobile.value = window.innerWidth <= 768;
}

function getCookieValue(name) {
  try {
    const match = document.cookie.match(new RegExp(`(?:^|; )${name.replace(/[-[\]{}()*+?.,\\\\^$|#\\s]/g, '\\\\$&')}=([^;]*)`));
    return match ? decodeURIComponent(match[1]) : '';
  } catch {
    return '';
  }
}

function getTenantIdForCache() {
  return getTenantId();
}

function applyConfigFromParsed(parsedConfig) {
  if (isNewModuleFormat(parsedConfig) && parsedConfig?.modules && parsedConfig.modules.length > 0) {
    useNewModuleSystem.value = true;
    pageConfig.value = parsedConfig;
    config.value = null;
    return 'new';
  }

  if (isOldFormat(parsedConfig)) {
    const migratedConfig = migrateOldConfig(parsedConfig);
    if (migratedConfig && migratedConfig.modules && migratedConfig.modules.length > 0) {
      useNewModuleSystem.value = true;
      pageConfig.value = migratedConfig;
      config.value = null;
      return 'new';
    }
  }

  useNewModuleSystem.value = false;
  pageConfig.value = createDefaultPageConfig();
  config.value = {
    hotelName: parsedConfig?.hotelName || defaultConfig.hotelName,
    hotelSubtitle: parsedConfig?.hotelSubtitle || defaultConfig.hotelSubtitle,
    hotelIntro: parsedConfig?.hotelIntro || defaultConfig.hotelIntro,
    heroImage: parsedConfig?.heroImage || defaultConfig.heroImage,
    features: parsedConfig?.features || defaultConfig.features,
    companyIntro: parsedConfig?.companyIntro || defaultConfig.companyIntro,
    foundingTeam: parsedConfig?.foundingTeam || defaultConfig.foundingTeam,
    promise: parsedConfig?.promise || defaultConfig.promise,
    contact: parsedConfig?.contact || defaultConfig.contact,
    sections: parsedConfig?.sections || defaultSections,
    styles: { ...defaultConfig.styles, ...(parsedConfig?.styles || {}) }
  };
  return 'old';
}

async function loadConfig() {
  const tenantIdForCache = getTenantIdForCache();
  const cacheKey = tenantIdForCache ? `hotel_showcase_cache_${tenantIdForCache}` : '';
  let hasHydratedFromCache = false;

  if (cacheKey) {
    try {
      const cached = localStorage.getItem(cacheKey);
      if (cached) {
        const parsedCache = JSON.parse(cached);
        if (parsedCache?.data) {
          applyConfigFromParsed(parsedCache.data);
          hasHydratedFromCache = true;
        }
      }
    } catch {}
  }

  isConfigLoading.value = !hasHydratedFromCache;
  try {
    let res;
    try {
      res = isLoggedIn() ? await getMyCustomization() : await getDefaultCustomization(tenantIdForCache || undefined);
    } catch (apiErr) {
      logger.warn('API调用失败，使用默认配置:', apiErr);
      config.value = { ...defaultConfig, sections: defaultSections };
      return;
    }
    
    const response = res?.data || res;
    logger.debug('📦 酒店配置响应:', response);
    
    if (response?.code === 200 && response?.data?.hotelPageContent) {
      try {
        const parsedConfig = typeof response.data.hotelPageContent === 'string' 
          ? JSON.parse(response.data.hotelPageContent) 
          : response.data.hotelPageContent;

        const appliedMode = applyConfigFromParsed(parsedConfig);
        if (cacheKey) {
          try {
            localStorage.setItem(cacheKey, JSON.stringify({ mode: appliedMode, data: parsedConfig, updatedAt: Date.now() }));
          } catch {}
        }
      } catch (parseErr) {
        logger.error('解析配置失败:', parseErr);
        config.value = { ...defaultConfig, sections: defaultSections };
      }
    } else {
      config.value = { ...defaultConfig, sections: defaultSections };
    }
  } catch (err) {
    logger.error('加载配置失败:', err);
    config.value = { ...defaultConfig, sections: defaultSections };
  } finally {
    isConfigLoading.value = false;
  }
}

onMounted(() => {
  checkMobile();
  window.addEventListener('resize', checkMobile);
  loadConfig();
  
  // 自动轮播（旧版）
  setInterval(() => {
    if (!useNewModuleSystem.value && config.value?.features) {
      config.value.features.forEach((feature, index) => {
        if (feature.hasGallery && feature.galleryImages?.length > 1) {
          galleryIndexes[index] = ((galleryIndexes[index] || 0) + 1) % feature.galleryImages.length;
        }
      });
    }
  }, 3000);
  
  // 滚动动画
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) entry.target.classList.add('animate-in');
    });
  }, { threshold: 0.1, rootMargin: '0px 0px -50px 0px' });
  
  setTimeout(() => {
    document.querySelectorAll('.feature-module').forEach(el => observer.observe(el));
  }, 100);
});
</script>

<style scoped>
.hotel-page { background: #f5f5f7; min-height: 100vh; padding-bottom: 40px; }
.hotel-showcase, .hotel-showcase-new { width: 95%; max-width: 1200px; margin: 0 auto 20px; background: white; box-shadow: 0 2px 30px rgba(0,0,0,0.08); border-radius: 12px; overflow: hidden; }
.hero-section { position: relative; height: 45vh; min-height: 320px; max-height: 480px; overflow: hidden; }
.hero-image { width: 100%; height: 100%; object-fit: cover; }
.hero-overlay { position: absolute; bottom: 0; left: 0; right: 0; padding: 60px 40px; background: linear-gradient(to top, rgba(0,0,0,0.8), transparent); color: white; }
.hotel-title-group { text-align: left; padding-left: 60px; }
.hotel-name-modern { font-size: 3.8rem; font-weight: 700; color: #fff; margin-bottom: 20px; letter-spacing: 0.08em; font-style: italic; transform: skewX(-8deg); text-shadow: 2px 2px 4px rgba(0,0,0,0.5); }
.hotel-subtitle { font-size: 0.95rem; color: rgba(255,255,255,0.9); }
.intro-section { padding: 40px 30px; text-align: center; background: white; border-bottom: 1px solid #f0f0f0; }
.features-section { padding: 30px 20px 50px; background: white; }
.feature-module { margin-bottom: 30px; opacity: 1; transform: translateY(0); }
.feature-module.animate-in { animation: fadeInUp 0.6s ease forwards; }
.art-title-wrapper { text-align: center; margin-bottom: 30px; padding: 20px 0; position: relative; }
.art-title-wrapper::before { content: ''; position: absolute; left: 50%; top: 0; transform: translateX(-50%); width: 60px; height: 1px; background: linear-gradient(90deg, transparent, #ff5983, transparent); }
.art-title-cn { font-size: 2.2rem; font-weight: 100; letter-spacing: 12px; margin-bottom: 8px; color: #1a1a1a; }
.art-title-en { display: block; font-size: 0.8rem; letter-spacing: 3px; color: #999; text-transform: uppercase; }
.feature-image-wrapper { position: relative; width: 100%; height: 300px; overflow: hidden; margin-bottom: 15px; }
.feature-image-wrapper img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.5s ease; }
.feature-overlay { position: absolute; bottom: 0; left: 0; right: 0; background: linear-gradient(transparent, rgba(0,0,0,0.6)); padding: 20px; color: white; }
.overlay-text { font-size: 1rem; font-weight: 300; margin: 0; }
.feature-description { text-align: center; font-size: 0.9rem; color: #666; line-height: 1.6; max-width: 600px; margin: 0 auto; padding: 0 20px; }
.image-gallery { margin-bottom: 15px; }
.gallery-main { position: relative; width: 100%; height: 350px; overflow: hidden; }
.gallery-main img { width: 100%; height: 100%; object-fit: cover; }
.gallery-thumbs { display: flex; gap: 10px; justify-content: center; }
.thumb { width: 80px; height: 60px; object-fit: cover; cursor: pointer; transition: all 0.3s ease; }
.promise-section { min-height: 200px; background: linear-gradient(135deg, #f6f8fb 0%, #fff 100%); display: flex; align-items: center; justify-content: center; padding: 40px 20px; border-radius: 8px; }
.promise-content { text-align: center; }
.promise-text { font-size: 1.2rem; color: #1a1a1a; font-weight: 300; letter-spacing: 2px; }
.promise-sub { font-size: 0.9rem; color: #666; }
.contact-section { padding: 40px 30px 20px; background: #1a1a1a; color: white; }
.contact-content { display: flex; justify-content: space-between; align-items: flex-start; padding-bottom: 30px; border-bottom: 1px solid #333; }
.contact-info h3 { font-size: 1.8rem; font-weight: 300; margin-bottom: 30px; }
.contact-item { margin-bottom: 20px; font-size: 1rem; opacity: 0.9; }
.contact-item i { margin-right: 12px; width: 20px; text-align: center; }
.qr-section { text-align: center; }
.qr-placeholder, .qr-image { width: 120px; height: 120px; background: #333; border-radius: 8px; display: flex; align-items: center; justify-content: center; margin-bottom: 10px; }
.qr-image { object-fit: cover; }
.qr-placeholder i { font-size: 4rem; color: #666; }
.qr-section p { font-size: 0.9rem; opacity: 0.8; }
.copyright { text-align: center; padding-top: 30px; opacity: 0.6; font-size: 0.9rem; }
@keyframes fadeInUp { to { opacity: 1; transform: translateY(0); } }

/* ========== 移动端优化样式 ========== */
@media (max-width: 768px) {
  /* 页面容器 */
  .hotel-page {
    padding-bottom: 20px;
  }
  
  .hotel-showcase, .hotel-showcase-new {
    width: 100%;
    margin: 0 auto 10px;
    border-radius: 0;
  }
  
  /* 导航栏占位符 */
  .w-full.h-\[56px\] {
    height: 56px !important;
  }
  
  /* 顶部大图 */
  .hero-section {
    height: 35vh;
    min-height: 200px;
    max-height: 280px;
  }
  
  .hero-overlay {
    padding: 20px 15px;
  }
  
  .hotel-title-group {
    padding-left: 10px;
  }
  
  .hotel-name-modern {
    font-size: 1.75rem;
    margin-bottom: 8px;
    letter-spacing: 0.04em;
  }
  
  .hotel-subtitle {
    font-size: 0.75rem;
  }
  
  /* 酒店介绍 */
  .intro-section {
    padding: 20px 15px;
  }
  
  .intro-section h2 {
    font-size: 1.25rem !important;
    margin-bottom: 0.75rem !important;
  }
  
  .intro-section .w-16.h-1 {
    width: 2.5rem;
    margin-bottom: 1rem;
  }
  
  .intro-section p {
    font-size: 0.8125rem !important;
    line-height: 1.6 !important;
  }
  
  /* 特色模块 */
  .features-section {
    padding: 15px 12px 25px;
  }
  
  .feature-module {
    margin-bottom: 20px;
  }
  
  /* 艺术标题 */
  .art-title-wrapper {
    margin-bottom: 15px;
    padding: 12px 0;
  }
  
  .art-title-cn {
    font-size: 1.25rem;
    letter-spacing: 6px;
    margin-bottom: 4px;
  }
  
  .art-title-en {
    font-size: 0.625rem;
    letter-spacing: 2px;
  }
  
  /* 特色图片 */
  .feature-image-wrapper {
    height: 180px;
    margin-bottom: 10px;
    border-radius: 8px !important;
  }
  
  .feature-description {
    font-size: 0.75rem;
    padding: 0 10px;
    margin-top: 10px;
  }
  
  /* 图片轮播 */
  .gallery-main {
    height: 200px;
    border-radius: 8px !important;
    margin-bottom: 8px;
  }
  
  .gallery-thumbs {
    gap: 6px;
  }
  
  .thumb {
    width: 50px;
    height: 38px;
    border-radius: 4px;
  }
  
  /* 品牌承诺 */
  .promise-section {
    min-height: 140px;
    padding: 20px 15px;
    border-radius: 8px;
  }
  
  .promise-section .w-20.h-20 {
    width: 3rem;
    height: 3rem;
    margin-bottom: 0.75rem;
  }
  
  .promise-section .text-4xl {
    font-size: 1.5rem;
  }
  
  .promise-text {
    font-size: 0.9375rem;
    letter-spacing: 1px;
  }
  
  .promise-sub {
    font-size: 0.75rem;
  }
  
  /* 联系方式 */
  .contact-section {
    padding: 20px 15px 15px;
  }
  
  .contact-content {
    flex-direction: column;
    gap: 20px;
    padding-bottom: 20px;
  }
  
  .contact-info h3 {
    font-size: 1.25rem;
    margin-bottom: 15px;
  }
  
  .contact-item {
    margin-bottom: 12px;
    font-size: 0.8125rem;
  }
  
  .contact-item i {
    margin-right: 8px;
    width: 16px;
  }
  
  .qr-placeholder, .qr-image {
    width: 80px;
    height: 80px;
  }
  
  .qr-placeholder i {
    font-size: 2.5rem;
  }
  
  .qr-section p {
    font-size: 0.75rem;
  }
  
  .copyright {
    padding-top: 15px;
    font-size: 0.75rem;
  }
}

/* 超小屏幕优化 (< 375px) */
@media (max-width: 375px) {
  .hotel-name-modern {
    font-size: 1.5rem;
  }
  
  .art-title-cn {
    font-size: 1.125rem;
    letter-spacing: 4px;
  }
  
  .feature-image-wrapper {
    height: 150px;
  }
  
  .gallery-main {
    height: 160px;
  }
  
  .thumb {
    width: 40px;
    height: 30px;
  }
}
</style>


