import { reactive, computed } from 'vue'
import router from '@/router'
import guideScenarios, { guideModules } from '@/guide/scenarios'
import {
  completeGuideScenario,
  getGuideOnboardingStatus,
  resetAllGuideScenarios,
  resetGuideScenario
} from '@/api/guideOnboarding'

const COMPLETED_KEY = 'guide-tour-completed-v2'
const SESSION_KEY = 'guide-tour-session-state-v2'
const TARGET_PADDING = 10
const SCROLL_DELAY = 260
const SELECTOR_WAIT_MS = 6000
const GUARD_CHECK_INTERVAL = 240
const AUTO_START_GUIDE = false

const state = reactive({
  active: false,
  panelOpen: false,
  onboardingActive: false,
  scenarioId: null,
  stepIndex: 0,
  displayStepIndex: 0,
  loading: false,
  target: null,
  targetRect: null,
  currentPlacement: 'bottom',
  guardActive: false,
  guardSatisfied: true,
  guardMessage: '',
  guardType: null
})

const scenarioMap = new Map(guideScenarios.map((scenario) => [scenario.id, scenario]))
let listenersRegistered = false
let guardCleanupFns = []
let guardObserver = null
let guardInterval = null
const guardRuntimeState = new Set()
const guardAutoAdvanceState = new Set()

function readStorage(key, fallback = {}) {
  if (typeof window === 'undefined') {
    return fallback
  }
  try {
    const raw = window.localStorage.getItem(key)
    return raw ? JSON.parse(raw) : fallback
  } catch {
    return fallback
  }
}

function writeStorage(key, value) {
  if (typeof window === 'undefined') {
    return
  }
  window.localStorage.setItem(key, JSON.stringify(value))
}

function parseStoredUserInfo() {
  if (typeof window === 'undefined') {
    return null
  }
  try {
    const raw = window.localStorage.getItem('userInfo')
    if (!raw) {
      return null
    }
    const parsed = JSON.parse(raw)
    return parsed && typeof parsed === 'object' ? parsed : null
  } catch {
    return null
  }
}

function getCurrentUserKey() {
  const user = parseStoredUserInfo()
  const userId = user?.userId ?? user?.id
  if (userId === null || userId === undefined || userId === '') {
    return 'guest'
  }
  return String(userId)
}

function isGuestUser() {
  return getCurrentUserKey() === 'guest'
}

function readScopedStorage(key, fallback = {}) {
  const all = readStorage(key, {})
  const userKey = getCurrentUserKey()
  return all[userKey] || fallback
}

function writeScopedStorage(key, value) {
  const all = readStorage(key, {})
  all[getCurrentUserKey()] = value
  writeStorage(key, all)
}

function readSessionState() {
  if (typeof window === 'undefined') {
    return {}
  }
  try {
    const raw = window.sessionStorage.getItem(SESSION_KEY)
    const all = raw ? JSON.parse(raw) : {}
    return all[getCurrentUserKey()] || {}
  } catch {
    return {}
  }
}

function writeSessionState(value) {
  if (typeof window === 'undefined') {
    return
  }
  let all = {}
  try {
    const raw = window.sessionStorage.getItem(SESSION_KEY)
    all = raw ? JSON.parse(raw) : {}
  } catch {
    all = {}
  }
  all[getCurrentUserKey()] = value
  window.sessionStorage.setItem(SESSION_KEY, JSON.stringify(all))
}

function getScenario(id) {
  return scenarioMap.get(id) || null
}

function getScenarioStep(scenario, index) {
  return scenario?.steps?.[index] || null
}

function getActiveStep(index = state.stepIndex) {
  return getScenarioStep(activeScenario.value, index)
}

function readGuideOnboardingFromUser() {
  return parseStoredUserInfo()?.guideOnboarding || null
}

function hasServerGuideState() {
  return !isGuestUser() && !!readGuideOnboardingFromUser()
}

function buildCompletedMapFromScenarios(scenarios = []) {
  return scenarios.reduce((accumulator, scenarioId) => {
    accumulator[scenarioId] = {
      completedAt: null
    }
    return accumulator
  }, {})
}

function getCompletedMap() {
  if (hasServerGuideState()) {
    return buildCompletedMapFromScenarios(readGuideOnboardingFromUser()?.completedScenarios || [])
  }
  if (!isGuestUser()) {
    return buildCompletedMapFromScenarios(guideScenarios.map((item) => item.id))
  }
  return readScopedStorage(COMPLETED_KEY, {})
}

function getCompletedScenarioCount() {
  if (hasServerGuideState()) {
    return Number(readGuideOnboardingFromUser()?.completedScenarioCount || 0)
  }
  if (!isGuestUser()) {
    return getTotalScenarioCount()
  }
  return Object.keys(getCompletedMap()).length
}

function getTotalScenarioCount() {
  if (hasServerGuideState()) {
    return Number(readGuideOnboardingFromUser()?.totalScenarioCount || guideScenarios.length)
  }
  return guideScenarios.length
}

function isOnboardingActive() {
  if (hasServerGuideState()) {
    return !!readGuideOnboardingFromUser()?.needsOnboarding
  }
  return false
}

function setOnboardingActive(active) {
  state.onboardingActive = !!active
}

function updateStoredUserGuideOnboarding(guideOnboarding) {
  if (typeof window === 'undefined' || isGuestUser()) {
    return false
  }
  const userInfo = parseStoredUserInfo()
  if (!userInfo) {
    return false
  }
  userInfo.guideOnboarding = guideOnboarding || null
  writeStorage('userInfo', userInfo)
  return true
}

function applyGuideOnboardingState(guideOnboarding) {
  if (!guideOnboarding) {
    setOnboardingActive(false)
    return null
  }
  updateStoredUserGuideOnboarding(guideOnboarding)
  setOnboardingActive(!!guideOnboarding.needsOnboarding)
  return guideOnboarding
}

async function fetchGuideOnboardingState() {
  if (isGuestUser()) {
    setOnboardingActive(false)
    return null
  }
  const response = await getGuideOnboardingStatus()
  const guideOnboarding = response?.data?.data || response?.data
  return applyGuideOnboardingState(guideOnboarding)
}

function syncOnboardingCompletionState() {
  if (isGuestUser()) {
    setOnboardingActive(false)
    return
  }
  setOnboardingActive(getCompletedScenarioCount() < getTotalScenarioCount())
}

function isScenarioCompleted(id) {
  return !!getCompletedMap()[id]
}

async function markScenarioCompleted(id) {
  if (!isGuestUser()) {
    const response = await completeGuideScenario(id)
    const guideOnboarding = response?.data?.data || response?.data
    applyGuideOnboardingState(guideOnboarding)
    return
  }
  const completed = getCompletedMap()
  completed[id] = {
    completedAt: new Date().toISOString()
  }
  writeScopedStorage(COMPLETED_KEY, completed)
  syncOnboardingCompletionState()
}

async function resetScenarioState(id) {
  if (!isGuestUser()) {
    const response = await resetGuideScenario(id)
    const guideOnboarding = response?.data?.data || response?.data
    applyGuideOnboardingState(guideOnboarding)
  } else {
    const completed = getCompletedMap()
    delete completed[id]
    writeScopedStorage(COMPLETED_KEY, completed)
  }

  const sessionState = readSessionState()
  delete sessionState[id]
  writeSessionState(sessionState)
}

async function resetAllScenarioStates() {
  if (!isGuestUser()) {
    const response = await resetAllGuideScenarios()
    const guideOnboarding = response?.data?.data || response?.data
    applyGuideOnboardingState(guideOnboarding)
  } else {
    writeScopedStorage(COMPLETED_KEY, {})
  }
  writeSessionState({})
  setOnboardingActive(!isGuestUser())
}

function markScenarioStartedThisSession(id) {
  const sessionState = readSessionState()
  sessionState[id] = true
  writeSessionState(sessionState)
}

function hasScenarioStartedThisSession(id) {
  return !!readSessionState()[id]
}

function resolveSelectors(step) {
  if (!step) {
    return []
  }
  if (Array.isArray(step.selectors)) {
    return step.selectors
  }
  if (step.selector) {
    return [step.selector]
  }
  return []
}

function resolveRoutePath(routeConfig) {
  if (!routeConfig) {
    return ''
  }
  if (typeof routeConfig === 'string') {
    return routeConfig
  }
  return routeConfig.path || ''
}

function normalizePath(path) {
  return typeof path === 'string' ? path.replace(/\/+$/, '') || '/' : ''
}

function splitPathSegments(path) {
  const normalized = normalizePath(path)
  if (normalized === '/') {
    return []
  }
  return normalized.split('/').filter(Boolean)
}

function isPathPattern(path) {
  return splitPathSegments(path).some((segment) => segment.startsWith(':'))
}

function matchesPathPattern(expectedPath, actualPath) {
  const expected = normalizePath(expectedPath)
  const actual = normalizePath(actualPath)

  if (!expected || !actual) {
    return false
  }

  if (expected === actual) {
    return true
  }

  const expectedSegments = splitPathSegments(expected)
  const actualSegments = splitPathSegments(actual)

  if (expectedSegments.length !== actualSegments.length) {
    return false
  }

  return expectedSegments.every((segment, index) => segment.startsWith(':') || segment === actualSegments[index])
}

function resolveGuard(step) {
  return step?.guard || null
}

function resolveGuardSelectors(step) {
  const guard = resolveGuard(step)
  if (!guard) {
    return []
  }
  if (Array.isArray(guard.selectors) && guard.selectors.length) {
    return guard.selectors
  }
  if (guard.selector) {
    return [guard.selector]
  }
  return resolveSelectors(step)
}

function resolveGuardPaths(guard) {
  if (!guard) {
    return []
  }
  if (Array.isArray(guard.paths)) {
    return guard.paths.map(resolveRoutePath).filter(Boolean)
  }
  if (guard.path) {
    return [resolveRoutePath(guard.path)]
  }
  return []
}

function matchesScenarioStartRoute(scenario, currentPath) {
  const firstStepRoute = resolveRoutePath(scenario?.steps?.[0]?.route)
  return firstStepRoute ? matchesPathPattern(firstStepRoute, currentPath) : false
}

function findNextAutoStartScenario(currentPath, options = {}) {
  const { ignoreSessionStarted = false } = options
  return guideScenarios.find((item) => {
    if (!item.autoStart || isScenarioCompleted(item.id)) {
      return false
    }
    if (!ignoreSessionStarted && hasScenarioStartedThisSession(item.id)) {
      return false
    }
    return matchesScenarioStartRoute(item, currentPath)
  })
}

function isVisibleElement(element) {
  if (!element) {
    return false
  }
  const style = window.getComputedStyle(element)
  const rect = element.getBoundingClientRect()
  return style.display !== 'none' && style.visibility !== 'hidden' && rect.width > 0 && rect.height > 0
}

function findTarget(step) {
  const selectors = resolveSelectors(step)
  for (const selector of selectors) {
    const elements = document.querySelectorAll(selector)
    for (const element of elements) {
      if (isVisibleElement(element)) {
        return element
      }
    }
  }
  return null
}

function findVisibleBySelectors(selectors = []) {
  for (const selector of selectors) {
    const elements = document.querySelectorAll(selector)
    for (const element of elements) {
      if (isVisibleElement(element)) {
        return element
      }
    }
  }
  return null
}

function delay(ms) {
  return new Promise((resolve) => {
    window.setTimeout(resolve, ms)
  })
}

function shouldForceStepRoute(step) {
  const stepPath = resolveRoutePath(step?.route)
  if (!stepPath) {
    return false
  }
  const guard = resolveGuard(step)
  if (!guard || guard.type !== 'route') {
    return true
  }
  const guardPaths = resolveGuardPaths(guard)
  if (!guardPaths.length) {
    return true
  }
  return guardPaths.every((path) => normalizePath(path) === normalizePath(stepPath))
}

async function ensureRoute(step) {
  if (!step?.route || !shouldForceStepRoute(step)) {
    return
  }
  const targetRoute = typeof step.route === 'string' ? { path: step.route } : step.route
  const targetPath = resolveRoutePath(step.route)
  const current = router.currentRoute.value
  if (matchesPathPattern(targetPath, current.path)) {
    return
  }
  if (isPathPattern(targetPath)) {
    return
  }
  await router.push(targetRoute)
  await router.isReady()
}

function updateTargetRect(target = state.target) {
  if (!target || !isVisibleElement(target)) {
    state.target = null
    state.targetRect = null
    return
  }
  const rect = target.getBoundingClientRect()
  state.target = target
  state.targetRect = {
    top: Math.max(rect.top - TARGET_PADDING, 8),
    left: Math.max(rect.left - TARGET_PADDING, 8),
    width: rect.width + TARGET_PADDING * 2,
    height: rect.height + TARGET_PADDING * 2
  }
}

function getStepRuntimeKey(step) {
  if (!step) {
    return ''
  }
  return `${state.scenarioId || 'unknown'}:${step.id || 'step'}:${state.stepIndex}`
}

function hasRuntimeGuardState(step) {
  const key = getStepRuntimeKey(step)
  return key ? guardRuntimeState.has(key) : false
}

function resetGuardRuntimeState() {
  guardRuntimeState.clear()
  guardAutoAdvanceState.clear()
}

function clearGuardWatchers() {
  guardCleanupFns.forEach((cleanup) => cleanup())
  guardCleanupFns = []
  if (guardObserver) {
    guardObserver.disconnect()
    guardObserver = null
  }
  if (guardInterval) {
    window.clearInterval(guardInterval)
    guardInterval = null
  }
  state.guardActive = false
  state.guardSatisfied = true
  state.guardMessage = ''
  state.guardType = null
}

function markGuardSatisfied(step = getActiveStep()) {
  state.guardSatisfied = true
  const key = getStepRuntimeKey(step)
  if (key) {
    guardRuntimeState.add(key)
  }
  maybeAutoAdvanceGuard(step)
}

function maybeAutoAdvanceGuard(step) {
  const guard = resolveGuard(step)
  const key = getStepRuntimeKey(step)
  if (!guard?.autoAdvance || !key || guardAutoAdvanceState.has(key)) {
    return
  }
  guardAutoAdvanceState.add(key)
  const delayMs = Number.isFinite(guard.autoAdvanceDelay) ? guard.autoAdvanceDelay : 240
  window.setTimeout(() => {
    if (!state.active || getActiveStep()?.id !== step?.id || !state.guardSatisfied) {
      return
    }
    nextStep()
  }, delayMs)
}

function resolveInputValue(element) {
  if (!element) {
    return ''
  }
  if ('value' in element) {
    return String(element.value || '')
  }
  if (element.isContentEditable) {
    return String(element.textContent || '')
  }
  return String(element.textContent || '')
}

function matchesSelectorTree(target, selectors = []) {
  if (!target) {
    return false
  }
  const element = target instanceof Element ? target : target.parentElement
  if (!element) {
    return false
  }
  return selectors.some((selector) => element.matches(selector) || !!element.closest(selector))
}

function evaluateGuard(step) {
  const guard = resolveGuard(step)
  if (!guard) {
    return true
  }

  if ((guard.type === 'click' || guard.type === 'event') && hasRuntimeGuardState(step)) {
    return true
  }

  if (guard.type === 'input') {
    return resolveGuardSelectors(step)
      .flatMap((selector) => Array.from(document.querySelectorAll(selector)))
      .some((element) => resolveInputValue(element).trim().length > 0)
  }

  if (guard.type === 'visible') {
    return !!findVisibleBySelectors(resolveGuardSelectors(step))
  }

  if (guard.type === 'route') {
    const guardPaths = resolveGuardPaths(guard)
    if (!guardPaths.length) {
      return false
    }
    const currentPath = router.currentRoute.value.path
    return guardPaths.some((path) => matchesPathPattern(path, currentPath))
  }

  return false
}

function setupStepGuard(step) {
  clearGuardWatchers()
  const guard = resolveGuard(step)
  if (!guard) {
    return
  }

  state.guardActive = true
  state.guardSatisfied = evaluateGuard(step)
  state.guardMessage = guard.message || '请先完成当前操作后再继续。'
  state.guardType = guard.type || 'custom'

  if (state.guardSatisfied) {
    maybeAutoAdvanceGuard(step)
    return
  }

  const guardSelectors = resolveGuardSelectors(step)

  if (guard.type === 'click') {
    const clickHandler = (event) => {
      if (matchesSelectorTree(event.target, guardSelectors)) {
        markGuardSatisfied(step)
      }
    }
    document.addEventListener('click', clickHandler, true)
    guardCleanupFns.push(() => document.removeEventListener('click', clickHandler, true))
    return
  }

  if (guard.type === 'input') {
    const inputHandler = (event) => {
      if (!matchesSelectorTree(event.target, guardSelectors)) {
        return
      }
      if (resolveInputValue(event.target).trim().length > 0) {
        markGuardSatisfied(step)
      }
    }
    document.addEventListener('input', inputHandler, true)
    document.addEventListener('change', inputHandler, true)
    guardCleanupFns.push(() => document.removeEventListener('input', inputHandler, true))
    guardCleanupFns.push(() => document.removeEventListener('change', inputHandler, true))
    return
  }

  if (guard.type === 'visible') {
    const evaluateVisible = () => {
      if (findVisibleBySelectors(guardSelectors)) {
        markGuardSatisfied(step)
      }
    }
    evaluateVisible()
    if (state.guardSatisfied) {
      return
    }
    if (document.body) {
      guardObserver = new MutationObserver(() => {
        evaluateVisible()
      })
      guardObserver.observe(document.body, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ['class', 'style', 'hidden', 'aria-hidden']
      })
    }
    guardInterval = window.setInterval(evaluateVisible, GUARD_CHECK_INTERVAL)
    return
  }

  if (guard.type === 'event' && guard.event) {
    const eventHandler = (event) => {
      if (guard.detailKey) {
        const actual = event?.detail?.[guard.detailKey]
        if (actual !== guard.detailValue) {
          return
        }
      }
      markGuardSatisfied(step)
    }
    window.addEventListener(guard.event, eventHandler)
    guardCleanupFns.push(() => window.removeEventListener(guard.event, eventHandler))
  }
}

async function syncCurrentStep({ instant = false, stepIndex = state.stepIndex } = {}) {
  const step = getActiveStep(stepIndex)
  if (!step) {
    clearGuardWatchers()
    return
  }

  state.loading = true
  try {
    await ensureRoute(step)
    let elapsed = 0
    let target = findTarget(step)
    while (!target && elapsed < SELECTOR_WAIT_MS) {
      await delay(150)
      elapsed += 150
      target = findTarget(step)
      if (evaluateGuard(step)) {
        break
      }
    }

    if (target) {
      target.scrollIntoView({
        behavior: instant ? 'auto' : 'smooth',
        block: 'center',
        inline: 'center'
      })
      if (!instant) {
        await delay(SCROLL_DELAY)
      }
      updateTargetRect(target)
    } else {
      state.target = null
      state.targetRect = null
    }

    state.currentPlacement = step.placement || 'bottom'
    setupStepGuard(step)
    state.displayStepIndex = stepIndex
  } finally {
    state.loading = false
  }
}

async function startScenario(id, options = {}) {
  const scenario = getScenario(id)
  if (!scenario) {
    return
  }
  resetGuardRuntimeState()
  clearGuardWatchers()
  state.panelOpen = false
  state.active = true
  state.scenarioId = id
  state.stepIndex = 0
  state.displayStepIndex = 0
  markScenarioStartedThisSession(id)
  await syncCurrentStep({ instant: true, stepIndex: 0 })
}

async function nextStep() {
  const scenario = activeScenario.value
  if (!scenario) {
    return false
  }
  if (state.guardActive && !state.guardSatisfied) {
    return false
  }
  if (state.stepIndex >= scenario.steps.length - 1) {
    await finishScenario()
    return true
  }
  const nextIndex = state.stepIndex + 1
  state.stepIndex = nextIndex
  await syncCurrentStep({ stepIndex: nextIndex })
  return true
}

async function prevStep() {
  if (state.stepIndex <= 0) {
    return
  }
  const prevIndex = state.stepIndex - 1
  state.stepIndex = prevIndex
  await syncCurrentStep({ stepIndex: prevIndex })
}

function closeTour() {
  clearGuardWatchers()
  resetGuardRuntimeState()
  state.active = false
  state.target = null
  state.targetRect = null
}

async function finishScenario() {
  const nextScenarioId = activeScenario.value?.nextScenarioId
  const currentPath = router.currentRoute.value.path
  const currentScenarioId = state.scenarioId
  if (state.scenarioId) {
    await markScenarioCompleted(state.scenarioId)
  }
  closeTour()
  if (!nextScenarioId || isScenarioCompleted(nextScenarioId) || hasScenarioStartedThisSession(nextScenarioId)) {
    if (isOnboardingActive()) {
      const nextRouteScenario = findNextAutoStartScenario(currentPath, { ignoreSessionStarted: true })
      if (nextRouteScenario && nextRouteScenario.id !== currentScenarioId) {
        window.setTimeout(() => {
          startScenario(nextRouteScenario.id)
        }, 260)
      }
    }
    return
  }
  window.setTimeout(() => {
    startScenario(nextScenarioId)
  }, 320)
}

function openPanel() {
  state.panelOpen = true
}

function closePanel() {
  state.panelOpen = false
}

function togglePanel() {
  state.panelOpen = !state.panelOpen
}

function restartScenario(id) {
  return startScenario(id, { manual: true })
}

function refreshTarget() {
  if (!state.active) {
    return
  }
  const step = getActiveStep()
  const target = findTarget(step)
  updateTargetRect(target)
}

async function handleIdentityChange() {
  closeTour()
  closePanel()
  if (isGuestUser()) {
    setOnboardingActive(false)
  } else {
    const guideOnboarding = await fetchGuideOnboardingState()
    if (guideOnboarding?.needsOnboarding) {
      writeSessionState({})
    }
  }
  await maybeAutoStart()
}

const activeScenario = computed(() => getScenario(state.scenarioId))
const currentStep = computed(() => getScenarioStep(activeScenario.value, state.displayStepIndex))
const stepProgress = computed(() => {
  const total = activeScenario.value?.steps?.length || 0
  return {
    current: total ? state.displayStepIndex + 1 : 0,
    total
  }
})
const canGoNext = computed(() => !state.guardActive || state.guardSatisfied)
const groupedModules = computed(() => {
  return guideModules.map((module) => ({
    ...module,
    items: module.scenarios
      .map((scenarioId) => getScenario(scenarioId))
      .filter(Boolean)
  }))
})

function registerListeners() {
  if (listenersRegistered || typeof window === 'undefined') {
    return
  }
  listenersRegistered = true
  const refresh = () => refreshTarget()
  window.addEventListener('resize', refresh)
  window.addEventListener('scroll', refresh, true)
  router.afterEach(() => {
    if (state.active) {
      window.requestAnimationFrame(() => {
        syncCurrentStep({ instant: true, stepIndex: state.stepIndex })
      })
      return
    }
    window.requestAnimationFrame(() => {
      maybeAutoStart()
    })
  })
}

async function maybeAutoStart() {
  registerListeners()
  if (!AUTO_START_GUIDE) {
    return
  }
  const currentPath = router.currentRoute.value.path
  const scenario = findNextAutoStartScenario(currentPath)
  if (!scenario) {
    return
  }
  await delay(900)
  await startScenario(scenario.id)
}

state.onboardingActive = isOnboardingActive()
registerListeners()

export function emitGuideEvent(name, detail = {}) {
  if (typeof window === 'undefined') {
    return
  }
  window.dispatchEvent(new CustomEvent(name, { detail }))
}

export function useGuideTour() {
  return {
    state,
    activeScenario,
    currentStep,
    stepProgress,
    groupedModules,
    canGoNext,
    isScenarioCompleted,
    startScenario,
    restartScenario,
    nextStep,
    prevStep,
    closeTour,
    finishScenario,
    openPanel,
    closePanel,
    togglePanel,
    maybeAutoStart,
    refreshTarget,
    resetScenarioState,
    resetAllScenarioStates,
    handleIdentityChange
  }
}
