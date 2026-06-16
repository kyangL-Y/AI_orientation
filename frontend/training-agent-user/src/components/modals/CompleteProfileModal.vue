<template>
  <transition name="modal-fade">
    <teleport to="body">
      <div class="fixed inset-0 z-[100000] flex items-center justify-center px-4" v-show="show">
        <!-- 背景遮罩 -->
        <div class="absolute inset-0 bg-slate-900/75 backdrop-blur-sm transition-opacity" @click="closeModal"></div>
        
        <!-- 模态框主体 -->
        <div class="relative bg-white w-full max-w-md rounded-2xl shadow-2xl transform transition-all overflow-hidden flex flex-col max-h-[90vh] animate-modal-in border border-slate-100">
          
          <!-- 头部 -->
          <div class="relative px-8 py-6 border-b border-slate-100 bg-gradient-to-r from-blue-50/50 to-indigo-50/50">
            <div class="flex items-center justify-between relative z-10">
              <div>
                <h2 class="text-xl font-bold text-slate-800 tracking-tight">完善资料</h2>
                <p class="text-xs text-slate-500 mt-1">当前账号已创建，请补充所在信息后继续使用学习、考试与会员功能</p>
              </div>
              <button v-if="canClose" @click="closeModal" class="w-8 h-8 flex items-center justify-center rounded-full bg-white text-slate-400 hover:bg-rose-50 hover:text-rose-500 transition-all shadow-sm border border-slate-200/50">
                <i class="fa fa-times"></i>
              </button>
            </div>
            <!-- 装饰背景 -->
            <div class="absolute top-0 right-0 w-32 h-32 bg-blue-400/10 rounded-full blur-3xl -mr-16 -mt-16 pointer-events-none"></div>
          </div>

          <!-- 内容区域 (可滚动) -->
          <div class="px-8 py-6 overflow-y-auto custom-scrollbar flex-1">
            <!-- 头像上传 -->
            <div class="flex flex-col items-center mb-8">
              <div class="relative group cursor-pointer">
                <div class="w-28 h-28 rounded-full bg-slate-50 border-4 border-white shadow-lg flex items-center justify-center overflow-hidden ring-1 ring-slate-200 group-hover:ring-blue-400 transition-all duration-300">
                  <img v-if="form.avatar" :src="form.avatar" class="w-full h-full object-cover" />
                  <div v-else class="flex flex-col items-center justify-center text-slate-300 group-hover:text-blue-400 transition-colors">
                    <i class="fa fa-user text-5xl mb-1"></i>
                  </div>
                  
                  <!-- 悬停遮罩 -->
                  <div class="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center backdrop-blur-[1px]">
                    <i class="fa fa-camera text-white text-2xl drop-shadow-md"></i>
                  </div>
                </div>
                
                <div class="absolute bottom-1 right-1 w-8 h-8 bg-blue-600 rounded-full border-2 border-white flex items-center justify-center text-white shadow-md group-hover:scale-110 group-hover:bg-blue-500 transition-all duration-300 z-10">
                  <i class="fa fa-pencil text-xs"></i>
                </div>
              </div>
              <span class="mt-3 text-xs font-medium text-slate-500 group-hover:text-blue-600 transition-colors">点击头像进行修改</span>
            </div>

            <form @submit.prevent="handleSubmit" class="space-y-5">
              <!-- 用户名 -->
              <div class="space-y-1.5 group">
                <label class="text-sm font-semibold text-slate-700 flex items-center gap-2">
                  用户名
                  <span class="text-rose-500">*</span>
                </label>
                <div class="relative">
                  <div class="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-blue-500 transition-colors">
                    <i class="fa fa-user"></i>
                  </div>
                  <input 
                    type="text" 
                    v-model="form.nickName"
                    :disabled="isLoading"
                    class="w-full h-12 pl-11 pr-4 bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10 transition-all outline-none text-slate-700 placeholder:text-slate-400 text-sm font-medium"
                    placeholder="请输入用户名"
                  />
                </div>
              </div>

              <!-- 手机号 -->
              <div class="space-y-1.5">
                <label class="text-sm font-semibold text-slate-700 flex items-center gap-2">
                  手机号
                </label>
                <div class="relative">
                  <div class="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                    <i class="fa fa-phone"></i>
                  </div>
                  <input 
                    type="tel" 
                    v-model="form.phonenumber"
                    :disabled="isLoading"
                    maxlength="11"
                    class="w-full h-12 pl-11 pr-24 bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10 transition-all outline-none text-slate-700 placeholder:text-slate-400 disabled:bg-slate-100 disabled:text-slate-400 text-sm font-medium"
                    placeholder="可填写手机号"
                  />
                  <div class="absolute right-4 top-1/2 -translate-y-1/2">
                    <span
                      :class="[
                        'text-xs px-2 py-1 rounded-md font-medium',
                        hasBoundPhone ? 'bg-green-100 text-green-600' : 'bg-slate-100 text-slate-400'
                      ]"
                    >
                      {{ hasBoundPhone ? '已绑定' : '未绑定' }}
                    </span>
                  </div>
                </div>
              </div>

              <!-- 邮箱 -->
              <div class="space-y-1.5 group">
                <label class="text-sm font-semibold text-slate-700 flex items-center gap-2">
                  邮箱
                  <span class="text-xs font-normal text-slate-400 ml-auto">可选</span>
                </label>
                <div class="relative">
                  <div class="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-blue-500 transition-colors">
                    <i class="fa fa-envelope"></i>
                  </div>
                  <input 
                    type="email" 
                    v-model="form.email"
                    :disabled="isLoading"
                    class="w-full h-12 pl-11 pr-4 bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10 transition-all outline-none text-slate-700 placeholder:text-slate-400 text-sm font-medium"
                    placeholder="请输入邮箱地址"
                  />
                </div>
              </div>

              <!-- 公司 -->
              <div class="space-y-1.5 group">
                <label class="text-sm font-semibold text-slate-700 flex items-center gap-2">
                  所属公司
                  <span class="text-rose-500">*</span>
                </label>
                <div class="relative">
                  <div class="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-blue-500 transition-colors">
                    <i class="fa fa-building"></i>
                  </div>
                  <div
                    v-if="isTenantLocked"
                    class="w-full h-12 pl-11 pr-4 bg-slate-50 border border-slate-200 rounded-xl text-slate-700 text-sm font-medium flex items-center"
                  >
                    {{ lockedTenantDisplayName }}
                  </div>
                  <select
                    v-else
                    v-model="selectedCompanyId" 
                    @change="handleCompanyChange" 
                    :disabled="isLoading"
                    class="w-full h-12 pl-11 pr-10 bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10 transition-all outline-none text-slate-700 appearance-none text-sm font-medium cursor-pointer"
                  >
                    <option value="" disabled>请选择公司</option>
                    <option v-for="company in companies" :key="company.id" :value="company.id">
                      {{ company.label }}
                    </option>
                  </select>
                  <i v-if="!isTenantLocked" class="fa fa-chevron-down absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 text-xs pointer-events-none transition-transform group-focus-within:rotate-180"></i>
                </div>
              </div>

              <!-- 部门 -->
              <div class="space-y-1.5 group" v-if="isTenantLocked || selectedCompanyId">
                <label class="text-sm font-semibold text-slate-700 flex items-center gap-2">
                  所属部门
                  <span class="text-rose-500">*</span>
                </label>
                <div class="relative">
                  <div class="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-blue-500 transition-colors">
                    <i class="fa fa-sitemap"></i>
                  </div>
                  <select 
                    v-model="form.deptId" 
                    :disabled="isLoading || !departments.length"
                    class="w-full h-12 pl-11 pr-10 bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10 transition-all outline-none text-slate-700 appearance-none disabled:bg-slate-100 disabled:text-slate-400 text-sm font-medium cursor-pointer"
                  >
                    <option value="" disabled>请选择部门</option>
                    <option v-for="dept in departments" :key="dept.id" :value="dept.id">
                      {{ dept.label }}
                    </option>
                  </select>
                  <i class="fa fa-chevron-down absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 text-xs pointer-events-none transition-transform group-focus-within:rotate-180"></i>
                </div>
                <p v-if="departments.length === 0 && selectedCompanyId" class="text-xs text-amber-500 pl-1 flex items-center gap-1">
                  <i class="fa fa-exclamation-circle"></i> 该公司下暂无部门
                </p>
              </div>
            </form>
          </div>

          <!-- 底部按钮 -->
          <div class="px-8 py-5 border-t border-slate-100 shrink-0 flex gap-4 bg-slate-50/50 backdrop-blur-sm">
            <button 
              v-if="canClose"
              @click="closeModal" 
              class="flex-1 h-12 rounded-xl bg-white border border-slate-200 text-slate-600 font-semibold hover:bg-slate-50 hover:text-slate-800 hover:border-slate-300 transition-all text-sm shadow-sm"
            >
              取消
            </button>
            <button 
              @click="handleSubmit"
              :disabled="isLoading || (!isTenantLocked && !selectedCompanyId) || !form.deptId"
              class="flex-1 h-12 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-semibold shadow-lg shadow-blue-500/25 hover:shadow-blue-500/40 hover:scale-[1.01] active:scale-[0.99] transition-all disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100 text-sm flex items-center justify-center gap-2"
            >
              <i v-if="isLoading" class="fa fa-circle-notch fa-spin"></i>
              <span>{{ isLoading ? '保存中...' : '保存并继续' }}</span>
            </button>
          </div>
        </div>
      </div>
    </teleport>
  </transition>
</template>

<script setup>
import logger from '@/utils/logger';
import { ref, reactive, watch, onMounted, computed } from 'vue'
import { updateUserInfo, getUserInfo } from '@/api/auth'
import { api } from '@/utils/api'
import { syncTenantContextFromUser } from '@/utils/tenantContext'
import { ElMessage } from 'element-plus'

const props = defineProps({
  show: Boolean,
  canClose: {
    type: Boolean,
    default: false // 强制完善，默认不可关闭
  }
})

const emit = defineEmits(['close', 'success'])

const isLoading = ref(false)
const deptTreeLoading = ref(false)
const companies = ref([])
const departments = ref([])
const selectedCompanyId = ref('')
const pendingDeptId = ref('')
const lockedTenantId = ref('')
const lockedTenantName = ref('')
const isTenantLocked = computed(() => !!lockedTenantId.value)
const lockedTenantDisplayName = computed(() => lockedTenantName.value || (lockedTenantId.value ? `公司 ${lockedTenantId.value}` : '已绑定公司'))
const hasBoundPhone = computed(() => !!String(form.phonenumber || '').trim())
const DEFAULT_TENANT_ID = '000000'
const INVITE_PROFILE_CONTEXT_KEY = 'inviteProfileContext'

const form = reactive({
  nickName: '',
  phonenumber: '',
  email: '',
  deptId: '',
  avatar: '', // 头像URL，目前后端可能未支持直接上传，作为预留
  sex: '0'
})

const getLocalUserInfo = () => {
  try {
    return JSON.parse(localStorage.getItem('userInfo') || '{}')
  } catch {
    return {}
  }
}

const getInviteProfileContext = () => {
  try {
    return JSON.parse(localStorage.getItem(INVITE_PROFILE_CONTEXT_KEY) || '{}')
  } catch {
    return {}
  }
}

const clearInviteProfileContext = () => {
  try {
    localStorage.removeItem(INVITE_PROFILE_CONTEXT_KEY)
  } catch {}
}

const hydrateLockedTenant = (user = getLocalUserInfo()) => {
  const inviteContext = getInviteProfileContext()
  const candidateTenantId = inviteContext.tenantId || user.tenantId || user.tenant_id || user.profileCompletion?.tenantId || ''
  lockedTenantId.value = candidateTenantId && candidateTenantId !== DEFAULT_TENANT_ID ? candidateTenantId : ''
  lockedTenantName.value = inviteContext.tenantName || user.companyName || user.company || user.tenantName || ''
  if (lockedTenantId.value) {
    selectedCompanyId.value = lockedTenantId.value
  }
}

const formatApiError = (error) => ({
  message: error?.message || 'unknown error',
  url: error?.config?.url || '',
  baseURL: error?.config?.baseURL || '',
  status: error?.response?.status || '',
  data: error?.response?.data || '',
  code: error?.code || ''
})

const fetchOpenDeptTree = async (tenantId) => {
  return api.get('/open/org/depts', {
    params: tenantId ? { tenantId } : undefined,
    __skipAuth: true,
    __skipTenantHeader: true,
    headers: { Accept: 'application/json' }
  })
}

// 获取公司和部门数据（通用解析，不依赖固定ID）
const fetchDeptTree = async () => {
  if (deptTreeLoading.value) {
    return
  }
  deptTreeLoading.value = true
  try {
    hydrateLockedTenant()
    const response = await fetchOpenDeptTree(lockedTenantId.value || undefined)
    logger.debug('API响应数据:', response.data)

    const raw = response && response.data ? response.data : response
    // 兼容 AjaxResult 结构 { code, data } 和直接返回数组两种情况
    const deptTree = Array.isArray(raw)
      ? raw
      : Array.isArray(raw?.data)
        ? raw.data
        : []

    logger.debug('部门树数据:', deptTree)

    // 递归规范化节点，确保所有层级都被正确处理
    const normalizeNode = (node) => {
      if (!node) return null
      return {
        id: node.id || node.value || node.deptId,
        label: node.label || node.deptName || node.name || '',
        children: Array.isArray(node.children) 
          ? node.children.map(child => normalizeNode(child)).filter(Boolean)
          : []
      }
    }

    const roots = deptTree.map(normalizeNode).filter(Boolean)
    const companiesList = []

    if (roots.length > 0) {
      logger.debug('规范化后的根节点:', roots)

      // 判断是否存在三层结构：集团 -> 公司 -> 部门
      const hasThirdLevel = roots.some(root =>
        root.children && root.children.some(child => Array.isArray(child.children) && child.children.length > 0)
      )

      logger.debug('是否三层结构:', hasThirdLevel)

      if (hasThirdLevel) {
        // 把集团下的子节点作为公司，它们的子节点作为部门
        roots.forEach(root => {
          (root.children || []).forEach(company => {
            companiesList.push({
              id: company.id,
              label: company.label,
              children: company.children || []
            })
          })
        })
      } else {
        // 普通两层结构：公司 -> 部门，直接把根节点当作公司
        roots.forEach(company => {
          companiesList.push({
            id: company.id,
            label: company.label,
            children: company.children || []
          })
        })
      }
    }

    if (lockedTenantId.value) {
      companies.value = []
      selectedCompanyId.value = lockedTenantId.value
      departments.value = flattenTenantDeptTree(roots)
      restoreExistingDeptSelection()
      if (!departments.value.length) {
        ElMessage.warning('该公司下暂无部门，请联系管理员')
      }
      return
    }

    companies.value = companiesList
    logger.debug('处理后的公司数据:', companies.value)
    logger.debug('第一个公司的部门:', companies.value[0]?.children)
    restoreExistingDeptSelection()

    if (!companies.value.length) {
      logger.debug('API未返回数据，没有可用的公司信息')
      ElMessage.warning('暂无公司数据，请联系管理员')
    }
  } catch (error) {
    logger.error('获取部门信息失败:', formatApiError(error))
    ElMessage.error('获取部门信息失败，请检查网络连接')
  } finally {
    deptTreeLoading.value = false
  }
}

// 默认头像：简洁的中性灰色人像
const DEFAULT_AVATAR = 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyMDAgMjAwIj48cmVjdCB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgZmlsbD0iI2YxZjVmOSIvPjxjaXJjbGUgY3g9IjEwMCIgY3k9IjgwIiByPSI0MCIgZmlsbD0iI2NiZDVlMSIvPjxwYXRoIGQ9Ik00MCAxODBjMC00MCA2MC01MCA2MC01MHM2MCAxMCA2MCA1MCIgZmlsbD0iI2NiZDVlMSIvPjwvc3ZnPg=='

// 初始化用户信息
const initUserInfo = () => {
  const user = getLocalUserInfo()
  const inviteContext = getInviteProfileContext()
  hydrateLockedTenant(user)
  if (Object.keys(user).length > 0) {
    form.nickName = user.nickName || user.userName || ''
    form.phonenumber = user.phonenumber || ''
    form.email = user.email || ''
    // 如果没有头像，使用默认头像
    form.avatar = user.avatar || DEFAULT_AVATAR
    form.deptId = user.deptId ? String(user.deptId) : (inviteContext.deptId ? String(inviteContext.deptId) : '')
    pendingDeptId.value = form.deptId
    restoreExistingDeptSelection()
  }
}

const restoreExistingDeptSelection = () => {
  if (!pendingDeptId.value) {
    return
  }

  if (isTenantLocked.value && departments.value.some(dept => String(dept.id) === String(pendingDeptId.value))) {
    form.deptId = pendingDeptId.value
    return
  }

  if (companies.value.length === 0) {
    return
  }

  const matchedCompany = companies.value.find(company =>
    Array.isArray(company.children) && flattenDeptTree(company.children).some(dept => String(dept.id) === String(pendingDeptId.value))
  )

  if (!matchedCompany) {
    return
  }

  selectedCompanyId.value = matchedCompany.id
  departments.value = flattenDeptTree(matchedCompany.children || [])
  form.deptId = pendingDeptId.value
}

const flattenDeptTree = (nodes = [], level = 0) => {
  const result = []
  for (const node of nodes) {
    if (!node?.id || !node?.label) {
      continue
    }
    result.push({
      id: String(node.id),
      label: `${'　'.repeat(level)}${node.label}`
    })
    if (Array.isArray(node.children) && node.children.length > 0) {
      result.push(...flattenDeptTree(node.children, level + 1))
    }
  }
  return result
}

const flattenTenantDeptTree = (roots = []) => {
  const selectableRoots = []
  roots.forEach((root) => {
    if (Array.isArray(root.children) && root.children.length > 0) {
      selectableRoots.push(...root.children)
    } else if (root?.id && root?.label) {
      selectableRoots.push(root)
    }
  })
  return flattenDeptTree(selectableRoots)
}

// 组件挂载时初始化数据
onMounted(() => {
  logger.debug('CompleteProfileModal 组件已挂载')
  initUserInfo()
  if (props.show) {
    fetchDeptTree()
  }
})

watch(() => props.show, (newVal) => {
  if (newVal) {
    logger.debug('完善信息弹窗显示')
    initUserInfo()
    fetchDeptTree()
  }
})

const handleCompanyChange = () => {
  logger.debug('选择的公司ID:', selectedCompanyId.value)
  form.deptId = ''
  const company = companies.value.find(c => c.id == selectedCompanyId.value)
  logger.debug('找到的公司:', company)
  if (company && company.children) {
    departments.value = flattenDeptTree(company.children)
    logger.debug('该公司的部门列表:', departments.value)
  } else {
    departments.value = []
    logger.debug('该公司没有部门或公司不存在')
  }
}

const buildProfileUserInfo = (payload, fallback = {}) => {
  const profileUser = payload?.user || payload?.data || {}
  const profileCompletion = payload?.profileCompletion || profileUser.profileCompletion || fallback.profileCompletion || null
  const resolveTenantId = () => {
    const primary = profileUser.tenantId || profileUser.tenant_id || payload?.tenantId || payload?.tenant_id || profileCompletion?.tenantId || ''
    if (primary && primary !== DEFAULT_TENANT_ID) {
      return primary
    }
    return fallback.tenantId || fallback.tenant_id || lockedTenantId.value || primary || null
  }
  const deptName = payload?.deptName || profileUser.deptName || profileUser.dept?.deptName || fallback.deptName || null
  const companyName = payload?.companyName || payload?.tenantName || profileUser.companyName || profileUser.tenantName || fallback.companyName || fallback.company || fallback.tenantName || null
  const userName = profileUser.userName || profileUser.username || profileUser.user_name || fallback.userName || null
  const tenantId = resolveTenantId()
  const phonenumber = profileUser.phonenumber || profileUser.phoneNumber || fallback.phonenumber || form.phonenumber || ''

  return {
    ...profileUser,
    tenantId,
    userName,
    nickName: profileUser.nickName || profileUser.nickname || userName,
    phonenumber,
    phoneNumber: profileUser.phoneNumber || phonenumber,
    deptName,
    department: deptName || fallback.department || null,
    companyName,
    company: companyName || fallback.company || null,
    profileCompletion
  }
}

const handleSubmit = async () => {
  if (!form.nickName) {
    ElMessage.warning('请输入昵称')
    return
  }
  if (form.phonenumber && !/^1[3-9]\d{9}$/.test(String(form.phonenumber).trim())) {
    ElMessage.warning('请输入正确的手机号')
    return
  }
  if (!isTenantLocked.value && !selectedCompanyId.value) {
    ElMessage.warning('请选择公司')
    return
  }
  if (!form.deptId) {
    ElMessage.warning('请选择部门')
    return
  }
  
  try {
    isLoading.value = true
    const selectedCompany = companies.value.find(c => String(c.id) === String(selectedCompanyId.value))
    const selectedDept = departments.value.find(d => String(d.id) === String(form.deptId))
    const submitData = {
      ...form,
      userName: form.nickName,
      nickName: form.nickName,
      phonenumber: String(form.phonenumber || '').trim(),
      deptId: form.deptId ? Number(form.deptId) : null,
      tenantId: lockedTenantId.value || undefined
    }
    const response = await updateUserInfo(submitData)
    if (response.data.code === 200) {
      ElMessage.success('资料已完善')
      // 更新本地用户信息
      const userInfoRes = await getUserInfo()
      if (userInfoRes.data.code === 200) {
        const userInfo = buildProfileUserInfo(userInfoRes.data, {
          userName: form.nickName,
          deptName: selectedDept?.label?.replace(/^[　\s]+/, '') || null,
          department: selectedDept?.label?.replace(/^[　\s]+/, '') || null,
          companyName: selectedCompany?.label || lockedTenantName.value || null,
          company: selectedCompany?.label || lockedTenantName.value || null,
          tenantId: lockedTenantId.value || undefined
        })
        syncTenantContextFromUser(userInfo)
        localStorage.setItem('userInfo', JSON.stringify(userInfo))
        window.dispatchEvent(new CustomEvent('userLogin', { detail: userInfo }))
      }
      clearInviteProfileContext()
      emit('success')
      emit('close')
    } else {
      throw new Error(response.data.msg || '提交失败')
    }
  } catch (error) {
    ElMessage.error(error?.response?.data?.msg || error.message || '提交失败，请重试')
  } finally {
    isLoading.value = false
  }
}

const closeModal = () => {
  if (props.canClose) {
    emit('close')
  }
}
</script>

<style scoped>
.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.3s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

.animate-modal-in {
  animation: modalIn 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes modalIn {
  from {
    opacity: 0;
    transform: scale(0.95) translateY(10px);
  }
  to {
    opacity: 1;
    transform: scale(1) translateY(0);
  }
}

/* 自定义滚动条 */
.custom-scrollbar::-webkit-scrollbar {
  width: 4px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 4px;
}
.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}
</style>

