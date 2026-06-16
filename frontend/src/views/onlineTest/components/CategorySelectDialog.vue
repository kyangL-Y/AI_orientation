<template>
  <el-dialog
    v-model="open"
    title="选择专项题库"
    width="92%"
    class="mobile-category-dialog"
    :show-close="true"
  >
    <div class="mb-4">
      <div class="relative">
        <input
          v-model="query"
          type="text"
          placeholder="搜索题库..."
          class="w-full bg-slate-50 border border-slate-200 rounded-xl pl-10 pr-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
        >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 absolute left-3.5 top-3 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      </div>
    </div>

    <div class="max-h-[55vh] overflow-y-auto -mx-2 px-2">
      <div v-if="deptCategoryGroups.length > 0" class="mb-4">
        <div
          @click="deptExpanded = !deptExpanded"
          class="flex items-center gap-2 mb-2 px-1 cursor-pointer hover:bg-slate-50 rounded-lg py-1.5 -mx-1 transition-colors"
        >
          <div class="w-6 h-6 rounded-md bg-emerald-100 flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
          <span class="text-xs font-bold text-slate-600 flex-1">部门课程专项</span>
          <span class="text-xs text-slate-400">({{ filteredDeptCategories.length }})</span>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4 text-slate-400 transition-transform duration-200"
            :class="deptExpanded ? 'rotate-180' : ''"
            fill="none" viewBox="0 0 24 24" stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </div>

        <div v-show="deptExpanded" class="space-y-2">
          <div
            @click="select(deptAllCategory)"
            class="flex items-center justify-between p-3 rounded-xl cursor-pointer transition-all"
            :class="activeCategory === deptAllCategory.id ? 'bg-emerald-50 ring-2 ring-emerald-500' : 'bg-white border border-slate-100 active:bg-slate-50'"
          >
            <div class="flex items-center gap-2.5 min-w-0">
              <div
                class="w-8 h-8 rounded-lg flex items-center justify-center text-xs font-bold shrink-0"
                :class="activeCategory === deptAllCategory.id ? 'bg-emerald-500 text-white' : 'bg-emerald-50 text-emerald-500'"
              >
                全
              </div>
              <span class="text-sm font-bold truncate" :class="activeCategory === deptAllCategory.id ? 'text-emerald-700' : 'text-slate-700'">{{ deptAllCategory.name }}</span>
            </div>
            <span class="text-xs px-2 py-1 rounded-md font-medium shrink-0"
                  :class="activeCategory === deptAllCategory.id ? 'bg-emerald-200 text-emerald-800' : 'bg-slate-100 text-slate-500'">
              {{ deptAllCategory.count }}题
            </span>
          </div>
          <div v-for="group in deptCategoryGroups" :key="group.id" class="space-y-1.5">
            <div class="flex items-center justify-between px-1">
              <span class="text-[11px] font-bold text-slate-400">{{ group.name }}</span>
              <span class="text-[10px] px-1.5 py-0.5 rounded bg-emerald-50 text-emerald-600">{{ group.count }}题</span>
            </div>
            <div
              v-for="category in group.children"
              :key="category.id"
              @click="select(category)"
              class="flex items-center justify-between p-3 rounded-xl cursor-pointer transition-all"
              :class="activeCategory === category.id ? 'bg-emerald-50 ring-2 ring-emerald-500' : 'bg-white border border-slate-100 active:bg-slate-50'"
            >
              <div class="flex items-center gap-2.5 min-w-0">
                <div class="w-8 h-8 rounded-lg flex items-center justify-center shrink-0"
                     :class="activeCategory === category.id ? 'bg-emerald-500 text-white' : 'bg-emerald-50 text-emerald-500'">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
                  </svg>
                </div>
                <span class="text-sm font-medium truncate" :class="activeCategory === category.id ? 'text-emerald-700' : 'text-slate-700'">{{ category.name }}</span>
              </div>
              <span class="text-xs px-2 py-1 rounded-md font-medium shrink-0"
                    :class="activeCategory === category.id ? 'bg-emerald-200 text-emerald-800' : 'bg-slate-100 text-slate-500'">
                {{ category.count }}题
              </span>
            </div>
          </div>
        </div>
      </div>

      <div v-if="filteredOtaCategories.length > 0">
        <div
          @click="otaExpanded = !otaExpanded"
          class="flex items-center gap-2 mb-2 px-1 cursor-pointer hover:bg-slate-50 rounded-lg py-1.5 -mx-1 transition-colors"
        >
          <div class="w-6 h-6 rounded-md bg-indigo-100 flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
            </svg>
          </div>
          <span class="text-xs font-bold text-slate-600 flex-1">OTA平台</span>
          <span class="text-xs text-slate-400">({{ filteredOtaCategories.length }})</span>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4 text-slate-400 transition-transform duration-200"
            :class="otaExpanded ? 'rotate-180' : ''"
            fill="none" viewBox="0 0 24 24" stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </div>

        <div v-show="otaExpanded" class="space-y-2">
          <div v-for="group in otaCategoryGroups" :key="group.id" class="space-y-1.5">
            <div class="px-1 flex items-center justify-between text-[11px] font-bold text-slate-400">
              <span>{{ group.name }}</span>
              <span>{{ group.children.length }}项 / {{ group.count }}题</span>
            </div>
            <div
              v-for="category in group.children"
              :key="category.id"
              @click="select(category)"
              class="flex items-center justify-between p-3 rounded-xl cursor-pointer transition-all"
              :class="activeCategory === category.id ? 'bg-indigo-50 ring-2 ring-indigo-500' : 'bg-white border border-slate-100 active:bg-slate-50'"
            >
              <div class="flex items-center gap-2.5 min-w-0">
                <div class="w-8 h-8 rounded-lg flex items-center justify-center shrink-0"
                     :class="activeCategory === category.id ? 'bg-indigo-500 text-white' : 'bg-indigo-50 text-indigo-500'">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
                  </svg>
                </div>
                <span class="text-sm font-medium truncate" :class="activeCategory === category.id ? 'text-indigo-700' : 'text-slate-700'">{{ category.name }}</span>
              </div>
              <span class="text-xs px-2 py-1 rounded-md font-medium shrink-0"
                    :class="activeCategory === category.id ? 'bg-indigo-200 text-indigo-800' : 'bg-slate-100 text-slate-500'">
                {{ category.count }}题
              </span>
            </div>
          </div>
        </div>
      </div>

      <div v-if="filteredCultureCategories.length > 0" class="mb-4">
        <div
          @click="cultureExpanded = !cultureExpanded"
          class="flex items-center gap-2 mb-2 px-1 cursor-pointer hover:bg-slate-50 rounded-lg py-1.5 -mx-1 transition-colors"
        >
          <div class="w-6 h-6 rounded-md bg-purple-100 flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
          <span class="text-xs font-bold text-slate-600 flex-1">企业文化</span>
          <span class="text-xs text-slate-400">({{ filteredCultureCategories.length }})</span>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4 text-slate-400 transition-transform duration-200"
            :class="cultureExpanded ? 'rotate-180' : ''"
            fill="none" viewBox="0 0 24 24" stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </div>

        <div v-show="cultureExpanded" class="space-y-1.5">
          <div
            v-for="category in filteredCultureCategories"
            :key="category.id"
            @click="select(category)"
            class="flex items-center justify-between p-3 rounded-xl cursor-pointer transition-all"
            :class="activeCategory === category.id ? 'bg-purple-50 ring-2 ring-purple-500' : 'bg-white border border-slate-100 active:bg-slate-50'"
          >
            <div class="flex items-center gap-2.5">
              <div class="w-8 h-8 rounded-lg flex items-center justify-center"
                   :class="activeCategory === category.id ? 'bg-purple-500 text-white' : 'bg-purple-50 text-purple-500'">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
                </svg>
              </div>
              <span class="text-sm font-medium" :class="activeCategory === category.id ? 'text-purple-700' : 'text-slate-700'">{{ category.name }}</span>
            </div>
            <span class="text-xs px-2 py-1 rounded-md font-medium"
                  :class="activeCategory === category.id ? 'bg-purple-200 text-purple-800' : 'bg-slate-100 text-slate-500'">
              {{ category.count }}题
            </span>
          </div>
        </div>
      </div>

      <!-- 绿色饭店题库 -->
      <div v-if="filteredGreenHotelCategories.length > 0" class="mb-4">
        <div
          @click="greenHotelExpanded = !greenHotelExpanded"
          class="flex items-center gap-2 mb-2 px-1 cursor-pointer hover:bg-slate-50 rounded-lg py-1.5 -mx-1 transition-colors"
        >
          <div class="w-6 h-6 rounded-md bg-teal-100 flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-teal-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <span class="text-xs font-bold text-slate-600 flex-1">绿色饭店</span>
          <span class="text-xs text-slate-400">({{ filteredGreenHotelCategories.length }})</span>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4 text-slate-400 transition-transform duration-200"
            :class="greenHotelExpanded ? 'rotate-180' : ''"
            fill="none" viewBox="0 0 24 24" stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </div>

        <div v-show="greenHotelExpanded" class="space-y-2">
          <div v-for="group in greenHotelCategoryGroups" :key="group.id" class="space-y-1.5">
            <div class="px-1 flex items-center justify-between text-[11px] font-bold text-slate-400">
              <span>{{ group.name }}</span>
              <span>{{ group.children.length }}项 / {{ group.count }}题</span>
            </div>
            <div
              v-for="category in group.children"
              :key="category.id"
              @click="select(category)"
              class="flex items-center justify-between p-3 rounded-xl cursor-pointer transition-all"
              :class="activeCategory === category.id ? 'bg-teal-50 ring-2 ring-teal-500' : 'bg-white border border-slate-100 active:bg-slate-50'"
            >
              <div class="flex items-center gap-2.5 min-w-0">
                <div class="w-8 h-8 rounded-lg flex items-center justify-center shrink-0"
                     :class="activeCategory === category.id ? 'bg-teal-500 text-white' : 'bg-teal-50 text-teal-500'">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
                  </svg>
                </div>
                <span class="text-sm font-medium truncate" :class="activeCategory === category.id ? 'text-teal-700' : 'text-slate-700'">{{ category.name }}</span>
              </div>
              <span class="text-xs px-2 py-1 rounded-md font-medium shrink-0"
                    :class="activeCategory === category.id ? 'bg-teal-200 text-teal-800' : 'bg-slate-100 text-slate-500'">
                {{ category.count }}题
              </span>
            </div>
          </div>
        </div>
      </div>

      <div v-if="deptCategoryGroups.length === 0 && filteredOtaCategories.length === 0 && filteredCultureCategories.length === 0 && filteredGreenHotelCategories.length === 0" class="text-center py-10">
        <div class="w-16 h-16 mx-auto mb-4 bg-slate-100 rounded-full flex items-center justify-center">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </div>
        <p class="text-slate-400 text-sm">没有找到相关题库</p>
      </div>
    </div>
  </el-dialog>
</template>

<script setup>
import { computed, ref } from 'vue'

const greenHotelExpanded = ref(true)
const cultureExpanded = ref(true)

const props = defineProps({
  modelValue: {
    type: Boolean,
    required: true,
  },
  searchQuery: {
    type: String,
    default: '',
  },
  filteredDeptCategories: {
    type: Array,
    default: () => [],
  },
  deptAllCategory: {
    type: Object,
    required: true,
  },
  deptCategoryGroups: {
    type: Array,
    default: () => [],
  },
  filteredOtaCategories: {
    type: Array,
    default: () => [],
  },
  otaCategoryGroups: {
    type: Array,
    default: () => [],
  },
  cultureCategories: {
    type: Array,
    default: () => [],
  },
  greenHotelCategories: {
    type: Array,
    default: () => [],
  },
  greenHotelCategoryGroups: {
    type: Array,
    default: () => [],
  },
  deptSectionExpanded: {
    type: Boolean,
    default: false,
  },
  otaSectionExpanded: {
    type: Boolean,
    default: false,
  },
  activeCategory: {
    type: [String, Number, Object],
    default: null,
  },
})

const emit = defineEmits([
  'update:modelValue',
  'update:searchQuery',
  'update:deptSectionExpanded',
  'update:otaSectionExpanded',
  'selectCategory',
])

const open = computed({
  get: () => props.modelValue,
  set: (v) => emit('update:modelValue', v),
})

const query = computed({
  get: () => props.searchQuery,
  set: (v) => emit('update:searchQuery', v),
})

const deptExpanded = computed({
  get: () => props.deptSectionExpanded,
  set: (v) => emit('update:deptSectionExpanded', v),
})

const otaExpanded = computed({
  get: () => props.otaSectionExpanded,
  set: (v) => emit('update:otaSectionExpanded', v),
})

const filteredGreenHotelCategories = computed(() => {
  if (!props.searchQuery) return props.greenHotelCategories;
  const lower = props.searchQuery.toLowerCase();
  return props.greenHotelCategories.filter(c => c.name.toLowerCase().includes(lower));
})

const filteredCultureCategories = computed(() => {
  if (!props.searchQuery) return props.cultureCategories;
  const lower = props.searchQuery.toLowerCase();
  return props.cultureCategories.filter(c => c.name.toLowerCase().includes(lower));
})

const select = (category) => {
  emit('selectCategory', category)
  open.value = false
}
</script>

