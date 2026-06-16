<template>
  <div class="edit-page" :class="{ 'fullscreen-mode': fullscreenMode }">
    <HeaderBar v-if="!fullscreenMode" />

    <div class="page-container" @scroll="handleScroll">
      <div class="write-wrapper">
        <!-- 左侧导航 -->
        <aside class="left-sidebar" v-if="!fullscreenMode" data-guide="knowledge-create-nav">
          <div class="topic-box">
             <div class="box-title">常用操作</div>
             <div class="topic-list">
               <div class="topic-item" @click="goBack">
                 <span class="topic-hash"><i class="fas fa-arrow-left"></i></span>
                 <span class="topic-name">返回列表</span>
               </div>
             </div>
          </div>

          <div class="nav-menu">
            <div class="menu-item" @click="confirmLeave('/knowledge')">
              <i class="fas fa-compass"></i>
              <span>知识广场</span>
            </div>
            <div class="menu-item" @click="confirmLeave('/knowledge/my')">
              <i class="fas fa-user"></i>
              <span>我的文章</span>
            </div>
            <div class="menu-item" @click="confirmLeave('/knowledge/fav')">
              <i class="fas fa-bookmark"></i>
              <span>我的收藏</span>
            </div>
          </div>
        </aside>

        <!-- 主编辑区 (Center) -->
        <main class="write-main" :class="{ 'fullscreen-main': fullscreenMode }">
          <!-- 工具栏 -->
          <div class="editor-toolbar-top" data-guide="knowledge-create-toolbar">
             <div class="toolbar-left">
               <button class="tool-btn" @click="editorUndo" title="撤销 (Ctrl+Z)">
                 <i class="fas fa-undo"></i>
               </button>
               <button class="tool-btn" @click="editorRedo" title="重做 (Ctrl+Y)">
                 <i class="fas fa-redo"></i>
               </button>
               <span class="toolbar-divider"></span>
               <button class="tool-btn" @click="showTableModal = true" title="插入表格">
                 <i class="fas fa-table"></i>
               </button>
             </div>
             <div class="toolbar-right">
               <button class="tool-btn" @click="toggleFullscreen" :class="{ active: fullscreenMode }">
                 <i :class="fullscreenMode ? 'fas fa-compress' : 'fas fa-expand'"></i> {{ fullscreenMode ? '退出全屏' : '全屏编辑' }}
               </button>
               <button class="tool-btn" @click="togglePreview" :class="{ active: previewMode }">
                 <i class="fas fa-eye"></i> {{ previewMode ? '退出预览' : '预览模式' }}
               </button>
             </div>
          </div>

          <!-- 预览模式内容 -->
          <div v-if="previewMode" class="preview-content markdown-body" v-html="safePreviewContent"></div>

          <!-- 编辑模式内容 -->
          <div v-show="!previewMode" class="edit-mode-content">
            <!-- 封面添加按钮 (如果未添加) -->
            <div class="cover-add-wrapper" v-if="!form.coverImage">
              <button class="btn-add-cover" @click="triggerCoverUpload">
                <i class="fas fa-image"></i> 添加封面
              </button>
            </div>
            
            <!-- 封面预览 (如果已添加) -->
            <div class="cover-preview-wrapper" v-if="form.coverImage">
              <img :src="form.coverImage" class="cover-image-large" />
              <div class="cover-actions">
                <button @click="triggerCoverUpload"><i class="fas fa-camera"></i> 更换封面</button>
                <button @click="removeCover"><i class="fas fa-trash"></i> 删除</button>
              </div>
            </div>

            <!-- 标题输入 -->
            <div class="title-wrapper" data-guide="knowledge-create-title">
              <textarea 
                v-model="form.title"
                data-guide="knowledge-create-title-input"
                class="title-input-large"
                placeholder="请输入标题 (最多 100 个字)"
                rows="1"
                @input="autoResize"
                ref="titleInput"
                maxlength="100"
              ></textarea>
              <span class="title-count" v-if="form.title.length > 0">{{ form.title.length }}/100</span>
            </div>

            <!-- 编辑器 -->
            <div class="editor-wrapper" data-guide="knowledge-create-editor">
              <div ref="editorRef" class="editor-container"></div>
            </div>
          </div>
        </main>

        <!-- 右侧创作助手 -->
        <aside class="right-sidebar" v-if="!fullscreenMode" data-guide="knowledge-create-actions">
          <div class="sidebar-action-card">
            <button class="btn-publish-large" data-guide="knowledge-publish-trigger" @click="showPublishModal = true">发布文章</button>
            <button class="btn-draft-large" @click="handleSave('draft')">保存草稿</button>
          </div>

          <div class="sidebar-card">
            <div class="card-header">
              <h3>最近草稿</h3>
            </div>
            <div class="draft-list">
               <div v-for="(draft, index) in recentDrafts" :key="draft.articleId || index" class="draft-item" @click="loadDraft(draft.articleId)">
                 <span class="draft-title">{{ draft.title || '无标题草稿' }}</span>
                 <span class="draft-time">{{ formatTime(draft.updateTime) }}</span>
               </div>
               <div v-if="recentDrafts.length === 0" class="empty-tip">暂无草稿</div>
            </div>
          </div>

          <div class="sidebar-card">
            <div class="card-header">
              <h3>创作助手</h3>
            </div>
            <div class="card-body">
              <div class="helper-item" @click="toggleSidebar('template')">
                <div class="icon-box orange"><i class="fas fa-th-large"></i></div>
                <div class="text-box">
                  <h4>内容模板</h4>
                  <p>快速使用预设结构</p>
                </div>
              </div>
              <div class="helper-item" @click="smartFormat">
                <div class="icon-box blue"><i class="fas fa-magic"></i></div>
                <div class="text-box">
                  <h4>智能排版</h4>
                  <p>一键优化格式</p>
                </div>
              </div>
            </div>
            
            <!-- 模板列表展开 -->
            <div class="template-list" v-if="activeSidebar === 'template'">
               <div class="tpl-item" @click="applyTemplate('case')">
                 <span class="tpl-tag">案例</span>
                 <span>服务案例复盘</span>
               </div>
               <div class="tpl-item" @click="applyTemplate('ota')">
                 <span class="tpl-tag">运营</span>
                 <span>OTA 运营心得</span>
               </div>
               <div class="tpl-item" @click="applyTemplate('daily')">
                 <span class="tpl-tag">日报</span>
                 <span>每日工作总结</span>
               </div>
               <div class="tpl-item" @click="applyTemplate('meeting')">
                 <span class="tpl-tag">会议</span>
                 <span>会议纪要</span>
               </div>
               <div class="tpl-item" @click="applyTemplate('plan')">
                 <span class="tpl-tag">计划</span>
                 <span>周工作计划</span>
               </div>
               <div class="tpl-item" @click="applyTemplate('sharing')">
                 <span class="tpl-tag">分享</span>
                 <span>技能分享</span>
               </div>
               <div class="tpl-item" @click="applyTemplate('project')">
                 <span class="tpl-tag">项目</span>
                 <span>项目复盘</span>
               </div>
               <div class="tpl-item" @click="applyTemplate('note')">
                 <span class="tpl-tag">笔记</span>
                 <span>学习笔记</span>
               </div>
               <div class="tpl-item" @click="applyTemplate('bug')">
                 <span class="tpl-tag">故障</span>
                 <span>故障排查</span>
               </div>
            </div>
          </div>
        </aside>
      </div>
    </div>

    <!-- 底部字数统计 (固定) -->
    <div class="footer-stats" :class="{ 'fullscreen-footer': fullscreenMode }">
      <span>正文 {{ wordCount }} 字</span>
      <span class="auto-save-tip" v-if="autoSaveEnabled">
        <i class="fas fa-clock"></i> 自动保存已开启
      </span>
      <span v-if="saving" class="saving-tip"><i class="fas fa-sync fa-spin"></i> 保存中...</span>
      <span v-else-if="hasChanges" class="saving-tip" style="color: #f59e0b;"><i class="fas fa-exclamation-circle"></i> 未保存</span>
      <span v-else class="saving-tip"><i class="fas fa-check"></i> 已保存</span>
    </div>

    <!-- 隐藏的文件上传 input -->
    <input type="file" ref="fileInput" style="display: none" accept="image/*" @change="handleFileChange">

    <!-- 插入表格弹窗 -->
    <div class="modal-overlay" v-if="showTableModal" @click.self="showTableModal = false">
      <div class="table-modal">
        <div class="modal-header">
          <h3>插入表格</h3>
          <button class="close-btn" @click="showTableModal = false"><i class="fas fa-times"></i></button>
        </div>
        <div class="modal-body">
          <div class="table-size-selector">
            <div class="size-input-group">
              <label>行数</label>
              <input type="number" v-model.number="tableRows" min="1" max="20" class="size-input" @input="syncPreviewSize" />
            </div>
            <div class="size-input-group">
              <label>列数</label>
              <input type="number" v-model.number="tableCols" min="1" max="10" class="size-input" @input="syncPreviewSize" />
            </div>
          </div>
          <div class="table-preview-grid" @mouseleave="resetPreviewSize">
            <div
              v-for="row in 8"
              :key="'row-' + row"
              class="table-preview-row"
            >
              <div
                v-for="col in 8"
                :key="'col-' + col"
                class="table-preview-cell"
                :class="{ active: row <= previewRows && col <= previewCols, selected: row <= tableRows && col <= tableCols }"
                @mouseenter="hoverTableSize(row, col)"
                @click="selectTableSize(row, col)"
              ></div>
            </div>
          </div>
          <p class="table-size-hint">{{ previewRows }} × {{ previewCols }}</p>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="showTableModal = false">取消</button>
          <button class="btn-confirm-publish" @click="insertTable">插入表格</button>
        </div>
      </div>
    </div>

    <!-- 表格编辑工具栏 -->
    <div class="table-toolbar" v-if="showTableToolbar" :style="tableToolbarStyle">
      <button @click="tableAction('addRowAbove')" title="在上方插入行"><i class="fas fa-arrow-up"></i> 上插行</button>
      <button @click="tableAction('addRowBelow')" title="在下方插入行"><i class="fas fa-arrow-down"></i> 下插行</button>
      <button @click="tableAction('addColLeft')" title="在左侧插入列"><i class="fas fa-arrow-left"></i> 左插列</button>
      <button @click="tableAction('addColRight')" title="在右侧插入列"><i class="fas fa-arrow-right"></i> 右插列</button>
      <span class="toolbar-divider"></span>
      <button @click="tableAction('deleteRow')" title="删除当前行" class="danger"><i class="fas fa-trash-alt"></i> 删行</button>
      <button @click="tableAction('deleteCol')" title="删除当前列" class="danger"><i class="fas fa-trash-alt"></i> 删列</button>
      <button @click="tableAction('deleteTable')" title="删除整个表格" class="danger"><i class="fas fa-trash"></i> 删表格</button>
    </div>

    <!-- 发布设置弹窗 -->
    <div class="modal-overlay" v-if="showPublishModal" @click.self="showPublishModal = false">
      <div class="publish-modal" data-guide="knowledge-publish-modal">
        <div class="modal-header">
          <h3>发布设置</h3>
          <button class="close-btn" @click="showPublishModal = false"><i class="fas fa-times"></i></button>
        </div>
        <div class="modal-body">
          <!-- 发布范围选择 -->
          <div class="form-group">
            <label>发布范围</label>
            <div class="publish-scope-selector">
              <div
                class="scope-option"
                :class="{ active: form.publishScope === 'tenant' }"
                @click="form.publishScope = 'tenant'"
              >
                <div class="scope-icon"><i class="fas fa-building"></i></div>
                <div class="scope-text">
                  <h4>本租户可见</h4>
                  <p>仅本集团/公司内部员工可见</p>
                </div>
                <i class="fas fa-check-circle scope-check" v-if="form.publishScope === 'tenant'"></i>
              </div>
              <div
                class="scope-option"
                :class="{ active: form.publishScope === 'platform', disabled: !canPublishPlatform }"
                @click="canPublishPlatform && (form.publishScope = 'platform')"
              >
                <div class="scope-icon"><i class="fas fa-globe"></i></div>
                <div class="scope-text">
                  <h4>全平台可见</h4>
                  <p>所有租户用户都可以看到</p>
                </div>
                <i class="fas fa-check-circle scope-check" v-if="form.publishScope === 'platform'"></i>
                <span class="scope-badge" v-if="!canPublishPlatform">需平台管理员权限</span>
              </div>
            </div>
          </div>

          <div class="form-group">
            <label>文章话题</label>
            <div class="topic-selector">
              <div class="topic-tags" v-if="form.topics && form.topics.length > 0">
                <span v-for="(tag, index) in form.topics" :key="index" class="tag">
                  {{ tag }} <i class="fas fa-times" @click="form.topics.splice(index, 1)"></i>
                </span>
              </div>
              <button class="btn-add-topic" @click="addTopic"><i class="fas fa-plus"></i> 添加话题</button>
            </div>
            <p class="hint">添加话题，让更多人看到你的文章</p>
          </div>
          
          <div class="form-group">
            <label>预览摘要</label>
            <textarea 
              class="summary-input" 
              placeholder="如果不填写，将自动抓取正文前 100 字作为摘要"
              rows="3"
            ></textarea>
          </div>

          <div class="form-group">
            <label>封面设置</label>
            <div class="cover-mini-preview" v-if="form.coverImage">
               <img :src="form.coverImage" />
               <button class="btn-text" @click="triggerCoverUpload">更换</button>
            </div>
            <button class="btn-upload-outline" v-else @click="triggerCoverUpload">
              <i class="fas fa-image"></i> 上传封面
            </button>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="showPublishModal = false">取消</button>
          <button class="btn-confirm-publish" @click="handleSave('pending')">确定发布</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import logger from '@/utils/logger';
import { ref, computed, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import HeaderBar from '@/components/HeaderBar.vue'
import { getArticleDetail, createArticle, updateArticle, getArticleList } from '@/api/knowledge'
import { api } from '@/utils/api'
import { sanitizeHtml } from '@/utils/security'
import Quill from 'quill'
import 'quill/dist/quill.snow.css'

// 注册自定义表格 Blot
const BlockEmbed = Quill.import('blots/block/embed')

class TableBlot extends BlockEmbed {
  static create(value) {
    const node = super.create()
    node.innerHTML = sanitizeHtml(value)
    node.setAttribute('contenteditable', 'false')
    node.classList.add('ql-table-wrapper')

    // 让表格单元格可编辑
    setTimeout(() => {
      const cells = node.querySelectorAll('td, th')
      cells.forEach(cell => {
        cell.setAttribute('contenteditable', 'true')
      })
    }, 0)

    return node
  }

  static value(node) {
    return sanitizeHtml(node.innerHTML)
  }
}

TableBlot.blotName = 'tableEmbed'
TableBlot.tagName = 'div'
TableBlot.className = 'ql-table-wrapper'

Quill.register(TableBlot)

export default {
  name: 'KnowledgeEdit',
  components: { HeaderBar },
  setup() {
    const router = useRouter()
    const route = useRoute()

    const formRef = ref(null)
    const saving = ref(false)
    const isEdit = ref(false)
    const articleId = ref(null)
    const editorRef = ref(null)
    let quillEditor = null
    const titleInput = ref(null)
    const fileInput = ref(null)
    const showPublishModal = ref(false)
    const activeSidebar = ref('template')
    const wordCount = ref(0)
    const hasScroll = ref(false)

    // New features
    const previewMode = ref(false)
    const recentDrafts = ref([])
    const fullscreenMode = ref(false)
    const showTableModal = ref(false)
    const tableRows = ref(3)
    const tableCols = ref(3)
    const previewRows = ref(3)
    const previewCols = ref(3)

    // 自动保存相关
    const autoSaveEnabled = ref(true)
    const autoSaveInterval = ref(null)
    const AUTO_SAVE_DELAY = 30000 // 30秒自动保存

    // 表格编辑工具栏
    const showTableToolbar = ref(false)
    const tableToolbarStyle = ref({})
    const currentTableCell = ref(null)

    const hasChanges = ref(false)

    const form = ref({
      title: '',
      content: '',
      coverImage: '',
      images: [],
      status: 'draft',
      topics: [],
      publishScope: 'tenant'  // 默认本租户可见
    })

    const sanitizeEditorContent = (content) => sanitizeHtml(content || '')

    const setEditorContent = (content) => {
      const sanitized = sanitizeEditorContent(content)
      if (quillEditor) {
        quillEditor.root.innerHTML = sanitized
      }
      form.value.content = sanitized
      return sanitized
    }

    const getSanitizedEditorContent = () => {
      if (quillEditor) {
        return sanitizeEditorContent(quillEditor.root.innerHTML)
      }
      return sanitizeEditorContent(form.value.content)
    }

    const safePreviewContent = computed(() => sanitizeEditorContent(form.value.content))

    // 是否可以发布全平台（所有用户都可以选择，由审核来把关）
    const canPublishPlatform = ref(true)

    const initEditor = () => {
      if (!editorRef.value) return

      // Register custom font sizes with inline styles
      const Size = Quill.import('attributors/style/size')
      const sizeList = ['12px', '13px', '14px', '15px', '16px', '18px', '20px', '24px', '32px', '48px']
      Size.whitelist = sizeList
      Quill.register(Size, true)

      // 注册字体
      const Font = Quill.import('attributors/style/font')
      const fontList = ['sans-serif', 'serif', 'monospace', 'Microsoft YaHei', 'SimSun', 'SimHei', 'KaiTi', 'FangSong']
      Font.whitelist = fontList
      Quill.register(Font, true)

      const toolbarOptions = [
        [{ 'header': [1, 2, 3, 4, 5, 6, false] }],
        [{ 'font': fontList }],
        [{ 'size': sizeList }],
        ['bold', 'italic', 'underline', 'strike', 'blockquote', 'code-block'],
        [{ 'list': 'ordered'}, { 'list': 'bullet' }],
        [{ 'indent': '-1'}, { 'indent': '+1' }],
        [{ 'align': [] }],
        [{ 'color': [] }, { 'background': [] }],
        ['link', 'image'],
        ['clean']
      ]

      quillEditor = new Quill(editorRef.value, {
        modules: {
          toolbar: {
            container: toolbarOptions,
            handlers: { image: imageHandler }
          },
          history: {
            delay: 1000,
            maxStack: 100,
            userOnly: true
          }
        },
        theme: 'snow',
        placeholder: '请输入正文...'
      })
      
      // 增强图片处理：支持直接粘贴和拖拽
      quillEditor.root.addEventListener('paste', handlePaste, false)
      quillEditor.root.addEventListener('drop', handleDrop, false)

      // Add tooltips to toolbar buttons
      addToolbarTooltips()

      quillEditor.on('text-change', (delta, oldDelta, source) => {
        form.value.content = getSanitizedEditorContent()
        const text = quillEditor.getText()
        wordCount.value = Math.max(0, text.length - 1)
        if (source === 'user') {
          hasChanges.value = true
        }
      })
    }

    const addToolbarTooltips = () => {
      const tooltipMap = {
        'ql-bold': '加粗',
        'ql-italic': '斜体',
        'ql-underline': '下划线',
        'ql-strike': '删除线',
        'ql-blockquote': '引用',
        'ql-code-block': '代码块',
        'ql-header': '标题',
        'ql-list[value="ordered"]': '有序列表',
        'ql-list[value="bullet"]': '无序列表',
        'ql-indent[value="-1"]': '减少缩进',
        'ql-indent[value="+1"]': '增加缩进',
        'ql-align': '对齐方式',
        'ql-color': '字体颜色',
        'ql-background': '背景颜色',
        'ql-link': '插入链接',
        'ql-image': '插入图片',
        'ql-clean': '清除格式',
        'ql-font': '字体',
        'ql-size': '字号'
      }

      for (const [selector, title] of Object.entries(tooltipMap)) {
        const buttons = document.querySelectorAll(`.ql-toolbar .${selector}`)
        buttons.forEach(btn => {
          btn.setAttribute('data-tooltip', title)
          btn.removeAttribute('title') // 移除原生 title 防止双重显示和延迟
        })
      }
      
      // Handle pickers (dropdowns)
      const pickerMap = {
        'ql-header': '选择标题',
        'ql-align': '对齐方式',
        'ql-color': '字体颜色',
        'ql-background': '背景颜色'
      }
      
      for (const [selector, title] of Object.entries(pickerMap)) {
        const pickers = document.querySelectorAll(`.ql-toolbar .ql-picker.${selector}`)
        pickers.forEach(picker => {
           picker.setAttribute('data-tooltip', title)
           picker.removeAttribute('title')
        })
      }
    }

    // 图片压缩函数
    const compressImage = (file, maxWidth = 1200, quality = 0.8) => {
      return new Promise((resolve) => {
        // 如果文件小于 200KB，不压缩
        if (file.size < 200 * 1024) {
          resolve(file)
          return
        }

        const reader = new FileReader()
        reader.onload = (e) => {
          const img = new Image()
          img.onload = () => {
            const canvas = document.createElement('canvas')
            let width = img.width
            let height = img.height

            // 按比例缩放
            if (width > maxWidth) {
              height = Math.round((height * maxWidth) / width)
              width = maxWidth
            }

            canvas.width = width
            canvas.height = height

            const ctx = canvas.getContext('2d')
            ctx.drawImage(img, 0, 0, width, height)

            canvas.toBlob(
              (blob) => {
                if (blob) {
                  const compressedFile = new File([blob], file.name, {
                    type: 'image/jpeg',
                    lastModified: Date.now()
                  })
                  logger.debug(`图片压缩: ${(file.size / 1024).toFixed(1)}KB -> ${(compressedFile.size / 1024).toFixed(1)}KB`)
                  resolve(compressedFile)
                } else {
                  resolve(file)
                }
              },
              'image/jpeg',
              quality
            )
          }
          img.src = e.target.result
        }
        reader.readAsDataURL(file)
      })
    }

    // 通用上传函数
    const uploadImage = async (file) => {
      const token = localStorage.getItem('authToken')
      if (!token) {
        ElMessage.warning('请先登录后再上传图片')
        return null
      }

      // 压缩图片
      const compressedFile = await compressImage(file)

      const formData = new FormData()
      formData.append('file', compressedFile)
      try {
        const res = await api.post('/common/upload', formData, {
          headers: { 'Content-Type': 'multipart/form-data' }
        })
        if (res.data.code === 200) {
          return res.data.url
        } else {
          ElMessage.error(res.data.msg || '图片上传失败')
          return null
        }
      } catch (e) {
        logger.error('Upload error:', e)
        ElMessage.error('图片上传出错')
        return null
      }
    }

    const imageHandler = () => {
      const input = document.createElement('input')
      input.setAttribute('type', 'file')
      input.setAttribute('accept', 'image/*')
      input.click()
      input.onchange = async () => {
        const file = input.files[0]
        if (file) {
          const url = await uploadImage(file)
          if (url && quillEditor) {
            const range = quillEditor.getSelection(true)
            if (range) {
               quillEditor.insertEmbed(range.index, 'image', url)
               quillEditor.setSelection(range.index + 1)
            } else {
               // 如果没有选区，追加到最后
               const length = quillEditor.getLength()
               quillEditor.insertEmbed(length, 'image', url)
            }
          }
        }
      }
    }
    
    const handlePaste = async (e) => {
      const clipboardData = e.clipboardData || window.clipboardData
      if (clipboardData && clipboardData.items) {
        for (let i = 0; i < clipboardData.items.length; i++) {
          const item = clipboardData.items[i]
          if (item.type.indexOf('image') !== -1) {
            e.preventDefault()
            const file = item.getAsFile()
            const url = await uploadImage(file)
            if (url) {
              const range = quillEditor.getSelection(true) || { index: quillEditor.getLength() }
              quillEditor.insertEmbed(range.index, 'image', url)
              quillEditor.setSelection(range.index + 1)
            }
            return
          }
        }
      }
    }
    
    const handleDrop = async (e) => {
      e.preventDefault()
      const dt = e.dataTransfer
      if (dt && dt.files && dt.files.length) {
        const file = dt.files[0]
        if (file.type.indexOf('image') !== -1) {
          const url = await uploadImage(file)
          if (url) {
            const range = quillEditor.getSelection(true) || { index: quillEditor.getLength() }
            quillEditor.insertEmbed(range.index, 'image', url)
            quillEditor.setSelection(range.index + 1)
          }
        }
      }
    }

    const autoResize = () => {
      const el = titleInput.value
      if(el) {
        el.style.height = 'auto'
        el.style.height = el.scrollHeight + 'px'
      }
      hasChanges.value = true
    }

    const applyTemplate = (type) => {
      let content = ''
      if (type === 'case') {
        content = `<h2>一、背景信息</h2><p>时间：</p><p>地点：</p><p>人物：</p><h2>二、事件经过</h2><p>请详细描述事情发生的起因、经过...</p><h2>三、处理过程</h2><p>我们采取了哪些措施？</p><h2>四、复盘反思</h2><p>做的好的地方：</p><p>需要改进的地方：</p>`
        form.value.title = '【案例复盘】关于xxx客诉的处理'
      } else if (type === 'ota') {
        content = `<h2>一、数据表现</h2><p>本周评分变化：</p><h2>二、关键动作</h2><p>1. 回复率提升：</p><h2>三、成效分析</h2><p>...</p>`
        form.value.title = '【运营心得】OTA评分提升实战'
      } else if (type === 'daily') {
        const d = new Date()
        content = `<h2>一、今日完成工作</h2><p>1. </p><h2>二、遇到的问题</h2><p>...</p><h2>三、明日计划</h2><p>1. </p>`
        form.value.title = `${d.getFullYear()}/${d.getMonth()+1}/${d.getDate()} 工作总结`
      } else if (type === 'meeting') {
        const d = new Date()
        content = `<h2>一、会议主题</h2><p></p><h2>二、参会人员</h2><p></p><h2>三、会议内容</h2><p>1. </p><h2>四、行动计划</h2><p></p>`
        form.value.title = `${d.getFullYear()}/${d.getMonth()+1}/${d.getDate()} 会议纪要`
      } else if (type === 'plan') {
        content = `<h2>一、本周目标</h2><p></p><h2>二、关键任务</h2><p>1. </p><h2>三、所需支持</h2><p></p>`
        form.value.title = '【周计划】本周工作安排'
      } else if (type === 'sharing') {
        content = `<h2>一、技能介绍</h2><p></p><h2>二、应用场景</h2><p></p><h2>三、操作步骤</h2><p>1. </p><h2>四、注意事项</h2><p></p>`
        form.value.title = '【技能分享】关于xxx的操作技巧'
      } else if (type === 'project') {
        content = `<h2>一、项目背景</h2><p></p><h2>二、项目目标</h2><p></p><h2>三、执行过程</h2><p></p><h2>四、项目成果</h2><p></p><h2>五、经验总结</h2><p></p>`
        form.value.title = '【项目复盘】xxx项目总结'
      } else if (type === 'note') {
        content = `<h2>一、核心观点</h2><p></p><h2>二、详细内容</h2><p>1. </p><h2>三、个人思考</h2><p></p><h2>四、延伸阅读</h2><p></p>`
        form.value.title = '【学习笔记】xxx学习心得'
      } else if (type === 'bug') {
        content = `<h2>一、故障现象</h2><p>发生时间：</p><p>影响范围：</p><h2>二、排查过程</h2><p>1. </p><h2>三、根本原因</h2><p></p><h2>四、解决方案</h2><p></p><h2>五、预防措施</h2><p></p>`
        form.value.title = '【故障排查】xxx故障分析报告'
      }

      setEditorContent(content)
      nextTick(() => {
        autoResize()
        hasChanges.value = true
      })
    }

    const smartFormat = () => {
      if (!quillEditor) return

      const oldHtml = quillEditor.root.innerHTML
      let newHtml = oldHtml

      // 1. 移除连续的空行 (<p><br></p>)
      newHtml = newHtml.replace(/(<p><br><\/p>\s*){2,}/g, '<p><br></p>')

      // 2. 移除段落开头的空格
      newHtml = newHtml.replace(/<p>(&nbsp;|\s)+/g, '<p>')

      // 3. 移除多余的空格（连续多个空格变成一个）
      newHtml = newHtml.replace(/(&nbsp;){2,}/g, '&nbsp;')

      // 4. 修复空的标题标签
      newHtml = newHtml.replace(/<(h[1-6])>\s*<br>\s*<\/\1>/gi, '')
      newHtml = newHtml.replace(/<(h[1-6])>\s*<\/\1>/gi, '')

      // 5. 中英文之间添加空格（可选，常见的排版规范）
      // newHtml = newHtml.replace(/([\u4e00-\u9fa5])([a-zA-Z0-9])/g, '$1 $2')
      // newHtml = newHtml.replace(/([a-zA-Z0-9])([\u4e00-\u9fa5])/g, '$1 $2')

      // 6. 修复标点符号（全角/半角统一）
      newHtml = newHtml.replace(/,\s*/g, '，')  // 英文逗号转中文
      newHtml = newHtml.replace(/\.\s+/g, '。')  // 英文句号转中文（后面有空格的情况）
      newHtml = newHtml.replace(/!\s*/g, '！')
      newHtml = newHtml.replace(/\?\s*/g, '？')
      newHtml = newHtml.replace(/;\s*/g, '；')
      newHtml = newHtml.replace(/:\s*/g, '：')

      // 7. 移除首尾空白
      newHtml = newHtml.trim()

      // 统计优化项
      let changes = []
      if (oldHtml !== newHtml) {
        if (oldHtml.match(/(<p><br><\/p>\s*){2,}/)) changes.push('合并空行')
        if (oldHtml.match(/<p>(&nbsp;|\s)+/)) changes.push('清理段首空格')
        if (oldHtml.match(/(&nbsp;){2,}/)) changes.push('清理多余空格')
        if (oldHtml.match(/[,.:;!?]/)) changes.push('统一标点符号')

        const safeFormattedContent = sanitizeEditorContent(newHtml)
        quillEditor.root.innerHTML = safeFormattedContent
        form.value.content = safeFormattedContent
        hasChanges.value = true

        const msg = changes.length > 0 ? `已优化：${changes.join('、')}` : '已优化排版'
        ElMessage.success(msg)
      } else {
        ElMessage.info('格式良好，无需优化')
      }
    }

    const loadArticle = async () => {
      const token = localStorage.getItem('authToken')
      if (!token) {
        ElMessage.warning('请先登录')
        goBack()
        return
      }
      try {
        const response = await getArticleDetail(articleId.value)
        if (response.data.code === 200) {
          const article = response.data.data
          const safeContent = sanitizeEditorContent(article.content)
          form.value = {
            title: article.title,
            content: safeContent,
            coverImage: article.coverImage || '',
            images: article.images || [],
            status: article.status,
            topics: article.topics || [],
            publishScope: article.publishScope || 'tenant'
          }
          setEditorContent(safeContent)
          nextTick(() => {
            autoResize()
            hasChanges.value = false
            bindTableEvents()
          })
        } else {
          ElMessage.error(response.data.msg || '加载失败')
          goBack()
        }
      } catch (error) {
        logger.error('加载文章失败:', error)
        ElMessage.error('加载失败')
        goBack()
      }
    }

    const fetchRecentDrafts = async () => {
      // 如果没有登录，不获取草稿，避免报错
      const token = localStorage.getItem('authToken')
      if (!token) {
        recentDrafts.value = []
        return
      }

      try {
        // Fetch drafts (status='draft')
        const params = { pageNum: 1, pageSize: 5, status: 'draft' }
        const res = await getArticleList(params)
        if (res.data.code === 200) {
          recentDrafts.value = res.data.rows || []
        }
      } catch (error) {
        logger.error('Fetch drafts error:', error)
        recentDrafts.value = []
      }
    }

    const loadDraft = (id) => {
       if (id === articleId.value) return
       ElMessageBox.confirm(
        '是否切换到该草稿？当前未保存的内容将丢失。',
        '提示',
        { confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning' }
      ).then(() => {
        router.push(`/knowledge/edit/${id}`).then(() => {
          articleId.value = id
          isEdit.value = true
          loadArticle()
        })
      }).catch(() => {})
    }

    const handleSave = async (status) => {
      const token = localStorage.getItem('authToken')
      if (!token) {
        const actionName = status === 'draft' ? '保存' : '发布'
        ElMessage.warning(`请先登录后再${actionName}`)
        return
      }

      if (!form.value.title) {
        ElMessage.warning('请输入标题')
        return
      }
      if (!quillEditor || quillEditor.getLength() <= 1) {
        ElMessage.warning('请输入正文内容')
        return
      }

      saving.value = true
      try {
        const safeContent = getSanitizedEditorContent()
        const data = {
          ...form.value,
          status,
          content: safeContent
        }
        if (isEdit.value) {
          data.articleId = articleId.value
        }

        const response = isEdit.value 
          ? await updateArticle(data)
          : await createArticle(data)

        if (response.data.code === 200) {
          ElMessage.success(status === 'draft' ? '保存成功' : '提交成功')
          hasChanges.value = false
          if (status === 'pending') {
            router.push('/knowledge/my')
          } else if (!isEdit.value) {
            // If created a new draft, switch to edit mode
            const newId = response.data.data // Assuming backend returns ID
            if (newId) {
               articleId.value = newId
               isEdit.value = true
               router.replace(`/knowledge/edit/${newId}`)
            }
            fetchRecentDrafts() // Refresh drafts
          } else {
            fetchRecentDrafts() // Refresh drafts
          }
        } else {
          ElMessage.error(response.data.msg || '保存失败')
        }
      } catch (error) {
        logger.error('保存文章失败:', error)
        ElMessage.error('保存失败')
      } finally {
        saving.value = false
        showPublishModal.value = false
      }
    }

    const triggerCoverUpload = () => {
      fileInput.value.click()
    }

    const handleFileChange = (e) => {
      const file = e.target.files[0]
      if (!file) return
      
      const isImage = file.type.startsWith('image/')
      const isLt5M = file.size / 1024 / 1024 < 5

      if (!isImage) {
        ElMessage.error('只能上传图片文件!')
        return
      }
      if (!isLt5M) {
        ElMessage.error('图片大小不能超过 5MB!')
        return
      }

      const reader = new FileReader()
      reader.onload = (e) => {
        form.value.coverImage = e.target.result
        hasChanges.value = true
        ElMessage.success('封面已添加')
      }
      reader.readAsDataURL(file)
    }

    const removeCover = () => {
      form.value.coverImage = ''
      hasChanges.value = true
    }

    const addTopic = () => {
      ElMessage.info('话题功能开发中')
    }

    const goBack = () => router.back()
    
    const confirmLeave = (path) => {
      if (form.value.title || (quillEditor && quillEditor.getLength() > 1)) {
         ElMessageBox.confirm(
          '当前内容未保存，确定要离开吗？',
          '提示',
          { confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning' }
        ).then(() => {
          router.push(path)
        }).catch(() => {})
      } else {
        router.push(path)
      }
    }

    const toggleSidebar = (panel) => {
      activeSidebar.value = activeSidebar.value === panel ? null : panel
    }
    
    const handleScroll = (e) => {
      hasScroll.value = e.target.scrollTop > 10
    }
    
    const togglePreview = () => {
      previewMode.value = !previewMode.value
    }

    // 全屏模式
    const toggleFullscreen = () => {
      fullscreenMode.value = !fullscreenMode.value
      if (fullscreenMode.value) {
        document.body.style.overflow = 'hidden'
      } else {
        document.body.style.overflow = ''
      }
    }

    // 撤销/重做
    const editorUndo = () => {
      if (quillEditor) {
        quillEditor.history.undo()
      }
    }

    const editorRedo = () => {
      if (quillEditor) {
        quillEditor.history.redo()
      }
    }

    // 表格相关
    const hoverTableSize = (row, col) => {
      previewRows.value = row
      previewCols.value = col
    }

    const selectTableSize = (row, col) => {
      tableRows.value = row
      tableCols.value = col
      previewRows.value = row
      previewCols.value = col
    }

    const resetPreviewSize = () => {
      previewRows.value = tableRows.value
      previewCols.value = tableCols.value
    }

    const syncPreviewSize = () => {
      previewRows.value = tableRows.value
      previewCols.value = tableCols.value
    }

    const insertTable = () => {
      if (!quillEditor) return

      const rows = tableRows.value
      const cols = tableCols.value

      // 生成表格 HTML
      let tableHtml = '<table class="editor-table" style="border-collapse: collapse; width: 100%; table-layout: fixed;">'

      // 表头
      tableHtml += '<thead><tr>'
      for (let j = 0; j < cols; j++) {
        tableHtml += `<th style="border: 1px solid #d0d7de; padding: 10px 12px; background-color: #f6f8fa; font-weight: 600; text-align: left;">表头${j + 1}</th>`
      }
      tableHtml += '</tr></thead>'

      // 表体
      tableHtml += '<tbody>'
      for (let i = 1; i < rows; i++) {
        tableHtml += '<tr>'
        for (let j = 0; j < cols; j++) {
          tableHtml += '<td style="border: 1px solid #d0d7de; padding: 10px 12px; text-align: left;">&nbsp;</td>'
        }
        tableHtml += '</tr>'
      }
      tableHtml += '</tbody></table>'

      // 获取当前光标位置
      const range = quillEditor.getSelection(true)
      const index = range ? range.index : quillEditor.getLength()

      // 使用自定义 Blot 插入表格
      quillEditor.insertEmbed(index, 'tableEmbed', tableHtml, 'user')
      quillEditor.insertText(index + 1, '\n', 'user')
      quillEditor.setSelection(index + 2, 0, 'user')

      // 更新内容
      form.value.content = getSanitizedEditorContent()
      showTableModal.value = false
      hasChanges.value = true

      ElMessage.success('表格已插入')

      // 绑定表格点击事件
      nextTick(() => {
        bindTableEvents()
      })
    }

    // 绑定表格事件
    const bindTableEvents = () => {
      if (!editorRef.value) return

      const tables = editorRef.value.querySelectorAll('table')
      tables.forEach(table => {
        // 移除旧的事件监听器
        table.removeEventListener('click', handleTableClick)
        // 添加新的事件监听器
        table.addEventListener('click', handleTableClick)
      })
    }

    // 处理表格点击
    const handleTableClick = (e) => {
      const cell = e.target.closest('td, th')
      if (cell) {
        currentTableCell.value = cell
        showTableToolbar.value = true

        // 计算工具栏位置
        const rect = cell.getBoundingClientRect()
        const editorRect = editorRef.value.getBoundingClientRect()

        tableToolbarStyle.value = {
          position: 'fixed',
          top: `${rect.top - 45}px`,
          left: `${rect.left}px`,
          zIndex: 1000
        }
      }
    }

    // 表格操作
    const tableAction = (action) => {
      if (!currentTableCell.value) return

      const cell = currentTableCell.value
      const row = cell.parentElement
      const table = row.closest('table')

      if (!table) return

      // 获取 tbody，如果没有则获取 table 本身
      const tbody = table.querySelector('tbody') || table
      const thead = table.querySelector('thead')

      // 判断当前行是否在 thead 中
      const isInThead = thead && thead.contains(row)

      // 获取所有行（包括 thead 和 tbody）
      const allRows = Array.from(table.querySelectorAll('tr'))
      const rowIndex = allRows.indexOf(row)
      const colIndex = Array.from(row.cells).indexOf(cell)
      const numCols = row.cells.length

      const cellStyle = 'border: 1px solid #d0d7de; padding: 10px 12px; text-align: left;'
      const headerStyle = 'border: 1px solid #d0d7de; padding: 10px 12px; background-color: #f6f8fa; font-weight: 600; text-align: left;'

      switch (action) {
        case 'addRowAbove': {
          const newRow = document.createElement('tr')
          for (let i = 0; i < numCols; i++) {
            const td = document.createElement('td')
            td.style.cssText = cellStyle
            td.setAttribute('contenteditable', 'true')
            td.textContent = '\u00A0'
            newRow.appendChild(td)
          }
          // 如果在表头上方插入，则插入到 tbody 开头
          if (isInThead) {
            if (tbody.firstChild) {
              tbody.insertBefore(newRow, tbody.firstChild)
            } else {
              tbody.appendChild(newRow)
            }
          } else {
            row.parentElement.insertBefore(newRow, row)
          }
          break
        }
        case 'addRowBelow': {
          const newRow = document.createElement('tr')
          for (let i = 0; i < numCols; i++) {
            const td = document.createElement('td')
            td.style.cssText = cellStyle
            td.setAttribute('contenteditable', 'true')
            td.textContent = '\u00A0'
            newRow.appendChild(td)
          }
          // 如果在表头，则插入到 tbody 开头
          if (isInThead) {
            if (tbody.firstChild) {
              tbody.insertBefore(newRow, tbody.firstChild)
            } else {
              tbody.appendChild(newRow)
            }
          } else if (row.nextSibling) {
            row.parentElement.insertBefore(newRow, row.nextSibling)
          } else {
            row.parentElement.appendChild(newRow)
          }
          break
        }
        case 'addColLeft': {
          allRows.forEach((r) => {
            const isHeader = thead && thead.contains(r)
            const newCell = document.createElement(isHeader ? 'th' : 'td')
            newCell.style.cssText = isHeader ? headerStyle : cellStyle
            newCell.setAttribute('contenteditable', 'true')
            newCell.textContent = isHeader ? '新列' : '\u00A0'
            if (r.cells[colIndex]) {
              r.insertBefore(newCell, r.cells[colIndex])
            } else {
              r.appendChild(newCell)
            }
          })
          break
        }
        case 'addColRight': {
          allRows.forEach((r) => {
            const isHeader = thead && thead.contains(r)
            const newCell = document.createElement(isHeader ? 'th' : 'td')
            newCell.style.cssText = isHeader ? headerStyle : cellStyle
            newCell.setAttribute('contenteditable', 'true')
            newCell.textContent = isHeader ? '新列' : '\u00A0'
            if (r.cells[colIndex + 1]) {
              r.insertBefore(newCell, r.cells[colIndex + 1])
            } else {
              r.appendChild(newCell)
            }
          })
          break
        }
        case 'deleteRow': {
          // 不允许删除表头行
          if (isInThead) {
            ElMessage.warning('不能删除表头行')
            break
          }
          const tbodyRows = tbody.querySelectorAll('tr')
          if (tbodyRows.length > 1) {
            row.remove()
          } else {
            ElMessage.warning('表格至少需要保留一行数据')
          }
          break
        }
        case 'deleteCol': {
          if (numCols > 1) {
            allRows.forEach(r => {
              if (r.cells[colIndex]) {
                r.cells[colIndex].remove()
              }
            })
          } else {
            ElMessage.warning('表格至少需要保留一列')
          }
          break
        }
        case 'deleteTable': {
          ElMessageBox.confirm('确定要删除整个表格吗？', '提示', {
            confirmButtonText: '确定',
            cancelButtonText: '取消',
            type: 'warning'
          }).then(() => {
            // 删除表格及其包裹容器
            const wrapper = table.closest('.table-wrapper')
            if (wrapper) {
              wrapper.remove()
            } else {
              table.remove()
            }
            showTableToolbar.value = false
            hasChanges.value = true
            form.value.content = getSanitizedEditorContent()
            ElMessage.success('表格已删除')
          }).catch(() => {})
          return
        }
      }

      hasChanges.value = true
      form.value.content = getSanitizedEditorContent()
      showTableToolbar.value = false
    }

    // 点击其他地方关闭表格工具栏
    const handleDocumentClick = (e) => {
      // 如果点击的是表格弹窗内的元素，不关闭工具栏
      if (e.target.closest('.table-modal') || e.target.closest('.modal-overlay')) {
        return
      }
      if (!e.target.closest('.table-toolbar') && !e.target.closest('table')) {
        showTableToolbar.value = false
      }
    }

    // 自动保存
    const startAutoSave = () => {
      if (autoSaveInterval.value) {
        clearInterval(autoSaveInterval.value)
      }

      autoSaveInterval.value = setInterval(() => {
        if (hasChanges.value && form.value.title && autoSaveEnabled.value) {
          autoSaveDraft()
        }
      }, AUTO_SAVE_DELAY)
    }

    const autoSaveDraft = async () => {
      const token = localStorage.getItem('authToken')
      if (!token) return

      if (!form.value.title || !quillEditor || quillEditor.getLength() <= 1) return

      saving.value = true

      try {
        const safeContent = getSanitizedEditorContent()
        const data = {
          ...form.value,
          status: 'draft',
          content: safeContent
        }

        if (isEdit.value && articleId.value) {
          data.articleId = articleId.value
          await updateArticle(data)
        } else {
          const response = await createArticle(data)
          if (response.data.code === 200 && response.data.data) {
            articleId.value = response.data.data
            isEdit.value = true
            router.replace(`/knowledge/edit/${response.data.data}`)
          }
        }

        hasChanges.value = false
        fetchRecentDrafts()
      } catch (error) {
        logger.error('自动保存失败:', error)
      } finally {
        saving.value = false
      }
    }

    const formatTime = (timeStr) => {
       if (!timeStr) return ''
       const date = new Date(timeStr)
       return `${date.getMonth()+1}/${date.getDate()} ${date.getHours()}:${date.getMinutes().toString().padStart(2, '0')}`
    }

    // 检查用户权限
    const checkUserPermission = () => {
      // 默认所有用户都可以选择全平台发布，由后台审核控制
      canPublishPlatform.value = true
    }

    // 键盘快捷键处理
    const handleKeydown = (e) => {
      // Ctrl+S 保存
      if ((e.ctrlKey || e.metaKey) && e.key === 's') {
        e.preventDefault()
        handleSave('draft')
      }
      // Esc 退出全屏
      if (e.key === 'Escape' && fullscreenMode.value) {
        toggleFullscreen()
      }
    }

    onMounted(() => {
      if (route.params.id) {
        isEdit.value = true
        articleId.value = route.params.id
      }
      checkUserPermission()  // 检查用户权限
      nextTick(() => {
        initEditor()
        if (isEdit.value) loadArticle()
        // 绑定表格事件
        bindTableEvents()
      })
      fetchRecentDrafts()
      startAutoSave()

      // 添加键盘事件监听
      document.addEventListener('keydown', handleKeydown)
      // 添加点击事件监听（用于关闭表格工具栏）
      document.addEventListener('click', handleDocumentClick)
    })

    onBeforeUnmount(() => {
      quillEditor = null
      // 清理自动保存定时器
      if (autoSaveInterval.value) {
        clearInterval(autoSaveInterval.value)
      }
      // 清理键盘事件监听
      document.removeEventListener('keydown', handleKeydown)
      // 清理点击事件监听
      document.removeEventListener('click', handleDocumentClick)
      // 恢复 body overflow
      document.body.style.overflow = ''
    })

    return {
      formRef, form, saving, isEdit, articleId, editorRef,
      handleSave, handleFileChange, removeCover, goBack, applyTemplate, smartFormat,
      titleInput, fileInput, autoResize, showPublishModal,
      activeSidebar, toggleSidebar, triggerCoverUpload, wordCount,
      addTopic, hasScroll, handleScroll, hasChanges,
      previewMode, togglePreview, recentDrafts, loadDraft, confirmLeave, formatTime,
      safePreviewContent,
      canPublishPlatform,
      // 新功能
      fullscreenMode, toggleFullscreen,
      editorUndo, editorRedo,
      showTableModal, tableRows, tableCols, previewRows, previewCols,
      hoverTableSize, selectTableSize, resetPreviewSize, syncPreviewSize, insertTable,
      autoSaveEnabled,
      // 表格编辑
      showTableToolbar, tableToolbarStyle, tableAction
    }
  }
}
</script>

<style scoped>
/* Reset & Base */
.edit-page {
  height: 100vh;
  background: #f8fafc;
  display: flex;
  flex-direction: column;
  color: #121212;
  font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", "PingFang SC", "Microsoft YaHei", sans-serif;
  overflow: hidden;
}

/* 全屏模式 */
.edit-page.fullscreen-mode {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 9999;
  background: #fff;
}

.edit-page.fullscreen-mode .page-container {
  margin-top: 0;
  max-width: 900px;
  padding-top: 20px;
}

.edit-page.fullscreen-mode .write-wrapper {
  grid-template-columns: 1fr;
}

.fullscreen-main {
  max-width: 100%;
  min-height: calc(100vh - 100px);
}

.fullscreen-footer {
  position: fixed;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  right: auto;
}

/* 主内容容器 */
.page-container {
  flex: 1;
  overflow-y: auto;
  margin-top: 64px; /* 避开固定 Header */
  padding-top: 10px;
  padding-bottom: 40px;
  max-width: 1280px;
  margin-left: auto;
  margin-right: auto;
  padding-left: 20px;
  padding-right: 20px;
  width: 100%;
}

.write-wrapper {
  display: grid;
  grid-template-columns: 240px 1fr 300px;
  gap: 24px;
  align-items: start;
}

/* 左侧边栏 */
.left-sidebar {
  position: sticky;
  top: 20px;
}

.nav-menu {
  background: #fff;
  border-radius: 12px;
  padding: 8px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.menu-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border-radius: 8px;
  cursor: pointer;
  color: #64748b;
  font-weight: 500;
  transition: all 0.2s;
}

.menu-item:hover {
  background-color: #f1f5f9;
  color: #3b82f6;
}

.menu-item i {
  width: 20px;
  text-align: center;
}

.topic-box {
  background: #fff;
  border-radius: 12px;
  padding: 16px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
  margin-bottom: 16px;
}

.box-title {
  font-size: 14px;
  font-weight: 600;
  color: #94a3b8;
  margin-bottom: 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.topic-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.topic-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border-radius: 6px;
  cursor: pointer;
  color: #475569;
  transition: all 0.2s;
}

.topic-item:hover {
  background-color: #f8fafc;
  color: #3b82f6;
}

.topic-hash {
  color: #cbd5e1;
  font-weight: bold;
}

.topic-name {
  font-weight: 500;
}

/* 主编辑区 */
.write-main {
  background: #fff;
  border-radius: 12px;
  padding: 24px 30px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
  min-height: 800px;
}

/* 工具栏 */
.editor-toolbar-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  border-bottom: 1px solid #f1f5f9;
  padding-bottom: 10px;
}

.toolbar-left,
.toolbar-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.toolbar-divider {
  width: 1px;
  height: 20px;
  background: #e2e8f0;
  margin: 0 4px;
}

.tool-btn {
  background: none;
  border: 1px solid #e2e8f0;
  color: #64748b;
  padding: 6px 16px;
  border-radius: 6px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 6px;
}

.tool-btn:hover {
  color: #3b82f6;
  border-color: #3b82f6;
}

.tool-btn.active {
  background: #eff6ff;
  color: #3b82f6;
  border-color: #3b82f6;
}

/* 预览模式 */
.preview-content {
  padding: 40px;
  background: #fff;
  min-height: 600px;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  line-height: 1.8;
  font-size: 16px;
  color: #333;
}

.preview-content :deep(h1) {
  font-size: 2em;
  margin-top: 0.67em;
  margin-bottom: 0.67em;
  font-weight: 600;
}

.preview-content :deep(h2) {
  font-size: 1.5em;
  margin-top: 1.5em;
  margin-bottom: 0.5em;
  font-weight: 600;
  border-bottom: 1px solid #eaecef;
  padding-bottom: 0.3em;
}

.preview-content :deep(h3) {
  font-size: 1.25em;
  margin-top: 1em;
  margin-bottom: 0.5em;
  font-weight: 600;
}

.preview-content :deep(p) {
  margin-bottom: 1em;
  line-height: 1.8;
}

.preview-content :deep(ul), .preview-content :deep(ol) {
  padding-left: 2em;
  margin-bottom: 1em;
}

.preview-content :deep(li) {
  margin-bottom: 0.5em;
}

.preview-content :deep(blockquote) {
  margin: 0;
  padding: 0 1em;
  color: #6a737d;
  border-left: 0.25em solid #dfe2e5;
  margin-bottom: 1em;
}

.preview-content :deep(img) {
  max-width: 100%;
  border-radius: 4px;
}

/* 封面区域 */
.cover-add-wrapper {
  margin-bottom: 20px;
}

.btn-add-cover {
  background: none;
  border: none;
  color: #8590a6;
  font-size: 14px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 0;
}

.btn-add-cover:hover {
  color: #121212;
}

.cover-preview-wrapper {
  position: relative;
  margin-bottom: 30px;
  border-radius: 4px;
  overflow: hidden;
}

.cover-image-large {
  width: 100%;
  max-height: 300px;
  object-fit: cover;
  display: block;
}

.cover-actions {
  position: absolute;
  top: 10px;
  right: 10px;
  display: flex;
  gap: 10px;
  opacity: 0;
  transition: opacity 0.2s;
}

.cover-preview-wrapper:hover .cover-actions {
  opacity: 1;
}

.cover-actions button {
  background: rgba(0,0,0,0.6);
  color: #fff;
  border: none;
  padding: 4px 12px;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 4px;
}

/* 标题输入 */
.title-wrapper {
  margin-bottom: 20px;
  position: relative;
}

.title-input-large {
  width: 100%;
  border: none;
  font-size: 32px;
  font-weight: 600;
  color: #121212;
  line-height: 1.4;
  outline: none;
  resize: none;
  overflow: hidden;
  padding: 0;
  font-family: inherit;
  background: transparent;
}

.title-input-large::placeholder {
  color: #ebebeb;
}

.title-count {
  position: absolute;
  right: 0;
  bottom: 0;
  font-size: 12px;
  color: #ccc;
  font-weight: 400;
}

/* 编辑器工具栏和内容 */
.editor-wrapper {
  position: relative;
  min-height: 500px;
}

:deep(.ql-toolbar) {
  border: none !important;
  padding: 12px 0 !important;
  position: sticky;
  top: 0;
  background: #fff;
  z-index: 10;
  margin-bottom: 24px;
  border-bottom: 1px solid #f6f6f6 !important;
}

/* 自定义 Tooltip 样式 */
:deep(.ql-toolbar button[data-tooltip]),
:deep(.ql-toolbar .ql-picker[data-tooltip]) {
  position: relative;
}

:deep(.ql-toolbar button[data-tooltip]:hover::after),
:deep(.ql-toolbar .ql-picker[data-tooltip]:hover::after) {
  content: attr(data-tooltip);
  position: absolute;
  top: 100%;
  left: 50%;
  transform: translateX(-50%);
  margin-top: 8px;
  background-color: rgba(0, 0, 0, 0.85);
  color: #fff;
  padding: 5px 10px;
  border-radius: 4px;
  font-size: 12px;
  white-space: nowrap;
  z-index: 1000;
  pointer-events: none;
  line-height: 1.2;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
  animation: tooltipFadeIn 0.2s ease-in-out;
}

/* Tooltip 小箭头 */
:deep(.ql-toolbar button[data-tooltip]:hover::before),
:deep(.ql-toolbar .ql-picker[data-tooltip]:hover::before) {
  content: '';
  position: absolute;
  top: 100%;
  left: 50%;
  transform: translateX(-50%);
  margin-top: 3px;
  border-width: 5px;
  border-style: solid;
  border-color: transparent transparent rgba(0, 0, 0, 0.85) transparent;
  z-index: 1000;
  pointer-events: none;
  animation: tooltipFadeIn 0.2s ease-in-out;
}

@keyframes tooltipFadeIn {
  from { opacity: 0; transform: translateX(-50%) translateY(-5px); }
  to { opacity: 1; transform: translateX(-50%) translateY(0); }
}

:deep(.ql-container) {
  border: none !important;
  font-family: inherit;
  font-size: 16px;
}

:deep(.ql-editor) {
  padding: 0;
  line-height: 1.8;
  color: #121212;
  min-height: 400px;
}

:deep(.ql-editor.ql-blank::before) {
  left: 0;
  color: #8590a6;
  font-style: normal;
}

/* 右侧边栏 */
.right-sidebar {
  position: sticky;
  top: 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* 自定义滚动条样式 */
.right-sidebar::-webkit-scrollbar {
  width: 6px;
}

.right-sidebar::-webkit-scrollbar-track {
  background: transparent;
}

.right-sidebar::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 3px;
}

.right-sidebar::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}

.sidebar-action-card {
  display: flex;
  gap: 10px;
  margin-bottom: 10px;
}

.btn-publish-large {
  flex: 2;
  background: linear-gradient(135deg, #3b82f6, #2563eb);
  color: #fff;
  border: none;
  padding: 12px;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 4px 6px -1px rgba(59,130,246,0.3);
  transition: all 0.2s;
}

.btn-publish-large:hover {
  background: linear-gradient(135deg, #2563eb, #1d4ed8);
}

.btn-draft-large {
  flex: 1;
  background: #fff;
  border: 1px solid #e2e8f0;
  color: #64748b;
  padding: 12px;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-draft-large:hover {
  background: #f8fafc;
  color: #334155;
}

.sidebar-card {
  background: #fff;
  border-radius: 12px;
  padding: 16px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.card-header {
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #f1f5f9;
}

.card-header h3 {
  font-size: 14px;
  font-weight: 600;
  color: #334155;
  margin: 0;
}

.card-body {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.helper-item {
  display: flex;
  align-items: center;
  padding: 12px;
  background: #f9f9fa;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.helper-item:hover {
  background: #f1f5f9;
}

.icon-box {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 12px;
  font-size: 16px;
}

.icon-box.orange { background: #fff7ed; color: #f97316; }
.icon-box.blue { background: #eff6ff; color: #3b82f6; }

.text-box h4 {
  font-size: 14px;
  font-weight: 500;
  margin: 0 0 2px 0;
  color: #334155;
}

.text-box p {
  font-size: 12px;
  color: #94a3b8;
  margin: 0;
}

.template-list {
  margin-top: 12px;
  background: #fff;
  border: 1px solid #f1f5f9;
  border-radius: 8px;
  padding: 8px 0;
}

.tpl-item {
  display: flex;
  align-items: center;
  padding: 10px 16px;
  font-size: 13px;
  cursor: pointer;
  color: #475569;
}

.tpl-item:hover {
  background: #f8fafc;
  color: #3b82f6;
}

.tpl-tag {
  background: #f1f5f9;
  color: #64748b;
  font-size: 11px;
  padding: 2px 6px;
  border-radius: 4px;
  margin-right: 8px;
}

/* 草稿列表 */
.draft-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.draft-item {
  padding: 10px;
  border-radius: 8px;
  background: #f8fafc;
  cursor: pointer;
  transition: all 0.2s;
}

.draft-item:hover {
  background: #f1f5f9;
}

.draft-title {
  display: block;
  font-size: 13px;
  color: #334155;
  margin-bottom: 4px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.draft-time {
  display: block;
  font-size: 11px;
  color: #94a3b8;
}

.empty-tip {
  text-align: center;
  color: #94a3b8;
  font-size: 12px;
  padding: 20px 0;
}

/* 底部字数统计 */
.footer-stats {
  position: fixed;
  bottom: 20px;
  right: 40px;
  font-size: 12px;
  color: #94a3b8;
  background: #fff;
  padding: 6px 12px;
  border-radius: 20px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
  pointer-events: none;
  z-index: 50;
}

/* 模态框 */
.modal-overlay {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(0,0,0,0.4);
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
}

.publish-modal {
  width: 500px;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 10px 25px rgba(0,0,0,0.1);
  display: flex;
  flex-direction: column;
}

.modal-header {
  padding: 20px 24px;
  border-bottom: 1px solid #f1f5f9;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #1e293b;
}

.close-btn {
  background: none;
  border: none;
  font-size: 16px;
  color: #94a3b8;
  cursor: pointer;
}

.modal-body {
  padding: 24px;
}

.form-group {
  margin-bottom: 24px;
}

.form-group label {
  display: block;
  font-size: 14px;
  font-weight: 500;
  margin-bottom: 10px;
  color: #334155;
}

.hint {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 6px;
}

.topic-selector {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.btn-add-topic {
  border: 1px dashed #cbd5e1;
  background: none;
  color: #64748b;
  padding: 4px 12px;
  border-radius: 100px;
  font-size: 13px;
  cursor: pointer;
}

.summary-input {
  width: 100%;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px;
  font-size: 14px;
  outline: none;
  resize: none;
  color: #334155;
  background: #f8fafc;
}

.summary-input:focus {
  border-color: #3b82f6;
  background: #fff;
}

.cover-mini-preview img {
  width: 120px;
  height: 80px;
  object-fit: cover;
  border-radius: 8px;
  margin-right: 12px;
}

.btn-text {
  background: none;
  border: none;
  color: #3b82f6;
  cursor: pointer;
}

.btn-upload-outline {
  border: 1px dashed #cbd5e1;
  background: #f8fafc;
  color: #64748b;
  width: 120px;
  height: 80px;
  border-radius: 8px;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  font-size: 13px;
}

.modal-footer {
  padding: 16px 24px;
  border-top: 1px solid #f1f5f9;
  display: flex;
  justify-content: flex-end;
  gap: 16px;
}

.btn-cancel {
  background: none;
  border: 1px solid #e2e8f0;
  color: #64748b;
  padding: 8px 24px;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 500;
}

.btn-confirm-publish {
  background: #3b82f6;
  color: #fff;
  border: none;
  padding: 8px 24px;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
}

.btn-confirm-publish:hover {
  background: #2563eb;
}

/* 发布范围选择器 */
.publish-scope-options {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.scope-option {
  display: flex;
  align-items: center;
  padding: 14px 16px;
  border: 2px solid #e2e8f0;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
}

.scope-option:hover {
  border-color: #cbd5e1;
  background: #f8fafc;
}

.scope-option.active {
  border-color: #3b82f6;
  background: #eff6ff;
}

.scope-option.disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.scope-option.disabled:hover {
  border-color: #e2e8f0;
  background: transparent;
}

.scope-icon {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: #f1f5f9;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 14px;
  font-size: 18px;
  color: #64748b;
}

.scope-option.active .scope-icon {
  background: #dbeafe;
  color: #3b82f6;
}

.scope-icon.platform {
  background: #fef3c7;
  color: #f59e0b;
}

.scope-option.active .scope-icon.platform {
  background: #fef3c7;
  color: #f59e0b;
}

.scope-info {
  flex: 1;
}

.scope-info h4 {
  font-size: 14px;
  font-weight: 600;
  color: #334155;
  margin: 0 0 4px 0;
}

.scope-info p {
  font-size: 12px;
  color: #94a3b8;
  margin: 0;
}

.scope-check {
  color: #3b82f6;
  font-size: 18px;
  margin-left: 10px;
}

.scope-badge {
  position: absolute;
  top: -8px;
  right: 10px;
  background: #fef3c7;
  color: #92400e;
  font-size: 10px;
  padding: 2px 8px;
  border-radius: 10px;
  font-weight: 500;
}

/* Localize Quill Toolbar */
:deep(.ql-snow .ql-picker.ql-size .ql-picker-label::before),
:deep(.ql-snow .ql-picker.ql-size .ql-picker-item::before) {
  content: attr(data-value) !important;
}

:deep(.ql-snow .ql-picker.ql-size .ql-picker-label:not([data-value])::before) {
  content: '16px' !important; /* Default size display */
}

/* 字体选择器本地化 */
:deep(.ql-snow .ql-picker.ql-font .ql-picker-label[data-value="sans-serif"]::before),
:deep(.ql-snow .ql-picker.ql-font .ql-picker-item[data-value="sans-serif"]::before) {
  content: '默认字体' !important;
}

:deep(.ql-snow .ql-picker.ql-font .ql-picker-label[data-value="serif"]::before),
:deep(.ql-snow .ql-picker.ql-font .ql-picker-item[data-value="serif"]::before) {
  content: '衬线字体' !important;
}

:deep(.ql-snow .ql-picker.ql-font .ql-picker-label[data-value="monospace"]::before),
:deep(.ql-snow .ql-picker.ql-font .ql-picker-item[data-value="monospace"]::before) {
  content: '等宽字体' !important;
}

:deep(.ql-snow .ql-picker.ql-font .ql-picker-label[data-value="Microsoft YaHei"]::before),
:deep(.ql-snow .ql-picker.ql-font .ql-picker-item[data-value="Microsoft YaHei"]::before) {
  content: '微软雅黑' !important;
  font-family: 'Microsoft YaHei', sans-serif;
}

:deep(.ql-snow .ql-picker.ql-font .ql-picker-label[data-value="SimSun"]::before),
:deep(.ql-snow .ql-picker.ql-font .ql-picker-item[data-value="SimSun"]::before) {
  content: '宋体' !important;
  font-family: SimSun, serif;
}

:deep(.ql-snow .ql-picker.ql-font .ql-picker-label[data-value="SimHei"]::before),
:deep(.ql-snow .ql-picker.ql-font .ql-picker-item[data-value="SimHei"]::before) {
  content: '黑体' !important;
  font-family: SimHei, sans-serif;
}

:deep(.ql-snow .ql-picker.ql-font .ql-picker-label[data-value="KaiTi"]::before),
:deep(.ql-snow .ql-picker.ql-font .ql-picker-item[data-value="KaiTi"]::before) {
  content: '楷体' !important;
  font-family: KaiTi, serif;
}

:deep(.ql-snow .ql-picker.ql-font .ql-picker-label[data-value="FangSong"]::before),
:deep(.ql-snow .ql-picker.ql-font .ql-picker-item[data-value="FangSong"]::before) {
  content: '仿宋' !important;
  font-family: FangSong, serif;
}

:deep(.ql-snow .ql-picker.ql-font .ql-picker-label:not([data-value])::before) {
  content: '选择字体' !important;
}

/* 标题选择器本地化 */
:deep(.ql-snow .ql-picker.ql-header .ql-picker-label[data-value="1"]::before),
:deep(.ql-snow .ql-picker.ql-header .ql-picker-item[data-value="1"]::before) {
  content: '标题 1' !important;
}

:deep(.ql-snow .ql-picker.ql-header .ql-picker-label[data-value="2"]::before),
:deep(.ql-snow .ql-picker.ql-header .ql-picker-item[data-value="2"]::before) {
  content: '标题 2' !important;
}

:deep(.ql-snow .ql-picker.ql-header .ql-picker-label[data-value="3"]::before),
:deep(.ql-snow .ql-picker.ql-header .ql-picker-item[data-value="3"]::before) {
  content: '标题 3' !important;
}

:deep(.ql-snow .ql-picker.ql-header .ql-picker-label[data-value="4"]::before),
:deep(.ql-snow .ql-picker.ql-header .ql-picker-item[data-value="4"]::before) {
  content: '标题 4' !important;
}

:deep(.ql-snow .ql-picker.ql-header .ql-picker-label[data-value="5"]::before),
:deep(.ql-snow .ql-picker.ql-header .ql-picker-item[data-value="5"]::before) {
  content: '标题 5' !important;
}

:deep(.ql-snow .ql-picker.ql-header .ql-picker-label[data-value="6"]::before),
:deep(.ql-snow .ql-picker.ql-header .ql-picker-item[data-value="6"]::before) {
  content: '标题 6' !important;
}

:deep(.ql-snow .ql-picker.ql-header .ql-picker-label:not([data-value])::before),
:deep(.ql-snow .ql-picker.ql-header .ql-picker-item:not([data-value])::before) {
  content: '正文' !important;
}

/* 表格弹窗样式 */
.table-modal {
  width: 360px;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 10px 25px rgba(0,0,0,0.15);
  display: flex;
  flex-direction: column;
  z-index: 1001;
}

.table-modal .modal-header {
  padding: 20px 24px;
  border-bottom: 1px solid #f1f5f9;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.table-modal .modal-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #1e293b;
}

.table-modal .modal-body {
  padding: 24px;
}

.table-modal .modal-footer {
  padding: 16px 24px;
  border-top: 1px solid #f1f5f9;
  display: flex;
  justify-content: flex-end;
  gap: 16px;
}

.table-size-selector {
  display: flex;
  gap: 20px;
  margin-bottom: 20px;
}

.size-input-group {
  flex: 1;
}

.size-input-group label {
  display: block;
  font-size: 13px;
  color: #64748b;
  margin-bottom: 6px;
}

.size-input {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 14px;
  text-align: center;
  outline: none;
  transition: border-color 0.2s;
}

.size-input:focus {
  border-color: #3b82f6;
}

.table-preview-grid {
  background: #f8fafc;
  padding: 12px;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.table-preview-row {
  display: flex;
  gap: 4px;
}

.table-preview-cell {
  width: 28px;
  height: 28px;
  background: #e2e8f0;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.15s;
}

.table-preview-cell:hover {
  background: #cbd5e1;
}

.table-preview-cell.active {
  background: #93c5fd;
}

.table-preview-cell.selected {
  background: #3b82f6;
}

.table-preview-cell.active.selected {
  background: #3b82f6;
}

.table-size-hint {
  text-align: center;
  font-size: 14px;
  color: #64748b;
  margin-top: 12px;
  margin-bottom: 0;
}

/* 自动保存提示 */
.auto-save-tip {
  color: #10b981;
  margin-left: 12px;
}

.auto-save-tip i {
  margin-right: 4px;
}

.saving-tip {
  margin-left: 12px;
}

/* 表格编辑工具栏 */
.table-toolbar {
  display: flex;
  align-items: center;
  gap: 4px;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 6px 10px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.table-toolbar button {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 6px 10px;
  border: none;
  background: #f8fafc;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  color: #475569;
  transition: all 0.2s;
}

.table-toolbar button:hover {
  background: #e2e8f0;
  color: #1e293b;
}

.table-toolbar button.danger {
  color: #dc2626;
}

.table-toolbar button.danger:hover {
  background: #fee2e2;
  color: #b91c1c;
}

.table-toolbar .toolbar-divider {
  width: 1px;
  height: 20px;
  background: #e2e8f0;
  margin: 0 4px;
}

/* 编辑器中的表格样式 */
:deep(.ql-table-wrapper) {
  margin: 16px 0;
  overflow-x: auto;
}

:deep(.ql-table-wrapper table) {
  border-collapse: collapse;
  width: 100%;
  table-layout: fixed;
}

:deep(.ql-table-wrapper td),
:deep(.ql-table-wrapper th) {
  border: 1px solid #d0d7de;
  padding: 10px 12px;
  min-width: 80px;
  outline: none;
  text-align: left;
}

:deep(.ql-table-wrapper th) {
  background-color: #f6f8fa;
  font-weight: 600;
}

:deep(.ql-table-wrapper td:focus),
:deep(.ql-table-wrapper th:focus) {
  outline: 2px solid #3b82f6;
  outline-offset: -2px;
}

:deep(.ql-editor table) {
  border-collapse: collapse;
  width: 100%;
  margin: 16px 0;
}

:deep(.ql-editor table td),
:deep(.ql-editor table th) {
  border: 1px solid #ddd;
  padding: 8px 12px;
  min-width: 80px;
  outline: none;
}

:deep(.ql-editor table th) {
  background-color: #f5f7fa;
  font-weight: 600;
}

:deep(.ql-editor table td:focus),
:deep(.ql-editor table th:focus) {
  outline: 2px solid #3b82f6;
  outline-offset: -2px;
}

/* 响应式 */
@media (max-width: 1024px) {
  .write-wrapper {
    grid-template-columns: 200px 1fr;
  }
  .right-sidebar {
    display: none;
  }
}

@media (max-width: 768px) {
  .write-wrapper {
    grid-template-columns: 1fr;
  }
  .left-sidebar {
    display: none;
  }
  .page-container {
    padding-top: 60px;
  }
}
</style>

