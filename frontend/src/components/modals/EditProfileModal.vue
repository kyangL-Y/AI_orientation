<template>
  <transition name="modal-fade">
    <teleport to="body">
      <div class="modal-mask" v-show="show">
        <div class="modal-container">
          <div class="modal-header">
            <div class="brand-logo">
              <span>编辑个人资料</span>
            </div>
            <button class="modal-close" @click="closeModal">×</button>
          </div>
          
          <div class="modal-body">
            <form @submit.prevent="handleSubmit" class="space-y-6">
              <!-- 头像上传 -->
              <div class="flex flex-col items-center space-y-4">
                <div class="relative">
                  <div class="w-24 h-24 rounded-full overflow-hidden border-4 border-gray-200 bg-gray-100 flex items-center justify-center">
                    <img 
                      v-if="formData.avatar" 
                      :src="formData.avatar" 
                      alt="头像" 
                      class="w-full h-full object-cover"
                    >
                    <i v-else class="fa fa-user text-4xl text-gray-400"></i>
                  </div>
                  <button 
                    type="button"
                    @click="triggerFileUpload"
                    class="absolute -bottom-1 -right-1 w-8 h-8 bg-blue-600 text-white rounded-full flex items-center justify-center hover:bg-blue-700 transition-colors"
                  >
                    <i class="fa fa-camera text-sm"></i>
                  </button>
                  <input 
                    ref="fileInput"
                    type="file" 
                    accept="image/*" 
                    @change="handleAvatarChange"
                    class="hidden"
                  >
                </div>
                <p class="text-sm text-gray-500">点击相机图标上传头像</p>
              </div>

              <!-- 用户名(昵称) -->
              <div class="form-group">
                <label class="form-label">
                  <i class="fa fa-user form-icon"></i>
                  用户名
                </label>
                <input 
                  type="text" 
                  v-model="formData.userName"
                  class="form-input"
                  placeholder="请输入您的显示昵称"
                  autocomplete="username"
                  maxlength="20"
                  required
                >
                <div class="text-gray-500 text-sm mt-1">
                  <i class="fa fa-info-circle mr-1"></i>
                  这是您的显示名称，其他用户将看到此名称
                </div>
              </div>

              <!-- 手机号 -->
              <div class="form-group">
                <label class="form-label">
                  <i class="fa fa-phone form-icon"></i>
                  手机号
                </label>
                <input 
                  type="tel" 
                  v-model="formData.phonenumber"
                  class="form-input"
                  :placeholder="getPhonePlaceholder()"
                  pattern="^1[3-9]\d{9}$"
                  autocomplete="tel"
                >
                <div v-if="formData.phonenumber && !isValidPhone" class="text-red-500 text-sm mt-1">
                  请输入正确的手机号格式
                </div>
                <div v-if="!formData.phonenumber && isEmailUser" class="text-gray-500 text-sm mt-1">
                  <i class="fa fa-info-circle mr-1"></i>
                  您使用邮箱注册，可在此添加手机号
                </div>
              </div>

              <!-- 邮箱 -->
              <div class="form-group">
                <label class="form-label">
                  <i class="fa fa-envelope form-icon"></i>
                  邮箱
                </label>
                <input 
                  type="email" 
                  v-model="formData.email"
                  class="form-input"
                  :placeholder="getEmailPlaceholder()"
                  autocomplete="email"
                >
                <div v-if="formData.email && !isValidEmail" class="text-red-500 text-sm mt-1">
                  请输入正确的邮箱格式
                </div>
                <div v-if="!formData.email && isPhoneUser" class="text-gray-500 text-sm mt-1">
                  <i class="fa fa-info-circle mr-1"></i>
                  您使用手机号注册，可在此添加邮箱
                </div>
              </div>

              <!-- 公司选择 -->
              <div class="form-group">
                <label class="form-label">
                  <i class="fa fa-building form-icon"></i>
                  公司
                </label>
                <select 
                  v-model="selectedCompanyId" 
                  @change="handleCompanyChange" 
                  class="form-input"
                >
                  <option value="" disabled>请选择公司</option>
                  <option 
                    v-for="company in companies" 
                    :key="company.id" 
                    :value="company.id"
                  >
                    {{ company.label }}
                  </option>
                </select>
              </div>

              <!-- 部门选择 -->
              <div class="form-group">
                <label class="form-label">
                  <i class="fa fa-sitemap form-icon"></i>
                  部门
                </label>
                <select 
                  v-model="formData.deptId" 
                  class="form-input"
                  :disabled="!selectedCompanyId"
                >
                  <option value="" disabled>{{ selectedCompanyId ? '请选择部门' : '请先选择公司' }}</option>
                  <option 
                    v-for="dept in departments" 
                    :key="dept.id" 
                    :value="dept.id"
                  >
                    {{ dept.label }}
                  </option>
                </select>
              </div>

              <!-- 职位填写 -->
              <div class="form-group">
                <label class="form-label">
                  <i class="fa fa-id-badge form-icon"></i>
                  职位
                </label>
                <input 
                  type="text" 
                  v-model="formData.position"
                  class="form-input"
                  placeholder="请输入您的职位（如：前厅经理）"
                  maxlength="50"
                >
              </div>

              <!-- 按钮组 -->
              <div class="flex space-x-4 pt-6">
                <button 
                  type="button" 
                  @click="closeModal"
                  class="btn-cancel"
                >
                  取消
                </button>
                <button 
                  type="submit" 
                  :disabled="isSubmitting || !isFormValid"
                  class="btn-submit"
                >
                  <i v-if="isSubmitting" class="fa fa-spinner fa-spin mr-2"></i>
                  {{ isSubmitting ? '保存中...' : '保存更改' }}
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </teleport>
  </transition>
</template>

<script setup>
import logger from '@/utils/logger';
import { ref, computed, watch, onMounted } from 'vue'
import { updateUserProfile, uploadAvatar, getUserDetail } from '@/api/user'
import { getDeptTree } from '@/api/auth'
import { api } from '@/utils/api'
import { ElMessage } from 'element-plus'

// Props
const props = defineProps({
  show: {
    type: Boolean,
    default: false
  },
  userInfo: {
    type: Object,
    default: () => ({})
  }
})

// Emits
const emit = defineEmits(['close', 'success'])

// 表单数据
const formData = ref({
  userName: '', // user_name 现在是用户的显示昵称
  phonenumber: '',
  email: '',
  sex: '',
  avatar: '',
  deptId: '',
  position: '' // 新增职位字段
})

// 公司和部门数据
const companies = ref([])
const departments = ref([])
const selectedCompanyId = ref('')

// 状态
const isSubmitting = ref(false)
const fileInput = ref(null)

// 用户注册方式判断
const isEmailUser = computed(() => {
  return props.userInfo?.email && props.userInfo.email.includes('@')
})

const isPhoneUser = computed(() => {
  return props.userInfo?.phonenumber || props.userInfo?.phone
})

// 表单验证
const isValidPhone = computed(() => {
  if (!formData.value.phonenumber) return true
  return /^1[3-9]\d{9}$/.test(formData.value.phonenumber)
})

const isValidEmail = computed(() => {
  if (!formData.value.email) return true
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.value.email)
})

const isFormValid = computed(() => {
  // 用户名(昵称)必须填写
  if (!formData.value.userName) return false
  
  // 如果填写了手机号，必须格式正确
  if (formData.value.phonenumber && !isValidPhone.value) return false
  
  // 如果填写了邮箱，必须格式正确
  if (formData.value.email && !isValidEmail.value) return false
  
  // 至少要有手机号或邮箱其中一个
  if (!formData.value.phonenumber && !formData.value.email) return false
  
  return true
})

// 监听用户信息变化，初始化表单数据
watch(() => props.userInfo, (newUserInfo) => {
  logger.debug('🔄 EditProfileModal 监听到用户信息变化:', newUserInfo)
  if (newUserInfo) {
    // 保留 deptId 为数字类型，如果存在的话
    const deptIdValue = newUserInfo.deptId ? Number(newUserInfo.deptId) : null
    
    formData.value = {
      userName: newUserInfo.userName || newUserInfo.username || newUserInfo.user_name || newUserInfo.name || '用户',
      phonenumber: newUserInfo.phonenumber || newUserInfo.phone || '',
      email: newUserInfo.email || '',
      sex: newUserInfo.sex || '',
      avatar: newUserInfo.avatar || '',
      deptId: deptIdValue,
      position: newUserInfo.position || newUserInfo.postGroup || '' // 初始化职位
    }
    
    logger.debug('📝 表单数据初始化:', formData.value)
    
    // 如果用户已有部门且公司数据已加载，设置相应的公司和部门选择
    if (deptIdValue && companies.value.length > 0) {
      setInitialCompanyAndDept(deptIdValue)
    }
  }
}, { immediate: true, deep: true })

// 移除不再需要的部门变化监听器

// 加载组织架构数据（简化版，只用于显示用户当前的公司和部门）
const loadOrgData = async () => {
  try {
    // 检查是否已登录
    const token = localStorage.getItem('authToken')
    if (!token) {
      logger.warn('用户未登录，无法获取用户信息')
      return
    }
    
    logger.debug('正在加载用户信息...')
    
    // 尝试从API获取最新用户信息
    try {
      logger.debug('尝试使用 getUserDetail 接口获取用户信息...')
      const userResponse = await getUserDetail()
      logger.debug('用户详情响应:', userResponse)
      
      if (userResponse.data && userResponse.data.code === 200) {
        const userInfo = userResponse.data.data
        logger.debug('用户信息:', userInfo)
        const storedUserInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
        const mergedUserInfo = {
          ...storedUserInfo,
          ...userInfo,
          profileCompletion: userResponse.data.profileCompletion || userInfo.profileCompletion || storedUserInfo.profileCompletion || null
        }
        
        // 更新本地存储的用户信息
        localStorage.setItem('userInfo', JSON.stringify(mergedUserInfo))
        logger.debug('✅ 成功获取用户信息')
        return
      }
    } catch (userError) {
      logger.warn('使用 getUserDetail 接口失败，使用本地存储:', userError)
      
      // 如果API失败，使用本地存储的用户信息
      try {
        const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
        if (userInfo.userName || userInfo.email) {
          logger.debug('使用本地用户信息:', userInfo)
          return
        }
      } catch (localError) {
        logger.warn('使用本地用户信息失败:', localError)
      }
    }
  } catch (error) {
    logger.error('加载用户信息失败:', error)
  }
}


// 获取手机号占位符
const getPhonePlaceholder = () => {
  if (isPhoneUser.value) {
    return '已绑定手机号'
  }
  return '请输入手机号'
}

// 获取邮箱占位符
const getEmailPlaceholder = () => {
  if (isEmailUser.value) {
    return '已绑定邮箱'
  }
  return '请输入邮箱地址'
}

// 移除不再需要的部门和酒店选择相关函数

// 触发文件上传
const triggerFileUpload = () => {
  fileInput.value?.click()
}

// 处理头像上传
const handleAvatarChange = async (event) => {
  const file = event.target.files[0]
  if (file) {
    // 检查文件类型
    if (!file.type.startsWith('image/')) {
      ElMessage.warning('请选择图片文件')
      return
    }
    
    // 检查文件大小 (限制2MB)
    if (file.size > 2 * 1024 * 1024) {
      ElMessage.warning('图片大小不能超过2MB')
      return
    }
    
    try {
      // 先创建预览URL
      const reader = new FileReader()
      reader.onload = (e) => {
        formData.value.avatar = e.target.result
      }
      reader.readAsDataURL(file)
      
      // 上传到服务器
      const response = await uploadAvatar(file)
      if (response.data.code === 200) {
        formData.value.avatar = response.data.imgUrl || response.data.data?.url
        logger.debug('✅ 头像上传成功:', formData.value.avatar)
        // 头像上传成功，不显示弹窗
      } else {
        throw new Error(response.data.msg || '上传失败')
      }
    } catch (error) {
      logger.error('头像上传失败:', error)
      ElMessage.error('头像上传失败，请重试')
    }
  }
}

// 关闭模态框
const closeModal = () => {
  emit('close')
}

// 提交表单
const handleSubmit = async () => {
  if (!isFormValid.value) {
    ElMessage.warning('请填写完整的表单信息')
    return
  }
  
  // 检查登录状态
  const token = localStorage.getItem('authToken')
  if (!token) {
    ElMessage.warning('请先登录后再编辑个人资料')
    return
  }
  
  isSubmitting.value = true
  
  try {
    // 准备提交的数据，包含部门ID
    // 确保 deptId 是数字类型，如果有值的话
    const deptIdToSubmit = formData.value.deptId ? Number(formData.value.deptId) : null
    
    const submitData = {
      nickName: formData.value.userName, // 后端使用 nickName 字段
      userName: formData.value.userName, // 同时发送 userName
      phonenumber: formData.value.phonenumber,
      email: formData.value.email,
      sex: formData.value.sex,
      avatar: formData.value.avatar,
      deptId: deptIdToSubmit,
      position: formData.value.position
    }
    logger.debug('正在提交用户信息:', submitData)
    logger.debug('📤 deptId 值:', deptIdToSubmit, '类型:', typeof deptIdToSubmit)
    const response = await updateUserProfile(submitData)
    logger.debug('后端响应:', response)
    
    if (response.data.code === 200) {
      logger.debug('✅ 用户信息更新成功')
      
      // 查找选中的公司和部门名称，以便前端立即更新显示
      let companyName = ''
      let deptName = ''
      
      // 使用类型转换确保匹配
      const selectedCompany = companies.value.find(c => Number(c.id) === Number(selectedCompanyId.value))
      if (selectedCompany) {
        companyName = selectedCompany.label
        const selectedDept = selectedCompany.children?.find(d => Number(d.id) === Number(deptIdToSubmit))
        if (selectedDept) {
          deptName = selectedDept.label
        }
      }
      
      logger.debug('📋 查找到的公司:', companyName, '部门:', deptName)
      
      // 构造完整的更新数据回传给父组件
      const updatedData = {
        ...submitData,
        deptId: deptIdToSubmit, // 确保 deptId 是数字
        companyName: companyName,
        department: deptName,
        // 兼容可能的不同字段名
        company: companyName,
        deptName: deptName
      }
      
      // 后端可能不返回用户数据，我们传递构造好的完整数据
      emit('success', updatedData)
      closeModal() // 先关闭弹窗
      ElMessage.success('个人资料更新成功！') // 使用非阻塞提示
    } else {
      logger.error('后端返回错误:', response.data)
      throw new Error(response.data.msg || '更新失败')
    }
  } catch (error) {
    logger.error('更新用户信息失败:', error)
    
    // 根据错误类型显示不同的提示
    if (error.response?.status === 401) {
      ElMessage.error('登录已过期，请重新登录')
      // 清除本地存储的token
      localStorage.removeItem('authToken')
      localStorage.removeItem('userInfo')
      // 刷新页面让用户重新登录
      window.location.reload()
    } else if (error.response?.status === 403) {
      ElMessage.error('没有权限修改个人资料')
    } else {
      ElMessage.error(`更新失败：${error.message || '请重试'}`)
    }
  } finally {
    isSubmitting.value = false
  }
}

// 获取公司和部门数据（通用解析，不依赖固定ID）
const fetchDeptTree = async () => {
  try {
    const response = await getDeptTree()
    logger.debug('=== 获取部门树数据 ===')
    logger.debug('完整响应:', response)
    logger.debug('response.data:', response.data)
    logger.debug('response.data.data:', response.data?.data)

    const raw = response && response.data ? response.data : response
    // 兼容 AjaxResult 结构 { code, data } 和直接返回数组两种情况
    const deptTree = Array.isArray(raw)
      ? raw
      : Array.isArray(raw?.data)
        ? raw.data
        : []

    logger.debug('解析后的部门树数据:', deptTree)
    logger.debug('部门树数据类型:', typeof deptTree)
    logger.debug('是否为数组:', Array.isArray(deptTree))
    logger.debug('数组长度:', deptTree.length)

    const normalizeNode = (node) => ({
      id: node.id || node.value || node.deptId,
      label: node.label || node.deptName || node.name,
      children: Array.isArray(node.children) ? node.children : []
    })

    const companiesList = []

    if (Array.isArray(deptTree) && deptTree.length > 0) {
      const roots = deptTree.map(normalizeNode)

      // 判断是否存在三层结构：集团 -> 公司 -> 部门
      const hasThirdLevel = roots.some(root =>
        root.children && root.children.some(child => Array.isArray(child.children) && child.children.length > 0)
      )

      if (hasThirdLevel) {
        // 把集团下的子节点作为公司，它们的子节点作为部门
        roots.forEach(root => {
          (root.children || []).forEach(rawCompany => {
            const company = normalizeNode(rawCompany)
            const deptChildren = (company.children || []).map(normalizeNode)
            companiesList.push({
              id: company.id,
              label: company.label,
              children: deptChildren
            })
          })
        })
      } else {
        // 普通两层结构：公司 -> 部门，直接把根节点当作公司
        roots.forEach(rawCompany => {
          const company = normalizeNode(rawCompany)
          const deptChildren = (company.children || []).map(normalizeNode)
          companiesList.push({
            id: company.id,
            label: company.label,
            children: deptChildren
          })
        })
      }
    }

    companies.value = companiesList
    logger.debug('处理后的公司数据:', companies.value)

    if (!companies.value.length) {
      logger.debug('API未返回数据，没有可用的公司信息')
      ElMessage.warning('暂无公司数据，请联系管理员')
    } else {
      // 数据加载完成后，如果用户已有部门ID，设置初始选择
      if (formData.value.deptId) {
        setInitialCompanyAndDept(formData.value.deptId)
      }
    }
  } catch (error) {
    logger.error('获取部门信息失败:', error)
    ElMessage.error('获取部门信息失败，请检查网络连接')
  }
}

// 处理公司选择变化
const handleCompanyChange = () => {
  // 重置部门选择
  formData.value.deptId = null
  
  // 更新可选部门列表（使用类型转换确保匹配）
  const selectedCompany = companies.value.find(c => Number(c.id) === Number(selectedCompanyId.value))
  if (selectedCompany) {
    departments.value = selectedCompany.children || []
    logger.debug('选择的公司:', selectedCompany.label)
    logger.debug('可选部门:', departments.value)
  } else {
    departments.value = []
  }
}

// 根据用户现有的部门ID设置初始的公司和部门选择
const setInitialCompanyAndDept = (deptId) => {
  if (!deptId || !companies.value.length) {
    logger.debug('⚠️ setInitialCompanyAndDept 跳过:', { deptId, companiesLen: companies.value.length })
    return
  }
  
  logger.debug('🔍 setInitialCompanyAndDept 开始查找, deptId:', deptId, '类型:', typeof deptId)
  
  // 转换为数字进行比较（解决类型不匹配问题）
  const targetDeptId = Number(deptId)
  
  // 查找部门所属的公司
  for (const company of companies.value) {
    logger.debug('  检查公司:', company.label, 'ID:', company.id)
    const dept = company.children.find(d => Number(d.id) === targetDeptId)
    if (dept) {
      logger.debug('  ✅ 找到部门:', dept.label, '所属公司:', company.label)
      selectedCompanyId.value = company.id
      formData.value.deptId = targetDeptId
      departments.value = company.children || [] // 直接设置部门列表，不调用handleCompanyChange以免清空deptId
      return
    }
  }
  
  logger.debug('  ❌ 未找到匹配的部门')
}

// 组件挂载时加载数据
onMounted(() => {
  loadOrgData()
  fetchDeptTree()
})
</script>

<style scoped>
.modal-mask {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 100000;
  transition: all 0.3s ease;
}

.modal-container {
  background: #ffffff;
  border-radius: 16px;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  width: 90%;
  max-width: 480px;
  max-height: 90vh;
  overflow-y: auto;
  transform-origin: center center;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 28px;
  border-bottom: 1px solid #f3f4f6;
  background: #ffffff;
  position: sticky;
  top: 0;
  z-index: 10;
}

.brand-logo span {
  font-size: 20px;
  font-weight: 700;
  background: linear-gradient(135deg, #1e40af, #3b82f6);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  letter-spacing: -0.5px;
}

.modal-close {
  background: transparent;
  border: none;
  font-size: 24px;
  color: #9ca3af;
  cursor: pointer;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.modal-close:hover {
  background-color: #f3f4f6;
  color: #4b5563;
}

.modal-body {
  padding: 28px;
}

.form-group {
  margin-bottom: 20px;
}

.form-label {
  display: flex;
  align-items: center;
  font-size: 14px;
  font-weight: 600;
  color: #374151;
  margin-bottom: 8px;
}

.form-icon {
  margin-right: 8px;
  color: #3b82f6;
  width: 16px;
  font-size: 14px;
}

.form-input {
  width: 100%;
  padding: 12px 16px;
  background-color: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  font-size: 14px;
  color: #1f2937;
  transition: all 0.2s ease;
}

.form-input:focus {
  outline: none;
  background-color: #ffffff;
  border-color: #3b82f6;
  box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.1);
}

.form-input::placeholder {
  color: #9ca3af;
}

.form-input:disabled {
  background-color: #f3f4f6;
  color: #9ca3af;
  cursor: not-allowed;
}

select.form-input {
  appearance: none;
  background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e");
  background-position: right 0.5rem center;
  background-repeat: no-repeat;
  background-size: 1.5em 1.5em;
  padding-right: 2.5rem;
}

.btn-cancel {
  flex: 1;
  padding: 12px;
  background-color: #ffffff;
  border: 1px solid #e5e7eb;
  color: #4b5563;
  font-weight: 500;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-cancel:hover {
  background-color: #f9fafb;
  border-color: #d1d5db;
  color: #374151;
}

.btn-submit {
  flex: 1;
  padding: 12px;
  background: linear-gradient(135deg, #2563eb, #1d4ed8);
  border: none;
  color: #ffffff;
  font-weight: 500;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: 0 4px 6px -1px rgba(37, 99, 235, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-submit:hover {
  background: linear-gradient(135deg, #1d4ed8, #1e40af);
  transform: translateY(-1px);
  box-shadow: 0 6px 8px -1px rgba(37, 99, 235, 0.3);
}

.btn-submit:active {
  transform: translateY(0);
}

.btn-submit:disabled {
  background: #93c5fd;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

/* 动画效果 */
.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.3s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

.modal-fade-enter-active .modal-container {
  animation: modal-slide-in 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

.modal-fade-leave-active .modal-container {
  animation: modal-slide-out 0.2s ease-in;
}

@keyframes modal-slide-in {
  from {
    opacity: 0;
    transform: scale(0.95) translateY(10px);
  }
  to {
    opacity: 1;
    transform: scale(1) translateY(0);
  }
}

@keyframes modal-slide-out {
  from {
    opacity: 1;
    transform: scale(1) translateY(0);
  }
  to {
    opacity: 0;
    transform: scale(0.95) translateY(10px);
  }
}

/* 滚动条美化 */
.modal-container::-webkit-scrollbar {
  width: 6px;
}

.modal-container::-webkit-scrollbar-track {
  background: transparent;
}

.modal-container::-webkit-scrollbar-thumb {
  background-color: #e5e7eb;
  border-radius: 3px;
}

.modal-container::-webkit-scrollbar-thumb:hover {
  background-color: #d1d5db;
}
</style>
