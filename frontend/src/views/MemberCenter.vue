<template>
  <div class="member-page">
    <HeaderBar />
    <div class="header-spacer"></div>

    <!-- 顶部沉浸式区域 -->
    <div class="page-header">
      <!-- 动态极光背景 -->
      <div class="aurora-bg">
        <div class="aurora-beam"></div>
        <div class="aurora-beam"></div>
        <div class="aurora-beam"></div>
      </div>
      
      <!-- 3D 网格地平线 -->
      <div class="perspective-grid"></div>
      
      <!-- 粒子星尘 -->
      <div class="particles">
        <span
          v-for="particle in particles"
          :key="particle.id"
          class="particle"
          :style="particle.style"
        ></span>
      </div>

      <div class="header-content max-w-7xl mx-auto px-6 relative z-10">
        <div class="flex flex-col md:flex-row items-center justify-between gap-12">
          <!-- 左侧文案 -->
          <div class="header-text md:w-1/2">
            <div class="brand-tag">HUAWISE PRIME</div>
            <h1 class="hero-title">
              赋能人才 <br>
              <span class="text-gold">构建学习型组织</span>
            </h1>
            <p class="hero-desc">
              从单体酒店到连锁集团的智能培训专家，为您提供全方位的 AI 培训解决方案。
            </p>
            <div class="hero-stats">
              <div class="stat-item">
                <div class="stat-val">500+</div>
                <div class="stat-label">合作酒店</div>
              </div>
              <div class="stat-item">
                <div class="stat-val">10W+</div>
                <div class="stat-label">培训员工</div>
              </div>
              <div class="stat-item">
                <div class="stat-val">98%</div>
                <div class="stat-label">好评率</div>
              </div>
            </div>
          </div>

          <!-- 右侧会员卡 (数字通行证风格) -->
          <div class="card-container md:w-1/2 flex justify-center md:justify-end">
            <div class="digital-card">
              <!-- 动态光效背景 -->
              <div class="card-bg-glow"></div>
              <div class="card-noise"></div>
              
              <div class="card-inner">
                <div class="card-header">
                  <div class="company-brand">
                    <i class="fas fa-layer-group logo-icon"></i>
                    <span class="brand-name">HUAWISE</span>
                  </div>
                  <div class="status-badge">
                    <span class="dot"></span>
                    {{ currentLevelInfo.levelName }}
                  </div>
                </div>

                <div class="card-body">
                  <div class="user-avatar-placeholder">
                    {{ userInitials }}
                  </div>
                  <div class="user-info">
                    <div class="user-name">{{ userInfo.name || 'Guest User' }}</div>
                    <div class="user-role">{{ userInfo.position || '会员' }}</div>
                  </div>
                </div>

                <div class="card-footer">
                  <div class="card-meta">
                    <div class="meta-label">MEMBER SINCE</div>
                    <div class="meta-value">{{ memberSinceDate }}</div>
                  </div>
                  <div class="card-meta">
                    <div class="meta-label">VALID UNTIL</div>
                    <div class="meta-value">{{ membershipExpireDate }}</div>
                  </div>
                  <div class="card-id">
                    NO. {{ userInfo.userId ? String(userInfo.userId).padStart(8, '0') : '00000001' }}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="main-container max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      
      <!-- 费用计算器 -->
      <section class="calculator-section">
        <div class="section-header">
          <h2 class="section-title">智能报价估算</h2>
          <p class="section-subtitle">透明定价，按需付费，根据您的规模自动计算最优方案</p>
        </div>
        
        <div class="calculator-card">
          <div class="calc-input">
            <label class="input-label">预计使用员工数</label>
            <div class="slider-container">
              <el-slider v-model="userCount" :min="1" :max="600" :step="1" class="custom-slider" />
            </div>
            <div class="input-row">
              <el-input-number v-model="userCount" :min="1" :max="10000" size="large" controls-position="right" />
              <div class="price-tag">
                当前单价: <span class="highlight">¥{{ currentUnitPrice }}</span> /账号/年
              </div>
            </div>
          </div>
          
          <div class="calc-divider"></div>
          
          <div class="calc-result">
            <div class="result-row">
              <span class="label">账号总费用</span>
              <span class="value">¥{{ totalAccountFee.toLocaleString() }}</span>
            </div>
            <div class="result-row">
              <span class="label">平台基础年费</span>
              <span class="value text-blue">¥{{ selectedPlanPrice.toLocaleString() }}</span>
            </div>
            <div class="total-row">
              <span class="label">年度总预算</span>
              <span class="value total">¥{{ totalAnnualFee.toLocaleString() }}</span>
            </div>
          </div>
        </div>
      </section>

      <!-- 积分权益 -->
      <section class="benefits-section">
        <div class="bg-dark-gradient rounded-3xl p-8 md:p-12 text-white relative overflow-hidden">
          <div class="bg-pattern-overlay"></div>
          <div class="relative z-10 flex flex-col md:flex-row items-center gap-12">
            <div class="md:w-1/3">
              <h2 class="text-3xl font-bold mb-4 text-gold">积分权益体系</h2>
              <p class="text-gray-300 mb-8 leading-relaxed">
                我们在您学习成长的每一步都准备了惊喜。通过学习、分享和实践获取积分，兑换真实权益。
              </p>
              <button class="btn-outline-gold">查看兑换商城 <i class="fas fa-arrow-right ml-2"></i></button>
            </div>
            
            <div class="md:w-2/3 grid grid-cols-2 md:grid-cols-3 gap-4 w-full">
              <div class="benefit-card">
                <div class="benefit-icon"><i class="fas fa-pen-fancy"></i></div>
                <div class="benefit-val">+30</div>
                <div class="benefit-label">发布精华文章</div>
              </div>
              <div class="benefit-card">
                <div class="benefit-icon"><i class="fas fa-check-circle"></i></div>
                <div class="benefit-val">+15</div>
                <div class="benefit-label">回答被采纳</div>
              </div>
              <div class="benefit-card">
                <div class="benefit-icon"><i class="fas fa-users"></i></div>
                <div class="benefit-val">+20</div>
                <div class="benefit-label">组队打卡</div>
              </div>
              <div class="benefit-card">
                <div class="benefit-icon"><i class="fas fa-book-reader"></i></div>
                <div class="benefit-val">+10</div>
                <div class="benefit-label">完成课程</div>
              </div>
              <div class="benefit-card">
                <div class="benefit-icon"><i class="fas fa-calendar-check"></i></div>
                <div class="benefit-val">+5</div>
                <div class="benefit-label">每日登录</div>
              </div>
              <div class="benefit-card highlight">
                <div class="benefit-icon"><i class="fas fa-gift"></i></div>
                <div class="benefit-val">Exchange</div>
                <div class="benefit-label">兑换福利</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- 订阅方案 -->
      <section id="plans-section" class="plans-section mb-20">
        <div class="section-header">
          <h2 class="section-title">选择适合的方案</h2>
          <p class="section-subtitle">灵活订阅 · 按年付费 · 私有化部署支持</p>
        </div>

        <div class="plans-grid">
          <!-- Light Plan -->
          <div class="plan-card" :class="{ active: selectedPlan === 'light' }" @click="selectPlan('light', 2000)">
            <div class="plan-header">
              <div class="plan-name">轻量版</div>
              <div class="plan-price">¥2,000<span class="unit">/年</span></div>
              <div class="plan-desc">适用 ≤50 间房</div>
            </div>
            <ul class="plan-features">
              <li><i class="fas fa-check"></i> 岗位培训模块</li>
              <li><i class="fas fa-check"></i> 智能题库与测评</li>
              <li><i class="fas fa-check"></i> AI 教练基础对话</li>
              <li class="disabled"><i class="fas fa-minus"></i> 企业文化定制</li>
            </ul>
            <button class="btn-select">选择此方案</button>
          </div>

          <!-- Standard Plan -->
          <div class="plan-card popular" :class="{ active: selectedPlan === 'standard' }" @click="selectPlan('standard', 5000)">
            <div class="popular-tag">MOST POPULAR</div>
            <div class="plan-header">
              <div class="plan-name">标准版</div>
              <div class="plan-price">¥5,000<span class="unit">/年</span></div>
              <div class="plan-desc">适用 51-200 间房</div>
            </div>
            <ul class="plan-features">
              <li><i class="fas fa-check"></i> 包含轻量版所有功能</li>
              <li><i class="fas fa-check"></i> 学习数据看板 (完整)</li>
              <li><i class="fas fa-check"></i> 企业文化定制</li>
              <li><i class="fas fa-check"></i> 知识共享平台</li>
            </ul>
            <button class="btn-select">选择此方案</button>
          </div>

          <!-- Flagship Plan -->
          <div class="plan-card" :class="{ active: selectedPlan === 'flagship' }" @click="selectPlan('flagship', 10000)">
            <div class="plan-header">
              <div class="plan-name">旗舰版</div>
              <div class="plan-price">¥10,000<span class="unit">/年</span></div>
              <div class="plan-desc">适用 200+ 间房</div>
            </div>
            <ul class="plan-features">
              <li><i class="fas fa-check"></i> 包含标准版所有功能</li>
              <li><i class="fas fa-check"></i> 集团化管理后台</li>
              <li><i class="fas fa-check"></i> API 接口支持</li>
              <li><i class="fas fa-check"></i> 数据预测分析</li>
            </ul>
            <button class="btn-select">选择此方案</button>
          </div>

          <!-- Enterprise Plan -->
          <div class="plan-card dark" :class="{ active: selectedPlan === 'enterprise' }" @click="selectPlan('enterprise', 0)">
            <div class="plan-header">
              <div class="plan-name">企业版</div>
              <div class="plan-price">定制报价</div>
              <div class="plan-desc">集团 / 多品牌定制</div>
            </div>
            <ul class="plan-features">
              <li><i class="fas fa-star"></i> 私有化部署</li>
              <li><i class="fas fa-star"></i> 内容深度定制开发</li>
              <li><i class="fas fa-star"></i> 全程陪跑服务</li>
              <li><i class="fas fa-star"></i> 专属客户成功经理</li>
            </ul>
            <button class="btn-select dark">联系顾问</button>
          </div>
        </div>

        <div class="action-area">
          <button @click="handleSubscribe" class="btn-main-action">
            {{ selectedPlan === 'enterprise' ? '联系销售顾问' : '立即订阅方案' }}
          </button>
          <p class="promo-text">限时优惠：前50名签约客户享首年平台费 6 折，含 15 天全功能试用</p>
        </div>
      </section>
    </div>
    
    <FooterBar />
  </div>
</template>

<script setup>
import logger from '@/utils/logger';
import { ref, computed, onMounted } from 'vue'
import HeaderBar from '@/components/HeaderBar.vue'
import FooterBar from '@/components/FooterBar.vue'
import { getMyMembership } from '@/api/membership'
import { getUserInfo } from '@/api/auth'
import { ElMessage } from 'element-plus'

const userInfo = ref({ name: 'Guest User', userId: null, position: '会员' })
const userMembership = ref(null)
const userCount = ref(50)
const selectedPlan = ref('standard')
const selectedPlanPrice = ref(5000)
const particles = ref(
  Array.from({ length: 20 }, (_, i) => ({
    id: i,
    style: {
      left: '0%',
      top: '0%',
      animationDelay: '0s',
      opacity: 0.5
    }
  }))
)

// 模拟数据加载
onMounted(async () => {
  // 加载用户信息
  try {
    // 1. 先尝试从 localStorage 加载
    const storedUserInfo = localStorage.getItem('userInfo')
    if (storedUserInfo) {
      const parsedInfo = JSON.parse(storedUserInfo)
      // 尝试从本地获取公司名
      const localCompany = parsedInfo.companyName || parsedInfo.company
      // 尝试从本地获取部门名
      const localDept = parsedInfo.deptName || (parsedInfo.dept && parsedInfo.dept.deptName)
      
      userInfo.value = {
        ...parsedInfo,
        name: parsedInfo.name || parsedInfo.userName || 'Guest User',
        // 优先显示公司名 -> 岗位/职位 -> 部门名 (最低标准) -> 会员
        position: localCompany || parsedInfo.postGroup || parsedInfo.position || localDept || '会员'
      }
    }
    
    // 2. 调用 API 获取最新信息（包含公司名称）
    const userRes = await getUserInfo()
    if (userRes.data && userRes.data.code === 200) {
      const apiData = userRes.data
      const apiUser = apiData.user || {}
      const profileCompletion = apiData.profileCompletion || apiUser.profileCompletion || userInfo.value.profileCompletion || null
      
      // 获取公司名称 (API返回的顶级字段)
      const companyName = apiData.companyName || apiData.company
      // 获取部门名称 (API返回的顶级字段)
      const deptName = apiData.deptName || (apiData.dept && apiData.dept.deptName)
      
      // 合并信息
      userInfo.value = {
        ...userInfo.value,
        ...apiUser,
        profileCompletion,
        name: apiUser.name || apiUser.userName || userInfo.value.name,
        // 更新职位显示：优先显示公司名 -> 岗位/职位 -> 部门名 (最低标准) -> 会员
        position: companyName || apiUser.postGroup || apiUser.position || deptName || '会员'
      }
      
      // 如果获取到了公司名，更新到 localStorage 以便下次使用
      if (companyName) {
         const newStorage = {
           ...JSON.parse(localStorage.getItem('userInfo') || '{}'),
           ...apiUser,
           companyName,
           profileCompletion
         }
         localStorage.setItem('userInfo', JSON.stringify(newStorage))
      }
    }
  } catch (e) {
    logger.error('加载用户信息失败', e)
  }

  try {
    const res = await getMyMembership()
    if (res.data?.code === 200) {
      userMembership.value = res.data.data
    }
  } catch (e) {
    logger.error(e)
  }

  particles.value = particles.value.map((particle) => {
    return {
      id: particle.id,
      style: {
        left: Math.random() * 100 + '%',
        top: Math.random() * 100 + '%',
        animationDelay: Math.random() * 5 + 's',
        opacity: Math.random() * 0.5 + 0.2
      }
    }
  })
})

const userInitials = computed(() => {
  const name = userInfo.value.name || 'User'
  return name.substring(0, 1).toUpperCase()
})

const currentLevelInfo = computed(() => {
  if (!userMembership.value) {
    return {
      levelName: '体验版',
      levelCode: 'free'
    }
  }
  return {
    levelName: userMembership.value.levelName || '免费试用版',
    levelCode: userMembership.value.levelCode || 'free'
  }
})

const memberSinceDate = computed(() => {
  if (!userMembership.value || !userMembership.value.startTime) {
    return '--'
  }
  return new Date(userMembership.value.startTime).toLocaleDateString()
})

const membershipExpireDate = computed(() => {
  if (!userMembership.value || !userMembership.value.endTime) {
    return '--'
  }
  return new Date(userMembership.value.endTime).toLocaleDateString()
})

// 计算单价逻辑 (Mock Logic)
const currentUnitPrice = computed(() => {
  if (userCount.value <= 50) return 365
  if (userCount.value <= 200) return 299
  return 199
})

const totalAccountFee = computed(() => {
  return userCount.value * currentUnitPrice.value
})

const totalAnnualFee = computed(() => {
  return totalAccountFee.value + selectedPlanPrice.value
})

function selectPlan(plan, price) {
  selectedPlan.value = plan
  selectedPlanPrice.value = price
}

function handleSubscribe() {
  ElMessage.success('感谢您的兴趣！我们的销售顾问将尽快与您联系。')
}
</script>

<style scoped>
/* 基础设置 */
.member-page {
  min-height: 100vh;
  background-color: #f8fafc;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
}

.header-spacer { height: 60px; }

/* 文本颜色 */
.text-gold { color: #d4af37; }
.text-blue { color: #2563eb; }

/* 顶部区域 */
.page-header {
  background: #000;
  color: white;
  padding: 80px 0 100px;
  position: relative;
  overflow: hidden;
}

/* 极光背景 */
.aurora-bg {
  position: absolute;
  top: -50%; left: -50%;
  width: 200%; height: 200%;
  background: radial-gradient(circle at center, #0f172a 0%, #000 100%);
  z-index: 0;
  overflow: hidden;
}

.aurora-beam {
  position: absolute;
  filter: blur(80px);
  opacity: 0.6;
  border-radius: 50%;
  animation: drift 15s infinite alternate ease-in-out;
}

.aurora-beam:nth-child(1) {
  top: 20%; left: 20%;
  width: 60vw; height: 60vw;
  background: linear-gradient(135deg, #2563eb, #7c3aed);
  animation-duration: 20s;
}

.aurora-beam:nth-child(2) {
  bottom: 20%; right: 20%;
  width: 50vw; height: 50vw;
  background: linear-gradient(135deg, #d4af37, #b45309);
  animation-duration: 25s;
  animation-delay: -5s;
}

.aurora-beam:nth-child(3) {
  top: 40%; right: 40%;
  width: 40vw; height: 40vw;
  background: linear-gradient(135deg, #059669, #0d9488);
  opacity: 0.4;
  animation-duration: 18s;
  animation-delay: -10s;
}

@keyframes drift {
  0% { transform: translate(0, 0) rotate(0deg); }
  100% { transform: translate(100px, 50px) rotate(20deg); }
}

/* 3D透视网格 */
.perspective-grid {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background-image: 
    linear-gradient(rgba(255,255,255,0.05) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255,255,255,0.05) 1px, transparent 1px);
  background-size: 80px 80px;
  transform: perspective(500px) rotateX(60deg) scale(2);
  transform-origin: top center;
  mask-image: linear-gradient(to bottom, transparent 0%, black 40%, transparent 100%);
  -webkit-mask-image: linear-gradient(to bottom, transparent 0%, black 40%, transparent 100%);
  pointer-events: none;
  animation: gridMove 20s linear infinite;
  z-index: 1;
}

@keyframes gridMove {
  0% { background-position: 0 0; }
  100% { background-position: 0 80px; }
}

/* 粒子 */
.particles {
  position: absolute;
  inset: 0;
  z-index: 2;
  pointer-events: none;
}

.particle {
  position: absolute;
  width: 2px; height: 2px;
  background: white;
  border-radius: 50%;
  box-shadow: 0 0 4px white;
  animation: twinkle 3s infinite ease-in-out;
}

@keyframes twinkle {
  0%, 100% { opacity: 0.2; transform: scale(1); }
  50% { opacity: 1; transform: scale(1.5); }
}

.brand-tag {
  display: inline-block;
  padding: 6px 16px;
  background: rgba(255,255,255,0.1);
  border: 1px solid rgba(212, 175, 55, 0.3);
  color: #d4af37;
  font-size: 12px;
  font-weight: 600;
  border-radius: 20px;
  margin-bottom: 24px;
  letter-spacing: 2px;
}

.hero-title {
  font-size: 48px;
  font-weight: 800;
  line-height: 1.2;
  margin-bottom: 24px;
}

.hero-desc {
  font-size: 18px;
  color: #94a3b8;
  max-width: 500px;
  margin-bottom: 40px;
}

.hero-stats {
  display: flex;
  gap: 40px;
}

.stat-val {
  font-size: 24px;
  font-weight: 700;
  color: white;
}

.stat-label {
  font-size: 12px;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 1px;
}

/* 数字通行证风格 */
.digital-card {
  width: 380px;
  height: 220px;
  position: relative;
  border-radius: 24px;
  padding: 2px; /* For border gradient */
  background: linear-gradient(135deg, rgba(255,255,255,0.2), rgba(255,255,255,0.05));
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(20px);
  transform: perspective(1000px) rotateY(-5deg) rotateX(5deg);
  transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1);
  overflow: hidden;
}

.digital-card:hover {
  transform: perspective(1000px) rotateY(0) rotateX(0) scale(1.02);
  box-shadow: 0 30px 60px -12px rgba(0, 0, 0, 0.6), 0 0 30px rgba(212, 175, 55, 0.2);
}

.card-bg-glow {
  position: absolute;
  top: -50%; left: -50%; width: 200%; height: 200%;
  background: radial-gradient(circle at 50% 50%, rgba(37, 99, 235, 0.15), transparent 50%);
  animation: pulse 4s infinite alternate;
}

.card-noise {
  position: absolute;
  inset: 0;
  opacity: 0.05;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E");
}

.card-inner {
  background: linear-gradient(145deg, rgba(30, 41, 59, 0.9), rgba(15, 23, 42, 0.95));
  height: 100%;
  width: 100%;
  border-radius: 22px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  position: relative;
  z-index: 1;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.company-brand {
  display: flex;
  align-items: center;
  gap: 10px;
}

.logo-icon {
  font-size: 24px;
  background: linear-gradient(to bottom, #d4af37, #f3e5ab);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.brand-name {
  font-weight: 800;
  font-size: 18px;
  letter-spacing: 1px;
  color: white;
}

.status-badge {
  background: rgba(212, 175, 55, 0.15);
  border: 1px solid rgba(212, 175, 55, 0.3);
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 12px;
  color: #d4af37;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 6px;
}

.status-badge .dot {
  width: 6px;
  height: 6px;
  background: #d4af37;
  border-radius: 50%;
  box-shadow: 0 0 8px #d4af37;
}

.card-body {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-top: 10px;
}

.user-avatar-placeholder {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  background: linear-gradient(135deg, #d4af37, #b8860b);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  font-weight: 700;
  color: #0f172a;
  box-shadow: 0 4px 12px rgba(212, 175, 55, 0.3);
}

.user-info {
  display: flex;
  flex-direction: column;
}

.user-name {
  font-size: 20px;
  font-weight: 700;
  color: white;
  line-height: 1.2;
}

.user-role {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 2px;
}

.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  border-top: 1px solid rgba(255,255,255,0.1);
  padding-top: 16px;
}

.card-meta {
  display: flex;
  flex-direction: column;
}

.meta-label {
  font-size: 8px;
  color: #64748b;
  letter-spacing: 1px;
  margin-bottom: 2px;
}

.meta-value {
  font-size: 12px;
  color: #e2e8f0;
  font-weight: 500;
  font-family: monospace;
}

.card-id {
  font-family: 'Courier New', monospace;
  font-size: 12px;
  color: #64748b;
  letter-spacing: 1px;
}

@keyframes pulse {
  0% { transform: scale(1); opacity: 0.5; }
  100% { transform: scale(1.1); opacity: 0.8; }
}

/* 费用计算器 */
.calculator-section {
  margin-top: -30px;
  position: relative;
  z-index: 10;
  margin-bottom: 60px;
}

.section-header {
  text-align: center;
  margin-bottom: 40px;
}

.section-title {
  font-size: 32px;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 12px;
}

.section-subtitle {
  color: #64748b;
  font-size: 16px;
}

.calculator-card {
  background: white;
  border-radius: 24px;
  box-shadow: 0 10px 40px rgba(0,0,0,0.08);
  padding: 40px;
  display: flex;
  flex-direction: column;
  md:flex-row;
  gap: 40px;
}

@media (min-width: 768px) {
  .calculator-card {
    flex-direction: row;
    align-items: center;
  }
}

.calc-input { flex: 1; }

.input-label {
  display: block;
  font-weight: 600;
  color: #1e293b;
  margin-bottom: 20px;
}

.slider-container { margin-bottom: 20px; }

.input-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.price-tag {
  font-size: 14px;
  color: #64748b;
}

.price-tag .highlight {
  color: #2563eb;
  font-weight: 700;
  font-size: 18px;
}

.calc-divider {
  width: 1px;
  height: 120px;
  background: #e2e8f0;
  display: none;
}

@media (min-width: 768px) {
  .calc-divider { display: block; }
}

.calc-result {
  flex: 1;
  background: #f8fafc;
  padding: 30px;
  border-radius: 16px;
}

.result-row {
  display: flex;
  justify-content: space-between;
  margin-bottom: 16px;
  font-size: 14px;
  color: #64748b;
}

.result-row .value {
  font-weight: 600;
  color: #1e293b;
  font-size: 16px;
}

.total-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 24px;
  padding-top: 24px;
  border-top: 1px dashed #cbd5e1;
}

.total-row .label {
  font-weight: 600;
  color: #1e293b;
}

.total-row .total {
  font-size: 32px;
  font-weight: 800;
  color: #d4af37;
}

/* 积分权益 */
.benefits-section {
  margin-bottom: 80px;
}

.bg-dark-gradient {
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
}

.btn-outline-gold {
  padding: 12px 24px;
  border: 1px solid #d4af37;
  color: #d4af37;
  background: transparent;
  border-radius: 30px;
  font-weight: 600;
  transition: all 0.3s;
}

.btn-outline-gold:hover {
  background: #d4af37;
  color: #0f172a;
}

.benefit-card {
  background: rgba(255,255,255,0.05);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 16px;
  padding: 20px;
  text-align: center;
  transition: transform 0.3s, background 0.3s;
}

.benefit-card:hover {
  background: rgba(255,255,255,0.1);
  transform: translateY(-5px);
}

.benefit-card.highlight {
  background: linear-gradient(135deg, #d4af37 0%, #f3e5ab 100%);
  color: #1e293b;
  border: none;
}

.benefit-icon {
  font-size: 24px;
  margin-bottom: 8px;
  opacity: 0.8;
}

.benefit-val {
  font-size: 20px;
  font-weight: 800;
  margin-bottom: 4px;
}

.benefit-label {
  font-size: 12px;
  opacity: 0.7;
}

/* 套餐卡片 */
.plans-grid {
  display: grid;
  grid-template-columns: repeat(1, 1fr);
  gap: 24px;
  margin-bottom: 40px;
}

@media (min-width: 768px) {
  .plans-grid {
    grid-template-columns: repeat(4, 1fr);
  }
}

.plan-card {
  background: white;
  border-radius: 20px;
  padding: 30px;
  border: 1px solid #e2e8f0;
  transition: all 0.3s;
  position: relative;
  display: flex;
  flex-direction: column;
}

.plan-card:hover {
  transform: translateY(-10px);
  box-shadow: 0 20px 40px rgba(0,0,0,0.08);
}

.plan-card.active {
  border-color: #2563eb;
  box-shadow: 0 0 0 2px #2563eb;
}

.plan-card.popular {
  border-color: #d4af37;
  background: linear-gradient(to bottom, #fffcf5, #fff);
}

.plan-card.popular.active {
  box-shadow: 0 0 0 2px #d4af37;
}

.popular-tag {
  position: absolute;
  top: 0;
  left: 50%;
  transform: translateX(-50%);
  background: #d4af37;
  color: white;
  padding: 4px 12px;
  font-size: 10px;
  font-weight: 700;
  border-radius: 0 0 8px 8px;
}

.plan-card.dark {
  background: #1e293b;
  color: white;
  border-color: #334155;
}

.plan-header {
  text-align: center;
  margin-bottom: 24px;
  padding-bottom: 24px;
  border-bottom: 1px solid #f1f5f9;
}

.plan-card.dark .plan-header { border-bottom-color: #334155; }

.plan-name { font-weight: 700; font-size: 18px; margin-bottom: 8px; }
.plan-price { font-size: 28px; font-weight: 800; color: #1e293b; }
.plan-card.dark .plan-price { color: white; }
.plan-price .unit { font-size: 14px; color: #94a3b8; font-weight: 400; }
.plan-desc { font-size: 12px; color: #64748b; margin-top: 4px; }

.plan-features {
  list-style: none;
  padding: 0;
  margin: 0 0 30px;
  flex: 1;
}

.plan-features li {
  font-size: 13px;
  color: #475569;
  margin-bottom: 12px;
  display: flex;
  align-items: center;
}

.plan-card.dark .plan-features li { color: #cbd5e1; }

.plan-features li i {
  margin-right: 8px;
  color: #2563eb;
}

.plan-card.popular .plan-features li i { color: #d4af37; }
.plan-features li.disabled { color: #cbd5e1; }
.plan-features li.disabled i { color: #cbd5e1; }

.btn-select {
  width: 100%;
  padding: 12px;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  background: white;
  color: #1e293b;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.plan-card:hover .btn-select {
  background: #1e293b;
  color: white;
  border-color: #1e293b;
}

.plan-card.active .btn-select {
  background: #2563eb;
  color: white;
  border-color: #2563eb;
}

.plan-card.popular:hover .btn-select,
.plan-card.popular.active .btn-select {
  background: #d4af37;
  border-color: #d4af37;
  color: white;
}

.plan-card.dark .btn-select {
  background: rgba(255,255,255,0.1);
  color: white;
  border-color: rgba(255,255,255,0.2);
}

.plan-card.dark:hover .btn-select {
  background: white;
  color: #1e293b;
}

.action-area { text-align: center; }

.btn-main-action {
  padding: 16px 48px;
  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
  color: white;
  border: none;
  border-radius: 50px;
  font-size: 18px;
  font-weight: 700;
  box-shadow: 0 10px 20px rgba(37, 99, 235, 0.3);
  cursor: pointer;
  transition: transform 0.2s;
}

.btn-main-action:hover {
  transform: translateY(-2px);
  box-shadow: 0 15px 30px rgba(37, 99, 235, 0.4);
}

.promo-text {
  margin-top: 16px;
  color: #64748b;
  font-size: 13px;
}
</style>

