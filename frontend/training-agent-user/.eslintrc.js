module.exports = {
  root: true,
  env: {
    node: true,
    browser: true,
    es2021: true
  },
  extends: [
    'plugin:vue/essential',
    'eslint:recommended'
  ],
  parserOptions: {
    ecmaVersion: 2021,
    sourceType: 'module',
    parser: '@babel/eslint-parser',
    requireConfigFile: false
  },
  rules: {
    'no-console': process.env.NODE_ENV === 'production' ? 'warn' : 'off',
    'no-debugger': process.env.NODE_ENV === 'production' ? 'warn' : 'off',
    // 将严格的错误改为警告或关闭
    'no-unused-vars': 'off',  // 关闭未使用变量检查
    'no-undef': 'warn',  // 未定义变量改为警告
    'no-empty': 'off',  // 关闭空块检查
    'no-irregular-whitespace': 'off',  // 关闭不规则空格检查
    'vue/no-side-effects-in-computed-properties': 'off',  // 关闭计算属性副作用检查
    'vue/valid-template-root': 'off',  // 关闭模板根元素检查
    'vue/multi-word-component-names': 'off'  // 关闭多词组件名检查
  },
  globals: {
    defineEmits: 'readonly',
    defineProps: 'readonly',
    defineExpose: 'readonly',
    withDefaults: 'readonly'
  }
}
