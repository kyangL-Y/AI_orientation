<template>
     <transition name="modal-fade">
 <teleport to="body">
    <div class="modal-mask" v-if="show">
      <div class="modal-container">
        <div class="modal-header">
          <div class="brand-logo">
            <span>华智酒店及度假村</span>
          </div>
          <p class="modal-subtitle">欢迎回来，请登录您的账号</p>
          <button class="modal-close" @click="closeModal">×</button>
        </div>
        
        <div class="modal-body">
          <!-- 登录方式切换 -->
          <div class="login-tabs" v-if="loginType !== 'reset'">
            <button
              :class="{ active: loginType === 'phone' }"
              @click="loginType = 'phone'"
            >
              手机验证码
            </button>
            <button
              :class="{ active: loginType === 'email' }"
              @click="loginType = 'email'"
            >
              邮箱验证码
            </button>
            <button
              :class="{ active: loginType === 'password' }"
              @click="loginType = 'password'"
            >
              密码登录
            </button>
          </div>

          <!-- 手机验证码登录表单 -->
          <form @submit.prevent="handleLogin">
          <div v-if="loginType === 'phone'" class="form-group">
            <input
              type="tel"
              placeholder="请输入手机号"
              v-model="form.phoneLogin.phone"
              :disabled="isLoading"
              autocomplete="tel"
              maxlength="11"
            />
            <div v-if="errors.phoneLogin?.phone" class="error-tip">{{ errors.phoneLogin.phone }}</div>
          </div>
          <div v-if="loginType === 'phone'" class="form-group">
            <input
              type="text"
              placeholder="请输入验证码"
              v-model="form.phoneLogin.code"
              :disabled="isLoading"
              autocomplete="one-time-code"
            />
            <button
              type="button"
              class="send-btn"
              :disabled="smsCountdown > 0 || isLoading"
              @click="sendPhoneLoginCode"
            >
              {{ smsCountdown > 0 ? `${smsCountdown}秒后重发` : '获取验证码' }}
            </button>
          </div>

          <!-- 邮箱验证码登录表单 -->
          <div v-if="loginType === 'email'" class="form-group">
              <input 
                type="email" 
                placeholder="请输入邮箱" 
                v-model="form.emailLogin.email"
                :disabled="isLoading"
                autocomplete="email"
              />
            <div v-if="errors.emailLogin?.email" class="error-tip">{{ errors.emailLogin.email }}</div>
          </div>
          <div v-if="loginType === 'email'" class="form-group">
            <input 
              type="text" 
              placeholder="请输入验证码" 
              v-model="form.emailLogin.code"
              :disabled="isLoading"
              autocomplete="one-time-code"
            />
            <button 
              type="button"
              class="send-btn"
              :disabled="emailCountdown > 0 || isLoading"
              @click="sendEmailLoginCode"
            >
              {{ emailCountdown > 0 ? `${emailCountdown}秒后重发` : '获取验证码' }}
            </button>
          </div>

          <!-- 密码登录表单 -->
          <div v-if="loginType === 'password'" class="form-group">
            <input 
              type="text" 
              placeholder="请输入账号/手机号/邮箱" 
              v-model="form.passwordLogin.username"
              :disabled="isLoading"
              autocomplete="username"
            />
            <div v-if="errors.passwordLogin?.username" class="error-tip">{{ errors.passwordLogin.username }}</div>
          </div>
          <div v-if="loginType === 'password'" class="form-group">
            <div class="password-input-wrapper">
              <input 
                :type="showPassword ? 'text' : 'password'" 
                placeholder="请输入密码" 
                v-model="form.passwordLogin.password"
                :disabled="isLoading"
                autocomplete="current-password"
              />
              <button type="button" class="toggle-password" @click="showPassword = !showPassword">
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
            <div v-if="errors.passwordLogin?.password" class="error-tip">{{ errors.passwordLogin.password }}</div>
          </div>

          <!-- 密码登录验证码 -->
          <div v-if="loginType === 'password' && loginCaptchaEnabled" class="form-group captcha-group">
              <div class="captcha-wrapper">
                <input 
                  type="text" 
                  placeholder="请输入验证码" 
                  v-model="form.passwordLogin.captchaCode"
                  :disabled="isLoading"
                  @input="form.passwordLogin.captchaCode = form.passwordLogin.captchaCode.replace(/\s+/g,'')"
                  class="captcha-input"
                />
                <div class="captcha-container">
                  <img 
                    v-if="!captchaImageLoading"
                    :key="captchaUuid || captchaGeneratedTime"
                    :src="captchaBase64" 
                    alt="验证码" 
                    class="captcha-img"
                    @click="generateCaptcha" 
                    title="点击刷新验证码"
                  />
                  <div v-else class="captcha-loading">
                    <span>加载中...</span>
                  </div>
                  <button 
                    type="button"
                    class="refresh-captcha"
                    @click.prevent="generateCaptcha()"
                    :disabled="isLoading || captchaImageLoading"
                    title="刷新验证码"
                  >
                    <i class="fa fa-refresh" :class="{ 'spinning': captchaImageLoading }"></i>
                  </button>
                </div>
              </div>
              <div v-if="errors.passwordLogin?.captcha" class="error-tip mt-2">{{ errors.passwordLogin.captcha }}</div>
            </div>
            
            <div v-if="loginType === 'password'" class="login-actions">
              <label class="remember-password">
                <input
                  type="checkbox"
                  v-model="rememberPassword"
                  :disabled="isLoading"
                />
                <span>记住密码</span>
              </label>
              <a class="forgot-pwd-link" @click="handleForgotPassword">忘记密码？</a>
            </div>

          <!-- 重置方式切换 -->
          <div class="login-tabs" v-if="loginType === 'reset'">
            <button 
              :class="{ active: resetType === 'phone' }" 
              @click="resetType = 'phone'"
            >
              手机找回
            </button>
            <button 
              :class="{ active: resetType === 'email' }" 
              @click="resetType = 'email'"
            >
              邮箱找回
            </button>
          </div>

          <!-- 重置密码表单 -->
          <div v-if="loginType === 'reset' && resetType === 'phone'" class="form-group">
            <div class="phone-input">
              <select v-model="form.reset.countryCode">
                <option value="+86">CN +86</option>
                <option value="+1">US +1</option>
              </select>
              <input 
                type="tel" 
                placeholder="请输入手机号" 
                v-model="form.reset.phoneNumber"
                :disabled="isLoading"
              />
            </div>
            <div v-if="errors.reset.phone" class="error-tip">{{ errors.reset.phone }}</div>
          </div>
          
          <div v-if="loginType === 'reset' && resetType === 'email'" class="form-group">
             <input type="email" placeholder="请输入绑定邮箱" v-model="form.reset.email" :disabled="isLoading"/>
             <div v-if="errors.reset.email" class="error-tip">{{ errors.reset.email }}</div>
          </div>
          
          <div v-if="loginType === 'reset'" class="form-group">
            <input 
              type="text" 
              placeholder="请输入验证码" 
              v-model="form.reset.code"
              :disabled="isLoading"
            />
            <button 
              type="button"
              class="send-btn"
              :disabled="(resetType === 'phone' ? smsCountdown : emailCountdown) > 0 || isLoading"
              @click="resetType === 'phone' ? sendSMSCode() : sendResetEmailCode()"
            >
              {{ (resetType === 'phone' ? smsCountdown : emailCountdown) > 0 ? `${resetType === 'phone' ? smsCountdown : emailCountdown}秒后重发` : '获取验证码' }}
            </button>
            <div v-if="errors.reset.code" class="error-tip">{{ errors.reset.code }}</div>
          </div>
          <div v-if="loginType === 'reset'" class="form-group">
            <div class="password-input-wrapper">
              <input 
                :type="showPassword ? 'text' : 'password'" 
                placeholder="请输入新密码（5-20位）" 
                v-model="form.reset.password"
                :disabled="isLoading"
                autocomplete="new-password"
              />
              <button type="button" class="toggle-password" @click="showPassword = !showPassword">
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
            <div v-if="errors.reset.password" class="error-tip">{{ errors.reset.password }}</div>
          </div>
          <div v-if="loginType === 'reset'" class="form-group">
            <div class="password-input-wrapper">
              <input 
                :type="showPassword ? 'text' : 'password'" 
                placeholder="请确认新密码" 
                v-model="form.reset.confirmPassword"
                :disabled="isLoading"
                autocomplete="new-password"
              />
              <button type="button" class="toggle-password" @click="showPassword = !showPassword">
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
            <div v-if="errors.reset.confirmPassword" class="error-tip">{{ errors.reset.confirmPassword }}</div>
          </div>

          <button 
            type="submit"
            class="login-btn" 
            :disabled="isLoading"
          >
            <span v-if="isLoading">处理中...</span>
            <span v-else>{{ loginType === 'reset' ? '确认重置' : '登录' }}</span>
          </button>
          </form>

          <!-- 第三方登录 -->
          <div class="third-party-login" v-if="loginType !== 'reset' && isThirdPartyLoginMockEnabled">
            <div class="divider">或使用以下方式登录</div>
            <div class="third-buttons">
              <button class="third-btn wechat" @click="openThirdPartyModal('wechat')">
                <i class="fab fa-weixin"></i>
                <span>微信</span>
              </button>
              <button class="third-btn qq" @click="openThirdPartyModal('qq')">
                <i class="fab fa-qq"></i>
                <span>QQ</span>
              </button>
            </div>
          </div>

          <!-- 用户协议 -->
          <div
            ref="agreementRef"
            class="agreement"
            v-if="loginType !== 'reset'"
          >
            <input 
              ref="agreementCheckboxRef"
              class="agreement-checkbox"
              :class="{ 'shake-animation': shakeAgreement, warning: agreementWarning }"
              type="checkbox" 
              v-model="agreed" 
              :disabled="isLoading"
            />
            <span>我已阅读并同意 <a href="#">用户协议</a></span>
          </div>
        </div>
        
        
        <div class="switch-tip" v-if="loginType !== 'reset'">
          没有账号？<a @click="$emit('to-register', loginType)">去注册</a>
        </div>
        <div class="switch-tip" v-if="loginType === 'reset'">
          <a @click="loginType = 'password'">返回登录</a>
        </div>
        <div class="modal-footer">
          <div class="slogan">每时每刻，都有人在此成功！</div>
        </div>
      </div>
    </div>
  </teleport>
</transition>
<!-- 拟真第三方登录弹窗 -->
<teleport to="body">
  <div v-if="showThirdPartyModal && isThirdPartyLoginMockEnabled" class="thirdparty-modal">
    <div class="thirdparty-overlay" @click.self="showThirdPartyModal = false"></div>
    <div class="thirdparty-container">
      <div class="thirdparty-header">
        <span>{{
          thirdPartyType === 'wechat' ? '微信' :
          thirdPartyType === 'qq' ? 'QQ' :
          '第三方'
        }}授权登录</span>
        <button class="thirdparty-close" @click="showThirdPartyModal = false">×</button>
      </div>
      <div class="thirdparty-body">
        <div v-if="thirdPartyType === 'wechat'">
          <img src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=wechat-mock" alt="微信二维码" />
          <p>请使用微信扫码以继续</p>
        </div>
        <div v-else-if="thirdPartyType === 'qq'">
          <img src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=qq-mock" alt="QQ二维码" />
          <p>请使用QQ扫码以继续</p>
        </div>
        <button class="thirdparty-confirm" @click="confirmThirdPartyLogin">确认授权</button>
        <button class="thirdparty-cancel" @click="showThirdPartyModal = false">取消</button>
      </div>
    </div>
  </div>
</teleport>
</template>

<script setup>
import { ref, reactive, watch, onBeforeUnmount, nextTick } from 'vue'
import { login, emailCodeLogin, smsLogin, sendSmsCode, sendEmailCode, getUserInfo, checkPhone, resetPwd } from '@/api/auth'
import { defineProps, defineEmits } from 'vue'
import { getCaptchaUrl, getNetworkInfo, testBackendConnection } from '@/utils/backend'
import { api } from '@/utils/api'
import { storage } from '@/utils/storage'
import { setTenantId, syncTenantContextFromUser } from '@/utils/tenantContext'
import { ElMessage } from 'element-plus'
import logger from '@/utils/logger'

// 配置axios
/* const api = axios.create({
  baseURL: 'http://localhost:8989/api/v1/auth', // 调整基础URL
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
})
 */
/* // 添加请求拦截器
api.interceptors.request.use(config => {
  const token = localStorage.getItem('authToken')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
}, error => {
  return Promise.reject(error)
})
 */
const props = defineProps({
  show: Boolean // 接收父组件的显示状态
})

const isThirdPartyLoginMockEnabled = import.meta.env.DEV &&
  (import.meta.env.VITE_ENABLE_THIRD_PARTY_LOGIN_MOCK === 'true' ||
   import.meta.env.VITE_APP_ENABLE_THIRD_PARTY_LOGIN_MOCK === 'true')

watch(() => props.show, (newVal) => {
  if (newVal) {
    initializeLoginModal()
  }
  // 模态框显示时生成验证码（仅在启用验证码时）
  if (newVal && loginType.value === 'password' && loginCaptchaEnabled.value) {
    generateCaptcha()
  }
})
const loginType = ref('password')
const resetType = ref('phone') // 'phone' | 'email'
const showPassword = ref(false)
const agreed = ref(false)
const shakeAgreement = ref(false)
const agreementWarning = ref(false)
const agreementRef = ref(null)
const agreementCheckboxRef = ref(null)
const rememberPassword = ref(false)
const isLoading = ref(false)
const smsCountdown = ref(0)
const emailCountdown = ref(0) // 邮箱验证码倒计时
let countdownTimer = null
let emailTimer = null

const REMEMBER_PASSWORD_STORAGE_KEY = 'rememberedPasswordLogin'

// 是否启用登录时图形验证码（登录需要验证码；注册需要，不受此开关影响）
const loginCaptchaEnabled = ref(true)

// 验证码相关状态
const generatedSMSCode = ref('') // 手机验证码
const generatedEmailCode = ref('') // 邮箱验证码
const captchaText = ref('')     // 邮箱图片验证码文本
/*const captchaKey = ref('')*/
const captchaBase64 = ref('')
const captchaImageLoading = ref(false) // 验证码图片加载状态
const captchaUuid = ref('') // 验证码UUID
const captchaGeneratedTime = ref(0) // 验证码生成时间戳
const captchaExpiryTime = 120000 // 验证码有效期（2分钟 = 120秒）
let captchaExpiryTimer = null // 验证码过期检查定时器

// 表单数据（新增邮箱验证码字段）
const form = reactive({
  phoneLogin: {
    phone: '',
    code: ''
  },
  emailLogin: {
    email: '',
    code: ''
  },
  passwordLogin: {
    username: '',
    password: '',
    captchaCode: ''
  },
  reset: {
    countryCode: '+86',
    phoneNumber: '',
    email: '',
    code: '',
    password: '',
    confirmPassword: ''
  }
})

// 错误信息（新增验证码错误）
const errors = reactive({
  phoneLogin: {
    phone: ''
  },
  emailLogin: {
    email: ''
  },
  passwordLogin: {
    username: '',
    password: '',
    captcha: ''
  },
  reset: {
    phone: '',
    email: '',
    code: '',
    password: '',
    confirmPassword: ''
  }
})

const loadRememberedPasswordLogin = () => {
  const remembered = storage.getJSON(REMEMBER_PASSWORD_STORAGE_KEY, null)
  if (!remembered || typeof remembered !== 'object') {
    rememberPassword.value = false
    return
  }

  form.passwordLogin.username = remembered.username || ''
  form.passwordLogin.password = remembered.password || ''
  rememberPassword.value = !!(remembered.username && remembered.password)
}

const saveRememberedPasswordLogin = () => {
  storage.set(REMEMBER_PASSWORD_STORAGE_KEY, {
    username: form.passwordLogin.username,
    password: form.passwordLogin.password
  })
}

const clearRememberedPasswordLogin = () => {
  storage.remove(REMEMBER_PASSWORD_STORAGE_KEY)
}

const initializeLoginModal = () => {
  agreementWarning.value = false
  shakeAgreement.value = false
  loadRememberedPasswordLogin()
}

const extractProfileCompletion = (payload, fallback = null) => {
  const nestedProfileCompletion = payload?.profileCompletion ||
    payload?.data?.profileCompletion ||
    payload?.user?.profileCompletion ||
    payload?.data?.user?.profileCompletion ||
    fallback ||
    null

  const needsProfileCompletion = payload?.needsProfileCompletion === true ||
    payload?.profileCompletionRequired === true ||
    payload?.data?.needsProfileCompletion === true ||
    payload?.data?.profileCompletionRequired === true ||
    nestedProfileCompletion?.needsProfileCompletion === true

  if (!nestedProfileCompletion && !needsProfileCompletion) {
    return null
  }

  return {
    ...(nestedProfileCompletion && typeof nestedProfileCompletion === 'object' ? nestedProfileCompletion : {}),
    needsProfileCompletion,
    completed: typeof nestedProfileCompletion?.completed === 'boolean'
      ? nestedProfileCompletion.completed
      : !needsProfileCompletion
  }
}

const buildStoredUserInfo = (payload, fallback = {}) => {
  const profileUser = payload?.user || payload?.data || payload || {}
  const userName = profileUser.userName || profileUser.username || profileUser.user_name || fallback.userName || fallback.username || ''
  const nickName = profileUser.nickName || profileUser.nickname || fallback.nickName || fallback.nickname || userName
  const email = profileUser.email || fallback.email || ''
  const phonenumber = profileUser.phonenumber || profileUser.phoneNumber || fallback.phonenumber || fallback.phoneNumber || ''
  const tenantId = profileUser.tenantId || profileUser.tenant_id || fallback.tenantId || fallback.tenant_id || ''
  const deptId = profileUser.deptId || fallback.deptId || null
  const profileCompletion = extractProfileCompletion(payload, fallback.profileCompletion || null)

  return {
    ...profileUser,
    ...fallback,
    userName,
    username: profileUser.username || fallback.username || userName,
    nickName,
    nickname: profileUser.nickname || fallback.nickname || nickName,
    email,
    phonenumber,
    phoneNumber: profileUser.phoneNumber || fallback.phoneNumber || phonenumber,
    tenantId,
    tenant_id: profileUser.tenant_id || fallback.tenant_id || tenantId,
    deptId,
    authHydrationPending: fallback.authHydrationPending === true,
    profileCompletion
  }
}

const inferLoginIdentityFallback = (value) => {
  const normalizedValue = (value || '').trim()
  if (!normalizedValue) {
    return {}
  }

  const fallback = {
    userName: normalizedValue,
    username: normalizedValue,
    nickName: normalizedValue
  }

  if (/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedValue)) {
    fallback.email = normalizedValue
    fallback.nickName = normalizedValue.split('@')[0]
  } else if (/^1[3-9]\d{9}$/.test(normalizedValue)) {
    fallback.phonenumber = normalizedValue
  }

  return fallback
}

const persistAuthenticatedUser = (userInfo) => {
  syncTenantContextFromUser(userInfo)
  localStorage.setItem('userInfo', JSON.stringify(userInfo))
}

const emitAuthenticatedUser = (userInfo) => {
  logger.debug('📢 触发userLogin事件，传递用户信息:', userInfo)
  window.dispatchEvent(new CustomEvent('userLogin', { detail: userInfo }))
}

const refreshAuthenticatedUserProfile = async (fallbackUserInfo, scene) => {
  try {
    const userInfoResponse = await getUserInfo()
    if (userInfoResponse.data.code === 200) {
      const refreshedUserInfo = buildStoredUserInfo(userInfoResponse.data, {
        ...fallbackUserInfo,
        authHydrationPending: false
      })
      persistAuthenticatedUser(refreshedUserInfo)
      emitAuthenticatedUser(refreshedUserInfo)
      return refreshedUserInfo
    }

    logger.warn(`${scene}后获取用户信息失败，响应码:`, userInfoResponse.data.code)
  } catch (profileError) {
    logger.warn(`${scene}后获取用户信息失败，已转为可恢复状态:`, profileError)
  }

  window.dispatchEvent(new CustomEvent('userProfileRefreshRequired', { detail: fallbackUserInfo }))
  return fallbackUserInfo
}

const getLoginSuccessMessage = (userInfo) => {
  return userInfo?.profileCompletion?.needsProfileCompletion
    ? '登录成功，请先完善所在信息'
    : '登录成功'
}

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

watch(agreed, (value) => {
  if (value) {
    agreementWarning.value = false
  }
})

watch(rememberPassword, (value) => {
  if (!value) {
    clearRememberedPasswordLogin()
  }
})

// 验证规则（新增验证码验证）
const validateEmailLogin = () => {
  errors.emailLogin.email = ''
  if (!form.emailLogin.email) {
    errors.emailLogin.email = '请输入邮箱'
    return false
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.emailLogin.email)) {
    errors.emailLogin.email = '请输入有效的邮箱'
    return false
  }
  return true
}

const validatePasswordLogin = () => {
  errors.passwordLogin.username = ''
  errors.passwordLogin.password = ''
  errors.passwordLogin.captcha = ''
  
  let isValid = true
  
  if (!form.passwordLogin.username) {
    errors.passwordLogin.username = '请输入账号/手机号/邮箱'
    isValid = false
  }
  
  if (!form.passwordLogin.password) {
    errors.passwordLogin.password = '请输入密码'
    isValid = false
  } else if (form.passwordLogin.password.length < 6) {
    errors.passwordLogin.password = '密码长度至少6位'
    isValid = false
  }
  
  if (loginCaptchaEnabled.value && !form.passwordLogin.captchaCode) {
    errors.passwordLogin.captcha = '请输入验证码'
    isValid = false
  }
  
  return isValid
}

// 监听登录类型变化，自动获取验证码
watch(loginType, (newVal) => {
  // 仅在弹窗显示时才刷新验证码，避免切换导致 uuid 被意外刷新
  if (props.show && newVal === 'password' && loginCaptchaEnabled.value) {
    generateCaptcha()
  }
})
// 获取图片验证码
const generateCaptcha = async () => {
  try {
    captchaImageLoading.value = true
    // 清空验证码输入框，提示用户需要重新输入
    form.passwordLogin.captchaCode = ''
    logger.debug('正在获取验证码...')
    
    // 输出网络环境信息
    const networkInfo = getNetworkInfo()
    logger.debug('网络环境信息:', networkInfo)
    
    // 使用工具函数获取验证码URL
    const captchaUrl = getCaptchaUrl()
    logger.debug('使用验证码URL:', captchaUrl)
    
    // 测试后端连接
    const isConnected = await testBackendConnection()
    logger.debug('后端连接状态:', isConnected)
    
    const response = await api.get(captchaUrl, {
      headers: { Accept: 'application/json' }
    })
    logger.debug('验证码响应状态:', response.status)
    logger.debug('验证码响应头:', response.headers)
    const data = response.data
    logger.debug('验证码响应数据:', data)

    if (data.code === 200) {
      if (data.captchaEnabled === false) {
        logger.warn('验证码已被禁用，跳过验证码验证')
        captchaBase64.value = ''
        captchaUuid.value = ''
        captchaGeneratedTime.value = 0
        return
      }

      if (data.img && data.uuid) {
        captchaBase64.value = `data:image/jpeg;base64,${data.img}`
        captchaUuid.value = data.uuid
        captchaGeneratedTime.value = Date.now()
        logger.debug('验证码生成成功，UUID:', data.uuid, '生成时间:', new Date(captchaGeneratedTime.value).toLocaleTimeString())

        if (captchaExpiryTimer) {
          clearTimeout(captchaExpiryTimer)
        }

        captchaExpiryTimer = setTimeout(() => {
          logger.debug('⏰ 验证码即将过期，自动刷新')
          ElMessage({
            message: '验证码已过期，已自动刷新',
            type: 'warning',
            duration: 2000
          })
          generateCaptcha()
        }, captchaExpiryTime)
      } else {
        throw new Error('验证码数据不完整')
      }
    } else {
      throw new Error(data.msg || '获取验证码失败')
    }
  } catch (error) {
    logger.error('获取验证码失败', error)
    ElMessage({
      message: '获取验证码失败，请重试: ' + error.message,
      type: 'error',
      duration: 3000
    })
    // 验证码获取失败时，清空显示
    captchaBase64.value = ''
    captchaUuid.value = ''
    captchaGeneratedTime.value = 0
  } finally {
    captchaImageLoading.value = false
  }
}
/* onMounted(() => {
  logger.debug(loginType.value === 'email')
  if (loginType.value === 'email') {
   
    fetchCaptcha()
  }
}) */




// 发送短信验证码
const sendSMSCode = async () => {
  if (loginType.value !== 'reset' || resetType.value !== 'phone') {
    ElMessage.warning('手机验证码仅用于忘记密码')
    return
  }

  const phoneNumber = form.reset.phoneNumber
  errors.reset.phone = ''
  if (!phoneNumber) {
    errors.reset.phone = '请输入手机号'
    return
  }
  if (!/^1[3-9]\d{9}$/.test(phoneNumber)) {
    errors.reset.phone = '请输入有效的手机号'
    return
  }
  if (smsCountdown.value > 0) return

  try {
    isLoading.value = true
    await checkPhone(phoneNumber)

    const response = await sendSmsCode(phoneNumber)
    if (response.data.code !== 200) {
      throw new Error(response.data?.msg || '发送验证码失败')
    }

    ElMessage.success('验证码已发送至手机号')
    smsCountdown.value = 60
    countdownTimer = setInterval(() => {
      smsCountdown.value--
      if (smsCountdown.value <= 0) clearInterval(countdownTimer)
    }, 1000)
  } catch (error) {
    const errorMsg = error.response?.data?.msg || error.message || '发送验证码失败'
    ElMessage.error(errorMsg)
  } finally {
    isLoading.value = false
  }
}

// 处理忘记密码
const handleForgotPassword = () => {
  loginType.value = 'reset'
  errors.reset.phone = ''
  errors.reset.code = ''
  errors.reset.password = ''
  errors.reset.confirmPassword = ''
}

// 发送手机登录验证码
const sendPhoneLoginCode = async () => {
  if (smsCountdown.value > 0) return

  const phone = form.phoneLogin.phone
  errors.phoneLogin.phone = ''

  if (!phone) {
    errors.phoneLogin.phone = '请输入手机号'
    return
  }
  if (!/^1[3-9]\d{9}$/.test(phone)) {
    errors.phoneLogin.phone = '请输入有效的手机号'
    return
  }

  try {
    isLoading.value = true
    const response = await sendSmsCode(phone)

    if (response.data.code === 200) {
      ElMessage.success('验证码已发送至手机号')
      smsCountdown.value = 60
      countdownTimer = setInterval(() => {
        smsCountdown.value--
        if (smsCountdown.value <= 0) clearInterval(countdownTimer)
      }, 1000)
    } else {
      throw new Error(response.data.msg || '发送失败')
    }
  } catch (error) {
    const msg = error.response?.data?.msg || error.message || '发送失败'
    ElMessage.error(msg)
  } finally {
    isLoading.value = false
  }
}

// 发送邮箱登录验证码
const sendEmailLoginCode = async () => {
  if (emailCountdown.value > 0) return
  if (!validateEmailLogin()) return

  try {
    isLoading.value = true
    const response = await sendEmailCode(form.emailLogin.email)

    if (response.data.code === 200) {
      ElMessage.success('验证码已发送至邮箱')
      emailCountdown.value = 60
      emailTimer = setInterval(() => {
        emailCountdown.value--
        if (emailCountdown.value <= 0) clearInterval(emailTimer)
      }, 1000)
    } else {
      throw new Error(response.data.msg || '发送失败')
    }
  } catch (error) {
    const msg = error.response?.data?.msg || error.message || '发送失败'
    ElMessage.error(msg)
  } finally {
    isLoading.value = false
  }
}

// 发送邮箱验证码
const sendResetEmailCode = async () => {
  if (emailCountdown.value > 0) return
  
  errors.reset.email = ''
  if (!form.reset.email) {
    errors.reset.email = '请输入邮箱'
    return
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.reset.email)) {
    errors.reset.email = '请输入有效的邮箱'
    return
  }
  
  try {
    isLoading.value = true
    const response = await sendEmailCode(form.reset.email)
    
    if (response.data.code === 200) {
       ElMessage.success('验证码已发送至邮箱')
       // Start countdown
       emailCountdown.value = 60
       emailTimer = setInterval(() => {
         emailCountdown.value--
         if (emailCountdown.value <= 0) clearInterval(emailTimer)
       }, 1000)
    } else {
       throw new Error(response.data.msg || '发送失败')
    }
  } catch (error) {
     const msg = error.response?.data?.msg || error.message || '发送失败'
     ElMessage.error(msg)
  } finally {
     isLoading.value = false
  }
}

const validateReset = () => {
  errors.reset.phone = ''
  errors.reset.email = ''
  errors.reset.code = ''
  errors.reset.password = ''
  errors.reset.confirmPassword = ''
  
  let isValid = true
  
  if (resetType.value === 'phone') {
    if (!form.reset.phoneNumber) {
      errors.reset.phone = '请输入手机号'
      isValid = false
    } else if (!/^1[3-9]\d{9}$/.test(form.reset.phoneNumber)) {
      errors.reset.phone = '请输入有效的手机号'
      isValid = false
    }
  } else {
    if (!form.reset.email) {
      errors.reset.email = '请输入邮箱'
      isValid = false
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.reset.email)) {
      errors.reset.email = '请输入有效的邮箱'
      isValid = false
    }
  }
  
  if (!form.reset.code) {
    errors.reset.code = '请输入验证码'
    isValid = false
  }
  
  if (!form.reset.password) {
    errors.reset.password = '请输入新密码'
    isValid = false
  } else if (form.reset.password.length < 5 || form.reset.password.length > 20) {
    errors.reset.password = '密码长度需在5-20位之间'
    isValid = false
  }
  
  if (form.reset.confirmPassword !== form.reset.password) {
    errors.reset.confirmPassword = '两次输入的密码不一致'
    isValid = false
  }
  
  return isValid
}

// 处理重置密码
const handleResetPwd = async () => {
  if (!validateReset()) return
  
  try {
    isLoading.value = true
    const data = {
      password: form.reset.password
    }
    
    if (resetType.value === 'phone') {
      data.phone = form.reset.phoneNumber
      data.smsCode = form.reset.code
    } else {
      data.email = form.reset.email
      data.emailCode = form.reset.code
    }
    
    const response = await resetPwd(data)
    
    if (response.data.code === 200) {
       ElMessage.success('密码重置成功，请使用新密码登录')
       // Switch back to password login
       loginType.value = 'password'
       // Pre-fill username
       form.passwordLogin.username = resetType.value === 'phone' ? form.reset.phoneNumber : form.reset.email
       // Clear reset form
       form.reset.phoneNumber = ''
       form.reset.email = ''
       form.reset.code = ''
       form.reset.password = ''
       form.reset.confirmPassword = ''
    } else {
       throw new Error(response.data.msg || '重置失败')
    }
  } catch (error) {
    logger.error('Reset password error:', error)
    const msg = error.response?.data?.msg || error.message || '重置失败'
    ElMessage.error(msg)
  } finally {
    isLoading.value = false
  }
}

// 检查验证码是否过期
const isCaptchaExpired = () => {
  if (!captchaGeneratedTime.value) return true
  const elapsed = Date.now() - captchaGeneratedTime.value
  return elapsed > captchaExpiryTime
}

const scrollToAgreement = async () => {
  await nextTick()
  agreementRef.value?.scrollIntoView({
    behavior: 'smooth',
    block: 'center',
    inline: 'nearest'
  })
  agreementCheckboxRef.value?.focus()
}

// 处理登录（对接真实API）
const handleLogin = async () => {
  if (loginType.value === 'reset') {
    await handleResetPwd()
    return
  }

  // 验证用户协议
  if (!agreed.value) {
    shakeAgreement.value = true
    agreementWarning.value = true
    await scrollToAgreement()
    ElMessage.warning('请阅读并同意用户协议')
    setTimeout(() => shakeAgreement.value = false, 500)
    return
  }
  
  // 表单验证
  let isValid = false
  if (loginType.value === 'phone') {
    // 手机验证码登录验证
    const phone = form.phoneLogin.phone
    errors.phoneLogin.phone = ''

    if (!phone) {
      errors.phoneLogin.phone = '请输入手机号'
      return
    }
    if (!/^1[3-9]\d{9}$/.test(phone)) {
      errors.phoneLogin.phone = '请输入有效的手机号'
      return
    }
    if (!form.phoneLogin.code) {
      ElMessage.warning('请输入验证码')
      return
    }
    isValid = true
  } else if (loginType.value === 'email') {
    isValid = validateEmailLogin()
    if (!form.emailLogin.code) {
      ElMessage.warning('请输入验证码')
      return
    }
  } else if (loginType.value === 'password') {
    isValid = validatePasswordLogin()
    if (!isValid) return
    
    // 检查验证码是否过期（仅在启用验证码时）
    if (loginCaptchaEnabled.value && captchaBase64.value && isCaptchaExpired()) {
      ElMessage({
        message: '验证码已过期，已自动刷新，请重新输入',
        type: 'warning',
        duration: 2000
      })
      await generateCaptcha()
      return
    }
  }
  
  try {
    isLoading.value = true
    
    // 1. 验证码校验
    if (loginType.value === 'phone') {
      logger.debug('🔍 手机验证码登录:')
      logger.debug('  - 用户输入验证码:', form.phoneLogin.code)

      if (!form.phoneLogin.code || form.phoneLogin.code.length < 4) {
        ElMessage.warning('请输入正确的验证码')
        return
      }
      logger.debug('✅ 手机验证码格式检查通过，将由后端校验')
    } else if (loginType.value === 'email') {
      logger.debug('🔍 邮箱验证码登录:')
      logger.debug('  - 用户输入验证码:', form.emailLogin.code)

      if (!form.emailLogin.code || form.emailLogin.code.length < 4) {
        ElMessage.warning('请输入正确的验证码')
        return
      }
      logger.debug('✅ 邮箱验证码格式检查通过，将由后端校验')
    } else if (loginCaptchaEnabled.value && captchaBase64.value) {
      // 密码登录验证码校验（由后端验证，这里只检查是否输入）
      if (!form.passwordLogin.captchaCode) {
        errors.passwordLogin.captcha = '请输入验证码'
        return
      }
    }
    
    // 2. 处理登录
    if (loginType.value === 'phone') {
      // 手机验证码登录
      const loginData = {
        phone: form.phoneLogin.phone,
        smsCode: form.phoneLogin.code
      }

      logger.debug('手机验证码登录数据:', loginData)

      const response = await smsLogin(loginData)

      if (response.data.code === 200) {
        const token = response.data.token

        if (rememberPassword.value) {
          saveRememberedPasswordLogin()
        } else {
          clearRememberedPasswordLogin()
        }

        // 存储token到localStorage
        localStorage.setItem('authToken', token)
        if (response.data.tenantId) {
          setTenantId(response.data.tenantId)
        }

        const fallbackUserInfo = buildStoredUserInfo(response.data, {
          ...inferLoginIdentityFallback(form.phoneLogin.phone),
          phonenumber: form.phoneLogin.phone,
          tenantId: response.data.tenantId || '',
          authHydrationPending: true
        })

        persistAuthenticatedUser(fallbackUserInfo)
        emitAuthenticatedUser(fallbackUserInfo)
        void refreshAuthenticatedUserProfile(fallbackUserInfo, '手机登录')

        closeModal()
        ElMessage.success(getLoginSuccessMessage(fallbackUserInfo))

        return
      } else {
        throw new Error(response.data.msg || '登录失败')
      }
    } else if (loginType.value === 'email') {
      // 邮箱验证码登录
      const loginData = {
        email: form.emailLogin.email,
        emailCode: form.emailLogin.code
      }

      logger.debug('邮箱验证码登录数据:', loginData)

      const response = await emailCodeLogin(loginData)
      
      if (response.data.code === 200) {
        const token = response.data.token

        if (rememberPassword.value) {
          saveRememberedPasswordLogin()
        } else {
          clearRememberedPasswordLogin()
        }
        
        // 存储token到localStorage
        localStorage.setItem('authToken', token)
        if (response.data.tenantId) {
          setTenantId(response.data.tenantId)
        }

        const fallbackUserInfo = buildStoredUserInfo(response.data, {
          ...inferLoginIdentityFallback(form.emailLogin.email),
          email: form.emailLogin.email,
          tenantId: response.data.tenantId || '',
          authHydrationPending: true
        })

        persistAuthenticatedUser(fallbackUserInfo)
        emitAuthenticatedUser(fallbackUserInfo)
        void refreshAuthenticatedUserProfile(fallbackUserInfo, '邮箱登录')

        closeModal()
        ElMessage.success(getLoginSuccessMessage(fallbackUserInfo))
        
        return
      } else {
        throw new Error(response.data.msg || '登录失败')
      }
    } else {
      // 密码登录使用真实API
      const loginData = {
        username: form.passwordLogin.username,
        password: form.passwordLogin.password,
        code: loginCaptchaEnabled.value ? form.passwordLogin.captchaCode : '',
        uuid: loginCaptchaEnabled.value ? captchaUuid.value : ''
      }
      
      logger.debug('登录数据:', loginData)
      logger.debug('验证码状态:', {
        enabled: loginCaptchaEnabled.value,
        code: loginData.code,
        uuid: captchaUuid.value,
        hasImage: !!captchaBase64.value
      })
      
      const response = await login(loginData)
      
      if (response.data.code === 200) {
        const token = response.data.token
        
        // 存储token到localStorage
        localStorage.setItem('authToken', token)
        if (response.data.tenantId) {
          setTenantId(response.data.tenantId)
        }

        const fallbackUserInfo = buildStoredUserInfo(response.data, {
          ...inferLoginIdentityFallback(form.passwordLogin.username),
          tenantId: response.data.tenantId || '',
          authHydrationPending: true
        })

        persistAuthenticatedUser(fallbackUserInfo)
        emitAuthenticatedUser(fallbackUserInfo)
        void refreshAuthenticatedUserProfile(fallbackUserInfo, '密码登录')

        closeModal()
        ElMessage.success(getLoginSuccessMessage(fallbackUserInfo))
        
      } else {
        throw new Error(response.data.msg || '登录失败')
      }
    }
    
  } catch (error) {
    logger.error('登录错误:', error)
    
    const errorMessage = error.response?.data?.msg || error.message || '登录失败，请重试'
    const shouldRefreshCaptcha = loginType.value === 'password' && loginCaptchaEnabled.value

    // 处理验证码失效的情况
    if (errorMessage.includes('验证码已失效') || errorMessage.includes('验证码错误')) {
      ElMessage({
        message: '验证码已失效，已自动刷新，请重新输入',
        type: 'warning',
        duration: 3000
      })
    } else {
      // 显示错误信息
      // 方法1：使用ElMessage弹出提示
      ElMessage({
        message: errorMessage,
        type: 'error',
        duration: 4000,
        showClose: true
      })
      
      // 方法2：同时在密码输入框下方显示错误
      if (errorMessage.includes('密码') || errorMessage.includes('用户不存在') || errorMessage.includes('登录失败')) {
        errors.passwordLogin.password = errorMessage
      }
      
      // 方法3：创建一个更明显的错误提示
      const errorToast = document.createElement('div')
      errorToast.style.cssText = `
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        padding: 20px 30px;
        background: #ff4d4f;
        color: white;
        border-radius: 8px;
        font-size: 16px;
        box-shadow: 0 4px 20px rgba(255, 77, 79, 0.3);
        z-index: 200000;
        animation: shake 0.5s;
      `
      errorToast.textContent = errorMessage
      document.body.appendChild(errorToast)
      
      // 添加抖动动画
      const style = document.createElement('style')
      style.textContent = `
        @keyframes shake {
          0%, 100% { transform: translate(-50%, -50%) translateX(0); }
          25% { transform: translate(-50%, -50%) translateX(-10px); }
          75% { transform: translate(-50%, -50%) translateX(10px); }
        }
      `
      document.head.appendChild(style)
      
      // 3秒后移除
      setTimeout(() => {
        errorToast.remove()
        style.remove()
        errors.passwordLogin.password = '' // 清除错误提示
      }, 3000)
    }

    if (shouldRefreshCaptcha) {
      form.passwordLogin.captchaCode = ''
      await generateCaptcha()
    }
  } finally {
    isLoading.value = false
  }
}


// 使用defineEmits声明事件
const emit = defineEmits(['close', 'to-register'])
const closeModal = () => {
  emit('close') // 通知父组件关闭
  // 清除倒计时
  if (countdownTimer) {
    clearInterval(countdownTimer)
    smsCountdown.value = 0
  }
  if (emailTimer) {
    clearInterval(emailTimer)
    emailCountdown.value = 0
  }
  // 清除验证码过期定时器
  if (captchaExpiryTimer) {
    clearTimeout(captchaExpiryTimer)
    captchaExpiryTimer = null
  }
  
  // 重置表单（新增验证码相关重置）
  form.emailLogin.email = ''
  form.emailLogin.code = ''
  form.passwordLogin.username = ''
  form.passwordLogin.password = ''
  form.passwordLogin.captchaCode = ''
  form.reset.phoneNumber = ''
  form.reset.email = ''
  form.reset.code = ''
  form.reset.password = ''
  form.reset.confirmPassword = ''
  agreed.value = false
  agreementWarning.value = false
  errors.emailLogin.email = ''
  errors.passwordLogin.username = ''
  errors.passwordLogin.password = ''
  errors.passwordLogin.captcha = ''
  // captchaKey.value = ''
  captchaBase64.value = ''
  loadRememberedPasswordLogin()
}

const showThirdPartyModal = ref(false)
const thirdPartyType = ref('') // 'wechat' | 'qq'

const openThirdPartyModal = (type) => {
  if (!isThirdPartyLoginMockEnabled) {
    ElMessage.warning('当前环境未启用第三方登录')
    return
  }
  thirdPartyType.value = type
  showThirdPartyModal.value = true
}

const confirmThirdPartyLogin = () => {
  if (!isThirdPartyLoginMockEnabled) {
    showThirdPartyModal.value = false
    ElMessage.warning('当前环境未启用第三方登录')
    return
  }
  // 模拟第三方登录成功
  const token = 'thirdparty_token_' + thirdPartyType.value
  const displayName = {
    wechat: '微信用户',
    qq: 'QQ用户',
  }[thirdPartyType.value] || '第三方用户'
  const userInfo = {
    username: displayName,
    userName: displayName,
    nickName: displayName,
    email: '',
    phone: '',
    profileCompletion: null
  }
  localStorage.setItem('authToken', token)
  localStorage.setItem('userInfo', JSON.stringify(userInfo))
  showThirdPartyModal.value = false
  closeModal()
  // 使用相对路径重定向到首页，避免硬编码URL
  window.location.href = '/'
}

// 组件卸载时清理定时器
onBeforeUnmount(() => {
  if (countdownTimer) {
    clearInterval(countdownTimer)
  }
  if (emailTimer) {
    clearInterval(emailTimer)
  }
  if (captchaExpiryTimer) {
    clearTimeout(captchaExpiryTimer)
  }
})

// defineExpose({
//   open: () => (isShow.value = true),
//   close: closeModal
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
  background-color: rgba(0, 0, 0, 0.6); /* 深色遮罩 */
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
  padding: 40px;
  display: flex;
  flex-direction: column;
  position: relative;
  overflow: hidden;
  animation: slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

/* 顶部装饰线 (可选) */
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
  margin-bottom: 32px;
  flex-shrink: 0;
}

.brand-logo span {
  font-size: 28px;
  font-weight: 700;
  background: linear-gradient(135deg, #1e40af, #3b82f6);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  letter-spacing: 1px;
}

/* 副标题 */
.modal-subtitle {
  display: block;
  margin-top: 8px;
  color: #64748b;
  font-size: 14px;
  text-align: center;
}

/* 关闭按钮 */
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

/* Tab 切换 */
.login-tabs {
  display: flex;
  justify-content: center;
  gap: 40px;
  margin-bottom: 32px;
  border-bottom: 1px solid #e2e8f0;
}

.login-tabs button {
  background: none;
  border: none;
  padding: 12px 4px;
  font-size: 16px;
  color: #64748b;
  cursor: pointer;
  position: relative;
  transition: color 0.2s;
  font-weight: 500;
}

.login-tabs button.active {
  color: #3b82f6;
  font-weight: 600;
}

.login-tabs button.active::after {
  content: '';
  position: absolute;
  bottom: -1px;
  left: 0;
  width: 100%;
  height: 2px;
  background-color: #3b82f6;
  border-radius: 2px;
}

/* 表单样式 */
.form-group {
  margin-bottom: 20px;
  position: relative;
}

/* 输入框 - 现代填充风格 */
.phone-input select,
.phone-input input,
.form-group input {
  width: 100%;
  height: 48px;
  padding: 0 16px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 15px;
  color: #334155;
  background-color: #f8fafc; /* 浅灰背景 */
  transition: all 0.2s;
  outline: none;
}

/* 聚焦态 */
.phone-input select:focus,
.phone-input input:focus,
.form-group input:focus {
  background-color: #fff;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

/* 布局调整 */
.phone-input {
  display: flex;
  gap: 10px;
}

.phone-input select {
  width: 130px;
  min-width: 130px;
  flex-shrink: 0;
  cursor: pointer;
}

.phone-input input {
  flex: 1;
}

/* 验证码区域 */
.captcha-wrapper {
  display: flex;
  gap: 10px;
}

.captcha-container {
  display: flex;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  overflow: hidden;
  height: 44px;
  background: #fff;
}

.captcha-img {
  height: 100%;
  width: 118px;
  padding: 0 4px;
  object-fit: contain;
  display: block;
  cursor: pointer;
}

.refresh-captcha {
  width: 40px;
  border: none;
  background: #f8fafc;
  border-left: 1px solid #e2e8f0;
  cursor: pointer;
  color: #64748b;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.refresh-captcha:hover {
  background: #f1f5f9;
  color: #3b82f6;
}

/* 发送验证码按钮 */
.send-btn {
  position: absolute;
  right: 6px;
  top: 6px;
  bottom: 6px;
  border: none;
  background: rgba(59, 130, 246, 0.1);
  color: #3b82f6;
  padding: 0 12px;
  border-radius: 6px;
  font-size: 13px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.2s;
}

.send-btn:hover:not(:disabled) {
  background: rgba(59, 130, 246, 0.2);
}

.send-btn:disabled {
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
  background: none;
  border: none;
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

/* 登录按钮 */
.login-btn {
  width: 100%;
  height: 48px;
  background: linear-gradient(135deg, #3b82f6, #2563eb); /* 蓝天渐变 */
  color: #fff;
  font-size: 16px;
  font-weight: 600;
  border: none;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.3s;
  margin-top: 12px;
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.2);
}

.login-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 16px rgba(37, 99, 235, 0.3);
  background: linear-gradient(135deg, #2563eb, #1d4ed8);
}

.login-btn:active {
  transform: translateY(0);
}

.login-btn:disabled {
  background: #cbd5e1;
  box-shadow: none;
  cursor: not-allowed;
}

/* 辅助链接 */
.text-right {
  text-align: right;
  margin-bottom: 24px;
  margin-top: -10px;
}

.forgot-pwd-link {
  color: #64748b;
  font-size: 13px;
  cursor: pointer;
  text-decoration: none;
  transition: color 0.2s;
}

.forgot-pwd-link:hover {
  color: #3b82f6;
}

/* 第三方登录 */
.third-party-login {
  margin-top: 32px;
}

.divider {
  position: relative;
  text-align: center;
  font-size: 12px;
  color: #94a3b8;
  margin-bottom: 20px;
}

.divider::before, .divider::after {
  content: '';
  position: absolute;
  top: 50%;
  width: 30%;
  height: 1px;
  background-color: #f1f5f9;
}

.divider::before { left: 0; }
.divider::after { right: 0; }

.third-buttons {
  display: flex;
  justify-content: center;
  gap: 16px;
}

.third-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  height: 40px;
  padding: 0 20px;
  min-width: 100px;
  border: 1px solid #e2e8f0;
  border-radius: 20px;
  background: #fff;
  color: #64748b;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 14px;
}

.third-btn:hover {
  background-color: #f8fafc;
  border-color: #94a3b8;
  color: #334155;
  transform: translateY(-1px);
  box-shadow: 0 2px 6px rgba(0,0,0,0.05);
}

.third-btn i {
  font-size: 18px;
}

.third-btn.wechat:hover {
  color: #07c160;
  border-color: #07c160;
  background: #f0fdf4;
}

.third-btn.qq:hover {
  color: #0ea5e9;
  border-color: #0ea5e9;
  background: #f0f9ff;
}

.third-btn span {
  display: inline-block; /* 恢复显示文字 */
}

/* 底部切换 */
.switch-tip {
  text-align: center;
  margin-top: 24px;
  font-size: 14px;
  color: #64748b;
}

.switch-tip a {
  color: #3b82f6;
  font-weight: 600;
  cursor: pointer;
  margin-left: 4px;
  text-decoration: none;
}

.switch-tip a:hover {
  text-decoration: underline;
}

.login-actions {
  margin-top: 14px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.remember-password {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: #64748b;
  font-size: 13px;
  cursor: pointer;
}

.remember-password input {
  accent-color: #3b82f6;
}

/* 协议 */
.agreement {
  margin-top: 20px;
  font-size: 12px;
  color: #94a3b8;
  display: flex;
  align-items: center;
  justify-content: center;
}

.agreement-checkbox {
  margin-right: 6px;
  accent-color: #3b82f6;
  transition: accent-color 0.2s ease, outline-color 0.2s ease;
}

.agreement-checkbox.warning {
  accent-color: #ef4444;
  outline: 2px solid rgba(239, 68, 68, 0.45);
  outline-offset: 1px;
  border-radius: 3px;
}

.agreement a {
  color: #3b82f6;
  text-decoration: none;
}

/* 错误提示 */
.error-tip {
  color: #ef4444;
  font-size: 12px;
  margin-top: 4px;
  padding-left: 2px;
}

/* 提示文字优化 */
.form-tip {
  font-size: 12px;
  color: #94a3b8;
  text-align: center;
  margin-top: 12px;
  margin-bottom: 4px;
}

/* 动画 */
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
@keyframes slideUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
@keyframes spin { 100% { transform: rotate(360deg); } }
.fa-refresh.spinning { animation: spin 1s linear infinite; }

/* 内容区滚动 */
.modal-body {
  overflow-y: auto;
  flex: 1;
  max-height: calc(90vh - 240px);
  padding-right: 5px;
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

/* 隐藏多余 */
.modal-footer { display: none; }

/* 移动端适配 */
@media (max-width: 480px) {
  .modal-mask {
    padding: 12px;
  }

  .modal-container {
    width: min(100%, 360px);
    max-height: 92vh;
    border-radius: 16px;
    padding: 18px 16px 16px;
  }

  .modal-header {
    margin-bottom: 16px;
  }

  .brand-logo span {
    font-size: 22px;
    letter-spacing: 0.5px;
    line-height: 1.2;
  }

  .modal-subtitle {
    margin-top: 6px;
    font-size: 12px;
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

  .login-tabs {
    gap: 16px;
    margin-bottom: 16px;
  }

  .login-tabs button {
    flex: 1;
    min-width: 0;
    padding: 10px 0;
    font-size: 14px;
    white-space: nowrap;
  }

  .form-group {
    margin-bottom: 12px;
  }

  .phone-input {
    gap: 8px;
  }

  .phone-input select {
    width: 110px;
    min-width: 110px;
  }

  .phone-input select,
  .phone-input input,
  .form-group input,
  .login-btn {
    height: 42px;
    font-size: 14px;
  }

  .captcha-container {
    height: 58px;
  }

  .phone-input select,
  .phone-input input,
  .form-group input {
    padding: 0 14px;
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

  .captcha-wrapper {
    gap: 8px;
  }

  .captcha-container {
    flex: 0 0 120px;
  }

  .captcha-img {
    width: 86px;
  }

  .refresh-captcha {
    width: 32px;
  }

  .send-btn {
    top: 4px;
    right: 4px;
    bottom: 4px;
    padding: 0 10px;
    font-size: 12px;
  }

  .login-actions {
    margin-top: 10px;
    gap: 8px;
  }

  .remember-password,
  .forgot-pwd-link {
    font-size: 12px;
  }

  .remember-password {
    gap: 6px;
  }

  .login-btn {
    margin-top: 8px;
    font-size: 15px;
  }

  .third-party-login {
    margin-top: 20px;
  }

  .divider {
    margin-bottom: 12px;
  }

  .third-buttons {
    gap: 10px;
  }

  .third-btn {
    flex: 1;
    min-width: 0;
    height: 36px;
    padding: 0 12px;
    font-size: 13px;
  }

  .third-btn i {
    font-size: 16px;
  }

  .agreement {
    margin-top: 12px;
    font-size: 11px;
    line-height: 1.4;
    justify-content: flex-start;
  }

  .agreement-checkbox {
    margin-top: 1px;
  }

  .switch-tip {
    margin-top: 14px;
    font-size: 12px;
  }
}

@media (max-width: 380px) {
  .modal-mask {
    padding: 10px;
  }

  .modal-container {
    padding: 16px 14px 14px;
    border-radius: 14px;
  }

  .brand-logo span {
    font-size: 20px;
  }

  .login-tabs {
    gap: 12px;
  }

  .login-tabs button {
    font-size: 13px;
  }

  .phone-input select {
    width: 102px;
    min-width: 102px;
  }

  .captcha-container {
    flex-basis: 120px;
  }

  .captcha-img {
    width: 88px;
  }

  .agreement {
    font-size: 10px;
  }
}

@media (max-width: 390px) {
  .modal-subtitle {
    line-height: 1.4;
  }

  .login-tabs {
    gap: 8px;
  }

  .login-tabs button {
    min-height: 42px;
    white-space: normal;
    line-height: 1.2;
    padding: 8px 4px;
  }
}

@media (max-width: 420px) {
  .send-btn {
    position: static;
    transform: none;
    width: 100%;
    height: 36px;
    margin-top: 8px;
    border-radius: 8px;
    justify-content: center;
    display: inline-flex;
    align-items: center;
  }

  .captcha-wrapper {
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(150px, 46%);
    align-items: stretch;
    gap: 8px;
  }

  .captcha-input {
    height: 42px;
  }

  .captcha-container {
    width: 100%;
    flex: none;
    justify-content: space-between;
    height: 42px;
  }

  .captcha-img {
    width: calc(100% - 32px);
  }

  .login-actions {
    flex-direction: column;
    align-items: stretch;
  }

  .forgot-pwd-link {
    align-self: flex-end;
  }

  .third-buttons {
    flex-direction: column;
  }

  .third-btn {
    width: 100%;
  }

  .agreement {
    align-items: flex-start;
  }
}

/* 小屏幕高度适配 */
@media (max-height: 700px) {
  .modal-container {
    max-height: 96vh;
    padding: 18px 18px 14px;
  }
  .modal-body {
    max-height: calc(96vh - 128px);
  }
  .modal-header {
    margin-bottom: 14px;
  }
  .form-group {
    margin-bottom: 10px;
  }
  .third-party-login {
    margin-top: 16px;
  }
}

/* 第三方登录弹窗样式 */
.thirdparty-modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 200000;
  display: flex;
  align-items: center;
  justify-content: center;
}

.thirdparty-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
}

.thirdparty-container {
  position: relative;
  background: #fff;
  border-radius: 16px;
  width: 320px;
  max-width: 90%;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  animation: slideUp 0.3s ease;
}

.thirdparty-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid #f1f5f9;
}

.thirdparty-header span {
  font-size: 18px;
  font-weight: 600;
  color: #1e293b;
}

.thirdparty-close {
  width: 32px;
  height: 32px;
  border: none;
  background: transparent;
  color: #94a3b8;
  font-size: 24px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.2s;
}

.thirdparty-close:hover {
  background: #f1f5f9;
  color: #64748b;
}

.thirdparty-body {
  padding: 32px 24px;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
}

.thirdparty-body img {
  width: 150px;
  height: 150px;
  border-radius: 8px;
  margin-bottom: 8px;
}

.thirdparty-body p {
  color: #64748b;
  font-size: 14px;
  margin-bottom: 8px;
}

.thirdparty-confirm, .thirdparty-cancel {
  width: 100%;
  height: 44px;
  border-radius: 10px;
  font-size: 15px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.thirdparty-confirm {
  background: #3b82f6;
  color: #fff;
  border: none;
}

.thirdparty-confirm:hover {
  background: #2563eb;
}

.thirdparty-cancel {
  background: #fff;
  border: 1px solid #e2e8f0;
  color: #64748b;
  margin-top: 8px;
}

.thirdparty-cancel:hover {
  background: #f8fafc;
  color: #334155;
}

/* 协议抖动动画 */
.shake-animation {
  animation: shake 0.5s cubic-bezier(.36,.07,.19,.97) both;
}

@keyframes shake {
  10%, 90% { transform: translate3d(-1px, 0, 0); }
  20%, 80% { transform: translate3d(2px, 0, 0); }
  30%, 50%, 70% { transform: translate3d(-4px, 0, 0); }
  40%, 60% { transform: translate3d(4px, 0, 0); }
}
</style>

