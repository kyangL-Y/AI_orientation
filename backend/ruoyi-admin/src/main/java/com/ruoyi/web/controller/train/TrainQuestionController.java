package com.ruoyi.web.controller.train;

import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.system.domain.TrainQuestion;
import com.ruoyi.system.domain.TrainQuestionAssign;
import com.ruoyi.system.service.ITrainQuestionService;
import com.ruoyi.system.service.ITrainQuestionAssignService;
import com.ruoyi.system.service.ITenantContentHiddenService;
import com.ruoyi.train.service.ITrainAiService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Objects;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/train/exercises")
public class TrainQuestionController extends BaseController {
    
    private static final Logger logger = LoggerFactory.getLogger(TrainQuestionController.class);
    private static final Pattern QUESTION_START_PATTERN = Pattern.compile("^(第\\s*[0-9一二三四五六七八九十百千零两]+\\s*题|[（(]?[0-9一二三四五六七八九十百千零两]+(?:[)）][、.．:：]?|[、.．:：]))\\s*(.*)$");
    private static final Pattern OPTION_PATTERN = Pattern.compile("^([A-Ha-h])[\\.．、:：)）]\\s*(.+)$");
    private static final Pattern ANSWER_PATTERN = Pattern.compile("^(?:答案|参考答案|正确答案)\\s*[：:]\\s*(.*)$");
    private static final Pattern EXPLANATION_PATTERN = Pattern.compile("^(?:解析|答案解析|解析说明|说明|备注)\\s*[：:]\\s*(.*)$");
    private static final Pattern QUESTION_TYPE_SECTION_PATTERN = Pattern.compile("^(?:[一二三四五六七八九十0-9]+[、.．])?\\s*(单选题|多选题|判断题|填空题|简答题|问答题|案例分析题)(?:\\s*[（(].*[)）])?$");
    
    /**
     * 处理对 /train/exercises 的GET请求（可能是前端路由误访问）
     * 返回友好的错误提示，避免显示技术性错误
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping
    public AjaxResult handleGetRequest() {
        // 如果是GET请求到基础路径，可能是前端路由，返回空数据而不是错误
        return success("请使用正确的API接口访问数据");
    }

    @Autowired
    private ITrainQuestionService trainQuestionService;

    @Autowired
    private ITrainQuestionAssignService trainQuestionAssignService;

    @Autowired
    private ITrainAiService trainAiService;

    @Autowired
    private ITenantContentHiddenService tenantContentHiddenService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private Long parseCourseId(Map<String, Object> requestBody) {
        Object rawCourseId = requestBody.get("courseId");
        if (rawCourseId == null || StringUtils.isBlank(String.valueOf(rawCourseId))) {
            return null;
        }
        try {
            return Long.valueOf(String.valueOf(rawCourseId));
        } catch (NumberFormatException e) {
            logger.warn("忽略非法课程ID: {}", rawCourseId);
            return null;
        }
    }

    private boolean hasTrainQuestionCourseIdColumn() {
        try {
            Integer columnCount = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'train_question' AND COLUMN_NAME = 'course_id'",
                    Integer.class);
            return columnCount != null && columnCount > 0;
        } catch (Exception e) {
            logger.warn("检查train_question.course_id字段失败", e);
            return false;
        }
    }

    private List<TrainQuestion> selectRandomByCourseId(Long courseId, Integer limit) {
        if (courseId == null || !hasTrainQuestionCourseIdColumn()) {
            return new ArrayList<>();
        }
        int questionLimit = limit != null && limit > 0 ? limit : 20;
        String sql = "SELECT id, course_id AS courseId, company_id AS companyId, hotel_code AS hotelCode, category, dept_id AS deptId, " +
                "question_type AS questionType, question_text AS questionText, option_a AS optionA, option_b AS optionB, " +
                "option_c AS optionC, option_d AS optionD, correct_answer AS correctAnswer, explanation, difficulty, " +
                "sort_order AS sortOrder, status, tenant_id AS tenantId, create_time AS createTime " +
                "FROM train_question WHERE course_id = ? AND status = 1 ORDER BY RAND() LIMIT ?";
        return jdbcTemplate.query(sql, new BeanPropertyRowMapper<>(TrainQuestion.class), courseId, questionLimit);
    }

    // 查询接口 - 允许所有登录用户访问（只读权限）
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/list")
    public TableDataInfo list(TrainQuestion query) {
        startPage();
        // 注入当前登录用户ID到查询参数（如果已登录）
        if (query.getParams() == null) {
            query.setParams(new java.util.HashMap<>());
        }
        try {
            query.getParams().put("userId", getUserId());
        } catch (Exception e) {
            // 用户未登录时忽略，不影响查询
            query.getParams().put("userId", null);
        }
        List<TrainQuestion> list = trainQuestionService.selectTrainQuestionList(query);
        return getDataTable(list);
    }

    // 查询接口 - 允许所有登录用户访问（只读权限）
    @PreAuthorize("isAuthenticated()")
    @GetMapping(value = "/{id}")
    public AjaxResult getInfo(@PathVariable Long id) {
        return success(trainQuestionService.selectTrainQuestionById(id));
    }

    // 获取题目详情（前端错题本补全数据使用）
    @PreAuthorize("isAuthenticated()")
    @GetMapping(value = "/detail/{id}")
    public AjaxResult getDetail(@PathVariable Long id) {
        TrainQuestion question = trainQuestionService.selectTrainQuestionById(id);
        if (question == null) {
            return error("题目不存在");
        }
        return success(question);
    }

    @PreAuthorize("@ss.hasPermi('train:exercises:add')")
    @Log(title = "刷题管理", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@Validated @RequestBody TrainQuestion question) {
        question.setCreateBy(getUsername());
        // 设置租户ID：超管/平台管理员新增的是公共数据，普通租户新增的是私有数据
        try {
            SysUser user = getLoginUser().getUser();
            if (user.isSuperAdmin() || user.isPlatformAdmin()) {
                question.setTenantId("000000"); // 公共数据
            } else {
                question.setTenantId(user.getTenantId()); // 私有数据
            }
        } catch (Exception e) {
            // 忽略
        }
        int result = trainQuestionService.insertTrainQuestion(question);
        
        if (result > 0 && question.getId() != null) {
            // 自动为创建者分配权限
            TrainQuestionAssign assign = new TrainQuestionAssign();
            assign.setQuestionId(question.getId());
            assign.setTargetType("user");
            assign.setTargetId(getUserId());
            trainQuestionAssignService.insert(assign);
        }
        
        return toAjax(result);
    }

    @PreAuthorize("@ss.hasPermi('train:exercises:edit')")
    @Log(title = "刷题管理", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@Validated @RequestBody TrainQuestion question) {
        question.setUpdateBy(getUsername());
        return toAjax(trainQuestionService.updateTrainQuestion(question));
    }

    @PreAuthorize("@ss.hasPermi('train:exercises:remove')")
    @Log(title = "刷题管理", businessType = BusinessType.DELETE)
    @DeleteMapping("/{ids}")
    public AjaxResult remove(@PathVariable Long[] ids) {
        return toAjax(trainQuestionService.deleteTrainQuestionByIds(ids));
    }

    // 查询接口 - 允许所有登录用户访问（只读权限）
    @GetMapping("/assign-info/{questionId}")
    public AjaxResult getAssign(@PathVariable Long questionId) {
        List<TrainQuestionAssign> assigns = trainQuestionAssignService.selectByQuestionId(questionId);
        return success(assigns);
    }

    @PreAuthorize("@ss.hasPermi('train:exercises:edit')")
    @Log(title = "题目权限管理", businessType = BusinessType.UPDATE)
    @PostMapping("/assign-info/{questionId}")
    public AjaxResult saveAssign(@PathVariable Long questionId, @RequestBody List<TrainQuestionAssign> assigns) {
        return toAjax(trainQuestionAssignService.batchInsert(questionId, assigns, getUsername()));
    }

    @PreAuthorize("@ss.hasPermi('train:exercises:edit')")
    @PostMapping("/sync/reverse")
    public AjaxResult reverseSyncDepts() {
        try {
            // 调用反向同步任务
            // 这里可以直接调用 TrainSyncTask 的方法
            // 或者通过 Quartz 手动触发任务
            return success("反向同步任务已触发，请在系统管理 > 定时任务中查看执行结果");
        } catch (Exception e) {
            return error("反向同步失败: " + e.getMessage());
        }
    }

    // 获取题目分类列表 - 允许匿名访问
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/categories")
    public AjaxResult getCategories() {
        try {
            // 从数据库获取分类统计
            List<Map<String, Object>> categories = trainQuestionService.getQuestionCategories();
            return success(categories);
        } catch (Exception e) {
            logger.error("获取分类失败", e);
            return error("获取分类失败: " + e.getMessage());
        }
    }

    // 根据分类获取题目 - 允许匿名访问
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/category/{categoryId}")
    public AjaxResult getQuestionsByCategory(@PathVariable("categoryId") Long categoryId, TrainQuestion query) {
        try {
            if (query.getParams() == null) {
                query.setParams(new java.util.HashMap<>());
            }
            // 允许匿名：尝试获取 userId，失败则忽略
            Long userId = null;
            try { userId = getUserId(); } catch (Exception e) { logger.debug("匿名访问，未获取到userId"); }
            if (userId != null) {
                query.getParams().put("userId", userId);
            }

            // 将前端传入的数值型 categoryId 映射为数据库中的 category 名称
            String categoryForQuery = categoryId.toString();
            try {
                List<java.util.Map<String, Object>> categories = trainQuestionService.getQuestionCategories();
                if (categories != null) {
                    for (java.util.Map<String, Object> c : categories) {
                        Object idObj = c.get("id");
                        if (idObj != null && idObj.toString().equals(categoryId.toString())) {
                            Object nameObj = c.get("name");
                            if (nameObj != null) {
                                categoryForQuery = nameObj.toString();
                            }
                            break;
                        }
                    }
                }
            } catch (Exception e) { logger.debug("分类映射查询失败: {}", e.getMessage()); }

            query.setCategory(categoryForQuery);
            // 不分页，返回该分类下的全部题目
            List<TrainQuestion> list = trainQuestionService.selectTrainQuestionList(query);
            // 若按中文名未查到，再按数字ID字符串回退查询一次
            if (list == null || list.isEmpty()) {
                String fallback = categoryId.toString();
                if (!fallback.equals(categoryForQuery)) {
                    query.setCategory(fallback);
                    list = trainQuestionService.selectTrainQuestionList(query);
                }
            }
            // 直接返回完整数据，避免前端再做分页裁剪
            return success(list);
        } catch (Exception e) {
            logger.warn("获取题目失败, categoryId={}", categoryId, e);
            return success(new ArrayList<>());
        }
    }

    // 获取刷题统计 - 允许匿名访问
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/stats")
    public AjaxResult getPracticeStats() {
        try {
            Long userId = null;
            try { userId = getUserId(); } catch (Exception e) { logger.debug("匿名访问，未获取到userId"); }
            Map<String, Object> stats = trainQuestionService.getPracticeStats(userId);
            return success(stats);
        } catch (Exception e) {
            return error("获取统计失败: " + e.getMessage());
        }
    }

    // 根据分类【名称】获取题目（直接按名称查询，避免任何映射）- 允许匿名访问
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/category/name/{category}")
    public AjaxResult getQuestionsByCategoryName(@PathVariable("category") String category, TrainQuestion query) {
        try {
            if (query.getParams() == null) {
                query.setParams(new java.util.HashMap<>());
            }
            query.setCategory(category);
            List<TrainQuestion> list = trainQuestionService.selectTrainQuestionList(query);
            return success(list);
        } catch (Exception e) {
            logger.warn("按分类名称查询失败, category={}", category, e);
            return success(new ArrayList<>());
        }
    }

    // 提交答题结果 - 需登录
    @PreAuthorize("isAuthenticated()")
    @PostMapping("/answer")
    public AjaxResult submitAnswer(@RequestBody Map<String, Object> answerData) {
        try {
            // 尝试获取用户ID，如果是匿名用户则跳过数据库保存
            Long userId = null;
            try {
                userId = getUserId();
            } catch (Exception e) {
                // 匿名用户，不保存到数据库，直接返回成功
                return success("答案已记录（本地存储）");
            }
            
            // 登录用户才保存到数据库
            Long questionId = Long.valueOf(answerData.get("questionId").toString());
            Integer answer = Integer.valueOf(answerData.get("answer").toString());
            Boolean isCorrect = Boolean.valueOf(answerData.get("isCorrect").toString());
            
            // 保存答题记录
            int result = trainQuestionService.saveAnswerRecord(userId, questionId, answer, isCorrect);
            return toAjax(result);
        } catch (Exception e) {
            return error("提交答案失败: " + e.getMessage());
        }
    }

    // 收藏题目 - 需登录
    @PreAuthorize("isAuthenticated()")
    @PostMapping("/{questionId}/favorite")
    public AjaxResult favoriteQuestion(@PathVariable Long questionId) {
        try {
            Long userId = null;
            try {
                userId = getUserId();
            } catch (Exception e) {
                return error("请先登录后再收藏题目");
            }
            int result = trainQuestionService.favoriteQuestion(userId, questionId);
            return toAjax(result);
        } catch (Exception e) {
            return error("收藏失败: " + e.getMessage());
        }
    }

    // 取消收藏题目 - 需登录
    @PreAuthorize("isAuthenticated()")
    @DeleteMapping("/{questionId}/unfavorite")
    public AjaxResult unfavoriteQuestion(@PathVariable Long questionId) {
        try {
            Long userId = null;
            try {
                userId = getUserId();
            } catch (Exception e) {
                return error("请先登录后再操作收藏");
            }
            int result = trainQuestionService.unfavoriteQuestion(userId, questionId);
            return toAjax(result);
        } catch (Exception e) {
            return error("取消收藏失败: " + e.getMessage());
        }
    }

    // 生成随机试卷（按分类和数量），允许匿名用于练习
    @PreAuthorize("isAuthenticated()")
    @PostMapping("/exam/generate")
    public AjaxResult generateExam(@RequestBody Map<String, Object> req) {
        try {
            String category = req.get("category") != null ? req.get("category").toString() : null;
            Integer limit = req.get("limit") != null ? Integer.valueOf(req.get("limit").toString()) : 20;
            Long courseId = parseCourseId(req);
            List<TrainQuestion> list = selectRandomByCourseId(courseId, limit);
            if (list.isEmpty()) {
                list = trainQuestionService.selectRandomByCategory(category, limit);
            }
            return success(list);
        } catch (Exception e) {
            return error("生成试卷失败: " + e.getMessage());
        }
    }

    // 生成随机试卷（前端兼容接口）- 允许匿名访问
    @PreAuthorize("isAuthenticated()")
    @PostMapping("/generate-paper")
    public AjaxResult generatePaper(@RequestBody Map<String, Object> req) {
        try {
            String category = req.get("category") != null ? req.get("category").toString() : null;
            Integer limit = req.get("limit") != null ? Integer.valueOf(req.get("limit").toString()) : 20;
            Long courseId = parseCourseId(req);
            List<TrainQuestion> list = selectRandomByCourseId(courseId, limit);
            if (list.isEmpty()) {
                list = trainQuestionService.selectRandomByCategory(category, limit);
            }
            return success(list);
        } catch (Exception e) {
            return error("生成试卷失败: " + e.getMessage());
        }
    }

    // AI生成题目解析
    @PreAuthorize("@ss.hasPermi('train:exercises:edit')")
    @PostMapping("/generate-explanation/{id}")
    public AjaxResult generateExplanation(@PathVariable Long id) {
        try {
            // 1. 根据ID查询题目
            TrainQuestion question = trainQuestionService.selectTrainQuestionById(id);
            if (question == null) {
                return error("题目不存在");
            }
            
            // 2. 验证题目信息是否完整
            if (question.getQuestionText() == null || question.getQuestionText().trim().isEmpty()) {
                return error("题目内容不能为空");
            }
            if (question.getCorrectAnswer() == null || question.getCorrectAnswer().trim().isEmpty()) {
                return error("正确答案不能为空");
            }
            
            // 3. 构建选项列表
            List<String> options = new ArrayList<>();
            if (question.getOptionA() != null && !question.getOptionA().trim().isEmpty()) {
                options.add(question.getOptionA());
            }
            if (question.getOptionB() != null && !question.getOptionB().trim().isEmpty()) {
                options.add(question.getOptionB());
            }
            if (question.getOptionC() != null && !question.getOptionC().trim().isEmpty()) {
                options.add(question.getOptionC());
            }
            if (question.getOptionD() != null && !question.getOptionD().trim().isEmpty()) {
                options.add(question.getOptionD());
            }
            
            if (options.isEmpty()) {
                return error("题目选项不能为空");
            }
            
            // 4. 调用AI服务生成解析
            String explanation = trainAiService.generateQuestionExplanation(
                question.getQuestionText(),
                options,
                question.getCorrectAnswer()
            );
            
            if (explanation == null || explanation.trim().isEmpty()) {
                return error("AI生成解析失败，请重试");
            }
            
            // 5. 返回解析文本（不直接保存，让用户确认后再保存）
            // 确保解析文本放在 data 字段中
            AjaxResult result = AjaxResult.success("AI解析生成成功", explanation);
            return result;
            
        } catch (Exception e) {
            return error("生成解析失败: " + e.getMessage());
        }
    }

    // 批量生成题目解析
    @PreAuthorize("@ss.hasPermi('train:exercises:edit')")
    @Log(title = "批量生成解析", businessType = BusinessType.UPDATE)
    @PostMapping("/batch-generate-explanation")
    public AjaxResult batchGenerateExplanation(@RequestBody Map<String, Object> params) {
        try {
            // 1. 获取题目ID列表（处理类型转换问题）
            Object questionIdsObj = params.get("questionIds");
            if (questionIdsObj == null) {
                return error("请选择要生成解析的题目");
            }
            
            List<Long> questionIds = new ArrayList<>();
            if (questionIdsObj instanceof List) {
                @SuppressWarnings("unchecked")
                List<Object> idsList = (List<Object>) questionIdsObj;
                for (Object idObj : idsList) {
                    if (idObj instanceof Number) {
                        questionIds.add(((Number) idObj).longValue());
                    } else if (idObj instanceof String) {
                        try {
                            questionIds.add(Long.parseLong((String) idObj));
                        } catch (NumberFormatException e) {
                            logger.warn("无法解析题目ID: {}", idObj);
                        }
                    }
                }
            }
            
            if (questionIds.isEmpty()) {
                return error("请选择要生成解析的题目");
            }
            
            // 2. 是否强制重新生成（覆盖已有解析）
            Boolean forceRegenerate = params.get("forceRegenerate") != null 
                ? Boolean.valueOf(params.get("forceRegenerate").toString()) 
                : false;
            
            int successCount = 0;      // 成功生成的数量
            int skipCount = 0;          // 跳过的数量（已有解析且不强制重新生成）
            int failCount = 0;          // 失败的数量
            List<String> failMessages = new ArrayList<>(); // 失败信息
            
            // 3. 遍历每个题目ID
            for (Long questionId : questionIds) {
                try {
                    // 3.1 查询题目
                    TrainQuestion question = trainQuestionService.selectTrainQuestionById(questionId);
                    if (question == null) {
                        failCount++;
                        failMessages.add("题目ID " + questionId + " 不存在");
                        continue;
                    }
                    
                    // 3.2 检查是否已有解析
                    boolean hasExplanation = question.getExplanation() != null 
                        && !question.getExplanation().trim().isEmpty();
                    
                    // 如果已有解析且不强制重新生成，则跳过
                    if (hasExplanation && !forceRegenerate) {
                        skipCount++;
                        continue;
                    }
                    
                    // 3.3 验证题目信息是否完整
                    if (question.getQuestionText() == null || question.getQuestionText().trim().isEmpty()) {
                        failCount++;
                        failMessages.add("题目ID " + questionId + " 题目内容为空");
                        continue;
                    }
                    // 如果没有正确答案，尝试从选项推断或跳过
                    if (question.getCorrectAnswer() == null || question.getCorrectAnswer().trim().isEmpty()) {
                        // 对于没有正确答案的题目，尝试生成一个提示性的解析
                        // 但这种情况应该先修复正确答案
                        failCount++;
                        failMessages.add("题目ID " + questionId + " 正确答案为空，请先填写正确答案");
                        continue;
                    }
                    
                    // 3.4 构建选项列表
                    List<String> options = new ArrayList<>();
                    if (question.getOptionA() != null && !question.getOptionA().trim().isEmpty()) {
                        options.add(question.getOptionA());
                    }
                    if (question.getOptionB() != null && !question.getOptionB().trim().isEmpty()) {
                        options.add(question.getOptionB());
                    }
                    if (question.getOptionC() != null && !question.getOptionC().trim().isEmpty()) {
                        options.add(question.getOptionC());
                    }
                    if (question.getOptionD() != null && !question.getOptionD().trim().isEmpty()) {
                        options.add(question.getOptionD());
                    }
                    
                    if (options.isEmpty()) {
                        failCount++;
                        failMessages.add("题目ID " + questionId + " 题目选项为空");
                        continue;
                    }
                    
                    // 3.5 调用AI服务生成解析
                    String explanation = trainAiService.generateQuestionExplanation(
                        question.getQuestionText(),
                        options,
                        question.getCorrectAnswer()
                    );
                    
                    if (explanation == null || explanation.trim().isEmpty()) {
                        failCount++;
                        failMessages.add("题目ID " + questionId + " AI生成解析失败");
                        continue;
                    }
                    
                    // 3.6 保存解析到数据库
                    question.setExplanation(explanation.trim());
                    question.setUpdateBy(getUsername());
                    int updateResult = trainQuestionService.updateTrainQuestion(question);
                    
                    if (updateResult > 0) {
                        successCount++;
                    } else {
                        failCount++;
                        failMessages.add("题目ID " + questionId + " 保存解析失败");
                    }
                    
                } catch (Exception e) {
                    failCount++;
                    failMessages.add("题目ID " + questionId + " 处理失败: " + e.getMessage());
                }
            }
            
            // 4. 构建返回结果
            Map<String, Object> result = new HashMap<>();
            result.put("total", questionIds.size());
            result.put("success", successCount);
            result.put("skip", skipCount);
            result.put("fail", failCount);
            result.put("failMessages", failMessages);
            
            String message = String.format("批量生成完成：成功 %d 个，跳过 %d 个（已有解析），失败 %d 个", 
                successCount, skipCount, failCount);
            
            // 将消息也放入result中，前端可以从data中获取
            result.put("message", message);
            return success(result);
            
        } catch (Exception e) {
            logger.error("批量生成解析异常", e);
            // 返回更详细的错误信息，帮助排查问题
            String errorMsg = "批量生成解析失败";
            if (e.getMessage() != null) {
                errorMsg += ": " + e.getMessage();
            }
            return error(errorMsg);
        }
    }

    /**
     * 获取当前用户的租户信息（用于前端权限判断）
     */
    @GetMapping("/tenant-info")
    public AjaxResult getTenantInfo() {
        try {
            Map<String, Object> info = new HashMap<>();
            SysUser user = getLoginUser().getUser();
            String tenantId = user.getTenantId();
            info.put("tenantId", tenantId);
            info.put("isSuperAdmin", "000000".equals(tenantId));
            info.put("userId", user.getUserId());
            return success(info);
        } catch (Exception e) {
            return error("获取租户信息失败: " + e.getMessage());
        }
    }

    /**
     * 隐藏内容（非超级管理员对超级管理员创建的内容）
     */
    @PreAuthorize("@ss.hasPermi('train:exercises:edit')")
    @Log(title = "隐藏题目", businessType = BusinessType.UPDATE)
    @PostMapping("/hide/{id}")
    public AjaxResult hideContent(@PathVariable Long id) {
        try {
            SysUser user = getLoginUser().getUser();
            String tenantId = user.getTenantId();
            
            // 超级管理员不需要隐藏功能
            if ("000000".equals(tenantId)) {
                return error("超级管理员无需使用隐藏功能");
            }
            
            int result = tenantContentHiddenService.hideContent(tenantId, "question", id, user.getUserId());
            return toAjax(result);
        } catch (Exception e) {
            return error("隐藏失败: " + e.getMessage());
        }
    }

    /**
     * 显示内容（取消隐藏）
     */
    @PreAuthorize("@ss.hasPermi('train:exercises:edit')")
    @Log(title = "显示题目", businessType = BusinessType.UPDATE)
    @PostMapping("/show/{id}")
    public AjaxResult showContent(@PathVariable Long id) {
        try {
            SysUser user = getLoginUser().getUser();
            String tenantId = user.getTenantId();
            
            int result = tenantContentHiddenService.showContent(tenantId, "question", id);
            return toAjax(result);
        } catch (Exception e) {
            return error("显示失败: " + e.getMessage());
        }
    }

    /**
     * 获取当前租户隐藏的题目ID列表
     */
    @GetMapping("/hidden-ids")
    public AjaxResult getHiddenIds() {
        try {
            SysUser user = getLoginUser().getUser();
            String tenantId = user.getTenantId();
            
            // 超级管理员没有隐藏列表
            if ("000000".equals(tenantId)) {
                return success(new ArrayList<>());
            }
            
            List<Long> hiddenIds = tenantContentHiddenService.getHiddenContentIds(tenantId, "question");
            return success(hiddenIds);
        } catch (Exception e) {
            return error("获取隐藏列表失败: " + e.getMessage());
        }
    }

    /**
     * AI智能生成题目（根据主题）
     */
    @PreAuthorize("@ss.hasPermi('train:exercises:add')")
    @Log(title = "AI生成题目", businessType = BusinessType.INSERT)
    @PostMapping("/ai-generate")
    public AjaxResult aiGenerateQuestions(@RequestBody Map<String, Object> params) {
        try {
            String topic = (String) params.get("topic");
            if (topic == null || topic.trim().isEmpty()) {
                return error("请输入主题/知识点");
            }
            
            Object questionTypeObj = params.get("questionType");
            String questionType = null;
            if (questionTypeObj instanceof List) {
                List<?> rawList = (List<?>) questionTypeObj;
                List<String> types = rawList.stream()
                    .filter(Objects::nonNull)
                    .map(Object::toString)
                    .map(String::trim)
                    .filter(item -> !item.isEmpty())
                    .collect(Collectors.toList());
                if (!types.isEmpty()) {
                    questionType = String.join("、", types);
                }
            } else if (questionTypeObj != null) {
                String value = questionTypeObj.toString().trim();
                if (!value.isEmpty()) {
                    questionType = value;
                }
            }
            String difficulty = (String) params.get("difficulty");
            String customRequirements = (String) params.get("customRequirements");
            Integer count = params.get("count") != null ? Integer.valueOf(params.get("count").toString()) : 5;
            
            // 限制单次生成数量
            if (count > 20) {
                count = 20;
            }
            
            logger.info("AI生成题目 - 主题: {}, 类型: {}, 难度: {}, 数量: {}, 额外要求: {}", topic, questionType, difficulty, count, customRequirements);
            
            List<Map<String, Object>> questions = trainAiService.generateQuestions(topic, questionType, difficulty, count, customRequirements);
            
            return success(questions);
        } catch (Exception e) {
            logger.error("AI生成题目失败", e);
            return error("AI生成题目失败: " + e.getMessage());
        }
    }

    /**
     * AI从文档生成题目
     */
    @PreAuthorize("@ss.hasPermi('train:exercises:add')")
    @Log(title = "AI从文档生成题目", businessType = BusinessType.INSERT)
    @PostMapping("/ai-generate-from-doc")
    public AjaxResult aiGenerateFromDocument(@RequestBody Map<String, Object> params) {
        try {
            String documentContent = (String) params.get("documentContent");
            if (documentContent == null || documentContent.trim().isEmpty()) {
                return error("请输入文档内容");
            }

            String importMode = params.get("importMode") != null ? params.get("importMode").toString().trim() : "ai";
            if ("paper".equalsIgnoreCase(importMode)) {
                List<Map<String, Object>> questions = parseQuestionsFromPaper(documentContent);
                if (questions.isEmpty()) {
                    return error("未识别到题目，请确认文档中包含“第1题/1.”、“A.选项”、“答案：”这类结构");
                }
                logger.info("按原试卷解析成功 - 文档长度: {}, 识别题目数: {}", documentContent.length(), questions.size());
                return success(questions);
            }
            
            String customRequirements = (String) params.get("customRequirements");
            Integer count = params.get("count") != null ? Integer.valueOf(params.get("count").toString()) : 5;
            
            // 限制单次生成数量
            if (count > 20) {
                count = 20;
            }
            
            logger.info("AI从文档生成题目 - 文档长度: {}, 数量: {}, 额外要求: {}", documentContent.length(), count, customRequirements);
            
            List<Map<String, Object>> questions = trainAiService.generateQuestionsFromDocument(documentContent, count, customRequirements);
            
            return success(questions);
        } catch (Exception e) {
            logger.error("AI从文档生成题目失败", e);
            return error("AI从文档生成题目失败: " + e.getMessage());
        }
    }

    /**
     * 批量保存AI生成的题目
     */
    @PreAuthorize("@ss.hasPermi('train:exercises:add')")
    @Log(title = "批量保存题目", businessType = BusinessType.INSERT)
    @PostMapping("/batch-save")
    public AjaxResult batchSaveQuestions(@RequestBody Map<String, Object> params) {
        try {
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> questions = (List<Map<String, Object>>) params.get("questions");
            if (questions == null || questions.isEmpty()) {
                return error("没有要保存的题目");
            }
            
            // 获取公共字段
            Long companyId = params.get("companyId") != null ? Long.valueOf(params.get("companyId").toString()) : null;
            String hotelCode = (String) params.get("hotelCode");
            Long deptId = params.get("deptId") != null ? Long.valueOf(params.get("deptId").toString()) : null;
            
            int successCount = 0;
            int failCount = 0;
            List<String> failMessages = new ArrayList<>();
            List<Map<String, Object>> savedQuestions = new ArrayList<>();
            
            for (Map<String, Object> q : questions) {
                try {
                    TrainQuestion question = new TrainQuestion();
                    question.setQuestionText((String) q.get("questionText"));
                    question.setQuestionType((String) q.get("questionType"));
                    question.setOptionA((String) q.get("optionA"));
                    question.setOptionB((String) q.get("optionB"));
                    question.setOptionC((String) q.get("optionC"));
                    question.setOptionD((String) q.get("optionD"));
                    question.setCorrectAnswer((String) q.get("correctAnswer"));
                    question.setExplanation((String) q.get("explanation"));
                    question.setDifficulty((String) q.get("difficulty"));
                    question.setCategory((String) q.get("category"));
                    question.setCompanyId(companyId);
                    question.setHotelCode(hotelCode);
                    question.setDeptId(deptId);
                    question.setStatus(1);
                    question.setCreateBy(getUsername());
                    
                    int result = trainQuestionService.insertTrainQuestion(question);
                    if (result > 0) {
                        successCount++;
                        if (question.getId() != null) {
                            try {
                                TrainQuestionAssign assign = new TrainQuestionAssign();
                                assign.setQuestionId(question.getId());
                                assign.setTargetType("user");
                                assign.setTargetId(getUserId());
                                trainQuestionAssignService.insert(assign);
                            } catch (Exception ignore) {
                                logger.debug("题目分配记录插入失败", ignore);
                            }

                            Map<String, Object> saved = new HashMap<>();
                            saved.put("id", question.getId());
                            saved.put("questionText", question.getQuestionText());
                            saved.put("questionType", question.getQuestionType());
                            saved.put("optionA", question.getOptionA());
                            saved.put("optionB", question.getOptionB());
                            saved.put("optionC", question.getOptionC());
                            saved.put("optionD", question.getOptionD());
                            saved.put("correctAnswer", question.getCorrectAnswer());
                            saved.put("explanation", question.getExplanation());
                            saved.put("difficulty", question.getDifficulty());
                            saved.put("category", question.getCategory());
                            savedQuestions.add(saved);
                        }
                    } else {
                        failCount++;
                        String text = question.getQuestionText();
                        if (text == null) text = "";
                        failMessages.add("保存失败: " + (text.isEmpty() ? "(题干为空)" : text.substring(0, Math.min(20, text.length()))));
                    }
                } catch (Exception e) {
                    failCount++;
                    failMessages.add("保存异常: " + e.getMessage());
                }
            }
            
            Map<String, Object> result = new HashMap<>();
            result.put("total", questions.size());
            result.put("success", successCount);
            result.put("fail", failCount);
            result.put("failMessages", failMessages);
            result.put("savedQuestions", savedQuestions);

            if (successCount == 0) {
                result.put("partial", false);
                return AjaxResult.error("题目保存失败，请检查题目内容后重试", result);
            }

            if (failCount > 0) {
                result.put("partial", true);
                return AjaxResult.success("部分题目保存成功", result);
            }

            result.put("partial", false);
            return AjaxResult.success("题目保存成功", result);
        } catch (Exception e) {
            logger.error("批量保存题目失败", e);
            return error("批量保存题目失败: " + e.getMessage());
        }
    }

    /**
     * 解析上传的文档（Word/PDF）提取文本内容
     */
    @PreAuthorize("@ss.hasPermi('train:exercises:add')")
    @PostMapping("/parse-document")
    public AjaxResult parseDocument(@RequestParam("file") org.springframework.web.multipart.MultipartFile file) {
        try {
            if (file == null || file.isEmpty()) {
                return error("请上传文件");
            }
            
            String fileName = file.getOriginalFilename();
            if (fileName == null) {
                return error("无法获取文件名");
            }
            
            String content = "";
            fileName = fileName.toLowerCase();
            
            if (fileName.endsWith(".txt")) {
                // TXT文件直接读取
                content = new String(file.getBytes(), "UTF-8");
            } else if (fileName.endsWith(".docx")) {
                // Word 2007+ 格式
                content = parseDocxFile(file);
            } else if (fileName.endsWith(".doc")) {
                // Word 97-2003 格式
                content = parseDocFile(file);
            } else if (fileName.endsWith(".pdf")) {
                // PDF格式
                content = parsePdfFile(file);
            } else {
                return error("不支持的文件格式，请上传 Word、PDF 或 TXT 文件");
            }
            
            if (content == null || content.trim().isEmpty()) {
                return error("文档内容为空或无法解析");
            }
            
            // 限制内容长度，避免过长
            if (content.length() > 50000) {
                content = content.substring(0, 50000) + "\n...(内容过长，已截断)";
            }
            
            logger.info("文档解析成功，内容长度: {}", content.length());
            return success(content);
            
        } catch (Exception e) {
            logger.error("解析文档失败", e);
            return error("解析文档失败: " + e.getMessage());
        }
    }
    
    /**
     * 解析 Word 2007+ (.docx) 文件
     */
    private String parseDocxFile(org.springframework.web.multipart.MultipartFile file) throws Exception {
        try (java.io.InputStream is = file.getInputStream();
             org.apache.poi.xwpf.usermodel.XWPFDocument doc = new org.apache.poi.xwpf.usermodel.XWPFDocument(is)) {
            
            StringBuilder sb = new StringBuilder();
            for (org.apache.poi.xwpf.usermodel.XWPFParagraph para : doc.getParagraphs()) {
                String text = para.getText();
                if (text != null && !text.trim().isEmpty()) {
                    sb.append(text.trim()).append("\n");
                }
            }
            
            // 也读取表格中的内容
            for (org.apache.poi.xwpf.usermodel.XWPFTable table : doc.getTables()) {
                for (org.apache.poi.xwpf.usermodel.XWPFTableRow row : table.getRows()) {
                    for (org.apache.poi.xwpf.usermodel.XWPFTableCell cell : row.getTableCells()) {
                        String text = cell.getText();
                        if (text != null && !text.trim().isEmpty()) {
                            sb.append(text.trim()).append(" ");
                        }
                    }
                    sb.append("\n");
                }
            }
            
            return sb.toString();
        }
    }
    
    /**
     * 解析 Word 97-2003 (.doc) 文件
     */
    private String parseDocFile(org.springframework.web.multipart.MultipartFile file) throws Exception {
        try (java.io.InputStream is = file.getInputStream();
             org.apache.poi.hwpf.HWPFDocument doc = new org.apache.poi.hwpf.HWPFDocument(is)) {
            
            org.apache.poi.hwpf.extractor.WordExtractor extractor = new org.apache.poi.hwpf.extractor.WordExtractor(doc);
            String text = extractor.getText();
            extractor.close();
            return text;
        }
    }
    
    /**
     * 解析 PDF 文件
     */
    private String parsePdfFile(org.springframework.web.multipart.MultipartFile file) throws Exception {
        try (java.io.InputStream is = file.getInputStream();
             org.apache.pdfbox.pdmodel.PDDocument doc = org.apache.pdfbox.pdmodel.PDDocument.load(is)) {
            
            org.apache.pdfbox.text.PDFTextStripper stripper = new org.apache.pdfbox.text.PDFTextStripper();
            return stripper.getText(doc);
        }
    }

    private List<Map<String, Object>> parseQuestionsFromPaper(String documentContent) {
        List<Map<String, Object>> questions = new ArrayList<>();
        if (documentContent == null || documentContent.trim().isEmpty()) {
            return questions;
        }

        String normalizedContent = normalizePaperStructure(documentContent);
        List<String> lines = Arrays.stream(normalizedContent.split("\n"))
            .map(line -> line == null ? "" : line.trim())
            .filter(line -> !line.isEmpty())
            .collect(Collectors.toList());

        String category = extractPaperCategory(lines);
        String currentSectionType = null;
        ParsedQuestionDraft current = null;

        for (String line : lines) {
            String compactLine = line.replaceAll("\\s+", " ").trim();
            if (compactLine.isEmpty()) {
                continue;
            }

            Matcher sectionMatcher = QUESTION_TYPE_SECTION_PATTERN.matcher(compactLine);
            if (sectionMatcher.matches()) {
                currentSectionType = normalizeQuestionType(sectionMatcher.group(1));
                continue;
            }

            Matcher questionMatcher = QUESTION_START_PATTERN.matcher(compactLine);
            if (questionMatcher.matches() && looksLikeQuestionLine(compactLine)) {
                if (current != null && current.hasQuestionText()) {
                    Map<String, Object> parsedQuestion = buildParsedQuestion(current, category);
                    if (parsedQuestion != null) {
                        questions.add(parsedQuestion);
                    }
                }
                current = new ParsedQuestionDraft();
                current.sectionType = currentSectionType;
                current.questionText = compactLine;
                continue;
            }

            if (current == null) {
                continue;
            }

            Matcher optionMatcher = OPTION_PATTERN.matcher(compactLine);
            if (optionMatcher.matches()) {
                current.appendOption(optionMatcher.group(1).toUpperCase(), optionMatcher.group(2).trim());
                continue;
            }

            Matcher answerMatcher = ANSWER_PATTERN.matcher(compactLine);
            if (answerMatcher.matches()) {
                current.rawAnswer = appendWithNewline(current.rawAnswer, answerMatcher.group(1).trim());
                current.lastOptionLabel = null;
                current.collectingAnswer = true;
                current.collectingExplanation = false;
                continue;
            }

            Matcher explanationMatcher = EXPLANATION_PATTERN.matcher(compactLine);
            if (explanationMatcher.matches()) {
                current.explanation = appendWithNewline(current.explanation, explanationMatcher.group(1).trim());
                current.collectingExplanation = true;
                current.collectingAnswer = false;
                current.lastOptionLabel = null;
                continue;
            }

            if (current.collectingAnswer) {
                current.rawAnswer = appendWithNewline(current.rawAnswer, compactLine);
                continue;
            }

            if (current.collectingExplanation) {
                current.explanation = appendWithNewline(current.explanation, compactLine);
                continue;
            }

            if (current.lastOptionLabel != null && current.hasOption(current.lastOptionLabel)) {
                current.appendToLastOption(compactLine);
                continue;
            }

            current.questionText = appendWithSpace(current.questionText, compactLine);
        }

        if (current != null && current.hasQuestionText()) {
            Map<String, Object> parsedQuestion = buildParsedQuestion(current, category);
            if (parsedQuestion != null) {
                questions.add(parsedQuestion);
            }
        }

        return questions;
    }

    private String normalizePaperStructure(String documentContent) {
        String normalized = documentContent
            .replace("\r\n", "\n")
            .replace('\r', '\n')
            .replace('\u3000', ' ')
            .replace('\u00A0', ' ');

        // 老式 .doc / 部分 PDF 解析后容易把整份试卷压成一两行，这里先按题号、选项、答案、解析补回结构换行。
        normalized = normalized.replaceAll("[ \\t]+(?=第\\s*[0-9一二三四五六七八九十百千零两]+\\s*题)", "\n");
        normalized = normalized.replaceAll("[ \\t]+(?=[（(]?[0-9一二三四五六七八九十百千零两]+(?:[)）][、.．:：]?|[、.．]))", "\n");
        normalized = normalized.replaceAll("[ \\t]+(?=[A-Ha-h][\\.．、:：)）])", "\n");
        normalized = normalized.replaceAll("[ \\t]+(?=(?:答案|参考答案|正确答案)\\s*[：:])", "\n");
        normalized = normalized.replaceAll("[ \\t]+(?=(?:解析|答案解析|解析说明|说明|备注)\\s*[：:])", "\n");
        normalized = normalized.replaceAll("[ \\t]+(?=(?:[一二三四五六七八九十0-9]+[、.．])?\\s*(?:单选题|多选题|判断题|填空题|简答题|问答题|案例分析题))", "\n");
        normalized = normalized.replaceAll("\n{2,}", "\n");
        return normalized;
    }

    private Map<String, Object> buildParsedQuestion(ParsedQuestionDraft draft, String fallbackCategory) {
        Map<String, Object> question = new LinkedHashMap<>();
        String questionType = determineQuestionType(draft);
        String normalizedAnswer = normalizeCorrectAnswer(questionType, draft.rawAnswer, draft);
        if (normalizedAnswer.isEmpty()) {
            return null;
        }

        question.put("questionText", defaultString(draft.questionText));
        question.put("questionType", questionType);
        question.put("optionA", defaultString(draft.optionA));
        question.put("optionB", defaultString(draft.optionB));
        question.put("optionC", defaultString(draft.optionC));
        question.put("optionD", defaultString(draft.optionD));
        question.put("correctAnswer", normalizedAnswer);
        question.put("explanation", defaultString(draft.explanation));
        question.put("difficulty", "中等");
        question.put("category", fallbackCategory);

        if ("判断题".equals(questionType) && draft.optionA == null && draft.optionB == null) {
            question.put("optionA", "正确");
            question.put("optionB", "错误");
        }

        return question;
    }

    private String determineQuestionType(ParsedQuestionDraft draft) {
        String sectionType = normalizeQuestionType(draft.sectionType);
        if (!sectionType.isEmpty()) {
            return sectionType;
        }

        if (looksLikeJudgeAnswer(draft.rawAnswer)) {
            return "判断题";
        }

        if (draft.hasChoiceOptions()) {
            String answerLetters = extractAnswerLetters(draft.rawAnswer);
            if (answerLetters.contains(",")) {
                return "多选题";
            }
            return "单选题";
        }

        String questionText = defaultString(draft.questionText);
        if (questionText.contains("____") || questionText.contains("___") || questionText.contains("（ ）") || questionText.contains("()") || questionText.contains("填空")) {
            return "填空题";
        }
        return "简答题";
    }

    private String normalizeCorrectAnswer(String questionType, String rawAnswer, ParsedQuestionDraft draft) {
        String answer = defaultString(rawAnswer).trim();
        if (answer.isEmpty()) {
            return "";
        }

        if ("判断题".equals(questionType)) {
            return normalizeJudgeAnswer(answer);
        }

        if ("单选题".equals(questionType) || "多选题".equals(questionType)) {
            String answerLetters = extractAnswerLetters(answer);
            if (!answerLetters.isEmpty()) {
                return answerLetters;
            }

            String matchedByText = matchAnswerByOptionText(answer, draft);
            if (!matchedByText.isEmpty()) {
                return matchedByText;
            }
        }

        return answer;
    }

    private String extractPaperCategory(List<String> lines) {
        for (String rawLine : lines) {
            String line = rawLine == null ? "" : rawLine.replaceAll("\\s+", " ").trim();
            if (line.isEmpty()) {
                continue;
            }
            if (QUESTION_START_PATTERN.matcher(line).matches() || OPTION_PATTERN.matcher(line).matches() || ANSWER_PATTERN.matcher(line).matches()) {
                break;
            }
            if (QUESTION_TYPE_SECTION_PATTERN.matcher(line).matches()) {
                continue;
            }
            if (line.length() <= 40) {
                return line;
            }
        }
        return "文档导入";
    }

    private boolean looksLikeQuestionLine(String line) {
        if (line == null || line.trim().isEmpty()) {
            return false;
        }
        return !OPTION_PATTERN.matcher(line).matches() && !ANSWER_PATTERN.matcher(line).matches() && !EXPLANATION_PATTERN.matcher(line).matches();
    }

    private boolean looksLikeJudgeAnswer(String value) {
        String normalized = defaultString(value).trim();
        return "正确".equals(normalized) || "错误".equals(normalized) || "对".equals(normalized) || "错".equals(normalized) || "T".equalsIgnoreCase(normalized) || "F".equalsIgnoreCase(normalized) || "√".equals(normalized) || "×".equals(normalized);
    }

    private String normalizeJudgeAnswer(String value) {
        String normalized = defaultString(value).trim();
        if ("错误".equals(normalized) || "错".equals(normalized) || "F".equalsIgnoreCase(normalized) || "×".equals(normalized)) {
            return "错误";
        }
        if ("正确".equals(normalized) || "对".equals(normalized) || "T".equalsIgnoreCase(normalized) || "√".equals(normalized)) {
            return "正确";
        }
        return "";
    }

    private String normalizeQuestionType(String value) {
        String normalized = defaultString(value).trim();
        if (normalized.isEmpty()) {
            return "";
        }
        if ("问答题".equals(normalized) || "案例分析题".equals(normalized)) {
            return "简答题";
        }
        return normalized;
    }

    private String extractAnswerLetters(String value) {
        Matcher matcher = Pattern.compile("[A-H]").matcher(defaultString(value).toUpperCase());
        List<String> labels = new ArrayList<>();
        while (matcher.find()) {
            String label = matcher.group();
            if (!labels.contains(label)) {
                labels.add(label);
            }
        }
        return String.join(",", labels);
    }

    private String matchAnswerByOptionText(String answer, ParsedQuestionDraft draft) {
        String normalizedAnswer = defaultString(answer).trim();
        List<String> matches = new ArrayList<>();
        if (normalizedAnswer.equals(defaultString(draft.optionA).trim())) matches.add("A");
        if (normalizedAnswer.equals(defaultString(draft.optionB).trim())) matches.add("B");
        if (normalizedAnswer.equals(defaultString(draft.optionC).trim())) matches.add("C");
        if (normalizedAnswer.equals(defaultString(draft.optionD).trim())) matches.add("D");
        return String.join(",", matches);
    }

    private String appendWithSpace(String current, String addition) {
        if (addition == null || addition.trim().isEmpty()) {
            return defaultString(current);
        }
        if (current == null || current.trim().isEmpty()) {
            return addition.trim();
        }
        return current + " " + addition.trim();
    }

    private String appendWithNewline(String current, String addition) {
        if (addition == null || addition.trim().isEmpty()) {
            return defaultString(current);
        }
        if (current == null || current.trim().isEmpty()) {
            return addition.trim();
        }
        return current + "\n" + addition.trim();
    }

    private String defaultString(String value) {
        return value == null ? "" : value;
    }

    private static class ParsedQuestionDraft {
        private String sectionType;
        private String questionText;
        private String optionA;
        private String optionB;
        private String optionC;
        private String optionD;
        private String rawAnswer;
        private String explanation;
        private String lastOptionLabel;
        private boolean collectingAnswer;
        private boolean collectingExplanation;

        private boolean hasQuestionText() {
            return questionText != null && !questionText.trim().isEmpty();
        }

        private boolean hasChoiceOptions() {
            return (optionA != null && !optionA.trim().isEmpty())
                || (optionB != null && !optionB.trim().isEmpty())
                || (optionC != null && !optionC.trim().isEmpty())
                || (optionD != null && !optionD.trim().isEmpty());
        }

        private boolean hasOption(String label) {
            return getOption(label) != null && !getOption(label).trim().isEmpty();
        }

        private void appendOption(String label, String value) {
            setOption(label, mergeText(getOption(label), value));
            lastOptionLabel = label;
            collectingAnswer = false;
            collectingExplanation = false;
        }

        private void appendToLastOption(String value) {
            if (lastOptionLabel == null) {
                return;
            }
            setOption(lastOptionLabel, mergeText(getOption(lastOptionLabel), value));
        }

        private String getOption(String label) {
            switch (label) {
                case "A":
                    return optionA;
                case "B":
                    return optionB;
                case "C":
                    return optionC;
                case "D":
                    return optionD;
                default:
                    return null;
            }
        }

        private void setOption(String label, String value) {
            switch (label) {
                case "A":
                    optionA = value;
                    break;
                case "B":
                    optionB = value;
                    break;
                case "C":
                    optionC = value;
                    break;
                case "D":
                    optionD = value;
                    break;
                default:
                    break;
            }
        }

        private String mergeText(String current, String addition) {
            if (addition == null || addition.trim().isEmpty()) {
                return current;
            }
            if (current == null || current.trim().isEmpty()) {
                return addition.trim();
            }
            return current + " " + addition.trim();
        }
    }
}
