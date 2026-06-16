<template>
  <div class="register-entry">
    <RegisterModal
      :show="true"
      :invite-code="inviteCode"
      :invite-token="inviteToken"
      @close="closePage"
      @to-login="closePage"
    />
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import RegisterModal from '@/components/modals/RegisterModal.vue'

const route = useRoute()
const router = useRouter()

const inviteCode = computed(() => String(route.query.inviteCode || ''))
const inviteToken = computed(() => String(route.query.inviteToken || ''))

const closePage = () => {
  router.replace('/study')
}
</script>

<style scoped>
.register-entry {
  min-height: 100vh;
}
</style>
