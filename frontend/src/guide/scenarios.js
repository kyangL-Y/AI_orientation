const learningModuleSteps = [
  {
    id: 'help-entry',
    route: '/study',
    selectors: ['[data-guide="guide-help-entry"]'],
    placement: 'bottom',
    title: '帮助入口',
    description: '以后你可以随时从这里重新打开学习中心引导，不需要常驻说明卡片。'
  },
  {
    id: 'study-dashboard',
    route: '/study',
    selectors: ['[data-guide="study-dashboard"]'],
    placement: 'bottom',
    title: '学习总览',
    description: '这里先看总体进度、剩余时间和学习日历，先掌握自己的整体节奏。'
  },
  {
    id: 'study-platform-sidebar',
    route: '/study',
    selectors: ['[data-guide="study-platform-sidebar"]'],
    placement: 'right',
    title: '平台分类',
    description: '左侧是真实的平台分类入口，切换后右侧课程会随之变化。'
  },
  {
    id: 'study-course-entry',
    route: '/study',
    selectors: ['[data-guide="study-first-course"]', '[data-guide="study-course-section"]'],
    placement: 'top',
    title: '课程入口',
    description: '课程卡片就是进入具体学习内容的入口，首批引导先带你识别这里。'
  },
  {
    id: 'practice-entry',
    route: '/study',
    selectors: ['[data-guide="practice-nav-trigger"]'],
    placement: 'bottom',
    title: '练习与考试入口',
    description: '刷题、在线考试和答题记录都从这个入口进入，后续模块会再分批细讲。'
  },
  {
    id: 'answer-record',
    route: '/answer-record',
    selectors: ['[data-guide="answer-record-filter"]', '[data-guide="answer-record-list"]', '[data-guide="answer-record-guest-empty"]'],
    placement: 'bottom',
    title: '答题记录',
    description: '系统会在这里保留你的答题历史、筛选条件和复盘入口，支持后续回看。'
  }
]

const practiceModuleSteps = [
  {
    id: 'practice-help-entry',
    route: '/online',
    selectors: ['[data-guide="guide-help-entry"]'],
    placement: 'bottom',
    title: '帮助入口',
    description: '刷题模块也能从这里随时重开，不需要页面里长期放说明卡片。'
  },
  {
    id: 'practice-summary',
    route: '/online',
    selectors: ['[data-guide="online-practice-summary"]'],
    placement: 'bottom',
    title: '练习概览',
    description: '这里集中展示打卡、刷题数量、正确率和练习时长，是刷题节奏的总看板。'
  },
  {
    id: 'practice-mode-entry',
    route: '/online',
    selectors: ['[data-guide="online-desktop-sidebar"]', '[data-guide="online-mobile-mode-tabs"]'],
    placement: 'right',
    title: '练习模式入口',
    description: '这里是真实的模式切换入口，可以在每日一练、错题、收藏和专项练习之间切换。'
  },
  {
    id: 'practice-workspace',
    route: '/online',
    selectors: ['[data-guide="online-question-workspace"]'],
    placement: 'left',
    title: '答题工作区',
    description: '中间区域就是实际答题区，题库范围切换、答题记录和当前题目都在这里完成。'
  },
  {
    id: 'practice-navigation',
    route: '/online',
    selectors: ['[data-guide="online-question-nav"]', '[data-guide="online-question-nav-trigger"]'],
    placement: 'left',
    title: '题目导航',
    description: '右侧或移动端浮动按钮会带你快速跳题，适合回看未答题和复盘已答题。'
  }
]

const examModuleSteps = [
  {
    id: 'exam-help-entry',
    route: '/online-exam',
    selectors: ['[data-guide="guide-help-entry"]'],
    placement: 'bottom',
    title: '帮助入口',
    description: '在线考试模块也可以随时从这里重新开始引导，不需要页面里长期放说明卡片。'
  },
  {
    id: 'exam-overview-stats',
    route: '/online-exam',
    selectors: ['[data-guide="exam-overview-stats"]'],
    placement: 'bottom',
    title: '考试总览',
    description: '先看待参加、已完成和平均分，快速判断自己当前的考试节奏。'
  },
  {
    id: 'exam-practice-section',
    route: '/online-exam',
    selectors: ['[data-guide="exam-practice-section"]'],
    placement: 'bottom',
    title: '综合平时测验',
    description: '这里是平时测验入口，适合先练再考，按不同题库随机抽题。'
  },
  {
    id: 'exam-upcoming-section',
    route: '/online-exam',
    selectors: ['[data-guide="exam-upcoming-section"]'],
    placement: 'bottom',
    title: '待参加考试',
    description: '正式考试从这里进入，点击卡片里的参加按钮就会跳到真实考试页。'
  },
  {
    id: 'exam-history-section',
    route: '/online-exam',
    selectors: ['[data-guide="exam-history-section"]'],
    placement: 'top',
    title: '考试历史',
    description: '已完成的正式考试和平时测验都会沉淀在这里，方便回看成绩和记录。'
  },
  {
    id: 'exam-countdown',
    route: '/online-exam/start',
    selectors: ['[data-guide="exam-countdown-desktop"]', '[data-guide="exam-countdown-mobile"]'],
    placement: 'bottom',
    title: '考试倒计时',
    description: '进入正式考试后，先盯住倒计时，系统会按考试时长持续扣减。'
  },
  {
    id: 'exam-question-workspace',
    route: '/online-exam/start',
    selectors: ['[data-guide="exam-question-workspace"]'],
    placement: 'right',
    title: '答题工作区',
    description: '题目内容、单题/全览切换、上一题和下一题都在这个主工作区完成。'
  },
  {
    id: 'exam-answer-sheet',
    route: '/online-exam/start',
    selectors: ['[data-guide="exam-answer-sheet-desktop"]', '[data-guide="exam-answer-sheet-mobile-trigger"]'],
    placement: 'left',
    title: '答题卡与提交',
    description: '桌面端右侧就是答题卡和提交入口；手机端先点右上角按钮展开答题卡。'
  }
]

const knowledgeModuleSteps = [
  {
    id: 'knowledge-help-entry',
    route: '/knowledge',
    selectors: ['[data-guide="guide-help-entry"]'],
    placement: 'bottom',
    title: '帮助入口',
    description: '知识模块同样支持从这里随时重开引导，不需要常驻说明卡片。'
  },
  {
    id: 'knowledge-square-nav',
    route: '/knowledge',
    selectors: ['[data-guide="knowledge-nav-my"]'],
    placement: 'right',
    title: '知识模块导航',
    description: '先从这里点击“我的文章”，引导会等你真正切过去后再允许继续。',
    guard: {
      type: 'route',
      path: '/knowledge/my',
      message: '请先点击“我的文章”，进入文章管理页。'
    }
  },
  {
    id: 'knowledge-square-banner',
    route: '/knowledge',
    selectors: ['[data-guide="knowledge-square-banner"]'],
    placement: 'bottom',
    title: '知识广场搜索区',
    description: '这里是知识广场首页，搜索、推荐话题和发布入口都围绕这个区域展开。'
  },
  {
    id: 'knowledge-square-list',
    route: '/knowledge',
    selectors: ['[data-guide="knowledge-square-list"]'],
    placement: 'top',
    title: '知识内容流',
    description: '文章卡片会在这里按最新或热门方式展开，点进去就能查看具体内容。'
  },
  {
    id: 'knowledge-my-header',
    route: '/knowledge/my',
    selectors: ['[data-guide="knowledge-my-header"]'],
    placement: 'bottom',
    title: '我的文章',
    description: '这里集中管理你自己发布的文章，可以从头部直接写文章或查看总量。'
  },
  {
    id: 'knowledge-my-filters',
    route: '/knowledge/my',
    selectors: ['[data-guide="knowledge-my-filters"]'],
    placement: 'bottom',
    title: '状态筛选',
    description: '按已发布、审核中、草稿、已拒绝分组筛选，快速定位当前文章状态。'
  },
  {
    id: 'knowledge-my-list',
    route: '/knowledge/my',
    selectors: ['[data-guide="knowledge-my-list"]'],
    placement: 'top',
    title: '文章管理列表',
    description: '每篇文章的浏览、编辑、查看和删除动作都在这个列表里完成。'
  },
  {
    id: 'knowledge-go-favorites',
    route: '/knowledge/my',
    selectors: ['[data-guide="knowledge-nav-favorites"]'],
    placement: 'right',
    title: '前往我的收藏',
    description: '继续点击“我的收藏”，切到你沉淀优质内容的收藏页。',
    guard: {
      type: 'route',
      path: '/knowledge/favorites',
      message: '请先点击“我的收藏”，进入收藏文章页。'
    }
  },
  {
    id: 'knowledge-favorites-header',
    route: '/knowledge/favorites',
    selectors: ['[data-guide="knowledge-favorites-header"]'],
    placement: 'bottom',
    title: '我的收藏',
    description: '收藏页会沉淀你标记过的优质文章，后续回看可以直接从这里进入。'
  },
  {
    id: 'knowledge-favorites-list',
    route: '/knowledge/favorites',
    selectors: ['[data-guide="knowledge-favorites-list"]'],
    placement: 'top',
    title: '收藏文章列表',
    description: '收藏文章会在这里按卡片展示，也可以直接取消收藏或继续阅读。'
  }
]

const knowledgeCreationSteps = [
  {
    id: 'knowledge-create-help-entry',
    route: '/knowledge/edit',
    selectors: ['[data-guide="guide-help-entry"]'],
    placement: 'bottom',
    title: '帮助入口',
    description: '进入创作页后，也可以从这里随时重开写作引导。'
  },
  {
    id: 'knowledge-create-nav',
    route: '/knowledge/edit',
    selectors: ['[data-guide="knowledge-create-nav"]'],
    placement: 'right',
    title: '创作页导航',
    description: '左侧放的是返回、知识广场、我的文章等快捷入口，避免写作时迷路。'
  },
  {
    id: 'knowledge-create-toolbar',
    route: '/knowledge/edit',
    selectors: ['[data-guide="knowledge-create-toolbar"]'],
    placement: 'bottom',
    title: '编辑工具栏',
    description: '撤销、重做、插表格、全屏和预览都集中在这里，是写作时的主控制区。'
  },
  {
    id: 'knowledge-create-title',
    route: '/knowledge/edit',
    selectors: ['[data-guide="knowledge-create-title"]'],
    placement: 'bottom',
    title: '标题区',
    description: '先在这里输入文章标题，系统会等你真正填入内容后再允许继续。',
    guard: {
      type: 'input',
      selectors: ['[data-guide="knowledge-create-title-input"]'],
      message: '请先输入文章标题。'
    }
  },
  {
    id: 'knowledge-create-editor',
    route: '/knowledge/edit',
    selectors: ['[data-guide="knowledge-create-editor"]'],
    placement: 'right',
    title: '正文编辑区',
    description: '正文内容、封面、富文本排版和内容模板最终都会落到这个主编辑区。'
  },
  {
    id: 'knowledge-create-actions',
    route: '/knowledge/edit',
    selectors: ['[data-guide="knowledge-create-actions"]'],
    placement: 'left',
    title: '发布与草稿',
    description: '右侧先保存草稿，再决定发布；最近草稿和创作助手也都在这个区域。'
  },
  {
    id: 'knowledge-create-open-publish',
    route: '/knowledge/edit',
    selectors: ['[data-guide="knowledge-publish-trigger"]'],
    placement: 'left',
    title: '打开发布设置',
    description: '点击“发布文章”打开发布设置弹窗，这一步必须真的执行操作后才能继续。',
    guard: {
      type: 'visible',
      selectors: ['[data-guide="knowledge-publish-modal"]'],
      message: '请先点击“发布文章”，打开发布设置弹窗。'
    }
  },
  {
    id: 'knowledge-create-publish-modal',
    route: '/knowledge/edit',
    selectors: ['[data-guide="knowledge-publish-modal"]'],
    placement: 'left',
    title: '发布设置弹窗',
    description: '这里可以设置发布范围、话题和封面。确认信息无误后，再决定正式发布。'
  }
]

const knowledgeDetailEntrySteps = [
  {
    id: 'knowledge-detail-entry-list',
    route: '/knowledge',
    selectors: ['[data-guide="knowledge-square-first-article"]', '[data-guide="knowledge-square-list"]'],
    placement: 'top',
    title: '文章入口',
    description: '文章卡片就是进入知识详情的真实入口；如果列表里已有内容，会优先高亮第一张卡片。'
  },
  {
    id: 'knowledge-detail-entry-open-article',
    route: '/knowledge',
    selectors: ['[data-guide="knowledge-square-first-article"]', '[data-guide="knowledge-square-list"]'],
    placement: 'top',
    title: '进入知识详情',
    description: '现在点击任意一篇文章卡片，系统会在你真正进入详情页后自动接到详情阅读引导。',
    guard: {
      type: 'route',
      path: '/knowledge/:id',
      autoAdvance: true,
      message: '请先点击一篇文章卡片，进入知识详情页。'
    }
  }
]

const knowledgeDetailSteps = [
  {
    id: 'knowledge-detail-help-entry',
    route: '/knowledge/:id',
    selectors: ['[data-guide="guide-help-entry"]'],
    placement: 'bottom',
    title: '帮助入口',
    description: '阅读知识详情时，也能从这里随时重新打开引导。'
  },
  {
    id: 'knowledge-detail-article',
    route: '/knowledge/:id',
    selectors: ['[data-guide="knowledge-detail-article"]'],
    placement: 'right',
    title: '正文阅读区',
    description: '标题、作者信息和正文内容都集中在这里，先按主内容区完成阅读。'
  },
  {
    id: 'knowledge-detail-actions',
    route: '/knowledge/:id',
    selectors: ['[data-guide="knowledge-detail-actions"]', '[data-guide="knowledge-detail-mobile-actions"]'],
    placement: 'left',
    title: '互动操作区',
    description: '点赞、收藏、评论和回到顶部都在这里，桌面端在左侧，移动端会落到正文底部。'
  },
  {
    id: 'knowledge-detail-like',
    route: '/knowledge/:id',
    selectors: ['[data-guide="knowledge-detail-like"]'],
    placement: 'left',
    title: '点赞按钮',
    description: '先点一次点赞按钮，系统会在互动成功后再允许你进入下一步。',
    guard: {
      type: 'event',
      event: 'guide:knowledge-detail-liked',
      message: '请先点一次点赞按钮。'
    }
  },
  {
    id: 'knowledge-detail-favorite',
    route: '/knowledge/:id',
    selectors: ['[data-guide="knowledge-detail-favorite"]'],
    placement: 'left',
    title: '收藏按钮',
    description: '觉得内容值得沉淀时，直接点收藏，系统会等收藏动作真正完成。',
    guard: {
      type: 'event',
      event: 'guide:knowledge-detail-favorited',
      message: '请先点一次收藏按钮。'
    }
  },
  {
    id: 'knowledge-detail-comment-trigger',
    route: '/knowledge/:id',
    selectors: ['[data-guide="knowledge-detail-comment-trigger"]'],
    placement: 'left',
    title: '前往评论区',
    description: '点击评论按钮，快速滚动到评论区，准备留下你的看法。',
    guard: {
      type: 'click',
      selectors: ['[data-guide="knowledge-detail-comment-trigger"]'],
      message: '请先点击评论按钮，跳转到评论区。'
    }
  },
  {
    id: 'knowledge-detail-comment-input',
    route: '/knowledge/:id',
    selectors: ['[data-guide="knowledge-detail-comments"]'],
    placement: 'top',
    title: '评论输入区',
    description: '在这里输入评论内容，系统检测到你开始输入后才会继续。',
    guard: {
      type: 'input',
      selectors: ['[data-guide="knowledge-detail-comment-input"]'],
      message: '请先输入评论内容。'
    }
  },
  {
    id: 'knowledge-detail-related',
    route: '/knowledge/:id',
    selectors: ['[data-guide="knowledge-detail-related"]'],
    placement: 'left',
    title: '相关推荐',
    description: '读完当前文章后，可以从这里继续延伸阅读相关内容。'
  }
]

const knowledgeDetailInteractionSteps = [
  {
    id: 'knowledge-detail-interaction-help-entry',
    route: '/knowledge/:id',
    selectors: ['[data-guide="guide-help-entry"]'],
    placement: 'bottom',
    title: '帮助入口',
    description: '深度互动引导也能从这里随时重开。'
  },
  {
    id: 'knowledge-detail-comment-submit',
    route: '/knowledge/:id',
    selectors: ['[data-guide="knowledge-detail-comment-submit"]'],
    placement: 'top',
    title: '发表评论',
    description: '先在评论框里写点内容，再真实点击“发表评论”，系统会在提交成功后继续。',
    guard: {
      type: 'event',
      event: 'guide:knowledge-detail-comment-submitted',
      message: '请先输入评论内容并成功发表。'
    }
  },
  {
    id: 'knowledge-detail-related-open',
    route: '/knowledge/:id',
    selectors: ['[data-guide="knowledge-detail-related-item"]'],
    placement: 'left',
    title: '打开相关推荐',
    description: '点击一篇相关推荐，真正跳到另一篇文章详情，继续完成阅读链路。',
    guard: {
      type: 'event',
      event: 'guide:knowledge-detail-related-opened',
      message: '请先点击一篇相关推荐文章。'
    }
  },
  {
    id: 'knowledge-detail-related-arrived',
    route: '/knowledge/:id',
    selectors: ['[data-guide="knowledge-detail-article"]'],
    placement: 'right',
    title: '新文章已打开',
    description: '现在你已经切到另一篇知识详情，可以继续阅读正文或重复互动流程。'
  }
]

function resolveFinalStepRoute(step) {
  if (!step) {
    return '/study'
  }
  if (step.guard?.type === 'route' && step.guard?.path) {
    return step.guard.path
  }
  return step.route
}

function withGuideReopenStep(scenarioId, steps = []) {
  const lastStep = steps[steps.length - 1]
  const finalRoute = resolveFinalStepRoute(lastStep)
  return [
    ...steps,
    {
      id: `${scenarioId}-reopen-guide`,
      route: finalRoute,
      selectors: ['[data-guide="guide-help-entry"]'],
      placement: 'bottom',
      title: '重新打开引导',
      description: '之后如果还想再看这一条新手指导，直接点击这里的“引导”入口就可以重新开始。'
    }
  ]
}

const guideScenarios = [
  {
    id: 'learning-module-overview',
    module: 'learning',
    role: 'learner',
    scene: 'study-home',
    title: '学习中心速览',
    description: '学习中心、课程入口、练习/考试入口和答题记录的第一批闭环引导。',
    autoStart: true,
    steps: withGuideReopenStep('learning-module-overview', learningModuleSteps)
  },
  {
    id: 'practice-module-overview',
    module: 'practice',
    role: 'learner',
    scene: 'practice-home',
    title: '刷题模块速览',
    description: '在线刷题页的第二批引导，覆盖练习概览、模式入口、答题区和题目导航。',
    autoStart: true,
    steps: withGuideReopenStep('practice-module-overview', practiceModuleSteps)
  },
  {
    id: 'exam-module-overview',
    module: 'exam',
    role: 'learner',
    scene: 'exam-home',
    title: '在线考试模块速览',
    description: '第三批上线：覆盖考试总览、待参加考试、考试历史和正式答题页。',
    autoStart: true,
    steps: withGuideReopenStep('exam-module-overview', examModuleSteps)
  },
  {
    id: 'knowledge-module-overview',
    module: 'knowledge',
    role: 'learner',
    scene: 'knowledge-home',
    title: '知识模块速览',
    description: '覆盖知识广场、我的文章和我的收藏的主路径。',
    autoStart: true,
    steps: withGuideReopenStep('knowledge-module-overview', knowledgeModuleSteps)
  },
  {
    id: 'knowledge-detail-entry-overview',
    module: 'knowledge',
    role: 'learner',
    scene: 'knowledge-detail-entry',
    title: '知识广场进入详情',
    description: '补齐知识广场到知识详情的跨页进入引导，完成后自动衔接详情阅读 tour。',
    autoStart: true,
    nextScenarioId: 'knowledge-detail-overview',
    steps: withGuideReopenStep('knowledge-detail-entry-overview', knowledgeDetailEntrySteps)
  },
  {
    id: 'knowledge-creation-overview',
    module: 'knowledge',
    role: 'learner',
    scene: 'knowledge-create',
    title: '知识创作速览',
    description: '覆盖知识发布/编辑页的创作主路径。',
    autoStart: true,
    steps: withGuideReopenStep('knowledge-creation-overview', knowledgeCreationSteps)
  },
  {
    id: 'knowledge-detail-overview',
    module: 'knowledge',
    role: 'learner',
    scene: 'knowledge-detail',
    title: '知识详情阅读速览',
    description: '覆盖正文阅读、点赞、收藏、评论与相关推荐。',
    autoStart: true,
    steps: withGuideReopenStep('knowledge-detail-overview', knowledgeDetailSteps)
  },
  {
    id: 'knowledge-detail-interaction-overview',
    module: 'knowledge',
    role: 'learner',
    scene: 'knowledge-detail-interaction',
    title: '知识详情深度互动',
    description: '覆盖真实评论提交与相关推荐跳转闭环。',
    autoStart: true,
    steps: withGuideReopenStep('knowledge-detail-interaction-overview', knowledgeDetailInteractionSteps)
  }
]

export const guideModules = [
  {
    id: 'learning',
    title: '学习中心模块',
    description: '第一批上线：学习中心主路径',
    scenarios: ['learning-module-overview']
  },
  {
    id: 'practice',
    title: '刷题练习模块',
    description: '第二批上线：在线刷题主路径',
    scenarios: ['practice-module-overview']
  },
  {
    id: 'exam',
    title: '在线考试模块',
    description: '第三批上线：在线考试主路径',
    scenarios: ['exam-module-overview']
  },
  {
    id: 'knowledge',
    title: '知识模块',
    description: '知识广场、进入详情、创作、详情阅读与深度互动主路径',
    scenarios: [
      'knowledge-module-overview',
      'knowledge-detail-entry-overview',
      'knowledge-creation-overview',
      'knowledge-detail-overview',
      'knowledge-detail-interaction-overview'
    ]
  }
]

export default guideScenarios
