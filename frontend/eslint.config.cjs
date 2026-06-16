const js = require("@eslint/js");
const globals = require("globals");
const vuePlugin = require("eslint-plugin-vue");
const babelParser = require("@babel/eslint-parser");
const vueParser = require("vue-eslint-parser");

module.exports = [
  {
    ignores: [
      "node_modules/**",
      "dist/**",
      "public/**",
      "*.config.js",
      ".eslintrc.js",
      "src/modules/onlineExam/api/http.js"
    ]
  },
  js.configs.recommended,
  ...vuePlugin.configs["flat/essential"],
  {
    files: ["**/*.{js,mjs,cjs}"],
    languageOptions: {
      parser: babelParser,
      parserOptions: {
        ecmaVersion: 2021,
        sourceType: "module",
        requireConfigFile: false
      },
      globals: {
        ...globals.browser,
        ...globals.node,
        defineEmits: "readonly",
        defineProps: "readonly",
        defineExpose: "readonly",
        withDefaults: "readonly"
      }
    },
    rules: {
      "no-console": process.env.NODE_ENV === "production" ? "warn" : "off",
      "no-debugger": process.env.NODE_ENV === "production" ? "warn" : "off",
      "no-unused-vars": "off",
      "no-undef": "warn",
      "no-empty": "off",
      "no-irregular-whitespace": "off"
    }
  },
  {
    files: ["**/*.vue"],
    languageOptions: {
      parser: vueParser,
      parserOptions: {
        parser: babelParser,
        ecmaVersion: 2021,
        sourceType: "module",
        requireConfigFile: false
      },
      globals: {
        ...globals.browser,
        ...globals.node,
        defineEmits: "readonly",
        defineProps: "readonly",
        defineExpose: "readonly",
        withDefaults: "readonly"
      }
    },
    rules: {
      "no-console": process.env.NODE_ENV === "production" ? "warn" : "off",
      "no-debugger": process.env.NODE_ENV === "production" ? "warn" : "off",
      "no-unused-vars": "off",
      "no-undef": "warn",
      "no-empty": "off",
      "no-irregular-whitespace": "off",
      "vue/no-side-effects-in-computed-properties": "off",
      "vue/valid-template-root": "off",
      "vue/multi-word-component-names": "off"
    }
  }
];
