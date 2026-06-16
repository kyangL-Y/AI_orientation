# 用户端集成多智能体学习报告

## 🎯 待完成工作

### 1. 添加后端 Controller（Java）

```java
@RestController
@RequestMapping("/train/report/multi-agent")
public class MultiAgentReportController {
    
    @Autowired
    private IMultiAgentReportService multiAgentReportService;
    
    @PostMapping("/generate")
    public AjaxResult generateReport(@RequestBody ReportGenerateRequest request) {
        Long userId = SecurityUtils.getUserId();
        TrainLearningReport report = multiAgentReportService.generateReportWithMultiAgent(
            userId, request.getPeriodType(), SecurityUtils.getTenantId(),
            request.getStartDate(), request.getEndDate(), SecurityUtils.getDeptId()
        );
        return AjaxResult.success(report);
    }
    
    @GetMapping
    public AjaxResult getReport(@RequestParam String periodType) {
        // 查询数据库获取最新报告
        return AjaxResult.success(report);
    }
}
```

### 2. 添加前端 API（`src/api/userStatistics.js`）

```javascript
export const generateMultiAgentReport = (params = {}) => {
  return api.post('/train/report/multi-agent/generate', params)
}

export const getMultiAgentReport = (params = {}) => {
  return api.get('/train/report/multi-agent', { params })
}
```

### 3. 改造前端展示（`src/views/LearningReport.vue`）

多智能体返回的关键数据：

```javascript
{
  executive_summary: "本周期累计学习180分钟...",
  learning_profile: {
    duration_value: "180分钟",
    score_value: "85分",
    // ...
  },
  analysis_result: {
    weak_points: [...],      // 薄弱知识点
    knowledge_trends: [...], // 知识掌握趋势
  },
  recommendation_result: {
    review_contents: [...],  // 推荐复习内容
    next_courses: [...],     // 推荐课程
  },
  charts: [...],            // 图表数据
}
```

调用示例：

```javascript
async function handleGenerateReport() {
  generating.value = true
  try {
    const res = await generateMultiAgentReport({
      periodType: periodType.value,
      startDate: periodStart.value,
      endDate: periodEnd.value
    })
    report.value = res.data.data
    ElMessage.success('AI 智能报告生成成功')
  } finally {
    generating.value = false
  }
}
```

## 🚀 启动步骤

```bash
# 1. 启动 Python 服务
cd training-agent-muti_agent/multi_agent_system
python main.py

# 2. 启动 Java 后端
cd training-agent-muti_agent
mvn spring-boot:run

# 3. 启动用户端
cd training-agent-user-muti_agent
npm run dev
```

详细文档见：`training-agent-muti_agent/multi_agent_system/README.md`
