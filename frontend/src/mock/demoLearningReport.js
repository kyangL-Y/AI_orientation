export function getDemoLearningReportPayload() {
  const previousReport = {
    reportId: 202602001,
    userName: '演示学员',
    periodType: 'monthly',
    periodStart: '2026-02-01 00:00:00',
    periodEnd: '2026-02-28 23:59:59',
    createTime: '2026-02-28 22:10:00',
    totalScore: 58,
    deptRank: 31,
    totalInDept: 42,
    dimensionScores: JSON.stringify({
      learning_duration: 42,
      quiz_count: 38,
      accuracy_rate: 57,
      completion_rate: 49,
      assessment_score: 52,
    }),
    abilityScores: JSON.stringify({
      cost_control: 52,
      customer_service: 61,
      team_collaboration: 58,
      professional_skills: 47,
      safety_compliance: 63,
    }),
    auxiliaryData: JSON.stringify({
      learningDuration: 165,
      quizCount: 64,
    }),
    rawData: JSON.stringify({
      totalAttempts: 84,
      correctCount: 48,
    }),
    aiSuggestion: JSON.stringify({
      report_intro: '2月是第一次接触平台的起步阶段，课程学习、刷题训练和阶段测评都还处在摸索期，整体基础刚刚建立。',
      learning_profile: {
        duration_value: '2.8小时',
        duration_eval: '刚完成初步熟悉，投入时长偏少',
        accuracy_value: '57%',
        accuracy_eval: '知识点还不稳定，错题复盘明显不足',
        score_value: '58分',
        score_eval: '整体还在起步区间',
        one_sentence: '第一次接触平台时，学习动作还没有形成完整闭环，所以得分、正确率和完成度都偏弱。',
      },
      dimension_analysis: [
        {
          dimension: '课程学习时长',
          title: '刚建立平台使用习惯',
          analysis: '2月只完成了少量课程浏览，学习时长不足以支撑完整知识框架，很多内容还停留在“知道有这回事”的阶段。',
          tip: '先把固定学习时段建立起来，比零散点击课程更有效。',
        },
        {
          dimension: '刷题数量',
          title: '题型接触不够',
          analysis: '当月刷题数量偏少，对平台题型和出题方式还不熟悉，所以做题时更容易犹豫，速度和稳定性都不够。',
          tip: '先拉训练量，再做针对性复盘，提升会更快。',
        },
        {
          dimension: '测评得分',
          title: '初次考试表现一般',
          analysis: '由于课程学习和练习还没有形成闭环，第一次阶段测评只表现出基础认知，对重点知识的理解深度明显不够。',
          tip: '课程学习后马上刷题，再进考试，效果会明显不同。',
        },
      ],
      action_plan: {
        consolidate: [
          '继续保持对平台的使用频率，尽快把学习动作从“偶尔进入”变成“固定习惯”。',
        ],
        improve: [
          '优先补课程学习时长，先把知识框架搭起来。',
          '增加专项刷题量，熟悉平台题型和常见考点。',
          '每次考试后做错题回看，避免重复丢分。',
        ],
      },
      closing_message: '2月最大的意义不是分数，而是完成了从“不会用平台”到“开始真正学习”的起步。',
    }),
  }

  const currentReport = {
    reportId: 202603001,
    userName: '演示学员',
    periodType: 'monthly',
    periodStart: '2026-03-01 00:00:00',
    periodEnd: '2026-03-21 23:59:59',
    createTime: '2026-03-21 20:30:00',
    totalScore: 91,
    deptRank: 6,
    totalInDept: 42,
    dimensionScores: JSON.stringify({
      learning_duration: 88,
      quiz_count: 93,
      accuracy_rate: 89,
      completion_rate: 86,
      assessment_score: 91,
    }),
    abilityScores: JSON.stringify({
      cost_control: 84,
      customer_service: 88,
      team_collaboration: 86,
      professional_skills: 92,
      safety_compliance: 90,
    }),
    auxiliaryData: JSON.stringify({
      learningDuration: 1480,
      quizCount: 1286,
    }),
    rawData: JSON.stringify({
      totalAttempts: 1320,
      correctCount: 1172,
    }),
    aiSuggestion: JSON.stringify({
      report_intro: '3月已经从平台新手阶段切换到高频学习阶段。课程学习、刷题训练和阶段考试形成了完整闭环，成长幅度非常明显。',
      learning_profile: {
        duration_value: '24.7小时',
        duration_eval: '课程投入显著增加，知识框架已经补起来了',
        accuracy_value: '89%',
        accuracy_eval: '刷题和错题复盘开始真正转化为结果',
        score_value: '91分',
        score_eval: '已经进入高质量成长区间',
        one_sentence: '3月最大的变化不是某一项单独变好，而是“看课程 + 刷题 + 考试”已经形成稳定循环，所以综合表现全面抬升。',
      },
      dimension_analysis: [
        {
          dimension: '课程学习时长',
          title: '知识框架明显补齐',
          analysis: '3月把课程学习时段固定下来后，原本零散的知识点开始串联成体系，后续做题和考试时的理解速度明显变快。',
          tip: '课程时长的提升，不只是看得多，而是让后面的刷题和考试有了基础。',
        },
        {
          dimension: '刷题数量',
          title: '练习密度快速拉高',
          analysis: '本月刷题量大幅增加，对常见题型、重点考点和易错点都有了更高熟悉度，所以答题稳定性比上月高很多。',
          tip: '高频训练是这次显著进步最直接的推动力之一。',
        },
        {
          dimension: '测评得分',
          title: '考试表现完成兑现',
          analysis: '课程学习打底、刷题训练加固、错题复盘修正后，3月测评表现已经从“勉强通过”抬升到“明显优秀”，成长感非常直观。',
          tip: '当前要做的不是重新起步，而是把高分状态稳定住。',
        },
      ],
      action_plan: {
        consolidate: [
          '继续保持固定课程学习时段，避免知识输入重新碎片化。',
          '维持当前刷题频率，把高正确率变成稳定输出。',
        ],
        improve: [
          '把新增训练量进一步聚焦到薄弱知识模块，争取把综合表现从优秀稳定到卓越。',
          '考试后保留错题复盘动作，让高分状态持续兑现。',
        ],
      },
      closing_message: '这份报告最适合用于演示“第一次接触平台后，如何通过课程、刷题和考试形成显著成长”。',
    }),
  }

  return {
    periodType: 'monthly',
    report: currentReport,
    historyReports: [previousReport, currentReport],
  }
}
