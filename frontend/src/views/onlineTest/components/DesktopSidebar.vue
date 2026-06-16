<template>
  <!-- 左侧侧边栏：导航与题库 -->
  <aside class="hidden lg:block lg:col-span-3 space-y-6 sticky top-24">
    <!-- 模式选择菜单 -->
    <div class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
      <div class="p-4 border-b border-slate-50">
        <h3 class="font-bold text-slate-700 text-sm">练习模式</h3>
      </div>
      <div class="p-2 space-y-1">
        <button
          @click="$emit('switchMode', 'daily')"
          class="w-full flex items-center gap-3 px-3 py-3 rounded-xl transition-all text-left group relative overflow-hidden"
          :class="currentMode === 'daily' ? 'bg-blue-50 text-blue-700 ring-1 ring-blue-100' : 'text-slate-600 hover:bg-slate-50'"
        >
          <div
            class="w-8 h-8 rounded-lg flex items-center justify-center transition-colors shrink-0"
            :class="currentMode === 'daily' ? 'bg-blue-500 text-white' : 'bg-blue-100 text-blue-500 group-hover:bg-blue-200'"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
              />
            </svg>
          </div>
          <span class="font-bold text-sm">每日一练</span>
          <div v-if="currentMode === 'daily'" class="absolute right-3 w-2 h-2 bg-blue-500 rounded-full"></div>
        </button>

        <button
          @click="$emit('switchMode', 'wrong')"
          class="w-full flex items-center gap-3 px-3 py-3 rounded-xl transition-all text-left group relative overflow-hidden"
          :class="currentMode === 'wrong' ? 'bg-rose-50 text-rose-700 ring-1 ring-rose-100' : 'text-slate-600 hover:bg-slate-50'"
        >
          <div
            class="w-8 h-8 rounded-lg flex items-center justify-center transition-colors shrink-0"
            :class="currentMode === 'wrong' ? 'bg-rose-500 text-white' : 'bg-rose-100 text-rose-500 group-hover:bg-rose-200'"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
              />
            </svg>
          </div>
          <span class="font-bold text-sm">我的错题</span>
          <div v-if="currentMode === 'wrong'" class="absolute right-3 w-2 h-2 bg-rose-500 rounded-full"></div>
        </button>

        <button
          @click="$emit('switchMode', 'fav')"
          class="w-full flex items-center gap-3 px-3 py-3 rounded-xl transition-all text-left group relative overflow-hidden"
          :class="currentMode === 'fav' ? 'bg-amber-50 text-amber-700 ring-1 ring-amber-100' : 'text-slate-600 hover:bg-slate-50'"
        >
          <div
            class="w-8 h-8 rounded-lg flex items-center justify-center transition-colors shrink-0"
            :class="currentMode === 'fav' ? 'bg-amber-500 text-white' : 'bg-amber-100 text-amber-500 group-hover:bg-amber-200'"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z"
              />
            </svg>
          </div>
          <span class="font-bold text-sm">收藏夹</span>
          <div v-if="currentMode === 'fav'" class="absolute right-3 w-2 h-2 bg-amber-500 rounded-full"></div>
        </button>

        <button
          @click="$emit('switchToFirstCategory')"
          class="w-full flex items-center gap-3 px-3 py-3 rounded-xl transition-all text-left group relative overflow-hidden"
          :class="currentMode === 'category' ? 'bg-indigo-50 text-indigo-700 ring-1 ring-indigo-100' : 'text-slate-600 hover:bg-slate-50'"
        >
          <div
            class="w-8 h-8 rounded-lg flex items-center justify-center transition-colors shrink-0"
            :class="currentMode === 'category' ? 'bg-indigo-500 text-white' : 'bg-indigo-100 text-indigo-500 group-hover:bg-indigo-200'"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
              />
            </svg>
          </div>
          <span class="font-bold text-sm">专项练习</span>
          <div v-if="currentMode === 'category'" class="absolute right-3 w-2 h-2 bg-indigo-500 rounded-full"></div>
        </button>
      </div>
    </div>

    <!-- 部门培训课程题库（可折叠） -->
    <div class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
      <div
        @click="$emit('update:deptCategoryExpanded', !deptCategoryExpanded)"
        class="p-4 flex justify-between items-center cursor-pointer hover:bg-slate-50 transition-colors"
      >
        <div class="flex items-center gap-2">
          <div class="w-8 h-8 rounded-lg bg-emerald-100 text-emerald-600 flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
              />
            </svg>
          </div>
          <div>
            <h3 class="font-bold text-slate-700 text-sm">部门课程题库</h3>
            <span class="text-xs text-slate-400">{{ deptCategoryGroups.length }} 类 / {{ deptCategories.length }} 个专项</span>
          </div>
        </div>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-4 w-4 text-slate-400 transition-transform"
          :class="deptCategoryExpanded ? 'rotate-180' : ''"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
        </svg>
      </div>
      <transition name="collapse">
        <div v-show="deptCategoryExpanded" class="border-t border-slate-100">
          <div v-if="deptCategories.length === 0" class="p-4 text-center text-slate-400 text-xs">
            暂无课程专项题库
          </div>
          <div v-else class="p-2 space-y-1 max-h-[200px] overflow-y-auto custom-scrollbar">
            <div
              @click="$emit('selectCategory', deptAllCategory)"
              class="group flex items-center justify-between px-3 py-2.5 rounded-xl cursor-pointer transition-all"
              :class="currentMode === 'category' && activeCategory === deptAllCategory.id ? 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-100' : 'text-slate-700 hover:bg-slate-50'"
            >
              <div class="flex items-center gap-3 min-w-0">
                <div
                  class="h-6 w-6 rounded-lg flex items-center justify-center text-xs font-bold"
                  :class="currentMode === 'category' && activeCategory === deptAllCategory.id ? 'bg-emerald-500 text-white' : 'bg-emerald-50 text-emerald-600'"
                >
                  全
                </div>
                <span class="text-sm font-bold truncate">{{ deptAllCategory.name }}</span>
              </div>
              <span
                class="text-[10px] px-1.5 py-0.5 rounded shrink-0 transition-colors"
                :class="currentMode === 'category' && activeCategory === deptAllCategory.id ? 'bg-emerald-200 text-emerald-800' : 'bg-slate-100 text-slate-500 group-hover:bg-white group-hover:text-emerald-600'"
              >
                {{ deptAllCategory.count }}
              </span>
            </div>
            <div v-for="group in deptCategoryGroups" :key="group.id" class="space-y-1">
              <div class="flex items-center justify-between px-3 pt-2 pb-1">
                <span class="text-[11px] font-bold text-slate-400 truncate">{{ group.name }}</span>
                <span class="text-[10px] px-1.5 py-0.5 rounded bg-emerald-50 text-emerald-600">{{ group.count }}</span>
              </div>
              <div
                v-for="category in group.children"
                :key="category.id"
                @click="$emit('selectCategory', category)"
                class="group flex items-center justify-between px-3 py-2.5 rounded-xl cursor-pointer transition-all"
                :class="currentMode === 'category' && activeCategory === category.id ? 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-100' : 'text-slate-600 hover:bg-slate-50'"
              >
                <div class="flex items-center gap-3 min-w-0">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-4 w-4 shrink-0 transition-colors"
                    :class="
                      currentMode === 'category' && activeCategory === category.id
                        ? 'text-emerald-500'
                        : 'text-slate-400 group-hover:text-emerald-500'
                    "
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"
                    />
                  </svg>
                  <span class="text-sm font-medium truncate">{{ category.name }}</span>
                </div>
                <span
                  class="text-[10px] px-1.5 py-0.5 rounded shrink-0 transition-colors"
                  :class="
                    currentMode === 'category' && activeCategory === category.id
                      ? 'bg-emerald-200 text-emerald-800'
                      : 'bg-slate-100 text-slate-500 group-hover:bg-white group-hover:text-emerald-600'
                  "
                >
                  {{ category.count }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </transition>
    </div>

    <!-- OTA专项题库（可折叠） -->
    <div
      v-if="questionBankScope === 'all'"
      class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden flex-1 flex flex-col max-h-[400px]"
    >
      <div
        @click="$emit('update:otaCategoryExpanded', !otaCategoryExpanded)"
        class="p-4 flex justify-between items-center cursor-pointer hover:bg-slate-50 transition-colors shrink-0"
      >
        <div class="flex items-center gap-2">
          <div class="w-8 h-8 rounded-lg bg-indigo-100 text-indigo-600 flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9"
              />
            </svg>
          </div>
          <div>
            <h3 class="font-bold text-slate-700 text-sm">OTA专项题库</h3>
            <span class="text-xs text-slate-400">{{ otaCategories.length }} 个分类</span>
          </div>
        </div>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-4 w-4 text-slate-400 transition-transform"
          :class="otaCategoryExpanded ? 'rotate-180' : ''"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
        </svg>
      </div>
      <transition name="collapse">
        <div v-show="otaCategoryExpanded" class="border-t border-slate-100 flex-1 overflow-hidden flex flex-col">
          <div class="p-3 bg-slate-50/50 shrink-0">
            <div class="relative">
              <input
                :value="searchQuery"
                @input="$emit('update:searchQuery', $event.target.value)"
                type="text"
                placeholder="搜索分类..."
                class="w-full bg-white border border-slate-100 rounded-lg pl-8 pr-3 py-2 text-xs focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition-all"
              />
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-3.5 w-3.5 absolute left-2.5 top-2.5 text-slate-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
          </div>
          <div v-if="loadingCategories" class="p-4 space-y-3">
            <div v-for="i in 5" :key="i" class="h-8 bg-slate-100 rounded animate-pulse"></div>
          </div>
          <div v-else-if="otaCategories.length === 0" class="p-4 text-center text-slate-400 text-xs">
            暂无OTA题库
          </div>
          <div v-else class="p-2 space-y-2 overflow-y-auto custom-scrollbar flex-1">
            <div v-for="group in otaCategoryGroups" :key="group.id" class="space-y-1">
              <div class="px-3 py-1 flex items-center justify-between text-[11px] font-bold text-slate-400">
                <span class="truncate">{{ group.name }}</span>
                <span>{{ group.children.length }}项 / {{ group.count }}题</span>
              </div>
              <div
                v-for="category in group.children"
                :key="category.id"
                @click="$emit('selectCategory', category)"
                class="group flex items-center justify-between px-3 py-2.5 rounded-xl cursor-pointer transition-all"
                :class="currentMode === 'category' && activeCategory === category.id ? 'bg-indigo-50 text-indigo-700 ring-1 ring-indigo-100' : 'text-slate-600 hover:bg-slate-50'"
              >
                <div class="flex items-center gap-3 min-w-0">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 shrink-0 transition-colors" :class="currentMode === 'category' && activeCategory === category.id ? 'text-indigo-500' : 'text-slate-400 group-hover:text-indigo-500'" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
                  </svg>
                  <span class="text-sm font-medium truncate">{{ category.name }}</span>
                </div>
                <span class="text-[10px] px-1.5 py-0.5 rounded shrink-0 transition-colors" :class="currentMode === 'category' && activeCategory === category.id ? 'bg-indigo-200 text-indigo-800' : 'bg-slate-100 text-slate-500 group-hover:bg-white group-hover:text-indigo-600'">
                  {{ category.count }}
                </span>
              </div>
            </div>
            <div v-if="filteredOtaCategories.length === 0 && searchQuery" class="text-center py-4 text-slate-400 text-xs">
              没有找到相关分类
            </div>
          </div>
        </div>
      </transition>
    </div>

    <!-- 绿色饭店题库（可折叠） -->
    <div
      v-if="questionBankScope === 'all'"
      class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden flex-1 flex flex-col max-h-[400px]"
    >
      <div
        @click="$emit('update:greenHotelCategoryExpanded', !greenHotelCategoryExpanded)"
        class="p-4 flex justify-between items-center cursor-pointer hover:bg-slate-50 transition-colors shrink-0"
      >
        <div class="flex items-center gap-2">
          <div class="w-8 h-8 rounded-lg bg-teal-100 text-teal-600 flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div>
            <h3 class="font-bold text-slate-700 text-sm">绿色饭店题库</h3>
            <span class="text-xs text-slate-400">{{ greenHotelCategories.length }} 个分类</span>
          </div>
        </div>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-4 w-4 text-slate-400 transition-transform"
          :class="greenHotelCategoryExpanded ? 'rotate-180' : ''"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
        </svg>
      </div>
      <transition name="collapse">
        <div v-show="greenHotelCategoryExpanded" class="border-t border-slate-100 flex-1 overflow-hidden flex flex-col">
          <div v-if="loadingCategories" class="p-4 space-y-3">
            <div v-for="i in 3" :key="i" class="h-8 bg-slate-100 rounded animate-pulse"></div>
          </div>
          <div v-else-if="greenHotelCategories.length === 0" class="p-4 text-center">
            <p class="text-xs text-slate-400 mb-2">暂无绿色饭店题库</p>
            <router-link
              to="/green-hotel"
              class="inline-flex items-center gap-1 text-xs text-teal-600 font-medium hover:underline"
            >
              先去看课学习
            </router-link>
          </div>
          <div v-else class="p-2 space-y-2 overflow-y-auto custom-scrollbar flex-1">
            <div v-for="group in greenHotelCategoryGroups" :key="group.id" class="space-y-1">
              <div class="px-3 py-1 flex items-center justify-between text-[11px] font-bold text-slate-400">
                <span class="truncate">{{ group.name }}</span>
                <span>{{ group.children.length }}项 / {{ group.count }}题</span>
              </div>
              <div
                v-for="category in group.children"
                :key="category.id"
                @click="$emit('selectCategory', category)"
                class="group flex items-center justify-between px-3 py-2.5 rounded-xl cursor-pointer transition-all"
                :class="currentMode === 'category' && activeCategory === category.id ? 'bg-teal-50 text-teal-700 ring-1 ring-teal-100' : 'text-slate-600 hover:bg-slate-50'"
              >
                <div class="flex items-center gap-3 min-w-0">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 shrink-0 transition-colors" :class="currentMode === 'category' && activeCategory === category.id ? 'text-teal-500' : 'text-slate-400 group-hover:text-teal-500'" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
                  </svg>
                  <span class="text-sm font-medium truncate">{{ category.name }}</span>
                </div>
                <span class="text-[10px] px-1.5 py-0.5 rounded shrink-0 transition-colors" :class="currentMode === 'category' && activeCategory === category.id ? 'bg-teal-200 text-teal-800' : 'bg-slate-100 text-slate-500 group-hover:bg-white group-hover:text-teal-600'">
                  {{ category.count }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </transition>
    </div>

    <!-- 企业文化题库（可折叠） -->
    <div
      v-if="questionBankScope === 'all'"
      class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden flex-1 flex flex-col max-h-[400px]"
    >
      <div
        @click="$emit('update:cultureCategoryExpanded', !cultureCategoryExpanded)"
        class="p-4 flex justify-between items-center cursor-pointer hover:bg-slate-50 transition-colors shrink-0"
      >
        <div class="flex items-center gap-2">
          <div class="w-8 h-8 rounded-lg bg-purple-100 text-purple-600 flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
              />
            </svg>
          </div>
          <div>
            <h3 class="font-bold text-slate-700 text-sm">企业文化题库</h3>
            <span class="text-xs text-slate-400">{{ cultureCategories.length }} 个分类</span>
          </div>
        </div>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-4 w-4 text-slate-400 transition-transform"
          :class="cultureCategoryExpanded ? 'rotate-180' : ''"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
        </svg>
      </div>
      <transition name="collapse">
        <div v-show="cultureCategoryExpanded" class="border-t border-slate-100 flex-1 overflow-hidden flex flex-col">
          <div v-if="loadingCategories" class="p-4 space-y-3">
            <div v-for="i in 3" :key="i" class="h-8 bg-slate-100 rounded animate-pulse"></div>
          </div>
          <div v-else-if="cultureCategories.length === 0" class="p-4 text-center text-slate-400 text-xs">
            暂无企业文化题库
          </div>
          <div v-else class="p-2 space-y-1 overflow-y-auto custom-scrollbar flex-1">
            <div
              v-for="category in cultureCategories"
              :key="category.id"
              @click="$emit('selectCategory', category)"
              class="group flex items-center justify-between px-3 py-2.5 rounded-xl cursor-pointer transition-all"
              :class="currentMode === 'category' && activeCategory === category.id ? 'bg-purple-50 text-purple-700 ring-1 ring-purple-100' : 'text-slate-600 hover:bg-slate-50'"
            >
              <div class="flex items-center gap-3 min-w-0">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 shrink-0 transition-colors"
                  :class="
                    currentMode === 'category' && activeCategory === category.id
                      ? 'text-purple-500'
                      : 'text-slate-400 group-hover:text-purple-500'
                  "
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"
                  />
                </svg>
                <span class="text-sm font-medium truncate">{{ category.name }}</span>
              </div>
              <span
                class="text-[10px] px-1.5 py-0.5 rounded shrink-0 transition-colors"
                :class="
                  currentMode === 'category' && activeCategory === category.id
                    ? 'bg-purple-200 text-purple-800'
                    : 'bg-slate-100 text-slate-500 group-hover:bg-white group-hover:text-purple-600'
                "
              >
                {{ category.count }}
              </span>
            </div>
          </div>
        </div>
      </transition>
    </div>
  </aside>
</template>

<script setup>
defineProps({
  currentMode: {
    type: String,
    required: true,
  },
  activeCategory: {
    type: [String, Number, null],
    default: null,
  },
  deptAllCategory: {
    type: Object,
    required: true,
  },
  deptCategories: {
    type: Array,
    default: () => [],
  },
  deptCategoryGroups: {
    type: Array,
    default: () => [],
  },
  otaCategories: {
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
  filteredOtaCategories: {
    type: Array,
    default: () => [],
  },
  loadingCategories: {
    type: Boolean,
    default: false,
  },
  questionBankScope: {
    type: String,
    default: 'self',
  },
  deptCategoryExpanded: {
    type: Boolean,
    default: false,
  },
  otaCategoryExpanded: {
    type: Boolean,
    default: false,
  },
  cultureCategoryExpanded: {
    type: Boolean,
    default: false,
  },
  greenHotelCategoryExpanded: {
    type: Boolean,
    default: false,
  },
  searchQuery: {
    type: String,
    default: '',
  },
})

defineEmits([
  'switchMode',
  'switchToFirstCategory',
  'selectCategory',
  'update:deptCategoryExpanded',
  'update:otaCategoryExpanded',
  'update:cultureCategoryExpanded',
  'update:greenHotelCategoryExpanded',
  'update:searchQuery',
])
</script>

