import { api } from '@/utils/api'

export const getGuideOnboardingStatus = () => {
  return api.get('/system/user/profile/guide-onboarding')
}

export const completeGuideScenario = (scenarioId) => {
  return api.post('/system/user/profile/guide-onboarding/complete', null, {
    params: { scenarioId }
  })
}

export const resetGuideScenario = (scenarioId) => {
  return api.post('/system/user/profile/guide-onboarding/reset', null, {
    params: { scenarioId }
  })
}

export const resetAllGuideScenarios = () => {
  return api.post('/system/user/profile/guide-onboarding/resetAll')
}
