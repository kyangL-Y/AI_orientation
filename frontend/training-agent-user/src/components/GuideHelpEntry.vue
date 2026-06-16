<template>
  <div class="guide-help-entry" ref="rootRef">
    <button
      type="button"
      class="guide-help-btn"
      data-guide="guide-help-entry"
      @click.stop="togglePanel"
    >
      <i class="fas fa-circle-question"></i>
      <span class="guide-help-text">引导</span>
    </button>

    <teleport to="body">
      <div
        v-if="state.panelOpen"
        class="guide-help-panel"
        :class="{ 'is-mobile': isMobileViewport }"
        :style="panelStyle"
        @click.stop
      >
        <div class="guide-help-header">
          <div>
            <div class="guide-help-title">新手引导</div>
            <p class="guide-help-subtitle">按模块分批上线，当前已开放 {{ groupedModules.length }} 个引导模块。</p>
          </div>
          <div class="guide-help-header-actions">
            <button class="guide-help-reset-all" type="button" @click="handleResetAll">重置全部</button>
            <button class="guide-help-close" type="button" @click="closePanel()">
              <i class="fas fa-times"></i>
            </button>
          </div>
        </div>

        <div v-for="module in groupedModules" :key="module.id" class="guide-help-module">
          <div class="guide-help-module-head">
            <div class="guide-help-module-title">{{ module.title }}</div>
            <div class="guide-help-module-desc">{{ module.description }}</div>
          </div>

          <div
            v-for="scenario in module.items"
            :key="scenario.id"
            class="guide-help-scenario"
          >
            <div class="guide-help-scenario-main">
              <div class="guide-help-scenario-title">
                {{ scenario.title }}
                <span v-if="isScenarioCompleted(scenario.id)" class="guide-help-done">已完成</span>
              </div>
              <div class="guide-help-scenario-desc">{{ scenario.description }}</div>
            </div>
            <div class="guide-help-actions">
              <button
                v-if="isScenarioCompleted(scenario.id)"
                class="guide-help-reset"
                type="button"
                @click="handleReset(scenario.id)"
              >
                重置
              </button>
              <button class="guide-help-action" type="button" @click="handleStart(scenario.id)">
                {{ isScenarioCompleted(scenario.id) ? '重新开始' : '开始引导' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </teleport>
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { useGuideTour } from '@/composables/useGuideTour'

const MOBILE_BREAKPOINT = 768

const {
  state,
  groupedModules,
  isScenarioCompleted,
  restartScenario,
  closePanel,
  openPanel,
  togglePanel: toggleTourPanel,
  resetScenarioState,
  resetAllScenarioStates
} = useGuideTour()
const rootRef = ref(null)
const panelStyle = ref({})
const isMobileViewport = ref(false)

const syncViewportMode = () => {
  if (typeof window === 'undefined') {
    return
  }
  const visualViewport = window.visualViewport
  isMobileViewport.value = Math.round(visualViewport?.width || window.innerWidth) <= MOBILE_BREAKPOINT
}

const updatePanelStyle = () => {
  syncViewportMode()
  if (!rootRef.value) {
    return
  }
  if (isMobileViewport.value) {
    panelStyle.value = {
      position: 'fixed',
      left: '8px',
      right: '8px',
      top: 'auto',
      bottom: 'calc(8px + env(safe-area-inset-bottom, 0px))',
      zIndex: 1200
    }
    return
  }
  const rect = rootRef.value.getBoundingClientRect()
  panelStyle.value = {
    position: 'fixed',
    top: `${rect.bottom + 10}px`,
    right: `${Math.max(16, window.innerWidth - rect.right)}px`,
    zIndex: 1200
  }
}

const togglePanel = () => {
  updatePanelStyle()
  toggleTourPanel()
}

const handleOpenPanel = () => {
  updatePanelStyle()
  openPanel()
}

const handleStart = async (scenarioId) => {
  closePanel()
  await restartScenario(scenarioId)
}

const handleReset = async (scenarioId) => {
  await resetScenarioState(scenarioId)
}

const handleResetAll = async () => {
  await resetAllScenarioStates()
}

const handleOutsideClick = (event) => {
  if (!state.panelOpen) {
    return
  }
  if (!rootRef.value?.contains(event.target) && !event.target.closest('.guide-help-panel')) {
    closePanel()
  }
}

onMounted(() => {
  syncViewportMode()
  window.addEventListener('resize', updatePanelStyle)
  window.visualViewport?.addEventListener('resize', updatePanelStyle)
  window.visualViewport?.addEventListener('scroll', updatePanelStyle)
  window.addEventListener('guide:open-panel', handleOpenPanel)
  document.addEventListener('click', handleOutsideClick)
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', updatePanelStyle)
  window.visualViewport?.removeEventListener('resize', updatePanelStyle)
  window.visualViewport?.removeEventListener('scroll', updatePanelStyle)
  window.removeEventListener('guide:open-panel', handleOpenPanel)
  document.removeEventListener('click', handleOutsideClick)
})
</script>

<style scoped>
.guide-help-entry {
  position: relative;
}

.guide-help-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  border: 1px solid #dbeafe;
  background: #eff6ff;
  color: #2563eb;
  padding: 8px 14px;
  border-radius: 999px;
  font-size: 0.85rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.guide-help-btn:hover {
  background: #dbeafe;
  border-color: #93c5fd;
}

.guide-help-panel {
  width: min(400px, calc(100vw - 24px));
  max-height: min(72vh, 720px);
  overflow-y: auto;
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 18px;
  box-shadow: 0 24px 60px rgba(15, 23, 42, 0.18);
  padding: 18px;
  scrollbar-gutter: stable;
  overscroll-behavior: contain;
}

.guide-help-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
  margin-bottom: 16px;
  position: sticky;
  top: -18px;
  background: #fff;
  z-index: 1;
  padding: 2px 0 12px;
}

.guide-help-header > div:first-child {
  flex: 1;
  min-width: 0;
}

.guide-help-header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}

.guide-help-title {
  font-size: 1rem;
  font-weight: 700;
  color: #111827;
}

.guide-help-subtitle {
  margin: 4px 0 0;
  font-size: 0.8rem;
  color: #6b7280;
  line-height: 1.5;
}

.guide-help-close {
  width: 32px;
  height: 32px;
  border: none;
  background: transparent;
  color: #9ca3af;
  cursor: pointer;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.guide-help-reset-all {
  border: none;
  background: #f8fafc;
  color: #64748b;
  border-radius: 999px;
  min-width: 76px;
  padding: 8px 12px;
  font-size: 0.74rem;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
}

.guide-help-module + .guide-help-module {
  margin-top: 18px;
}

.guide-help-module-head {
  margin-bottom: 12px;
}

.guide-help-module-title {
  font-size: 0.88rem;
  font-weight: 700;
  color: #1f2937;
}

.guide-help-module-desc {
  font-size: 0.75rem;
  color: #6b7280;
  margin-top: 2px;
}

.guide-help-scenario {
  display: flex;
  align-items: stretch;
  justify-content: space-between;
  gap: 12px;
  border: 1px solid #f1f5f9;
  border-radius: 14px;
  padding: 12px;
  background: #f8fafc;
}

.guide-help-scenario + .guide-help-scenario {
  margin-top: 8px;
}

.guide-help-scenario-main {
  flex: 1;
  min-width: 0;
}

.guide-help-scenario-title {
  font-size: 0.85rem;
  font-weight: 700;
  color: #111827;
  display: flex;
  align-items: center;
  gap: 8px;
}

.guide-help-done {
  font-size: 0.7rem;
  color: #047857;
  background: #d1fae5;
  border-radius: 999px;
  padding: 2px 8px;
}

.guide-help-scenario-desc {
  font-size: 0.75rem;
  color: #6b7280;
  margin-top: 4px;
  line-height: 1.5;
  word-break: break-word;
}

.guide-help-action {
  min-width: 88px;
  border: none;
  background: #2563eb;
  color: #fff;
  border-radius: 999px;
  padding: 9px 14px;
  font-size: 0.78rem;
  font-weight: 600;
  cursor: pointer;
}

.guide-help-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  align-self: center;
  flex-shrink: 0;
}

.guide-help-reset {
  min-width: 68px;
  border: none;
  background: #eef2ff;
  color: #4f46e5;
  border-radius: 999px;
  padding: 9px 12px;
  font-size: 0.76rem;
  font-weight: 600;
  cursor: pointer;
}

@media (max-width: 768px) {
  .guide-help-panel {
    width: auto;
    max-height: min(62dvh, 560px);
    padding: 14px 14px calc(12px + env(safe-area-inset-bottom, 0px));
    border-radius: 22px;
    box-shadow: 0 18px 42px rgba(15, 23, 42, 0.18);
  }

  .guide-help-text {
    display: none;
  }

  .guide-help-btn {
    width: 38px;
    height: 38px;
    justify-content: center;
    padding: 0;
    border-radius: 50%;
  }

  .guide-help-header {
    gap: 10px;
    top: -14px;
    padding-bottom: 10px;
  }

  .guide-help-reset-all {
    min-width: 0;
    padding: 7px 10px;
    font-size: 0.72rem;
  }

  .guide-help-close {
    width: 28px;
    height: 28px;
  }

  .guide-help-title {
    font-size: 0.95rem;
  }

  .guide-help-subtitle {
    font-size: 0.74rem;
    line-height: 1.4;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .guide-help-module + .guide-help-module {
    margin-top: 14px;
  }

  .guide-help-module-head {
    margin-bottom: 8px;
  }

  .guide-help-module-desc {
    font-size: 0.72rem;
  }

  .guide-help-scenario {
    flex-direction: column;
    gap: 10px;
    padding: 10px;
  }

  .guide-help-actions {
    flex-direction: row;
    justify-content: flex-end;
    align-self: auto;
    width: 100%;
    flex-wrap: wrap;
    gap: 6px;
  }

  .guide-help-scenario-title {
    font-size: 0.82rem;
  }

  .guide-help-scenario-desc {
    font-size: 0.72rem;
    line-height: 1.45;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .guide-help-action,
  .guide-help-reset {
    width: auto;
    min-width: 0;
    padding: 8px 12px;
    font-size: 0.74rem;
  }
}
</style>
