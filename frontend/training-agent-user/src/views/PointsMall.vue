<template>
  <div class="min-h-screen bg-slate-50 font-sans pb-10">
    <HeaderBar />
    
    <!-- 顶部背景 -->
    <div class="bg-gradient-to-r from-indigo-600 to-violet-600 text-white pt-24 pb-16 px-4">
      <div class="max-w-6xl mx-auto">
        <div class="flex flex-col md:flex-row justify-between items-center gap-6">
          <div>
            <h1 class="text-3xl font-extrabold mb-2">Points Mall</h1>
            <p class="text-indigo-100">用你的努力换取心仪的奖励 ✨</p>
          </div>
          
          <div class="bg-white/10 backdrop-blur-md rounded-2xl p-6 border border-white/20 min-w-[280px] text-center md:text-right">
            <div class="text-sm text-indigo-100 mb-1">我的积分余额</div>
            <div class="text-4xl font-black text-white flex items-center justify-center md:justify-end gap-2">
              {{ myPoints }}
              <span class="text-xl">pts</span>
            </div>
            <div class="mt-3 flex justify-center md:justify-end gap-2">
              <div class="text-xs text-indigo-200 bg-white/10 px-3 py-1 rounded-full cursor-pointer hover:bg-white/20 transition-colors" @click="showRules = true">
                积分规则 >
              </div>
              <div class="text-xs text-indigo-200 bg-white/10 px-3 py-1 rounded-full cursor-pointer hover:bg-white/20 transition-colors" @click="openPointsLog">
                积分明细 >
              </div>
              <div class="text-xs text-indigo-200 bg-white/10 px-3 py-1 rounded-full cursor-pointer hover:bg-white/20 transition-colors" @click="showOrders = true">
                兑换记录 >
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 主要内容 -->
    <div class="max-w-6xl mx-auto px-4 -mt-8">
      <!-- 搜索/过滤 -->
      <div class="bg-white rounded-xl shadow-lg p-4 mb-8 flex items-center gap-4">
        <div class="flex-1 relative">
          <input 
            v-model="queryParams.itemName" 
            type="text" 
            placeholder="搜索商品..." 
            class="w-full pl-10 pr-4 py-2 rounded-lg border border-slate-200 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-200 transition-all outline-none"
            @keyup.enter="handleQuery"
          >
          <span class="absolute left-3 top-2.5 text-slate-400">🔍</span>
        </div>
        <button 
          @click="handleQuery"
          class="bg-indigo-600 text-white px-6 py-2 rounded-lg font-semibold hover:bg-indigo-700 transition-colors"
        >
          搜索
        </button>
      </div>

      <!-- 商品列表 -->
      <div v-if="loading" class="flex justify-center py-20">
        <div class="w-10 h-10 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin"></div>
      </div>
      
      <div v-else-if="itemList.length > 0" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        <div 
          v-for="item in itemList" 
          :key="item.itemId"
          class="bg-white rounded-2xl shadow-sm hover:shadow-xl transition-all duration-300 group overflow-hidden border border-slate-100 flex flex-col"
        >
          <!-- 图片 -->
          <div class="relative h-48 overflow-hidden bg-slate-100">
            <img 
              :src="item.coverImg || defaultImage" 
              class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
            >
            <div v-if="item.stockQuantity <= 0" class="absolute inset-0 bg-slate-900/60 flex items-center justify-center backdrop-blur-sm">
              <span class="text-white font-bold text-lg border-2 border-white px-4 py-1 rounded-full transform -rotate-12">已抢光</span>
            </div>
          </div>
          
          <!-- 内容 -->
          <div class="p-5 flex-1 flex flex-col">
            <h3 class="font-bold text-slate-800 text-lg mb-2 line-clamp-1" :title="item.itemName">{{ item.itemName }}</h3>
            <p class="text-sm text-slate-500 mb-4 line-clamp-2 flex-1">{{ item.description }}</p>
            
            <div class="flex items-end justify-between mt-auto">
              <div>
                <div class="text-2xl font-black text-indigo-600">
                  {{ item.pointsRequired }}
                  <span class="text-xs font-medium text-slate-400">分</span>
                </div>
                <div class="text-xs text-slate-400 mt-1">
                  库存: {{ item.stockQuantity }}
                </div>
              </div>
              
              <button 
                @click="handleRedeem(item)"
                :disabled="item.stockQuantity <= 0 || myPoints < item.pointsRequired"
                :class="[
                  'px-4 py-2 rounded-lg font-bold text-sm transition-all',
                  item.stockQuantity <= 0 || myPoints < item.pointsRequired
                    ? 'bg-slate-100 text-slate-400 cursor-not-allowed'
                    : 'bg-indigo-600 text-white hover:bg-indigo-700 shadow-lg shadow-indigo-200 hover:shadow-indigo-300 hover:-translate-y-0.5'
                ]"
              >
                {{ item.stockQuantity <= 0 ? '缺货' : myPoints < item.pointsRequired ? '积分不足' : '立即兑换' }}
              </button>
            </div>
          </div>
        </div>
      </div>
      
      <div v-else class="text-center py-20">
        <div class="text-6xl mb-4 grayscale opacity-30">🎁</div>
        <p class="text-slate-400">暂无商品上架</p>
      </div>
    </div>

    <!-- 积分规则抽屉 -->
    <div v-if="showRules" class="fixed inset-0 z-50 flex justify-end">
      <div class="absolute inset-0 bg-black/20 backdrop-blur-sm" @click="showRules = false"></div>
      <div class="relative bg-white w-full max-w-md h-full shadow-2xl p-6 overflow-y-auto animate-slide-in-right">
        <div class="flex items-center justify-between mb-8">
          <h2 class="text-xl font-bold text-slate-800">积分规则</h2>
          <button @click="showRules = false" class="text-slate-400 hover:text-slate-600">✕</button>
        </div>
        
        <div class="space-y-6">
          <div class="bg-indigo-50 rounded-xl p-5 border border-indigo-100">
            <div class="flex items-center gap-3 mb-3">
              <div class="w-10 h-10 rounded-full bg-indigo-100 flex items-center justify-center text-xl">🎯</div>
              <h3 class="font-bold text-slate-800">如何获取积分？</h3>
            </div>
            <p class="text-slate-600 text-sm leading-relaxed">
              <span class="font-bold text-indigo-600">• 答题奖励：</span>每答对一道题目，奖励 <span class="font-bold text-indigo-600">1</span> 积分<br>
              <span class="font-bold text-indigo-600">• 考试通过：</span>80分以上，奖励 <span class="font-bold text-indigo-600">50</span> 积分<br>
              <span class="font-bold text-indigo-600">• 测验通过：</span>60分以上，奖励 <span class="font-bold text-indigo-600">20</span> 积分
            </p>
          </div>

          <div class="bg-purple-50 rounded-xl p-5 border border-purple-100">
            <div class="flex items-center gap-3 mb-3">
              <div class="w-10 h-10 rounded-full bg-purple-100 flex items-center justify-center text-xl">🛍️</div>
              <h3 class="font-bold text-slate-800">积分有什么用？</h3>
            </div>
            <p class="text-slate-600 text-sm leading-relaxed">
              您可以在积分商城中使用积分兑换各种精美礼品。<br>
              <span class="font-bold text-purple-600">• 兑换规则：</span>只要您的积分余额充足且商品有库存，即可随时兑换。兑换成功后将扣除相应积分。
            </p>
          </div>

          <div class="bg-amber-50 rounded-xl p-5 border border-amber-100">
            <div class="flex items-center gap-3 mb-3">
              <div class="w-10 h-10 rounded-full bg-amber-100 flex items-center justify-center text-xl">💡</div>
              <h3 class="font-bold text-slate-800">注意事项</h3>
            </div>
            <ul class="list-disc list-inside text-slate-600 text-sm leading-relaxed space-y-1">
              <li>积分仅限本人使用，不可转让。</li>
              <li>如发现作弊行为，平台有权扣除异常获取的积分。</li>
              <li>兑换的商品将在审核后发放，请耐心等待。</li>
            </ul>
          </div>
        </div>
      </div>
    </div>

    <!-- 兑换记录抽屉 -->
    <div v-if="showOrders" class="fixed inset-0 z-50 flex justify-end">
      <div class="absolute inset-0 bg-black/20 backdrop-blur-sm" @click="showOrders = false"></div>
      <div class="relative bg-white w-full max-w-md h-full shadow-2xl p-6 overflow-y-auto animate-slide-in-right">
        <div class="flex items-center justify-between mb-8">
          <h2 class="text-xl font-bold text-slate-800">兑换记录</h2>
          <button @click="showOrders = false" class="text-slate-400 hover:text-slate-600">✕</button>
        </div>
        
        <div v-if="orderList.length > 0" class="space-y-4">
          <div v-for="order in orderList" :key="order.orderId" class="bg-slate-50 rounded-xl p-4 border border-slate-100">
            <div class="flex justify-between items-start mb-2">
              <h3 class="font-bold text-slate-700">{{ order.itemName }}</h3>
              <span class="text-xs bg-green-100 text-green-600 px-2 py-0.5 rounded-full">兑换成功</span>
            </div>
            <div class="flex justify-between items-center text-sm">
              <span class="text-slate-400">{{ order.createTime }}</span>
              <span class="font-bold text-indigo-600">-{{ order.pointsSpent }} 积分</span>
            </div>
          </div>
        </div>
        <div v-else class="text-center py-10 text-slate-400">
          暂无兑换记录
        </div>
      </div>
    </div>

    <!-- 积分明细抽屉 -->
    <div v-if="showPointsLog" class="fixed inset-0 z-50 flex justify-end">
      <div class="absolute inset-0 bg-black/20 backdrop-blur-sm" @click="showPointsLog = false"></div>
      <div class="relative bg-white w-full max-w-md h-full shadow-2xl p-6 overflow-y-auto animate-slide-in-right">
        <div class="flex items-center justify-between mb-8">
          <h2 class="text-xl font-bold text-slate-800">积分明细</h2>
          <button @click="showPointsLog = false" class="text-slate-400 hover:text-slate-600">✕</button>
        </div>
        
        <div v-if="pointsLogList.length > 0" class="space-y-4">
          <div v-for="log in pointsLogList" :key="log.logId" class="bg-slate-50 rounded-xl p-4 border border-slate-100">
            <div class="flex justify-between items-start mb-2">
              <h3 class="font-bold text-slate-700">答题奖励</h3>
              <span :class="['text-sm font-bold px-2 py-0.5 rounded-full', log.pointsChange > 0 ? 'bg-green-100 text-green-600' : 'bg-red-100 text-red-600']">
                {{ log.pointsChange > 0 ? '+' : '' }}{{ log.pointsChange }}
              </span>
            </div>
            <div class="text-sm text-slate-400">
              {{ log.createTime }}
            </div>
          </div>
        </div>
        <div v-else class="text-center py-10 text-slate-400">
          暂无积分明细
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import logger from '@/utils/logger';
import { ref, onMounted } from 'vue'
import HeaderBar from '@/components/HeaderBar.vue'
import { getShopItemList, getMyPoints, redeemItem, getMyOrders, getMyPointsLog, getPointsRules } from '@/api/shop'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false)
const itemList = ref([])
const orderList = ref([])
const pointsLogList = ref([])
const myPoints = ref(0)
const pointsPerAnswer = ref(10)
const showOrders = ref(false)
const showPointsLog = ref(false)
const showRules = ref(false)
const queryParams = ref({
  itemName: '',
  pageNum: 1,
  pageSize: 20,
  status: '1'
})

const defaultImage = 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=500&q=80'

const loadData = async () => {
  loading.value = true
  try {
    const [itemsRes, pointsRes, ordersRes, rulesRes] = await Promise.all([
      getShopItemList(queryParams.value),
      getMyPoints(),
      getMyOrders({ pageNum: 1, pageSize: 50 }),
      getPointsRules()
    ])
    
    if (itemsRes.rows) itemList.value = itemsRes.rows
    if (pointsRes.code === 200) myPoints.value = pointsRes.data
    if (ordersRes.rows) orderList.value = ordersRes.rows
    if (rulesRes.code === 200 && rulesRes.data) {
      pointsPerAnswer.value = rulesRes.data.pointsPerAnswer
    }
  } catch (e) {
    logger.error('加载失败', e)
  } finally {
    loading.value = false
  }
}

const openPointsLog = async () => {
  showPointsLog.value = true
  try {
    const res = await getMyPointsLog({ pageNum: 1, pageSize: 50 })
    if (res.rows) {
      pointsLogList.value = res.rows
    }
  } catch (e) {
    ElMessage.error('加载积分明细失败')
  }
}

const handleQuery = () => {
  queryParams.value.pageNum = 1
  loadData()
}

const handleRedeem = (item) => {
  ElMessageBox.confirm(
    `确定要消耗 ${item.pointsRequired} 积分兑换 "${item.itemName}" 吗？`,
    '兑换确认',
    {
      confirmButtonText: '确定兑换',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(async () => {
    try {
      const res = await redeemItem(item.itemId)
      if (res.code === 200) {
        ElMessage.success('兑换成功！')
        loadData() // 刷新数据
      } else {
        ElMessage.error(res.msg || '兑换失败')
      }
    } catch (e) {
      ElMessage.error(e.message || '兑换出错')
    }
  })
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
@keyframes slideInRight {
  from { transform: translateX(100%); }
  to { transform: translateX(0); }
}
.animate-slide-in-right {
  animation: slideInRight 0.3s ease-out;
}
</style>

