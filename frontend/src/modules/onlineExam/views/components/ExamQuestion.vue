<template>
  <div class="exam-question">
    <div class="q-title">
      <span class="q-index">{{ index + 1 }}</span>
      <span class="q-text">{{ question.title }}</span>
      <span class="q-type">{{ typeLabel }}</span>
    </div>
    <div class="q-body">
      <template v-if="question.type === 'single'">
        <el-radio-group v-model="localAnswer" class="vertical-options">
          <el-radio v-for="(opt, idx) in question.options" :key="idx" :label="String.fromCharCode(65 + idx)" class="option-item">
            <div class="option-inner">
              <span class="option-badge">{{ String.fromCharCode(65 + idx) }}</span>
              <span class="option-content">{{ opt }}</span>
            </div>
          </el-radio>
        </el-radio-group>
      </template>
      <template v-else-if="question.type === 'multiple'">
        <el-checkbox-group v-model="localAnswer" class="vertical-options">
          <el-checkbox v-for="(opt, idx) in question.options" :key="idx" :label="String.fromCharCode(65 + idx)" class="option-item">
            <div class="option-inner">
              <span class="option-badge">{{ String.fromCharCode(65 + idx) }}</span>
              <span class="option-content">{{ opt }}</span>
            </div>
          </el-checkbox>
        </el-checkbox-group>
      </template>
      <template v-else-if="question.type === 'judge'">
        <el-radio-group v-model="localAnswer" class="judge-options">
          <el-radio :label="true" class="option-item judge-item judge-true">
            <div class="option-inner center">
              <span class="option-badge"><el-icon class="text-lg"><Check /></el-icon></span>
              <span class="option-content text-lg">正确</span>
            </div>
          </el-radio>
          <el-radio :label="false" class="option-item judge-item judge-false">
            <div class="option-inner center">
              <span class="option-badge"><el-icon class="text-lg"><Close /></el-icon></span>
              <span class="option-content text-lg">错误</span>
            </div>
          </el-radio>
        </el-radio-group>
      </template>
      <template v-else-if="question.type === 'text'">
        <el-input 
          v-model="localAnswer" 
          type="textarea" 
          :rows="4" 
          placeholder="请输入您的答案..." 
          class="custom-textarea"
        />
      </template>
      <template v-else-if="question.type === 'fill'">
        <el-input 
          v-model="localAnswer" 
          type="textarea" 
          :rows="3" 
          placeholder="请输入填空答案，多个空请用分号分隔" 
          class="custom-textarea"
        />
      </template>
      <template v-else-if="question.type === 'code'">
        <el-input 
          v-model="localAnswer" 
          type="textarea" 
          :rows="8" 
          placeholder="// 请在此处编写代码" 
          class="custom-textarea code-font"
        />
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, computed } from 'vue';
import { Check, Close } from '@element-plus/icons-vue';

const props = defineProps(['question', 'answer', 'index', 'total']);
const emit = defineEmits(['update:answer']);

const localAnswer = ref(props.answer);
watch(() => props.answer, val => { localAnswer.value = val; });
watch(localAnswer, val => { emit('update:answer', val); });

const typeLabel = computed(() => {
  switch (props.question.type) {
    case 'single': return '单选题';
    case 'multiple': return '多选题';
    case 'judge': return '判断题';
    case 'text': return '简答题';
    case 'fill': return '填空题';
    case 'code': return '代码题';
    default: return '未知';
  }
});
</script>

<style scoped>
.exam-question {
  padding: 0.5rem 0;
}

/* 标题样式 */
.q-title {
  font-size: 1.15rem;
  font-weight: 600;
  color: #1e293b;
  margin-bottom: 2rem;
  display: flex;
  align-items: flex-start;
  gap: 1rem;
  line-height: 1.6;
}

.q-index {
  font-family: 'Oswald', ui-monospace, SFMono-Regular, monospace;
  font-size: 1.5rem;
  font-weight: 500;
  color: #94a3b8;
  line-height: 1;
  margin-top: 0.2rem;
  font-style: italic;
}

.q-text {
  flex: 1;
}

.q-type {
  font-size: 0.75rem;
  color: #6366f1;
  background: #eef2ff;
  padding: 0.2rem 0.6rem;
  border-radius: 1rem;
  flex-shrink: 0;
  font-weight: 600;
  align-self: flex-start;
  margin-top: 0.3rem;
  letter-spacing: 0.05em;
}

.q-body {
  padding-left: 0.5rem;
}

/* 选项通用容器 */
.vertical-options {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  width: 100%;
}

.judge-options {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
  width: 100%;
}

/* 选项卡片核心样式 */
.option-item {
  display: flex !important;
  width: 100%;
  margin: 0 !important;
  padding: 0 !important;
  border: 2px solid #f1f5f9;
  border-radius: 1rem;
  background-color: #fff;
  height: auto !important;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

/* 判断题特定样式 */
.judge-item {
  min-height: 80px; /* 增加高度，使其更饱满 */
}

.option-item:hover {
  border-color: #cbd5e1;
  transform: translateY(-2px);
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05);
}

.option-item:active {
  transform: scale(0.99);
}

/* 选中状态 */
.option-item.is-checked {
  border-color: #3b82f6;
  background: linear-gradient(to right bottom, #eff6ff, #fff);
  box-shadow: 0 4px 6px -1px rgba(59, 130, 246, 0.1), 0 2px 4px -1px rgba(59, 130, 246, 0.06);
}

/* 判断题 - 正确 (绿色主题) */
.judge-true .option-badge { color: #10b981; background-color: #ecfdf5; }
.judge-true:hover { border-color: #6ee7b7; background-color: #f0fdf4; }
.judge-true.is-checked { 
  border-color: #10b981; 
  background: linear-gradient(to right bottom, #ecfdf5, #fff);
  box-shadow: 0 4px 6px -1px rgba(16, 185, 129, 0.1);
}
.judge-true.is-checked .option-badge { background-color: #10b981; color: #fff; transform: scale(1.1); }
.judge-true.is-checked .option-content { color: #059669; }

/* 判断题 - 错误 (红色主题) */
.judge-false .option-badge { color: #ef4444; background-color: #fef2f2; }
.judge-false:hover { border-color: #fca5a5; background-color: #fef2f2; }
.judge-false.is-checked { 
  border-color: #ef4444; 
  background: linear-gradient(to right bottom, #fef2f2, #fff);
  box-shadow: 0 4px 6px -1px rgba(239, 68, 68, 0.1);
}
.judge-false.is-checked .option-badge { background-color: #ef4444; color: #fff; transform: scale(1.1); }
.judge-false.is-checked .option-content { color: #b91c1c; }

/* 选项内部布局 */
.option-inner {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
  padding: 1.25rem 1.5rem;
  width: 100%;
}

.option-inner.center {
  align-items: center;
  justify-content: center;
}

/* 选项徽章 (A/B/C/D 或 图标) */
.option-badge {
  flex-shrink: 0;
  width: 2rem;
  height: 2rem;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background-color: #f3f4f6;
  color: #64748b;
  font-weight: 700;
  font-size: 0.9rem;
  transition: all 0.3s ease;
}

.option-item:hover .option-badge {
  background-color: #e2e8f0;
  color: #475569;
}

.option-item.is-checked .option-badge {
  background-color: #3b82f6;
  color: #fff;
  transform: rotate(360deg); /* 趣味旋转动画 */
}

.option-content {
  font-size: 1rem;
  color: #334155;
  font-weight: 500;
  line-height: 1.6;
  padding-top: 0.1rem;
}

.option-item.is-checked .option-content {
  color: #1e40af;
  font-weight: 600;
}

/* Element Plus 样式覆盖 */
:deep(.el-radio__input),
:deep(.el-checkbox__input) {
  display: none !important; /* 隐藏原生圆圈/方框 */
}

:deep(.el-radio__label),
:deep(.el-checkbox__label) {
  padding: 0 !important;
  width: 100%;
  margin: 0 !important;
  display: block;
}

/* 文本框优化 */
.custom-textarea :deep(.el-textarea__inner) {
  padding: 1rem;
  border-radius: 0.75rem;
  background-color: #f8fafc;
  border-color: #e2e8f0;
  font-size: 1rem;
  transition: all 0.3s;
}

.custom-textarea :deep(.el-textarea__inner:focus) {
  background-color: #fff;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.code-font :deep(.el-textarea__inner) {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}

/* 移动端适配 */
@media (max-width: 768px) {
  .q-title {
    font-size: 0.95rem;
    margin-bottom: 1rem;
    gap: 0.5rem;
  }
  
  .q-index {
    font-size: 1.1rem;
  }
  
  .q-type {
    font-size: 0.65rem;
    padding: 0.15rem 0.4rem;
  }
  
  .q-body {
    padding-left: 0;
  }
  
  .vertical-options {
    gap: 0.6rem;
  }
  
  .judge-options {
    gap: 0.5rem;
  }
  
  .judge-item {
    min-height: 60px;
  }
  
  .option-item {
    border-radius: 0.75rem;
  }
  
  .option-inner {
    padding: 0.75rem 1rem;
    gap: 0.6rem;
  }
  
  .option-badge {
    width: 1.5rem;
    height: 1.5rem;
    font-size: 0.75rem;
  }
  
  .option-content {
    font-size: 0.875rem;
    line-height: 1.5;
  }
  
  .judge-item .option-content {
    font-size: 0.9rem !important;
  }
  
  .judge-item .option-badge :deep(.el-icon) {
    font-size: 0.9rem !important;
  }
}
</style> 
