<template>
  <div class="culture-documents-page">
    <HeaderBar />
    <PageVisitTracker pageName="员工手册与制度" />
    <div v-if="readableDocuments.length" class="reading-progress" :style="{ width: `${readingProgress}%` }"></div>

    <main class="documents-shell">
      <section class="page-hero">
        <div>
          <div class="hero-kicker">
            <span class="eyebrow">HOTEL CULTURE</span>
            <span class="access-pill"><i class="fas fa-shield-alt"></i> 授权阅读</span>
          </div>
          <h1>员工手册与规章制度</h1>
          <p>南京公司专属阅读资料，聚合员工手册与规章制度总纲。</p>
        </div>
        <div v-if="readableDocuments.length" class="hero-stats">
          <div>
            <strong>{{ readableDocuments.length }}</strong>
            <span>份资料</span>
          </div>
          <div>
            <strong>{{ sectionCount }}</strong>
            <span>个章节</span>
          </div>
          <div>
            <strong>{{ paragraphCount }}</strong>
            <span>条内容</span>
          </div>
        </div>
      </section>

      <section v-if="loading" class="state-panel">
        <div class="spinner"></div>
        <span>正在加载资料...</span>
      </section>

      <section v-else-if="errorMessage" class="state-panel error-state">
        <i class="fas fa-lock"></i>
        <h2>{{ errorMessage }}</h2>
      </section>

      <section v-else-if="!readableDocuments.length" class="state-panel">
        <i class="far fa-folder-open"></i>
        <span>{{ documents.length ? '当前资料暂未配置可阅读正文' : '当前账号暂无可查看资料' }}</span>
      </section>

      <section v-else class="reader-layout">
        <aside class="document-nav" aria-label="资料目录">
          <div class="nav-panel">
            <span class="nav-title">资料</span>
            <button
              v-for="item in readableDocuments"
              :key="getDocumentId(item)"
              type="button"
              class="document-tab"
              :class="{ active: getDocumentId(item) === activeKey }"
              @click="selectDocument(item)"
            >
              <span class="tab-badge">{{ item.readable.badge }}</span>
              <strong>{{ item.readable.title }}</strong>
              <small>{{ item.readable.version }}</small>
              <em>{{ item.readable.sections.length }} 个章节</em>
            </button>
          </div>

          <div class="nav-panel toc-panel">
            <span class="nav-title">章节</span>
            <button
              v-for="section in activeDocument.sections"
              :key="section.title"
              type="button"
              class="toc-link"
              :class="{ active: activeSectionTitle === section.title }"
              @click="scrollToSection(section.title)"
            >
              {{ section.title }}
            </button>
          </div>
        </aside>

        <article class="reader-card">
          <header class="reader-header">
            <div class="reader-kicker">
              <span class="reader-badge">{{ activeDocument.badge }}</span>
              <span>{{ activeDocument.version }}</span>
            </div>
            <div class="reader-title-row">
              <div>
                <h2>{{ activeDocument.title }}</h2>
                <p>{{ activeDocument.subtitle }}</p>
              </div>
              <button
                v-if="activeSourceDocument"
                type="button"
                class="download-btn"
                :disabled="busyKey === getDocumentId(activeSourceDocument)"
                @click="downloadDocument(activeSourceDocument)"
              >
                <i class="fas fa-download"></i>
                <span>下载原 PDF</span>
              </button>
            </div>
            <div class="reader-summary">{{ activeDocument.summary }}</div>
            <dl class="reader-meta-grid">
              <div>
                <dt>资料来源</dt>
                <dd>{{ activeSourceDocument.fileName || activeDocument.title }}</dd>
              </div>
              <div>
                <dt>文件大小</dt>
                <dd>{{ activeSourceDocument.sizeLabel || '-' }}</dd>
              </div>
              <div>
                <dt>当前章节</dt>
                <dd>{{ activeSectionTitle || activeDocument.sections[0]?.title || '-' }}</dd>
              </div>
            </dl>
          </header>

          <nav class="section-chips" aria-label="章节快捷入口">
            <button
              v-for="section in activeDocument.sections"
              :key="section.title"
              type="button"
              :class="{ active: activeSectionTitle === section.title }"
              @click="scrollToSection(section.title)"
            >
              {{ section.title }}
            </button>
          </nav>

          <section
            v-for="(section, index) in activeDocument.sections"
            :key="section.title"
            :id="sectionId(section.title)"
            class="content-section"
          >
            <span v-if="section.eyebrow" class="section-eyebrow">{{ section.eyebrow }}</span>
            <h3>
              <span>{{ padSectionIndex(index + 1) }}</span>
              {{ section.title }}
            </h3>
            <div v-if="getSectionFocusItems(section).length" class="section-focus">
              <div class="section-focus-title">
                <i class="fas fa-bookmark"></i>
                <span>阅读要点</span>
              </div>
              <ul>
                <li
                  v-for="item in getSectionFocusItems(section)"
                  :key="item"
                >
                  {{ item }}
                </li>
              </ul>
            </div>
            <p
              v-for="(paragraph, paragraphIndex) in section.paragraphs"
              :key="paragraph"
              :class="{
                'lead-paragraph': paragraphIndex === 0,
                'rule-paragraph': isRuleParagraph(paragraph)
              }"
            >
              {{ paragraph }}
            </p>
          </section>
        </article>
      </section>
    </main>

    <button
      v-if="readableDocuments.length && readingProgress > 12"
      type="button"
      class="back-top-btn"
      aria-label="返回顶部"
      @click="scrollToTop"
    >
      <i class="fas fa-arrow-up"></i>
    </button>
  </div>
</template>

<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import HeaderBar from '@/components/HeaderBar.vue'
import PageVisitTracker from '@/components/PageVisitTracker.vue'
import { getHotelCultureDocumentBlob, getHotelCultureDocuments } from '@/api/hotelCultureDocuments'
import logger from '@/utils/logger'

const loading = ref(true)
const documents = ref([])
const errorMessage = ref('')
const busyKey = ref('')
const activeKey = ref('')
const activeSectionTitle = ref('')
const readingProgress = ref(0)
let sectionObserver = null

const parseResponseData = (response) => response?.data?.data || response?.data || []

const readableDocuments = computed(() => documents.value.filter(item => item?.readable?.sections?.length))

const activeSourceDocument = computed(() => {
  return readableDocuments.value.find(item => getDocumentId(item) === activeKey.value) || readableDocuments.value[0] || null
})

const activeDocument = computed(() => activeSourceDocument.value?.readable || {
  title: '',
  subtitle: '',
  version: '',
  badge: '',
  summary: '',
  sections: []
})

const sectionCount = computed(() => readableDocuments.value.reduce((total, item) => total + (item.readable?.sections?.length || 0), 0))

const paragraphCount = computed(() => readableDocuments.value.reduce((total, item) => {
  return total + (item.readable?.sections || []).reduce((count, section) => count + (section.paragraphs?.length || 0), 0)
}, 0))

const getFriendlyError = (error) => {
  const status = error?.response?.status
  const msg = error?.response?.data?.msg
  if (status === 403) return msg || '仅南京公司员工可查看该资料'
  if (status === 401) return '请先登录后查看资料'
  return msg || '资料暂时无法加载'
}

const loadDocuments = async () => {
  loading.value = true
  errorMessage.value = ''
  try {
    const response = await getHotelCultureDocuments()
    documents.value = parseResponseData(response)
    if (!activeKey.value && readableDocuments.value.length) {
      activeKey.value = getDocumentId(readableDocuments.value[0])
    }
  } catch (error) {
    logger.warn('[酒店文化资料] 加载失败', error)
    errorMessage.value = getFriendlyError(error)
  } finally {
    loading.value = false
  }
}

const getDocumentId = (doc) => doc.id || doc.documentId || doc.key

const selectDocument = (doc) => {
  activeKey.value = getDocumentId(doc)
  nextTick(() => {
    document.querySelector('.reader-card')?.scrollIntoView({ behavior: 'smooth', block: 'start' })
  })
}

const fetchDocumentBlob = async (doc) => {
  const documentId = getDocumentId(doc)
  busyKey.value = documentId
  try {
    const response = await getHotelCultureDocumentBlob(documentId)
    return new Blob([response.data], { type: doc.fileType === 'pdf' ? 'application/pdf' : 'application/octet-stream' })
  } finally {
    busyKey.value = ''
  }
}

const downloadDocument = async (doc) => {
  try {
    const blob = await fetchDocumentBlob(doc)
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = doc.fileName || `${getDocumentId(doc)}`
    document.body.appendChild(link)
    link.click()
    link.remove()
    URL.revokeObjectURL(url)
  } catch (error) {
    logger.warn('[酒店文化资料] 下载失败', error)
    errorMessage.value = getFriendlyError(error)
  }
}

const sectionId = (title) => `section-${activeKey.value}-${title.replace(/[^\u4e00-\u9fa5a-zA-Z0-9]/g, '')}`

const scrollToSection = (title) => {
  const target = document.getElementById(sectionId(title))
  target?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

const scrollToTop = () => {
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const padSectionIndex = (index) => String(index).padStart(2, '0')

const STRICT_RULE_PATTERN = /红线[一二三]|必须|不得|严禁|禁止|缺一不可|解除劳动合同|不支付.*经济补偿|一经发现|立即|第一时间|须提前|须当天|须在|不得隐瞒|移交司法机关/

const isRuleParagraph = (paragraph = '') => {
  const compactText = paragraph.replace(/\s/g, '')
  return STRICT_RULE_PATTERN.test(compactText)
}

const getSectionFocusItems = (section = {}) => {
  const explicitItems = section.focusItems || section.highlights || section.keyPoints
  if (Array.isArray(explicitItems) && explicitItems.length) {
    return explicitItems.slice(0, 4)
  }

  return (section.paragraphs || [])
    .filter(isRuleParagraph)
    .map(toFocusItem)
    .filter(Boolean)
    .slice(0, 3)
}

const toFocusItem = (paragraph = '') => {
  const [label, detail] = paragraph.split(/[：:]/)
  if (detail && label.length <= 14) {
    return `${label}：${trimFocusText(detail)}`
  }
  return trimFocusText(paragraph)
}

const trimFocusText = (text = '') => {
  const normalized = text.replace(/\s+/g, ' ').trim()
  return normalized.length > 54 ? `${normalized.slice(0, 54)}...` : normalized
}

const updateReadingProgress = () => {
  const scrollTop = window.scrollY || document.documentElement.scrollTop
  const maxScroll = Math.max(1, document.documentElement.scrollHeight - window.innerHeight)
  readingProgress.value = Math.min(100, Math.max(0, Math.round((scrollTop / maxScroll) * 100)))
}

const setupSectionObserver = () => {
  sectionObserver?.disconnect()
  activeSectionTitle.value = activeDocument.value.sections?.[0]?.title || ''
  sectionObserver = new IntersectionObserver((entries) => {
    const visible = entries
      .filter(entry => entry.isIntersecting)
      .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0]
    if (visible?.target?.dataset?.title) {
      activeSectionTitle.value = visible.target.dataset.title
    }
  }, { rootMargin: '-96px 0px -58% 0px', threshold: [0.1, 0.35] })

  activeDocument.value.sections.forEach(section => {
    const el = document.getElementById(sectionId(section.title))
    if (el) {
      el.dataset.title = section.title
      sectionObserver.observe(el)
    }
  })
}

watch(activeKey, () => {
  nextTick(setupSectionObserver)
})

onMounted(async () => {
  await loadDocuments()
  await nextTick()
  setupSectionObserver()
  updateReadingProgress()
  window.addEventListener('scroll', updateReadingProgress, { passive: true })
})

onUnmounted(() => {
  sectionObserver?.disconnect()
  window.removeEventListener('scroll', updateReadingProgress)
})
</script>

<style scoped>
.culture-documents-page {
  min-height: 100vh;
  background:
    linear-gradient(180deg, #eef4f8 0%, #f7f9fb 260px, #f4f6f8 100%);
  color: #172033;
}

.reading-progress {
  position: fixed;
  top: 64px;
  left: 0;
  z-index: 999;
  height: 3px;
  background: linear-gradient(90deg, #0f766e, #2563eb);
  transition: width 0.15s ease;
}

.documents-shell {
  width: min(1200px, calc(100% - 32px));
  margin: 0 auto;
  padding: 104px 0 56px;
}

.page-hero {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 28px;
  min-height: 188px;
  padding: 28px 0 30px;
  border-bottom: 1px solid #dbe2ea;
}

.eyebrow,
.section-eyebrow {
  display: inline-block;
  color: #0f766e;
  font-size: 12px;
  font-weight: 700;
}

.eyebrow {
  margin-bottom: 10px;
  letter-spacing: 0.16em;
}

.page-hero h1 {
  margin: 0;
  font-size: 36px;
  line-height: 1.2;
  font-weight: 800;
  color: #0f172a;
}

.page-hero p {
  margin: 10px 0 0;
  color: #64748b;
  font-size: 15px;
  line-height: 1.7;
}

.hero-kicker {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 10px;
}

.access-pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 26px;
  padding: 0 10px;
  border: 1px solid rgba(37, 99, 235, 0.18);
  border-radius: 999px;
  background: #eff6ff;
  color: #1d4ed8;
  font-size: 12px;
  font-weight: 700;
}

.hero-stats {
  display: grid;
  grid-template-columns: repeat(3, minmax(92px, 1fr));
  gap: 10px;
  min-width: 330px;
}

.hero-stats div {
  display: grid;
  gap: 4px;
  padding: 16px 18px;
  border: 1px solid rgba(15, 118, 110, 0.16);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.78);
  box-shadow: 0 12px 30px rgba(15, 23, 42, 0.05);
}

.hero-stats strong {
  color: #0f766e;
  font-size: 28px;
  line-height: 1;
}

.hero-stats span {
  color: #64748b;
  font-size: 13px;
}

.download-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  height: 40px;
  padding: 0 16px;
  border: 1px solid #0f766e;
  border-radius: 6px;
  background: #0f766e;
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: transform 0.16s ease, background 0.16s ease;
}

.download-btn:hover {
  background: #115e59;
  transform: translateY(-1px);
}

.download-btn:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}

.reader-layout {
  display: grid;
  grid-template-columns: 280px minmax(0, 1fr);
  gap: 22px;
  margin-top: 24px;
  align-items: start;
}

.document-nav {
  position: sticky;
  top: 92px;
  display: grid;
  gap: 14px;
}

.nav-panel {
  display: grid;
  gap: 10px;
  padding: 12px;
  border: 1px solid #dfe7ef;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.88);
  box-shadow: 0 10px 28px rgba(15, 23, 42, 0.045);
}

.nav-title {
  padding: 0 4px 2px;
  color: #64748b;
  font-size: 12px;
  font-weight: 700;
}

.document-tab {
  display: grid;
  gap: 6px;
  width: 100%;
  padding: 16px;
  text-align: left;
  border: 1px solid #d9e2ec;
  border-radius: 8px;
  background: #fff;
  color: #172033;
  cursor: pointer;
  transition: border 0.16s ease, background 0.16s ease, transform 0.16s ease;
}

.document-tab:hover {
  border-color: #5eead4;
  transform: translateY(-1px);
}

.document-tab.active {
  border-color: #0f766e;
  background: #ecfdf5;
  box-shadow: inset 3px 0 0 #0f766e;
}

.tab-badge,
.reader-badge {
  color: #0f766e;
  font-size: 12px;
  font-weight: 700;
}

.document-tab strong {
  font-size: 18px;
}

.document-tab small {
  color: #64748b;
}

.document-tab em {
  color: #94a3b8;
  font-size: 12px;
  font-style: normal;
}

.toc-panel {
  max-height: calc(100vh - 360px);
  overflow: auto;
}

.toc-link {
  width: 100%;
  padding: 9px 10px;
  border: none;
  border-radius: 6px;
  background: transparent;
  color: #475569;
  font-size: 13px;
  line-height: 1.35;
  text-align: left;
  cursor: pointer;
}

.toc-link:hover,
.toc-link.active {
  background: #eff6ff;
  color: #1d4ed8;
}

.reader-card,
.state-panel {
  background: #fff;
  border: 1px solid #dfe7ef;
  border-radius: 8px;
  box-shadow: 0 10px 32px rgba(15, 23, 42, 0.05);
}

.reader-card {
  overflow: hidden;
}

.reader-header {
  padding: 30px 34px 24px;
  border-bottom: 1px solid #e5edf4;
  background:
    linear-gradient(135deg, rgba(15, 118, 110, 0.08), rgba(37, 99, 235, 0.04)),
    #fff;
}

.reader-kicker {
  display: flex;
  align-items: center;
  gap: 10px;
  color: #64748b;
  font-size: 13px;
}

.reader-title-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 18px;
  margin-top: 8px;
}

.reader-header h2 {
  margin: 0 0 8px;
  font-size: 30px;
  line-height: 1.2;
  color: #0f172a;
}

.reader-header p {
  margin: 0;
  color: #64748b;
}

.reader-summary {
  margin-top: 18px;
  padding: 15px 17px;
  border-left: 4px solid #0f766e;
  background: #f8fafc;
  color: #334155;
  line-height: 1.7;
}

.reader-meta-grid {
  display: grid;
  grid-template-columns: 1.3fr 0.7fr 1fr;
  gap: 10px;
  margin: 16px 0 0;
}

.reader-meta-grid div {
  min-width: 0;
  padding: 12px 14px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.72);
}

.reader-meta-grid dt {
  margin-bottom: 5px;
  color: #64748b;
  font-size: 12px;
  font-weight: 700;
}

.reader-meta-grid dd {
  margin: 0;
  overflow: hidden;
  color: #1f2937;
  font-size: 13px;
  line-height: 1.45;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.section-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  padding: 18px 34px;
  border-bottom: 1px solid #e5edf4;
  background: #fff;
}

.section-chips button {
  height: 32px;
  padding: 0 12px;
  border: 1px solid #cbd5e1;
  border-radius: 999px;
  background: #fff;
  color: #334155;
  cursor: pointer;
  transition: border 0.16s ease, background 0.16s ease, color 0.16s ease;
}

.section-chips button:hover,
.section-chips button.active {
  border-color: #0f766e;
  background: #ecfdf5;
  color: #0f766e;
}

.content-section {
  scroll-margin-top: 96px;
  padding: 30px 34px;
  border-bottom: 1px solid #edf2f7;
}

.content-section:last-child {
  border-bottom: none;
}

.content-section h3 {
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 4px 0 14px;
  font-size: 22px;
  line-height: 1.35;
  color: #111827;
}

.content-section h3 span {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 34px;
  height: 28px;
  border-radius: 8px;
  background: #e0f2fe;
  color: #0369a1;
  font-size: 13px;
  font-weight: 800;
}

.content-section p {
  margin: 0 0 12px;
  color: #334155;
  font-size: 15px;
  line-height: 1.9;
}

.section-focus {
  display: grid;
  grid-template-columns: 108px minmax(0, 1fr);
  gap: 14px;
  margin: 0 0 18px;
  padding: 15px 16px;
  border: 1px solid #dbeafe;
  border-radius: 8px;
  background: #f8fbff;
}

.section-focus-title {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  color: #1d4ed8;
  font-size: 13px;
  font-weight: 800;
  white-space: nowrap;
}

.section-focus ul {
  display: grid;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.section-focus li {
  position: relative;
  padding-left: 14px;
  color: #334155;
  font-size: 14px;
  line-height: 1.65;
}

.section-focus li::before {
  position: absolute;
  top: 10px;
  left: 0;
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: #2563eb;
  content: "";
}

.content-section p.lead-paragraph:not(.rule-paragraph) {
  color: #1f2937;
  font-size: 16px;
}

.content-section p.rule-paragraph {
  position: relative;
  padding-left: 14px;
  color: #1f2937;
}

.content-section p.rule-paragraph::before {
  position: absolute;
  top: 10px;
  bottom: 10px;
  left: 0;
  width: 3px;
  border-radius: 999px;
  background: #f59e0b;
  content: "";
}

.content-section p:last-child {
  margin-bottom: 0;
}

.state-panel {
  display: flex;
  min-height: 260px;
  margin-top: 24px;
  align-items: center;
  justify-content: center;
  gap: 12px;
  color: #64748b;
  text-align: center;
}

.state-panel.error-state {
  flex-direction: column;
  color: #475569;
}

.state-panel.error-state i,
.state-panel > i {
  color: #94a3b8;
  font-size: 34px;
}

.state-panel h2 {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
}

.spinner {
  width: 28px;
  height: 28px;
  border: 3px solid #e2e8f0;
  border-top-color: #0f766e;
  border-radius: 50%;
  animation: spin 0.9s linear infinite;
}

.back-top-btn {
  position: fixed;
  right: 28px;
  bottom: 28px;
  z-index: 10;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 42px;
  height: 42px;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  background: #fff;
  color: #334155;
  box-shadow: 0 14px 34px rgba(15, 23, 42, 0.16);
  cursor: pointer;
  transition: transform 0.16s ease, color 0.16s ease;
}

.back-top-btn:hover {
  color: #0f766e;
  transform: translateY(-2px);
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

@media (max-width: 820px) {
  .documents-shell {
    width: min(100% - 24px, 1200px);
    padding-top: 84px;
  }

  .page-hero {
    align-items: flex-start;
    flex-direction: column;
    min-height: auto;
  }

  .page-hero h1 {
    font-size: 25px;
  }

  .hero-stats {
    width: 100%;
    min-width: 0;
  }

  .reader-layout {
    grid-template-columns: 1fr;
  }

  .document-nav {
    position: static;
    grid-template-columns: 1fr;
  }

  .nav-panel:first-child {
    grid-template-columns: 1fr 1fr;
  }

  .nav-title {
    grid-column: 1 / -1;
  }

  .toc-panel {
    display: none;
  }

  .reader-title-row {
    flex-direction: column;
  }

  .reader-meta-grid {
    grid-template-columns: 1fr;
  }

  .reader-header,
  .section-chips,
  .content-section {
    padding-left: 18px;
    padding-right: 18px;
  }

  .section-focus {
    grid-template-columns: 1fr;
    gap: 10px;
  }
}

@media (max-width: 560px) {
  .hero-stats,
  .nav-panel:first-child {
    grid-template-columns: 1fr;
  }

  .download-btn {
    width: 100%;
  }

  .back-top-btn {
    right: 16px;
    bottom: 18px;
  }
}
</style>
