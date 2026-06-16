<template>
  <teleport to="body">
    <div v-if="state.active" class="guide-tour-layer">
      <div
        v-if="state.targetRect"
        class="guide-tour-focus"
        :style="focusStyle"
      ></div>
      <div v-else class="guide-tour-mask"></div>

      <div ref="cardRef" class="guide-tour-card" :style="cardStyle">
        <button
          type="button"
          class="guide-tour-close"
          @click="closeTour()"
        >
          <i class="fas fa-times"></i>
        </button>

        <div class="guide-tour-content">
          <div class="guide-tour-progress">
            <span>{{ activeScenario?.title }}</span>
            <strong>{{ stepProgress.current }}/{{ stepProgress.total }}</strong>
          </div>

          <h3 class="guide-tour-title">{{ currentStep?.title }}</h3>
          <p class="guide-tour-description">
            {{ currentStep?.description }}
          </p>

          <div v-if="state.guardActive" class="guide-tour-guard" :class="{ ready: state.guardSatisfied }">
            <i class="fas" :class="state.guardSatisfied ? 'fa-circle-check' : 'fa-hand-pointer'"></i>
            <span>{{ state.guardSatisfied ? '当前步骤已完成，可以继续。' : state.guardMessage }}</span>
          </div>

          <div v-if="state.onboardingActive" class="guide-tour-onboarding-tip">
            <i class="fas fa-route"></i>
            <span>当前为首次登录引导，请按步骤完成本轮流程。</span>
          </div>
        </div>

        <div class="guide-tour-actions">
          <button
            type="button"
            class="guide-tour-btn guide-tour-btn-secondary"
            :disabled="stepProgress.current <= 1"
            @click="prevStep()"
          >
            上一步
          </button>
          <button
            type="button"
            class="guide-tour-btn guide-tour-btn-tertiary"
            @click="closeTour()"
          >
            {{ state.onboardingActive ? '关闭引导' : '稍后再看' }}
          </button>
          <button
            type="button"
            class="guide-tour-btn guide-tour-btn-primary"
            :disabled="!canGoNext"
            @click="handleNext"
          >
            {{ isLastStep ? '完成引导' : '下一步' }}
          </button>
        </div>

        <div
          v-if="state.targetRect && !isMobileViewport"
          class="guide-tour-arrow"
          :class="`is-${resolvedPlacement}`"
        ></div>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
import { useGuideTour } from '@/composables/useGuideTour'

const {
  state,
  activeScenario,
  currentStep,
  stepProgress,
  canGoNext,
  prevStep,
  nextStep,
  closeTour,
  finishScenario,
  refreshTarget
} = useGuideTour()
const CARD_WIDTH = 320
const GAP = 18
const DEFAULT_CARD_HEIGHT = 220
const DESKTOP_VIEWPORT_GAP = 16
const MOBILE_VIEWPORT_GAP = 12
const MOBILE_BREAKPOINT = 768
const cardRef = ref(null)
const cardHeight = ref(DEFAULT_CARD_HEIGHT)
const viewport = reactive({
  width: typeof window === 'undefined' ? CARD_WIDTH : window.innerWidth,
  height: typeof window === 'undefined' ? DEFAULT_CARD_HEIGHT : window.innerHeight
})

const isLastStep = computed(() => stepProgress.value.current === stepProgress.value.total)
const isMobileViewport = computed(() => viewport.width <= MOBILE_BREAKPOINT)
const cardWidth = computed(() => {
  const horizontalGap = isMobileViewport.value ? MOBILE_VIEWPORT_GAP * 2 : DESKTOP_VIEWPORT_GAP * 2
  return Math.max(0, Math.min(CARD_WIDTH, viewport.width - horizontalGap))
})
const maxCardHeight = computed(() => {
  const verticalGap = isMobileViewport.value ? MOBILE_VIEWPORT_GAP * 2 : DESKTOP_VIEWPORT_GAP * 2
  return Math.max(DEFAULT_CARD_HEIGHT, viewport.height - verticalGap)
})

const syncViewportMetrics = () => {
  if (typeof window === 'undefined') {
    return
  }
  const visualViewport = window.visualViewport
  viewport.width = Math.round(visualViewport?.width || window.innerWidth)
  viewport.height = Math.round(visualViewport?.height || window.innerHeight)
}

const syncCardMetrics = async () => {
  await nextTick()
  if (!cardRef.value) {
    cardHeight.value = DEFAULT_CARD_HEIGHT
    return
  }
  cardHeight.value = Math.max(DEFAULT_CARD_HEIGHT, Math.ceil(cardRef.value.getBoundingClientRect().height))
}

const resolvedPlacement = computed(() => {
  if (isMobileViewport.value) {
    return 'bottom'
  }
  const placement = state.currentPlacement || 'bottom'
  if (!state.targetRect) {
    return 'bottom'
  }
  const viewportWidth = viewport.width
  const viewportHeight = viewport.height
  const rect = state.targetRect

  if (placement === 'right' && rect.left + rect.width + GAP + cardWidth.value > viewportWidth - DESKTOP_VIEWPORT_GAP) {
    return 'left'
  }
  if (placement === 'left' && rect.left - GAP - cardWidth.value < DESKTOP_VIEWPORT_GAP) {
    return 'bottom'
  }
  if (placement === 'top' && rect.top - GAP - cardHeight.value < DESKTOP_VIEWPORT_GAP) {
    return 'bottom'
  }
  if (placement === 'bottom' && rect.top + rect.height + GAP + cardHeight.value > viewportHeight - DESKTOP_VIEWPORT_GAP) {
    return 'top'
  }
  return placement
})

const focusStyle = computed(() => {
  const rect = state.targetRect
  if (!rect) {
    return {}
  }
  return {
    top: `${rect.top}px`,
    left: `${rect.left}px`,
    width: `${rect.width}px`,
    height: `${rect.height}px`
  }
})

const cardStyle = computed(() => {
  const rect = state.targetRect
  const viewportWidth = viewport.width
  const viewportHeight = viewport.height
  const horizontalGap = isMobileViewport.value ? MOBILE_VIEWPORT_GAP : DESKTOP_VIEWPORT_GAP

  if (isMobileViewport.value) {
    return {
      top: 'auto',
      left: `${horizontalGap}px`,
      right: `${horizontalGap}px`,
      bottom: `calc(${MOBILE_VIEWPORT_GAP}px + env(safe-area-inset-bottom, 0px))`,
      width: 'auto',
      maxHeight: `${maxCardHeight.value}px`
    }
  }

  if (!rect) {
    return {
      top: '50%',
      left: '50%',
      transform: 'translate(-50%, -50%)',
      width: `${cardWidth.value}px`,
      maxHeight: `${maxCardHeight.value}px`
    }
  }

  let top = rect.top
  let left = rect.left
  const placement = resolvedPlacement.value
  if (placement === 'bottom') {
    top = rect.top + rect.height + GAP
    left = rect.left + rect.width / 2 - cardWidth.value / 2
  } else if (placement === 'top') {
    top = rect.top - cardHeight.value - GAP
    left = rect.left + rect.width / 2 - cardWidth.value / 2
  } else if (placement === 'right') {
    top = rect.top + rect.height / 2 - cardHeight.value / 2
    left = rect.left + rect.width + GAP
  } else {
    top = rect.top + rect.height / 2 - cardHeight.value / 2
    left = rect.left - cardWidth.value - GAP
  }

  top = Math.max(DESKTOP_VIEWPORT_GAP, Math.min(top, viewportHeight - cardHeight.value - DESKTOP_VIEWPORT_GAP))
  left = Math.max(DESKTOP_VIEWPORT_GAP, Math.min(left, viewportWidth - cardWidth.value - DESKTOP_VIEWPORT_GAP))

  return {
    top: `${top}px`,
    left: `${left}px`,
    width: `${cardWidth.value}px`,
    maxHeight: `${maxCardHeight.value}px`
  }
})

const handleNext = async () => {
  if (isLastStep.value) {
    await finishScenario()
    return
  }
  await nextStep()
}

const refresh = () => {
  syncViewportMetrics()
  refreshTarget()
  syncCardMetrics()
}

onMounted(() => {
  refresh()
  window.addEventListener('resize', refresh)
  window.addEventListener('scroll', refresh, true)
  window.visualViewport?.addEventListener('resize', refresh)
  window.visualViewport?.addEventListener('scroll', refresh)
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', refresh)
  window.removeEventListener('scroll', refresh, true)
  window.visualViewport?.removeEventListener('resize', refresh)
  window.visualViewport?.removeEventListener('scroll', refresh)
})

watch(
  () => [
    state.active,
    state.stepIndex,
    state.targetRect?.top,
    state.targetRect?.left,
    state.guardSatisfied,
    state.guardMessage,
    state.onboardingActive,
    viewport.width,
    viewport.height
  ],
  () => {
    syncCardMetrics()
  },
  { immediate: true }
)
</script>

<style scoped>
.guide-tour-layer {
  position: fixed;
  inset: 0;
  z-index: 1400;
  pointer-events: none;
}

.guide-tour-mask {
  position: absolute;
  inset: 0;
  background: rgba(15, 23, 42, 0.58);
}

.guide-tour-focus {
  position: absolute;
  border-radius: 18px;
  box-shadow: 0 0 0 9999px rgba(15, 23, 42, 0.58);
  border: 2px solid rgba(255, 255, 255, 0.95);
  background: transparent;
  pointer-events: none;
  z-index: 1;
}

.guide-tour-card {
  position: fixed;
  width: min(320px, calc(100vw - 32px));
  max-height: calc(100vh - 32px);
  background: #fff;
  border-radius: 20px;
  padding: 18px 18px 16px;
  box-shadow: 0 28px 80px rgba(15, 23, 42, 0.25);
  pointer-events: auto;
  z-index: 2;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  transition: top 0.14s ease, left 0.14s ease;
}

.guide-tour-content {
  flex: 1 1 auto;
  min-height: 0;
  overflow-y: auto;
  padding-right: 4px;
}

.guide-tour-close {
  position: absolute;
  top: 12px;
  right: 12px;
  border: none;
  background: transparent;
  color: #94a3b8;
  cursor: pointer;
}

.guide-tour-progress {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  font-size: 0.78rem;
  color: #64748b;
  margin-bottom: 10px;
  padding-right: 18px;
}

.guide-tour-progress strong {
  color: #2563eb;
}

.guide-tour-title {
  margin: 0;
  font-size: 1.05rem;
  font-weight: 800;
  color: #0f172a;
}

.guide-tour-description {
  margin: 10px 0 0;
  color: #475569;
  line-height: 1.7;
  font-size: 0.9rem;
}

.guide-tour-actions {
  display: flex;
  gap: 8px;
  margin-top: 16px;
  padding-top: 14px;
  border-top: 1px solid #e2e8f0;
  background: #fff;
  flex-shrink: 0;
}

.guide-tour-guard {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  margin-top: 14px;
  padding: 10px 12px;
  border-radius: 14px;
  background: #eff6ff;
  color: #1d4ed8;
  font-size: 0.82rem;
  line-height: 1.6;
}

.guide-tour-guard.ready {
  background: #ecfdf5;
  color: #047857;
}

.guide-tour-onboarding-tip {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  margin-top: 12px;
  padding: 10px 12px;
  border-radius: 14px;
  background: #fff7ed;
  color: #c2410c;
  font-size: 0.82rem;
  line-height: 1.6;
}

.guide-tour-btn {
  border-radius: 999px;
  padding: 10px 14px;
  border: none;
  font-size: 0.82rem;
  font-weight: 700;
  cursor: pointer;
  transition: background-color 0.14s ease, color 0.14s ease, opacity 0.14s ease;
}

.guide-tour-btn-secondary {
  background: #e2e8f0;
  color: #334155;
}

.guide-tour-btn-secondary:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.guide-tour-btn-tertiary {
  background: #f8fafc;
  color: #64748b;
}

.guide-tour-btn-primary {
  margin-left: auto;
  background: #2563eb;
  color: #fff;
}

.guide-tour-btn-primary:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.guide-tour-arrow {
  position: absolute;
  width: 16px;
  height: 16px;
  background: #fff;
  transform: rotate(45deg);
}

.guide-tour-arrow.is-bottom {
  top: -8px;
  left: 50%;
  margin-left: -8px;
}

.guide-tour-arrow.is-top {
  bottom: -8px;
  left: 50%;
  margin-left: -8px;
}

.guide-tour-arrow.is-right {
  left: -8px;
  top: 50%;
  margin-top: -8px;
}

.guide-tour-arrow.is-left {
  right: -8px;
  top: 50%;
  margin-top: -8px;
}

@media (max-width: 768px) {
  .guide-tour-card {
    width: auto;
    max-height: calc(100dvh - 24px - env(safe-area-inset-top, 0px) - env(safe-area-inset-bottom, 0px));
    padding: 16px;
    padding-bottom: calc(16px + env(safe-area-inset-bottom, 0px));
    border-radius: 22px;
  }

  .guide-tour-content {
    padding-right: 2px;
  }

  .guide-tour-progress {
    align-items: flex-start;
  }

  .guide-tour-actions {
    flex-wrap: wrap;
    margin-top: 14px;
  }

  .guide-tour-btn {
    flex: 1 1 calc(50% - 4px);
    justify-content: center;
  }

  .guide-tour-btn-primary {
    margin-left: 0;
  }

  .guide-tour-arrow {
    display: none;
  }
}
</style>
