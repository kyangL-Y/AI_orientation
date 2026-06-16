<template>
  <transition name="modal-fade">
    <teleport to="body">
      <div class="modal-mask" v-show="show">
        <div class="modal-container">
          <div class="modal-header">
            <div class="brand-logo">
              <span>华智酒店及度假村</span>
            </div>
            <button class="modal-close" @click="closeModal">×</button>
          </div>
          
          <div class="modal-body">
            <!-- 注册方式切换 -->
            <div class="register-type-switch">
              <button 
                type="button"
                :class="['type-btn', registerType === 'email' ? 'active' : '']"
                @click="registerType = 'email'"
              >
                邮箱注册
              </button>
              <button 
                type="button"
                :class="['type-btn', registerType === 'phone' ? 'active' : '']"
                @click="registerType = 'phone'"
              >
                手机注册
              </button>
            </div>

            <div v-if="isInviteMode" class="invite-summary">
              <div v-if="inviteLoading" class="invite-summary__loading">正在校验邀请信息...</div>
              <template v-else-if="inviteInfo">
                <div class="invite-summary__title">邀请注册</div>
                <div class="invite-summary__content">
                  <span>加入单位：{{ inviteInfo.tenantName }}</span>
                  <span>加入后所在团队：{{ inviteInfo.deptName || '注册时选择部门' }}</span>
                  <span v-if="inviteInfo.inviterName">邀请人：{{ inviteInfo.inviterName }}</span>
                </div>
              </template>
            </div>

            <div v-if="!isInviteMode" class="register-notice">
              填写验证码并设置密码后即可完成注册。
            </div>
            
            <!-- 邮箱注册表单 -->
            <form @submit.prevent="handleRegister" v-if="registerType === 'email'">
              <div class="form-group" :class="{ 'has-error': errors.email }">
                <label class="form-label required">邮箱</label>
                <input 
                  type="email" 
                  placeholder="请输入邮箱" 
                  v-model="form.email"
                  :disabled="isLoading"
                  autocomplete="email username"
                  :class="{ 'input-error': errors.email }"
                />
                <div v-if="errors.email" class="error-tip">{{ errors.email }}</div>
              </div>
              
              <!-- 公司/酒店选择 -->
              <div class="form-group" v-if="!isInviteMode && showOrgSelection && tenantList.length > 0" :class="{ 'has-error': errors.tenantId }">
                <label class="form-label required">所属公司</label>
                <select 
                  v-model="form.tenantId"
                  :disabled="isLoading || tenantLoading"
                  class="tenant-select"
                  :class="{ 'input-error': errors.tenantId }"
                  @change="onTenantChange"
                >
                  <option value="" disabled>请选择所属公司/酒店</option>
                  <option 
                    v-for="tenant in tenantList" 
                    :key="tenant.tenantId" 
                    :value="tenant.tenantId"
                  >
                    {{ tenant.tenantName }}
                  </option>
                </select>
                <div v-if="errors.tenantId" class="error-tip">{{ errors.tenantId }}</div>
              </div>
              
              <!-- 酒店选择（一级部门） -->
              <div class="form-group" v-if="showOrgSelection && showHotelSelect" :class="{ 'has-error': errors.hotelId }">
                <label class="form-label required">酒店</label>
                <select 
                  v-model="form.hotelId"
                  :disabled="isLoading || hotelLoading"
                  class="tenant-select"
                  :class="{ 'input-error': errors.hotelId }"
                  @change="onHotelChange"
                >
                  <option value="" disabled>请选择酒店</option>
                  <option 
                    v-for="hotel in hotelList" 
                    :key="hotel.deptId" 
                    :value="hotel.deptId"
                  >
                    {{ hotel.deptName }}
                  </option>
                </select>
                <div v-if="errors.hotelId" class="error-tip">{{ errors.hotelId }}</div>
              </div>
              
              <!-- 部门选择（二级部门） -->
              <div class="form-group" v-if="showOrgSelection && showDeptSelect" :class="{ 'has-error': errors.deptId }">
                <label class="form-label required">部门</label>
                <select 
                  v-model="form.deptId"
                  :disabled="isLoading || deptLoading"
                  class="tenant-select"
                  :class="{ 'input-error': errors.deptId }"
                >
                  <option value="" disabled>请选择部门</option>
                  <option 
                    v-for="dept in deptList" 
                    :key="dept.deptId" 
                    :value="dept.deptId"
                  >
                    {{ dept.deptName }}
                  </option>
                </select>
                <div v-if="errors.deptId" class="error-tip">{{ errors.deptId }}</div>
              </div>
              
              <!-- 邮箱验证码输入区域 -->
              <div class="form-group code-input-group" :class="{ 'has-error': errors.emailCode }">
                <label class="form-label required">验证码</label>
                <div class="input-with-btn">
                  <input 
                    type="text" 
                    placeholder="请输入邮箱验证码" 
                    v-model="form.emailCode"
                    :disabled="isLoading"
                    autocomplete="one-time-code"
                    :class="{ 'input-error': errors.emailCode }"
                  />
                  <button 
                    type="button" 
                    class="send-code-btn"
                    :disabled="!canSendEmailCode || emailCountdown > 0 || isLoading"
                    @click="sendEmailVerificationCode"
                  >
                    {{ emailCountdown > 0 ? `${emailCountdown}秒后重试` : '获取验证码' }}
                  </button>
                </div>
                <div v-if="errors.emailCode" class="error-tip">{{ errors.emailCode }}</div>
              </div>
              
              <!-- 图形验证码输入区域 -->
              <div class="form-group captcha-group" :class="{ 'has-error': errors.captchaCode }">
                <label class="form-label required">图形验证码</label>
                <div class="captcha-wrapper">
                  <input 
                    type="text" 
                    placeholder="请输入图形验证码" 
                    v-model="form.captchaCode"
                    :disabled="isLoading"
                    autocomplete="off"
                    class="captcha-input"
                    :class="{ 'input-error': errors.captchaCode }"
                  />
                  <div class="captcha-image" @click="refreshCaptcha">
                    <img 
                      v-if="captchaImageUrl && !captchaImageLoading" 
                      :src="captchaImageUrl" 
                      alt="验证码"
                    >
                    <span v-if="!captchaImageUrl && !captchaImageLoading" class="captcha-text">点击刷新</span>
                    <span v-else-if="captchaImageLoading" class="captcha-text">加载中...</span>
                  </div>
                </div>
                <div v-if="errors.captchaCode" class="error-tip">{{ errors.captchaCode }}</div>
                <div class="captcha-hint">
                  <i class="fa fa-info-circle"></i>
                  <span>提示：请输入图形验证码</span>
                </div>
              </div>
              
              <!-- 密码设置 -->
              <div class="form-group" :class="{ 'has-error': errors.password }">
                <label class="form-label required">登录密码</label>
                <div class="password-input-wrapper">
                  <input 
                    :type="showPassword ? 'text' : 'password'" 
                    placeholder="请设置登录密码" 
                    v-model="form.password"
                    :disabled="isLoading"
                    autocomplete="new-password"
                    :class="{ 'input-error': errors.password }"
                  />
                  <button type="button" class="toggle-password" @click.prevent="showPassword = !showPassword">
                    <svg v-if="!showPassword" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                      <circle cx="12" cy="12" r="3"></circle>
                    </svg>
                    <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path>
                      <line x1="1" y1="1" x2="23" y2="23"></line>
                    </svg>
                  </button>
                </div>
                <div v-if="errors.password" class="error-tip">{{ errors.password }}</div>
              </div>
              
              <!-- 确认密码 -->
              <div class="form-group" :class="{ 'has-error': errors.confirmPassword }">
                <label class="form-label required">确认密码</label>
                <div class="password-input-wrapper">
                  <input 
                    :type="showConfirmPassword ? 'text' : 'password'" 
                    placeholder="请确认密码" 
                    v-model="form.confirmPassword"
                    :disabled="isLoading"
                    autocomplete="new-password"
                    :class="{ 'input-error': errors.confirmPassword }"
                  />
                  <button type="button" class="toggle-password" @click.prevent="showConfirmPassword = !showConfirmPassword">
                    <svg v-if="!showConfirmPassword" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                      <circle cx="12" cy="12" r="3"></circle>
                    </svg>
                    <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path>
                      <line x1="1" y1="1" x2="23" y2="23"></line>
                    </svg>
                  </button>
                </div>
                <div v-if="errors.confirmPassword" class="error-tip">{{ errors.confirmPassword }}</div>
              </div>

              <button 
                type="submit"
                class="register-btn" 
                :disabled="isLoading"
              >
                <span v-if="isLoading">注册中...</span>
                <span v-else>{{ registerButtonText }}</span>
              </button>
            </form>
            
            <!-- 手机号注册表单 -->
            <form @submit.prevent="handleRegister" v-if="registerType === 'phone'">
              <div class="form-group" :class="{ 'has-error': errors.phone }">
                <label class="form-label required">手机号</label>
                <input 
                  type="tel" 
                  placeholder="请输入手机号" 
                  v-model="form.phone"
                  :disabled="isLoading"
                  autocomplete="tel"
                  maxlength="11"
                  :class="{ 'input-error': errors.phone }"
                />
                <div v-if="errors.phone" class="error-tip">{{ errors.phone }}</div>
              </div>
              
              <!-- 公司/酒店选择 -->
              <div class="form-group" v-if="!isInviteMode && showOrgSelection && tenantList.length > 0" :class="{ 'has-error': errors.tenantId }">
                <label class="form-label required">所属公司</label>
                <select 
                  v-model="form.tenantId"
                  :disabled="isLoading || tenantLoading"
                  class="tenant-select"
                  :class="{ 'input-error': errors.tenantId }"
                  @change="onTenantChange"
                >
                  <option value="" disabled>请选择所属公司/酒店</option>
                  <option 
                    v-for="tenant in tenantList" 
                    :key="tenant.tenantId" 
                    :value="tenant.tenantId"
                  >
                    {{ tenant.tenantName }}
                  </option>
                </select>
                <div v-if="errors.tenantId" class="error-tip">{{ errors.tenantId }}</div>
              </div>
              
              <!-- 酒店选择（一级部门） -->
              <div class="form-group" v-if="showOrgSelection && showHotelSelect" :class="{ 'has-error': errors.hotelId }">
                <label class="form-label required">酒店</label>
                <select 
                  v-model="form.hotelId"
                  :disabled="isLoading || hotelLoading"
                  class="tenant-select"
                  :class="{ 'input-error': errors.hotelId }"
                  @change="onHotelChange"
                >
                  <option value="" disabled>请选择酒店</option>
                  <option 
                    v-for="hotel in hotelList" 
                    :key="hotel.deptId" 
                    :value="hotel.deptId"
                  >
                    {{ hotel.deptName }}
                  </option>
                </select>
                <div v-if="errors.hotelId" class="error-tip">{{ errors.hotelId }}</div>
              </div>
              
              <!-- 部门选择（二级部门） -->
              <div class="form-group" v-if="showOrgSelection && showDeptSelect" :class="{ 'has-error': errors.deptId }">
                <label class="form-label required">部门</label>
                <select 
                  v-model="form.deptId"
                  :disabled="isLoading || deptLoading"
                  class="tenant-select"
                  :class="{ 'input-error': errors.deptId }"
                >
                  <option value="" disabled>请选择部门</option>
                  <option 
                    v-for="dept in deptList" 
                    :key="dept.deptId" 
                    :value="dept.deptId"
                  >
                    {{ dept.deptName }}
                  </option>
                </select>
                <div v-if="errors.deptId" class="error-tip">{{ errors.deptId }}</div>
              </div>
              
              <!-- 手机验证码输入区域 -->
              <div class="form-group code-input-group" :class="{ 'has-error': errors.phoneCode }">
                <label class="form-label required">验证码</label>
                <div class="input-with-btn">
                  <input 
                    type="text" 
                    placeholder="请输入手机验证码" 
                    v-model="form.phoneCode"
                    :disabled="isLoading"
                    autocomplete="one-time-code"
                    maxlength="6"
                    :class="{ 'input-error': errors.phoneCode }"
                  />
                  <button 
                    type="button" 
                    class="send-code-btn"
                    :disabled="!canSendPhoneCode || phoneCountdown > 0 || isLoading"
                    @click="sendPhoneVerificationCode"
                  >
                    {{ phoneCountdown > 0 ? `${phoneCountdown}秒后重试` : '获取验证码' }}
                  </button>
                </div>
                <div v-if="errors.phoneCode" class="error-tip">{{ errors.phoneCode }}</div>
              </div>
              
              <!-- 图形验证码输入区域 -->
              <div class="form-group captcha-group" :class="{ 'has-error': errors.captchaCode }">
                <label class="form-label required">图形验证码</label>
                <div class="captcha-wrapper">
                  <input 
                    type="text" 
                    placeholder="请输入图形验证码" 
                    v-model="form.captchaCode"
                    :disabled="isLoading"
                    autocomplete="off"
                    class="captcha-input"
                    :class="{ 'input-error': errors.captchaCode }"
                  />
                  <div class="captcha-image" @click="refreshCaptcha">
                    <img 
                      v-if="captchaImageUrl && !captchaImageLoading" 
                      :src="captchaImageUrl" 
                      alt="验证码"
                    >
                    <span v-if="!captchaImageUrl && !captchaImageLoading" class="captcha-text">点击刷新</span>
                    <span v-else-if="captchaImageLoading" class="captcha-text">加载中...</span>
                  </div>
                </div>
                <div v-if="errors.captchaCode" class="error-tip">{{ errors.captchaCode }}</div>
                <div class="captcha-hint">
                  <i class="fa fa-info-circle"></i>
                  <span>提示：请输入图形验证码</span>
                </div>
              </div>
              
              <!-- 密码设置 -->
              <div class="form-group" :class="{ 'has-error': errors.password }">
                <label class="form-label required">登录密码</label>
                <div class="password-input-wrapper">
                  <input 
                    :type="showPassword ? 'text' : 'password'" 
                    placeholder="请设置登录密码" 
                    v-model="form.password"
                    :disabled="isLoading"
                    autocomplete="new-password"
                    :class="{ 'input-error': errors.password }"
                  />
                  <button type="button" class="toggle-password" @click.prevent="showPassword = !showPassword">
                    <svg v-if="!showPassword" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                      <circle cx="12" cy="12" r="3"></circle>
                    </svg>
                    <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path>
                      <line x1="1" y1="1" x2="23" y2="23"></line>
                    </svg>
                  </button>
                </div>
                <div v-if="errors.password" class="error-tip">{{ errors.password }}</div>
              </div>
              
              <!-- 确认密码 -->
              <div class="form-group" :class="{ 'has-error': errors.confirmPassword }">
                <label class="form-label required">确认密码</label>
                <div class="password-input-wrapper">
                  <input 
                    :type="showConfirmPassword ? 'text' : 'password'" 
                    placeholder="请确认密码" 
                    v-model="form.confirmPassword"
                    :disabled="isLoading"
                    autocomplete="new-password"
                    :class="{ 'input-error': errors.confirmPassword }"
                  />
                  <button type="button" class="toggle-password" @click.prevent="showConfirmPassword = !showConfirmPassword">
                    <svg v-if="!showConfirmPassword" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                      <circle cx="12" cy="12" r="3"></circle>
                    </svg>
                    <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path>
                      <line x1="1" y1="1" x2="23" y2="23"></line>
                    </svg>
                  </button>
                </div>
                <div v-if="errors.confirmPassword" class="error-tip">{{ errors.confirmPassword }}</div>
              </div>

              <button 
                type="submit"
                class="register-btn" 
                :disabled="isLoading"
              >
                <span v-if="isLoading">注册中...</span>
                <span v-else>{{ registerButtonText }}</span>
              </button>
            </form>
          </div>
          
          <div class="switch-tip">
            已有账号？<a @click="$emit('to-login')">去登录</a>
          </div>
          <div class="modal-footer">
            <div class="slogan">每时每刻，都有人在此成功！</div>
          </div>
        </div>
      </div>
    </teleport>
  </transition>
</template>

<script setup>
import { defineProps, defineEmits } from 'vue'
import { ref, reactive, watch, onUnmounted, computed } from 'vue'
import { register, registerByInvitation, resolveInvitation, getUserInfo, sendEmailCode, sendSmsCode, getTenantOptions } from '@/api/auth'
import { getCaptchaUrl } from '@/utils/backend'
import { syncTenantContextFromUser } from '@/utils/tenantContext'
import { ElMessage } from 'element-plus'
import logger from '@/utils/logger'

const setNotificationMessage = (notification, title, details = []) => {
  notification.replaceChildren()

  if (title) {
    const strong = document.createElement('strong')
    strong.textContent = title
    notification.appendChild(strong)
  }

  details.forEach((detail) => {
    notification.appendChild(document.createElement('br'))
    const small = document.createElement('small')
    small.textContent = detail
    notification.appendChild(small)
  })
}

const props = defineProps({
  show: Boolean,
  initialType: {
    type: String,
    default: 'email' // 默认邮箱注册
  },
  inviteCode: {
    type: String,
    default: ''
  },
  inviteToken: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['close', 'to-login'])

// 状态管理
const isLoading = ref(false)
const showPassword = ref(false)
const showConfirmPassword = ref(false)
const registerType = ref('email') // 注册类型：'email' 或 'phone'
const inviteInfo = ref(null)
const inviteLoading = ref(false)
const inviteResolutionFailed = ref(false)
const hasInviteParams = computed(() => !!((props.inviteCode || '').trim() || (props.inviteToken || '').trim()))
const isInviteMode = computed(() => hasInviteParams.value && !inviteResolutionFailed.value)
const registerButtonText = computed(() => isInviteMode.value ? '接受邀请并注册' : '立即注册')

// 监听 show 和 initialType，当弹窗显示时设置初始注册类型
watch(() => props.show, (newVal) => {
  if (newVal) {
    if (props.initialType && (props.initialType === 'email' || props.initialType === 'phone')) {
      logger.debug('📝 设置注册类型为:', props.initialType)
      registerType.value = props.initialType
    } else {
      // 默认或兜底
      registerType.value = 'email'
    }
  }
})

// 租户列表
const tenantList = ref([])
const tenantLoading = ref(false)
const INVITE_PROFILE_CONTEXT_KEY = 'inviteProfileContext'

// 酒店列表（一级部门）
const hotelList = ref([])
const hotelLoading = ref(false)
const usesHotelLevel = ref(false)

// 部门列表（二级部门）
const deptList = ref([])
const deptLoading = ref(false)

// 表单数据
const form = reactive({
  email: '',
  emailCode: '',
  phone: '',
  phoneCode: '',
  tenantId: '', // 选择的租户/公司
  hotelId: '', // 选择的酒店（一级部门）
  deptId: '', // 选择的部门（二级部门）
  captchaCode: '',
  password: '',
  confirmPassword: ''
})

const showHotelSelect = computed(() => !!form.tenantId && usesHotelLevel.value && hotelList.value.length > 0)
const showDeptSelect = computed(() => {
  if (!form.tenantId || deptList.value.length === 0) {
    return false
  }
  return usesHotelLevel.value ? !!form.hotelId : true
})
const showOrgSelection = computed(() => isInviteMode.value)

const persistInviteProfileContext = (data) => {
  try {
    if (!data?.tenantId) return
    localStorage.setItem(INVITE_PROFILE_CONTEXT_KEY, JSON.stringify({
      tenantId: data.tenantId,
      tenantName: data.tenantName || '',
      deptId: data.deptId || '',
      deptName: data.deptName || '',
      inviteCode: data.inviteCode || props.inviteCode || '',
      inviteToken: props.inviteToken || ''
    }))
  } catch {}
}

const clearInviteProfileContext = () => {
  try {
    localStorage.removeItem(INVITE_PROFILE_CONTEXT_KEY)
  } catch {}
}

const applyInviteInfo = async (data) => {
  inviteResolutionFailed.value = false
  inviteInfo.value = data
  persistInviteProfileContext(data)
  form.tenantId = data?.tenantId || ''
  form.hotelId = ''
  form.deptId = data?.deptId ? String(data.deptId) : ''
  tenantList.value = data?.tenantId ? [{ tenantId: data.tenantId, tenantName: data.tenantName }] : []
  hotelList.value = []
  usesHotelLevel.value = false
  deptList.value = data?.deptId ? [{ deptId: data.deptId, deptName: data.deptName || '指定部门' }] : []
  if (data?.tenantId && !data?.deptId) {
    await loadHotelList()
  }
}

const prepareInviteContext = async () => {
  if (!hasInviteParams.value) {
    inviteInfo.value = null
    clearInviteProfileContext()
    return
  }
  try {
    inviteLoading.value = true
    const response = await resolveInvitation({
      inviteCode: props.inviteCode || undefined,
      inviteToken: props.inviteToken || undefined,
      scenario: 'register'
    })
    if (response.data?.code !== 200 || !response.data?.data) {
      throw new Error(response.data?.msg || '邀请码解析失败')
    }
    await applyInviteInfo(response.data.data)
  } catch (error) {
    inviteResolutionFailed.value = true
    inviteInfo.value = null
    clearInviteProfileContext()
    form.tenantId = ''
    form.hotelId = ''
    form.deptId = ''
    hotelList.value = []
    deptList.value = []
    usesHotelLevel.value = false
    logger.error('解析邀请码失败:', error)
    ElMessage.warning(error?.response?.data?.msg || error?.message || '邀请信息已失效，请直接注册。')
  } finally {
    inviteLoading.value = false
  }
}

// 加载租户列表
const loadTenantOptions = async () => {
  try {
    tenantLoading.value = true
    const response = await getTenantOptions()
    if (response.data.code === 200) {
      tenantList.value = response.data.data || []
      logger.debug('📋 租户列表加载成功:', tenantList.value)
      // 如果只有一个租户，自动选中
      if (tenantList.value.length === 1) {
        form.tenantId = tenantList.value[0].tenantId
        onTenantChange() // 自动加载部门
      }
    }
  } catch (error) {
    logger.error('加载租户列表失败:', error)
  } finally {
    tenantLoading.value = false
  }
}

// 租户变更时加载酒店列表
const onTenantChange = async () => {
  // 清空之前的选择
  form.hotelId = ''
  form.deptId = ''
  hotelList.value = []
  deptList.value = []
  usesHotelLevel.value = false
  
  if (!form.tenantId) return
  
  // 加载酒店列表（一级部门）
  await loadHotelList()
}

// 酒店变更时加载部门列表
const onHotelChange = async () => {
  // 清空之前的部门选择
  form.deptId = ''
  deptList.value = []
  
  if (!form.hotelId) return
  
  // 加载该酒店下的部门列表
  await loadDeptList()
}

// 加载酒店列表（一级部门）
const loadHotelList = async () => {
  try {
    hotelLoading.value = true
    const response = await fetch(`/open/org/depts?tenantId=${form.tenantId}`)
    const data = await response.json()
    if (data.code === 200) {
      const treeData = data.data || []

      const rootNodes = treeData.length === 1 && treeData[0].children && treeData[0].children.length > 0
        ? treeData[0].children
        : treeData

      const normalizedNodes = rootNodes.map(node => ({
        deptId: node.id || node.deptId,
        deptName: node.label || node.deptName,
        children: Array.isArray(node.children) ? node.children : []
      })).filter(node => node.deptId && node.deptName)

      const hasNestedDepartments = normalizedNodes.some(node => node.children && node.children.length > 0)

      if (hasNestedDepartments) {
        usesHotelLevel.value = true
        hotelList.value = normalizedNodes
        deptList.value = []
        logger.debug('📋 酒店列表加载成功（三层组织）:', hotelList.value)
      } else {
        usesHotelLevel.value = false
        hotelList.value = []
        deptList.value = flattenDeptTree(normalizedNodes, 0)
        logger.debug('📋 部门列表加载成功（两层组织）:', deptList.value)
      }
    }
  } catch (error) {
    logger.error('加载酒店列表失败:', error)
  } finally {
    hotelLoading.value = false
  }
}

// 加载部门列表（选中酒店的子部门）
const loadDeptList = async () => {
  try {
    deptLoading.value = true
    // 从已加载的酒店列表中找到选中酒店的子部门
    const selectedHotel = hotelList.value.find(h => h.deptId == form.hotelId)
    if (selectedHotel && selectedHotel.children && selectedHotel.children.length > 0) {
      deptList.value = flattenDeptTree(selectedHotel.children, 0)
    } else if (selectedHotel) {
      deptList.value = [{
        deptId: selectedHotel.deptId,
        deptName: selectedHotel.deptName
      }]
      form.deptId = String(selectedHotel.deptId)
    } else {
      deptList.value = []
    }
    if (deptList.value.length > 0) {
      logger.debug('📋 部门列表加载成功:', deptList.value)
    }
  } catch (error) {
    logger.error('加载部门列表失败:', error)
  } finally {
    deptLoading.value = false
  }
}

// 扁平化部门树（兼容 TreeSelect 结构：id/label 和原始结构：deptId/deptName）
const flattenDeptTree = (tree, level = 0) => {
  const result = []
  for (const node of tree) {
    // 兼容两种数据结构
    const deptId = node.id || node.deptId
    const deptName = node.label || node.deptName
    
    if (deptId && deptName) {
      result.push({
        deptId: deptId,
        deptName: '　'.repeat(level) + deptName
      })
    }
    if (node.children && node.children.length > 0) {
      result.push(...flattenDeptTree(node.children, level + 1))
    }
  }
  return result
}

// 验证码相关状态
const captchaImageLoading = ref(false)
const captchaImageUrl = ref('')
const captchaUuid = ref('')
const emailVerificationCode = ref('')
const emailCountdown = ref(0)
const phoneCountdown = ref(0)
let emailCountdownTimer = null
let phoneCountdownTimer = null

const normalizeEmail = (value) => (value || '').trim().toLowerCase()

const normalizePhone = (value) => (value || '').replace(/\s+/g, '')

const normalizeCode = (value) => (value || '').trim()

const normalizeRegisterFields = () => {
  form.email = normalizeEmail(form.email)
  form.phone = normalizePhone(form.phone)
  form.emailCode = normalizeCode(form.emailCode)
  form.phoneCode = normalizeCode(form.phoneCode)
  form.captchaCode = normalizeCode(form.captchaCode)
}

// 计算属性：是否可以发送邮箱验证码（邮箱必须输入且格式正确）
const canSendEmailCode = computed(() => {
  const normalizedEmail = normalizeEmail(form.email)
  return normalizedEmail && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)
})

// 计算属性：是否可以发送手机验证码（手机号必须输入且格式正确）
const canSendPhoneCode = computed(() => {
  const normalizedPhone = normalizePhone(form.phone)
  return normalizedPhone && /^1[3-9]\d{9}$/.test(normalizedPhone)
})

// 错误信息
const errors = reactive({
  email: '',
  emailCode: '',
  phone: '',
  phoneCode: '',
  tenantId: '',
  hotelId: '',
  deptId: '',
  captchaCode: '',
  password: '',
  confirmPassword: ''
})

// 监听模态框显示状态
watch(() => props.show, async (newVal) => {
  if (newVal) {
    resetForm()
    inviteResolutionFailed.value = false
    await refreshCaptcha()
    if (hasInviteParams.value) {
      await prepareInviteContext()
    }
  }
})

// 监听注册类型切换，重置表单
watch(() => registerType.value, (val) => {
  // 强制校验，防止出现空状态
  if (val !== 'email' && val !== 'phone') {
    logger.warn('⚠️ 注册类型异常，重置为 email')
    registerType.value = 'email'
    return
  }
  resetForm()
  refreshCaptcha()
  if (isInviteMode.value && inviteInfo.value) {
    void applyInviteInfo(inviteInfo.value)
  }
})

// 邮箱验证
const validateEmail = () => {
  errors.email = ''
  form.email = normalizeEmail(form.email)
  if (!form.email) {
    errors.email = '请输入邮箱'
    return false
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
    errors.email = '请输入有效的邮箱'
    return false
  }
  return true
}

// 手机号验证
const validatePhone = () => {
  errors.phone = ''
  form.phone = normalizePhone(form.phone)
  if (!form.phone) {
    errors.phone = '请输入手机号'
    return false
  }
  if (!/^1[3-9]\d{9}$/.test(form.phone)) {
    errors.phone = '请输入有效的手机号'
    return false
  }
  return true
}

// 密码验证
const validatePassword = () => {
  errors.password = ''
  errors.confirmPassword = ''
  
  if (!form.password) {
    errors.password = '请设置密码'
    return false
  }
  if (!/^[A-Za-z\d@$!%*#?&]{5,20}$/.test(form.password)) {
    errors.password = '密码只能是数字、字母、特殊字符，5 - 20位'
    return false
  }
  if (form.password !== form.confirmPassword) {
    errors.confirmPassword = '两次输入的密码不一致'
    return false
  }
  return true
}

// 刷新图形验证码
const refreshCaptcha = async () => {
  try {
    captchaImageLoading.value = true
    logger.debug('正在获取注册验证码...')
    
    // 使用工具函数获取验证码URL
    const captchaUrl = getCaptchaUrl()
    logger.debug('使用验证码URL:', captchaUrl)
    
    // 调用后端获取验证码图片
    const response = await fetch(captchaUrl, {
      method: 'GET',
      cache: 'no-store',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    })
    
    if (response.ok) {
      const data = await response.json()
      if (data.code === 200) {
        // 返回的是base64编码的图片
        captchaImageUrl.value = `data:image/jpeg;base64,${data.img}`
        captchaUuid.value = data.uuid
      } else {
        throw new Error(data.msg || '获取验证码失败')
      }
    } else {
      throw new Error('获取验证码失败')
    }
  } catch (error) {
    logger.error('获取验证码失败', error)
    ElMessage.error('获取验证码失败，请重试')
  } finally {
    captchaImageLoading.value = false
  }
}

// 发送邮箱验证码（真实接口）
const sendEmailVerificationCode = async () => {
  form.email = normalizeEmail(form.email)
  logger.sensitive('开始发送邮箱验证码，邮箱：', form.email)
  
  // 验证邮箱格式
  if (!form.email) {
    ElMessage.warning('请先输入邮箱地址')
    return
  }
  
  if (!validateEmail()) {
    return
  }
  
  // 如果正在倒计时，不允许发送
  if (emailCountdown.value > 0) {
    return
  }
  
  try {
    isLoading.value = true
    logger.sensitive('调用 sendEmailCode API...')
    const response = await sendEmailCode(form.email)
    logger.sensitive('API响应：', response)
    logger.sensitive('响应数据：', response.data)
    logger.sensitive('响应状态码：', response.status)
    
    // 检查响应是否成功
    if (response.status === 200 && response.data.code === 200) {
      // 显示发送成功提示
      ElMessage.success(`验证码已发送到 ${form.email}，请查收邮件`)
      
      // 清除之前的定时器（如果存在）
      if (emailCountdownTimer) {
        clearInterval(emailCountdownTimer)
      }
      
      // 开始倒计时（60秒，与后端缓存时间一致）
      emailCountdown.value = 60
      emailCountdownTimer = setInterval(() => {
        emailCountdown.value--
        if (emailCountdown.value <= 0) {
          clearInterval(emailCountdownTimer)
          emailCountdownTimer = null
        }
      }, 1000)
      
    } else {
      // 处理业务逻辑错误
      const errorMsg = response.data?.msg || '发送验证码失败'
      logger.error('业务逻辑错误：', errorMsg)
      ElMessage.error(`发送验证码失败：${errorMsg}`)
    }
  } catch (error) {
    logger.error('发送邮箱验证码失败:', error)
    logger.error('错误详情：', error.response)
    logger.error('错误状态：', error.response?.status)
    logger.error('错误数据：', error.response?.data)
    ElMessage.error('发送验证码失败，请重试')
  } finally {
    isLoading.value = false
  }
}

// 发送手机验证码（真实接口）
const sendPhoneVerificationCode = async () => {
  form.phone = normalizePhone(form.phone)
  logger.sensitive('开始发送手机验证码，手机号：', form.phone)
  
  // 验证手机号格式
  if (!form.phone) {
    ElMessage.warning('请先输入手机号')
    return
  }
  
  if (!validatePhone()) {
    return
  }
  
  // 如果正在倒计时，不允许发送
  if (phoneCountdown.value > 0) {
    return
  }
  
  try {
    isLoading.value = true
    logger.sensitive('调用 sendSmsCode API...')
    const response = await sendSmsCode(form.phone)
    logger.sensitive('API响应：', response)
    logger.sensitive('响应数据：', response.data)
    
    // 检查响应是否成功
    if (response.status === 200 && response.data.code === 200) {
      // 显示发送成功提示
      ElMessage.success(`验证码已发送到 ${form.phone}，请查收短信`)
      
      // 清除之前的定时器（如果存在）
      if (phoneCountdownTimer) {
        clearInterval(phoneCountdownTimer)
      }
      
      // 开始倒计时（60秒，与后端缓存时间一致）
      phoneCountdown.value = 60
      phoneCountdownTimer = setInterval(() => {
        phoneCountdown.value--
        if (phoneCountdown.value <= 0) {
          clearInterval(phoneCountdownTimer)
          phoneCountdownTimer = null
        }
      }, 1000)
      
    } else {
      // 处理业务逻辑错误
      const errorMsg = response.data?.msg || '发送验证码失败'
      logger.error('业务逻辑错误：', errorMsg)
      
      // 显示友好的错误提示
      const notification = document.createElement('div')
      notification.style.position = 'fixed'
      notification.style.top = '20px'
      notification.style.right = '20px'
      notification.style.padding = '15px 20px'
      notification.style.color = 'white'
      notification.style.borderRadius = '8px'
      notification.style.boxShadow = '0 4px 12px rgba(0,0,0,0.15)'
      notification.style.zIndex = '200000'
      notification.style.fontSize = '14px'
      notification.style.lineHeight = '1.5'
      
      if (errorMsg.includes('60秒后再试') || errorMsg.includes('稍后再试')) {
        notification.style.background = '#ffa726'
        setNotificationMessage(notification, '⏱️ 请稍后再试', ['为了防止频繁发送，同一手机号需要等待60秒后才能再次获取验证码'])
      } else if (errorMsg.includes('DailyLimit') || errorMsg.includes('每日') || errorMsg.includes('upper limit')) {
        notification.style.background = '#ff6b6b'
        setNotificationMessage(notification, '🚫 今日发送次数已达上限', ['今日发送次数已达上限', '请明天再试或联系管理员'])
      } else {
        notification.style.background = '#ff6b6b'
        setNotificationMessage(notification, '❌ 验证码发送失败', [errorMsg, '请检查手机号是否正确，或稍后重试'])
      }
      
      document.body.appendChild(notification)
      setTimeout(() => {
        notification.style.transition = 'opacity 0.5s'
        notification.style.opacity = '0'
        setTimeout(() => {
          if (document.body.contains(notification)) {
            document.body.removeChild(notification)
          }
        }, 500)
      }, 5000)
    }
  } catch (error) {
    logger.error('发送手机验证码失败:', error)
    logger.error('错误详情：', error.response)
    logger.error('错误状态：', error.response?.status)
    logger.error('错误数据：', error.response?.data)
    
    // 获取错误消息
    let errorMsg = '网络错误'
    if (error.response && error.response.data) {
      errorMsg = error.response.data.msg || error.response.data.message || '发送验证码失败'
    } else if (error.message) {
      errorMsg = error.message
    }
    
    logger.debug('最终错误消息:', errorMsg)
    
    // 显示友好的错误提示
    const notification = document.createElement('div')
    notification.style.position = 'fixed'
    notification.style.top = '20px'
    notification.style.right = '20px'
    notification.style.padding = '15px 20px'
    notification.style.color = 'white'
    notification.style.borderRadius = '8px'
    notification.style.boxShadow = '0 4px 12px rgba(0,0,0,0.15)'
    notification.style.zIndex = '200000'
    notification.style.fontSize = '14px'
    notification.style.lineHeight = '1.5'
    
    // 根据错误类型显示不同提示
    if (errorMsg.includes('60秒后再试') || errorMsg.includes('稍后再试')) {
      notification.style.background = '#ffa726'
      setNotificationMessage(notification, '⏱️ 请稍后再试', ['为了防止频繁发送，同一手机号需要等待60秒后才能再次获取验证码'])
    } else if (errorMsg.includes('DailyLimit') || errorMsg.includes('每日') || errorMsg.includes('upper limit')) {
      notification.style.background = '#ff6b6b'
      setNotificationMessage(notification, '🚫 今日发送次数已达上限', ['今日发送次数已达上限', '请明天再试或联系管理员'])
    } else if (errorMsg.includes('网络') || errorMsg.includes('Network')) {
      notification.style.background = '#ff6b6b'
      setNotificationMessage(notification, '❌ 网络错误', ['无法连接到服务器，请检查网络连接后重试'])
    } else {
      notification.style.background = '#ff6b6b'
      setNotificationMessage(notification, '❌ 验证码发送失败', [errorMsg, '请检查手机号是否正确，或稍后重试'])
    }
    
    document.body.appendChild(notification)
    setTimeout(() => {
      notification.style.transition = 'opacity 0.5s'
      notification.style.opacity = '0'
      setTimeout(() => {
        if (document.body.contains(notification)) {
          document.body.removeChild(notification)
        }
      }, 500)
    }, 5000)
  } finally {
    isLoading.value = false
  }
}

const buildProfileUserInfo = (payload, fallback = {}) => {
  const profileUser = payload?.user || payload?.data || {}
  const rawProfileCompletion = payload?.profileCompletion || profileUser.profileCompletion || fallback.profileCompletion || null
  const resolveTenantId = () => {
    const primary = profileUser.tenantId || profileUser.tenant_id || payload?.tenantId || payload?.tenant_id || rawProfileCompletion?.tenantId || ''
    if (primary && primary !== '000000') {
      return primary
    }
    return fallback.tenantId || fallback.tenant_id || primary || ''
  }
  const tenantId = resolveTenantId()
  const deptName = payload?.deptName || profileUser.deptName || profileUser.dept?.deptName || fallback.deptName || null
  const companyName = payload?.companyName || payload?.tenantName || profileUser.companyName || profileUser.tenantName || fallback.companyName || fallback.company || fallback.tenantName || null
  const userName = profileUser.userName || profileUser.username || profileUser.user_name || fallback.userName || null
  const nestedProfileCompletion = rawProfileCompletion
  const needsProfileCompletion = payload?.needsProfileCompletion === true ||
    payload?.profileCompletionRequired === true ||
    payload?.data?.needsProfileCompletion === true ||
    payload?.data?.profileCompletionRequired === true ||
    nestedProfileCompletion?.needsProfileCompletion === true
  const profileCompletion = nestedProfileCompletion || needsProfileCompletion
    ? {
        ...(nestedProfileCompletion && typeof nestedProfileCompletion === 'object' ? nestedProfileCompletion : {}),
        needsProfileCompletion,
        completed: typeof nestedProfileCompletion?.completed === 'boolean'
          ? nestedProfileCompletion.completed
          : !needsProfileCompletion
      }
    : null

  return {
    ...profileUser,
    userName,
    nickName: profileUser.nickName || profileUser.nickname || userName,
    username: profileUser.username || fallback.username || userName,
    deptName,
    department: deptName || fallback.department || null,
    deptId: profileUser.deptId || fallback.deptId || null,
    companyName,
    company: companyName || fallback.company || null,
    tenantId,
    tenant_id: tenantId,
    email: profileUser.email || fallback.email || '',
    phonenumber: profileUser.phonenumber || profileUser.phoneNumber || fallback.phonenumber || fallback.phoneNumber || '',
    phoneNumber: profileUser.phoneNumber || fallback.phoneNumber || fallback.phonenumber || '',
    authHydrationPending: fallback.authHydrationPending === true,
    profileCompletion
  }
}

const persistAuthenticatedUser = (userInfo) => {
  syncTenantContextFromUser(userInfo)
  localStorage.setItem('userInfo', JSON.stringify(userInfo))
}

const emitAuthenticatedUser = (userInfo) => {
  window.dispatchEvent(new CustomEvent('userLogin', { detail: userInfo }))
}

const refreshAuthenticatedUserProfile = async (fallbackUserInfo) => {
  try {
    const userInfoResponse = await getUserInfo()
    if (userInfoResponse.data.code === 200) {
      const userInfo = buildProfileUserInfo(userInfoResponse.data, {
        ...fallbackUserInfo,
        authHydrationPending: false
      })
      persistAuthenticatedUser(userInfo)
      emitAuthenticatedUser(userInfo)
      return userInfo
    }

    logger.warn('注册后获取用户信息失败，响应码:', userInfoResponse.data.code)
  } catch (error) {
    logger.warn('注册后获取用户信息失败，已转为可恢复状态:', error)
  }

  window.dispatchEvent(new CustomEvent('userProfileRefreshRequired', { detail: fallbackUserInfo }))
  return fallbackUserInfo
}

const getRegisterErrorMessage = (error) => {
  const rawMessage = error?.response?.data?.msg || error?.message || '注册失败，请重试'

  if (rawMessage.includes('请选择部门')) {
    return '注册失败：你还没有选择部门，请先选择部门后再提交。'
  }

  if (rawMessage.includes('所选部门不存在')) {
    return '注册失败：你选择的部门已失效或被删除，请重新选择有效部门。'
  }

  if (rawMessage.includes('所选部门与当前公司不匹配')) {
    return '注册失败：当前选择的部门不属于你选中的公司，请重新选择公司或部门。'
  }

  if (rawMessage.includes('邀请码')) {
    return `注册失败：${rawMessage}`
  }

  return rawMessage
}

const buildDeviceFingerprint = () => {
  try {
    return [
      navigator.userAgent || '',
      navigator.language || '',
      window.screen?.width || '',
      window.screen?.height || '',
      Intl.DateTimeFormat().resolvedOptions().timeZone || ''
    ].join('|')
  } catch {
    return 'web-client'
  }
}

const persistResolvedInviteContext = (payload = {}) => {
  if (!hasInviteParams.value) {
    return
  }
  persistInviteProfileContext({
    ...(inviteInfo.value || {}),
    tenantId: payload?.tenantId || payload?.data?.tenantId || payload?.profileCompletion?.tenantId || inviteInfo.value?.tenantId || form.tenantId,
    tenantName: payload?.tenantName || payload?.companyName || inviteInfo.value?.tenantName || '',
    deptId: payload?.deptId || payload?.data?.deptId || payload?.profileCompletion?.deptId || inviteInfo.value?.deptId || form.deptId,
    deptName: payload?.deptName || inviteInfo.value?.deptName || '',
    inviteCode: props.inviteCode || inviteInfo.value?.inviteCode || '',
    inviteToken: props.inviteToken || ''
  })
}

const getRegistrationSuccessMessage = (profileCompletion, autoLoggedIn) => {
  if (profileCompletion?.needsProfileCompletion) {
    return autoLoggedIn
      ? '注册并登录成功，请先完善所在信息。'
      : '注册成功！请登录后完善所在信息。'
  }
  return autoLoggedIn ? '注册并登录成功！' : '注册成功！请手动登录'
}

// 处理注册
const handleRegister = async () => {
  Object.keys(errors).forEach(key => errors[key] = '')
  normalizeRegisterFields()
  
  // 根据注册类型进行表单验证
  let hasError = false
  
  if (hasInviteParams.value && !inviteInfo.value) {
    await prepareInviteContext()
    if (!inviteInfo.value) {
      alert('邀请码未校验成功，请刷新邀请链接后重试。')
      return
    }
  }

  const shouldRequireOrgSelection = false

  if (shouldRequireOrgSelection && !form.tenantId) {
    errors.tenantId = '请选择所属公司'
    hasError = true
  }
  
  if (shouldRequireOrgSelection && showHotelSelect.value && !form.hotelId) {
    errors.hotelId = '请选择酒店'
    hasError = true
  }
  
  if (shouldRequireOrgSelection && showDeptSelect.value && !form.deptId) {
    errors.deptId = '请选择部门'
    hasError = true
  }
  
  if (registerType.value === 'email') {
    if (!form.email) {
      errors.email = '请输入邮箱'
      hasError = true
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
      errors.email = '请输入有效的邮箱'
      hasError = true
    }
    if (!form.emailCode) {
      errors.emailCode = '请输入邮箱验证码'
      hasError = true
    }
  } else if (registerType.value === 'phone') {
    if (!form.phone) {
      errors.phone = '请输入手机号'
      hasError = true
    } else if (!/^1[3-9]\d{9}$/.test(form.phone)) {
      errors.phone = '请输入有效的手机号'
      hasError = true
    }
    if (!form.phoneCode) {
      errors.phoneCode = '请输入手机验证码'
      hasError = true
    }
  }
  
  // 图形验证码验证
  if (!form.captchaCode) {
    errors.captchaCode = '请输入图形验证码'
    hasError = true
  }
  
  // 密码验证
  if (!form.password) {
    errors.password = '请设置密码'
    hasError = true
  } else if (!/^[A-Za-z\d@$!%*#?&]{5,20}$/.test(form.password)) {
    errors.password = '密码只能是数字、字母、特殊字符，5-20位'
    hasError = true
  }
  
  if (!form.confirmPassword) {
    errors.confirmPassword = '请确认密码'
    hasError = true
  } else if (form.password !== form.confirmPassword) {
    errors.confirmPassword = '两次输入的密码不一致'
    hasError = true
  }
  
  if (hasError) {
    return
  }

  try {
    isLoading.value = true
    
    // 构建注册数据
    const registerData = {
      password: form.password,
      code: form.captchaCode, // 图形验证码
      uuid: captchaUuid.value // 验证码UUID
    }
    
    if (form.deptId) {
      registerData.deptId = parseInt(form.deptId)
    } else if (form.hotelId) {
      registerData.deptId = parseInt(form.hotelId)
    }
    if (form.tenantId) {
      registerData.tenantId = form.tenantId
    }
    
    if (registerType.value === 'email') {
      registerData.email = form.email
      registerData.emailCode = form.emailCode
    } else if (registerType.value === 'phone') {
      registerData.phonenumber = form.phone
      registerData.phoneCode = form.phoneCode
    }

    if (isInviteMode.value && inviteInfo.value) {
      registerData.inviteCode = props.inviteCode || inviteInfo.value?.inviteCode || ''
      registerData.inviteToken = props.inviteToken || ''
      registerData.deviceFingerprint = buildDeviceFingerprint()
    }
    
    logger.debug('📝 注册数据:', registerData)
    
    // 调用后端注册接口
    const response = await (isInviteMode.value && inviteInfo.value ? registerByInvitation(registerData) : register(registerData))
    
    if (response.data.code === 200) {
      const token = response.data?.token || response.data?.data?.token
      let completionInfo = response.data?.profileCompletion || response.data?.data?.profileCompletion || null
      persistResolvedInviteContext(response.data || {})

      if (token) {
        localStorage.setItem('authToken', token)

        const fallbackUserInfo = buildProfileUserInfo(response.data, {
          userName: form.email || form.phone,
          username: form.email || form.phone,
          nickName: '',
          email: registerType.value === 'email' ? form.email : '',
          phonenumber: registerType.value === 'phone' ? form.phone : '',
          deptId: form.deptId ? Number(form.deptId) : (form.hotelId ? Number(form.hotelId) : null),
          tenantId: form.tenantId || '',
          companyName: inviteInfo.value?.tenantName || null,
          company: inviteInfo.value?.tenantName || null,
          deptName: inviteInfo.value?.deptName || null,
          department: inviteInfo.value?.deptName || null,
          profileCompletion: completionInfo,
          authHydrationPending: true
        })

        completionInfo = fallbackUserInfo.profileCompletion || completionInfo
        persistAuthenticatedUser(fallbackUserInfo)
        emitAuthenticatedUser(fallbackUserInfo)
        void refreshAuthenticatedUserProfile(fallbackUserInfo)

        alert(getRegistrationSuccessMessage(completionInfo, true))
        closeModal()
        return
      }

      alert(getRegistrationSuccessMessage(completionInfo, false))
      closeModal()
    } else {
      throw new Error(response.data.msg || '注册失败')
    }
  } catch (error) {
    alert(getRegisterErrorMessage(error))
    // 注册失败时刷新验证码
    refreshCaptcha()
  } finally {
    isLoading.value = false
  }
}

// 关闭模态框
const closeModal = () => {
  emit('close')
  resetForm()
}

// 重置表单
const resetForm = () => {
  form.email = ''
  form.emailCode = ''
  form.phone = ''
  form.phoneCode = ''
  form.tenantId = ''
  form.captchaCode = ''
  form.password = ''
  form.confirmPassword = ''
  form.hotelId = ''
  form.deptId = ''
  hotelList.value = []
  deptList.value = []
  usesHotelLevel.value = false
  
  // 清除错误信息
  Object.keys(errors).forEach(key => errors[key] = '')
  
  // 清除倒计时
  if (emailCountdownTimer) {
    clearInterval(emailCountdownTimer)
    emailCountdownTimer = null
  }
  emailCountdown.value = 0
  
  if (phoneCountdownTimer) {
    clearInterval(phoneCountdownTimer)
    phoneCountdownTimer = null
  }
  phoneCountdown.value = 0
  
  // 清除验证码
  if (captchaImageUrl.value) {
    URL.revokeObjectURL(captchaImageUrl.value)
    captchaImageUrl.value = ''
  }
  captchaUuid.value = ''
}

// 组件卸载时释放URL对象和清除定时器
onUnmounted(() => {
  if (captchaImageUrl.value) {
    URL.revokeObjectURL(captchaImageUrl.value)
  }
  if (emailCountdownTimer) {
    clearInterval(emailCountdownTimer)
    emailCountdownTimer = null
  }
  if (phoneCountdownTimer) {
    clearInterval(phoneCountdownTimer)
    phoneCountdownTimer = null
  }
})
</script>

<style scoped>
/* 
  Modern Blue Style - 蓝天科技风
  Clean, Professional, Luminous
*/

/* 遮罩层 */
.modal-mask {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background-color: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(4px);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 100000;
  animation: fadeIn 0.3s ease-out;
}

/* 模态框主体 */
.modal-container {
  width: 420px;
  max-height: 90vh;
  background-color: #ffffff;
  border-radius: 20px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
  padding: 40px 40px 30px;
  display: flex;
  flex-direction: column;
  position: relative;
  overflow: hidden;
  animation: slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

/* 顶部装饰线 */
.modal-container::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 4px;
  background: linear-gradient(90deg, #3b82f6, #06b6d4);
  z-index: 1;
}

/* 头部 */
.modal-header {
  text-align: center;
  margin-bottom: 24px;
  padding: 0;
  flex-shrink: 0;
}

.brand-logo span {
  font-size: 24px;
  font-weight: 700;
  background: linear-gradient(135deg, #1e40af, #3b82f6);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  letter-spacing: 1px;
}

.modal-close {
  position: absolute;
  top: 16px;
  right: 16px;
  width: 32px;
  height: 32px;
  border: none;
  background: transparent;
  color: #94a3b8;
  font-size: 24px;
  cursor: pointer;
  border-radius: 50%;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2;
}

.modal-close:hover {
  background-color: #f1f5f9;
  color: #475569;
}

/* 内容区 */
.modal-body {
  padding: 0;
  overflow-y: auto;
  flex: 1;
  max-height: calc(90vh - 180px);
}

/* 自定义滚动条 */
.modal-body::-webkit-scrollbar {
  width: 6px;
}

.modal-body::-webkit-scrollbar-track {
  background: #f1f5f9;
  border-radius: 3px;
}

.modal-body::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 3px;
}

.modal-body::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}

/* 注册方式切换 - Tab 风格 */
.register-type-switch {
  display: flex;
  justify-content: center;
  gap: 40px;
  margin-bottom: 24px;
  border-bottom: 1px solid #e2e8f0;
}

.invite-summary {
  margin-bottom: 18px;
  padding: 14px 16px;
  border-radius: 12px;
  background: linear-gradient(135deg, #eff6ff, #ecfeff);
  border: 1px solid #bfdbfe;
}

.invite-summary__title {
  font-size: 14px;
  font-weight: 700;
  color: #1d4ed8;
  margin-bottom: 6px;
}

.invite-summary__content {
  display: flex;
  flex-direction: column;
  gap: 4px;
  font-size: 13px;
  color: #334155;
}

.invite-summary__loading {
  font-size: 13px;
  color: #475569;
}

.register-notice {
  margin-bottom: 18px;
  padding: 12px 14px;
  border-radius: 12px;
  background: #f8fafc;
  border: 1px dashed #cbd5e1;
  color: #475569;
  font-size: 13px;
  line-height: 1.6;
}

.type-btn {
  background: none;
  border: none;
  padding: 12px 4px;
  font-size: 15px;
  color: #64748b;
  cursor: pointer;
  position: relative;
  transition: color 0.2s;
  font-weight: 500;
  border-radius: 0; /* 重置默认圆角 */
}

.type-btn:hover {
  background: none;
  color: #334155;
}

.type-btn.active {
  color: #3b82f6;
  font-weight: 600;
  background: none; /* 移除背景色 */
}

.type-btn.active::after {
  content: '';
  position: absolute;
  bottom: -1px;
  left: 0;
  width: 100%;
  height: 2px;
  background-color: #3b82f6;
  border-radius: 2px;
}

/* 表单通用 */
.form-group {
  margin-bottom: 16px;
  position: relative;
}

/* 表单标签 */
.form-label {
  display: block;
  font-size: 13px;
  font-weight: 500;
  color: #374151;
  margin-bottom: 6px;
}

/* 必填标识 */
.form-label.required::before {
  content: '*';
  color: #ef4444;
  margin-right: 4px;
  font-weight: bold;
}

/* 错误状态 */
.form-group.has-error input,
.form-group.has-error select,
.input-error {
  border-color: #ef4444 !important;
  background-color: #fef2f2 !important;
}

.form-group.has-error input:focus,
.form-group.has-error select:focus {
  border-color: #ef4444 !important;
  box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.1) !important;
}

.form-group input {
  width: 100%;
  height: 44px;
  padding: 0 16px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 14px;
  color: #334155;
  background-color: #f8fafc;
  transition: all 0.2s;
  outline: none;
}

.form-group input:focus {
  background-color: #fff;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

/* 公司/租户选择下拉框 */
.tenant-select {
  width: 100%;
  height: 44px;
  padding: 0 16px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 14px;
  color: #334155;
  background-color: #f8fafc;
  transition: all 0.2s;
  outline: none;
  cursor: pointer;
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%23475569' d='M6 8L1 3h10z'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 16px center;
}

.tenant-select:focus {
  background-color: #fff;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.tenant-select:disabled {
  background-color: #f1f5f9;
  cursor: not-allowed;
}

/* 验证码区域 */
.captcha-wrapper {
  display: flex;
  gap: 10px;
}

.captcha-input {
  flex: 1;
}

.captcha-image {
  width: 120px;
  height: 44px;
  padding: 0 4px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  overflow: hidden;
}

.captcha-image img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  display: block;
}

.captcha-hint {
  margin-top: 6px;
  font-size: 12px;
  color: #64748b;
  background: #f8fafc;
  padding: 6px 10px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  gap: 6px;
}

.captcha-hint i { color: #3b82f6; }

/* 发送验证码按钮 */
.input-with-btn {
  position: relative;
  width: 100%;
}

.input-with-btn input {
  width: 100%;
  padding-right: 100px;
}

.send-code-btn {
  position: absolute;
  right: 6px;
  top: 50%;
  transform: translateY(-50%);
  border: none;
  background: rgba(59, 130, 246, 0.1);
  color: #3b82f6;
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 12px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.2s;
  white-space: nowrap;
}

.send-code-btn:hover:not(:disabled) {
  background: rgba(59, 130, 246, 0.2);
}

.send-code-btn:disabled {
  background: #f1f5f9;
  color: #94a3b8;
  cursor: not-allowed;
}

/* 密码显隐 */
.password-input-wrapper {
  position: relative;
  width: 100%;
}

.password-input-wrapper input {
  width: 100%;
  padding-right: 45px;
}

.toggle-password {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  border: none;
  background: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.toggle-password:hover {
  color: #64748b;
}

.toggle-password svg {
  width: 18px;
  height: 18px;
}

/* 注册按钮 */
.register-btn {
  width: 100%;
  height: 44px;
  background: linear-gradient(135deg, #3b82f6, #2563eb);
  color: #fff;
  font-size: 15px;
  font-weight: 600;
  border: none;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.3s;
  margin-top: 8px;
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.2);
}

.register-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 16px rgba(37, 99, 235, 0.3);
  background: linear-gradient(135deg, #2563eb, #1d4ed8);
}

.register-btn:disabled {
  background: #cbd5e1;
  box-shadow: none;
  cursor: not-allowed;
  transform: none;
}

/* 底部切换 */
.switch-tip {
  text-align: center;
  font-size: 13px;
  color: #64748b;
  margin-top: 20px;
  margin-bottom: 16px;
}

.switch-tip a {
  color: #3b82f6;
  font-weight: 600;
  cursor: pointer;
  text-decoration: none;
  margin-left: 4px;
}

.switch-tip a:hover {
  text-decoration: underline;
}

/* Footer */
.modal-footer {
  background-color: #f8fafc;
  padding: 12px;
  text-align: center;
  border-radius: 0 0 20px 20px;
  margin: 0 -40px -30px; /* 抵消 padding */
}

.slogan {
  font-size: 12px;
  color: #94a3b8;
  letter-spacing: 1px;
}

/* 错误提示 */
.error-tip {
  color: #ef4444;
  font-size: 12px;
  margin-top: 4px;
  padding-left: 2px;
}

/* 图标 */
.icon { display: inline-block; font-style: normal; font-size: 18px; line-height: 1; }
.icon-eye::before { content: "○"; font-family: Arial, sans-serif; }
.icon-eye-off::before { content: "◉"; font-family: Arial, sans-serif; }

/* 动画 */
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
@keyframes slideUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }

/* 移动端适配 */
@media (max-width: 480px) {
  .modal-mask {
    padding: 12px;
  }

  .modal-container {
    width: min(100%, 360px);
    max-height: 92vh;
    border-radius: 16px;
    padding: 18px 16px 14px;
    margin: 0;
  }

  .modal-header {
    margin-bottom: 14px;
  }

  .brand-logo span {
    font-size: 22px;
    line-height: 1.2;
    letter-spacing: 0.5px;
  }

  .modal-close {
    top: 10px;
    right: 10px;
    width: 28px;
    height: 28px;
    font-size: 20px;
  }

  .modal-body {
    max-height: calc(92vh - 122px);
    padding-right: 2px;
  }

  .register-type-switch {
    gap: 16px;
    margin-bottom: 16px;
  }

  .type-btn {
    flex: 1;
    min-width: 0;
    padding: 10px 0;
    font-size: 14px;
    white-space: nowrap;
  }

  .form-group {
    margin-bottom: 10px;
  }

  .form-label {
    font-size: 12px;
    margin-bottom: 4px;
  }

  .form-group input,
  .tenant-select,
  .captcha-image,
  .register-btn {
    height: 40px;
    font-size: 14px;
  }

  .form-group input,
  .tenant-select {
    padding: 0 14px;
  }

  .tenant-select {
    background-position: right 12px center;
  }

  .captcha-wrapper {
    gap: 8px;
  }

  .captcha-image {
    width: 120px;
    border-radius: 9px;
  }

  .captcha-hint {
    margin-top: 4px;
    padding: 4px 8px;
    font-size: 11px;
    gap: 4px;
  }

  .input-with-btn input {
    padding-right: 94px;
  }

  .send-code-btn {
    right: 4px;
    padding: 5px 10px;
    font-size: 11px;
  }

  .password-input-wrapper input {
    padding-right: 40px;
  }

  .toggle-password {
    right: 10px;
  }

  .toggle-password svg {
    width: 16px;
    height: 16px;
  }

  .register-btn {
    margin-top: 6px;
    font-size: 15px;
  }

  .switch-tip {
    margin-top: 12px;
    margin-bottom: 8px;
    font-size: 12px;
  }

  .modal-footer {
    padding: 8px;
    margin: 0 -16px -14px;
  }

  .slogan {
    font-size: 11px;
    letter-spacing: 0.5px;
  }
}

@media (max-width: 380px) {
  .modal-mask {
    padding: 10px;
  }

  .modal-container {
    padding: 16px 14px 12px;
    border-radius: 14px;
  }

  .brand-logo span {
    font-size: 20px;
  }

  .register-type-switch {
    gap: 12px;
  }

  .type-btn {
    font-size: 13px;
  }

  .captcha-image {
    width: 112px;
  }

  .captcha-hint {
    font-size: 10px;
  }

  .modal-footer {
    margin: 0 -14px -12px;
  }
}

@media (max-width: 390px) {
  .register-type-switch {
    gap: 8px;
  }

  .type-btn {
    min-height: 42px;
    white-space: normal;
    line-height: 1.2;
    padding: 8px 4px;
  }

  .invite-summary__content {
    gap: 6px;
    line-height: 1.45;
  }
}

@media (max-width: 420px) {
  .input-with-btn {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .input-with-btn input {
    padding-right: 14px;
  }

  .send-code-btn {
    position: static;
    transform: none;
    width: 100%;
    justify-content: center;
    min-height: 36px;
    border-radius: 8px;
  }

  .captcha-wrapper {
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(150px, 46%);
    align-items: stretch;
    gap: 8px;
  }

  .captcha-input {
    height: 40px;
  }

  .captcha-image {
    width: 100%;
    height: 40px;
  }

  .invite-summary,
  .register-notice {
    padding: 12px;
  }
}

/* 小屏幕高度适配 */
@media (max-height: 700px) {
  .modal-container {
    max-height: 96vh;
    padding: 18px 18px 14px;
  }
  
  .modal-body {
    max-height: calc(96vh - 126px);
  }
  
  .modal-header {
    margin-bottom: 12px;
  }
  
  .form-group {
    margin-bottom: 10px;
  }

  .invite-summary,
  .register-notice {
    margin-bottom: 14px;
  }
}
</style>
