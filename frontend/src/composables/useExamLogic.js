import { computed } from 'vue'

export function useExamLogic({ questions, currentIndex, selectedOption, showAnswer }) {
  const currentQuestion = computed(() => {
    if (!questions.value || questions.value.length === 0 || currentIndex.value >= questions.value.length) {
      return null
    }
    const q = questions.value[currentIndex.value]
    if (!q) return null

    return {
      id: q.id || q.questionId || 0,
      title: q.title || q.questionText || q.content || '题目加载中...',
      type: q.type || '单选题',
      options: q.options || [],
      correctAnswer: q.correctAnswer !== undefined ? q.correctAnswer : 0,
      explanation: q.explanation || q.desc || q.remark || '暂无解析',
      level: q.level || q.difficulty || '中等',
      tag: q.tag || q.category || '通用',
      myAnswer: q.myAnswer,
      isSubmitted: q.isSubmitted,
    }
  })

  const isMultipleChoice = computed(() => {
    if (!currentQuestion.value) return false
    const type = currentQuestion.value.type
    const correct = currentQuestion.value.correctAnswer
    return type === '多选题' || type === 'multiple' || type === '2' || Array.isArray(correct)
  })

  const answeredCount = computed(() => questions.value.filter(q => q.isSubmitted).length)

  const isSelectedOption = (index) => {
    if (selectedOption.value === null) return false
    if (Array.isArray(selectedOption.value)) return selectedOption.value.includes(index)
    return selectedOption.value === index
  }

  const checkIsPartOfCorrectAnswer = (index) => {
    if (!currentQuestion.value) return false
    const ans = currentQuestion.value.correctAnswer
    if (Array.isArray(ans)) return ans.includes(index)
    return ans === index
  }

  const isCorrectOptionPart = (index) => checkIsPartOfCorrectAnswer(index)

  const getOptionClass = (index) => {
    const base = 'border-slate-100 bg-white hover:border-blue-200 hover:bg-blue-50/30'
    const isSelected = isSelectedOption(index)

    if (!showAnswer.value) {
      return isSelected
        ? 'border-blue-500 bg-blue-50 ring-1 ring-blue-500'
        : base
    }

    const isPartOfCorrectAnswer = checkIsPartOfCorrectAnswer(index)

    if (isSelected && isPartOfCorrectAnswer) return 'border-emerald-500 bg-emerald-50 ring-1 ring-emerald-500'
    if (isPartOfCorrectAnswer) return 'border-emerald-400 border-dashed bg-white ring-1 ring-emerald-200 ring-opacity-50'
    if (isSelected && !isPartOfCorrectAnswer) return 'border-rose-500 bg-rose-50 ring-1 ring-rose-500'
    return 'border-slate-100 opacity-40 grayscale'
  }

  const getOptionMarkerClass = (index) => {
    const isSelected = isSelectedOption(index)

    if (!showAnswer.value) {
      return isSelected
        ? 'bg-blue-600 text-white shadow-blue-200 rotate-animation'
        : 'bg-slate-100 text-slate-500 group-hover:bg-white group-hover:text-blue-600 group-hover:shadow-sm'
    }

    const isPartOfCorrectAnswer = checkIsPartOfCorrectAnswer(index)

    if (isSelected && isPartOfCorrectAnswer) return 'bg-emerald-500 text-white shadow-emerald-200 rotate-animation'
    if (isPartOfCorrectAnswer) return 'bg-white text-emerald-600 border-2 border-emerald-500 font-bold'
    if (isSelected && !isPartOfCorrectAnswer) return 'bg-rose-500 text-white shadow-rose-200 rotate-animation'
    return 'bg-slate-100 text-slate-400'
  }

  const isCorrectOption = (userSelection) => {
    if (!currentQuestion.value) return false
    const correct = currentQuestion.value.correctAnswer

    if (Array.isArray(correct)) {
      if (!Array.isArray(userSelection)) return false
      if (userSelection.length !== correct.length) return false
      const sortedUser = [...userSelection].sort((a, b) => a - b)
      const sortedCorrect = [...correct].sort((a, b) => a - b)
      return sortedUser.every((val, idx) => val === sortedCorrect[idx])
    }
    return correct === userSelection
  }

  const formatAnswer = (ans) => {
    if (ans === undefined || ans === null) return ''

    if (Array.isArray(ans)) {
      return ans.map(i => {
        if (typeof i === 'number') return String.fromCharCode(65 + i)
        if (typeof i === 'string' && /^[A-Za-z]$/.test(i)) return i.toUpperCase()
        return i
      }).join('、')
    }

    if (typeof ans === 'number') {
      return String.fromCharCode(65 + ans)
    }

    if (typeof ans === 'string') {
      let normalized = ans.replace(/[，、]/g, ',').replace(/\s/g, '')
      normalized = normalized.replace(/,+/g, ',').replace(/^,|,$/g, '')

      if (/^[A-Za-z](,[A-Za-z])*$/.test(normalized)) {
        return normalized.split(',').map(c => c.toUpperCase()).join('、')
      }

      if (/^[A-Za-z]+$/.test(normalized) && normalized.length > 1) {
        return normalized.toUpperCase().split('').join('、')
      }

      if (/^[A-Za-z]$/.test(normalized)) {
        return normalized.toUpperCase()
      }

      if (/^\d+$/.test(normalized)) {
        return String.fromCharCode(65 + parseInt(normalized))
      }

      return ans
    }

    return String(ans)
  }

  const getQuestionStatusClass = (q, index) => {
    if (currentIndex.value === index) return 'bg-blue-500 text-white'
    if (q.isSubmitted) return q.isCorrect ? 'bg-emerald-100 text-emerald-600' : 'bg-rose-100 text-rose-600'
    return 'bg-slate-100 text-slate-500 group-hover:bg-slate-200'
  }

  const jumpToQuestion = (index) => {
    if (index >= 0 && index < questions.value.length) {
      currentIndex.value = index
    }
  }

  return {
    currentQuestion,
    isMultipleChoice,
    answeredCount,
    isSelectedOption,
    isCorrectOptionPart,
    getOptionClass,
    getOptionMarkerClass,
    isCorrectOption,
    formatAnswer,
    getQuestionStatusClass,
    jumpToQuestion,
  }
}

