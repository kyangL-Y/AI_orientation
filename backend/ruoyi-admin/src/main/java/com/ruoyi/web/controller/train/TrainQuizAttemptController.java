package com.ruoyi.web.controller.train;

import java.util.List;
import java.util.Map;
import javax.servlet.http.HttpServletResponse;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.enums.DataSourceType;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.constant.MembershipLimitConstants;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.system.domain.TrainQuizAttempt;
import com.ruoyi.system.service.ITrainQuizAttemptService;
import com.ruoyi.train.service.IMembershipService;
import com.ruoyi.system.service.ITrainUserPointsService;
import com.ruoyi.common.utils.poi.ExcelUtil;
import com.ruoyi.common.core.page.TableDataInfo;
import org.springframework.jdbc.core.JdbcTemplate;

/**
 * 整场考试成绩Controller
 * 
 * @author ruoyi
 * @date 2025-01-27
 */
@RestController
@RequestMapping("/train/quiz")
public class TrainQuizAttemptController extends BaseController
{
    @Autowired
    private ITrainQuizAttemptService trainQuizAttemptService;

    @Autowired
    private IMembershipService membershipService;

    @Autowired
    private ITrainUserPointsService trainUserPointsService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private javax.sql.DataSource masterDataSource;

    /**
     * 查询整场考试成绩列表
     */
    @PreAuthorize("@ss.hasPermi('train:quiz:list')")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping("/list")
    public TableDataInfo list(TrainQuizAttempt trainQuizAttempt)
    {
        startPage();
        List<TrainQuizAttempt> list = trainQuizAttemptService.selectTrainQuizAttemptList(trainQuizAttempt);
        return getDataTable(list);
    }

    /**
     * 导出整场考试成绩列表
     */
    @PreAuthorize("@ss.hasPermi('train:quiz:export')")
    @DataSource(DataSourceType.SLAVE)
    @Log(title = "整场考试成绩", businessType = BusinessType.EXPORT)
    @PostMapping("/export")
    public void export(HttpServletResponse response, TrainQuizAttempt trainQuizAttempt)
    {
        List<TrainQuizAttempt> list = trainQuizAttemptService.selectTrainQuizAttemptList(trainQuizAttempt);
        ExcelUtil<TrainQuizAttempt> util = new ExcelUtil<TrainQuizAttempt>(TrainQuizAttempt.class);
        util.exportExcel(response, list, "整场考试成绩数据");
    }

    /**
     * 获取整场考试成绩详细信息
     */
    @PreAuthorize("@ss.hasPermi('train:quiz:query')")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping(value = "/{attemptId}")
    public AjaxResult getInfo(@PathVariable("attemptId") Long attemptId)
    {
        return success(trainQuizAttemptService.selectTrainQuizAttemptById(attemptId));
    }

    /**
     * 管理端：获取整场考试成绩完整详情（含题目、答案、解析）
     */
    @PreAuthorize("@ss.hasPermi('train:quiz:query')")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping(value = "/admin-detail/{attemptId}")
    public AjaxResult getAdminDetail(@PathVariable("attemptId") Long attemptId)
    {
        TrainQuizAttempt attemptDetail = trainQuizAttemptService.getAttemptDetailWithQuestions(attemptId, null);
        if (attemptDetail == null)
        {
            return error("记录不存在");
        }
        return success(attemptDetail);
    }

    /**
     * 新增整场考试成绩（保存到从库 hotel_training）
     * 非会员每天只能参加一次测试
     */
    @PreAuthorize("isAuthenticated()")
    @DataSource(DataSourceType.SLAVE)
    @Log(title = "整场考试成绩", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody TrainQuizAttempt trainQuizAttempt)
    {
        // 提交记录的用户ID以当前登录态为准，禁止请求体伪造
        Long userId = getUserId();
        trainQuizAttempt.setUserId(userId);
        logger.info("收到考试记录提交 userId={}, attemptType={}, score={}", userId, trainQuizAttempt.getAttemptType(), trainQuizAttempt.getScore());

        // 结课测验是课程闭环，不占用非会员每日普通测验次数。
        boolean courseQuizAttempt = isCourseQuizAttempt(trainQuizAttempt);
        if (!courseQuizAttempt && userId != null) {
            try {
                // 获取用户会员等级
                String memberLevel = membershipService.getUserMembershipLevelCode(userId);

                // 非会员或免费会员每天只能参加一次测试
                if (memberLevel == null || "expired".equals(memberLevel) || "free".equals(memberLevel)) {
                    // 查询今日已参加的测试次数
                    int todayQuizCount = trainQuizAttemptService.getTodayQuizCountForUser(userId);

                    if (todayQuizCount >= MembershipLimitConstants.FREE_QUIZ_DAILY_LIMIT) {
                        return AjaxResult.error("非会员每天只能参加" + MembershipLimitConstants.FREE_QUIZ_DAILY_LIMIT + "次测试，请升级会员解锁无限测试");
                    }
                }
            } catch (Exception e) {
                logger.warn("会员检查异常（已放行） userId={}", userId, e);
                // 会员检查异常时不阻止提交
            }
        }

        int result;
        try {
            result = trainQuizAttemptService.insertTrainQuizAttempt(trainQuizAttempt);
        } catch (IllegalStateException ex) {
            logger.warn("考试记录提交被拦截 userId={}, examId={}, reason={}", userId, trainQuizAttempt.getExamId(), ex.getMessage());
            return AjaxResult.error(ex.getMessage());
        }

        // 返回新插入的 attemptId，供前端保存题目详情使用
        if (result > 0) {
            // 根据考试类型和成绩发放积分
            try {
                String attemptType = trainQuizAttempt.getAttemptType();
                Integer score = trainQuizAttempt.getScore();
                int points = 0;
                String reason = "";

                if ("exam".equals(attemptType)) {
                    // 考试：80分以上获得50积分
                    if (score != null && score >= 80) {
                        points = 50;
                        reason = "考试通过奖励（" + score + "分）";
                    } else {
                    }
                } else if ("practice".equals(attemptType) || "quiz".equals(attemptType)) {
                    // 平时测验：60分以上获得20积分
                    if (score != null && score >= 60) {
                        points = 20;
                        reason = "测验通过奖励（" + score + "分）";
                    } else {
                    }
                }

                if (points > 0 && userId != null) {
                    trainUserPointsService.addPoints(userId, points, reason);
                }
            } catch (Exception e) {
                logger.warn("积分发放失败 userId={}", userId, e);
                // 积分发放失败不影响考试记录保存
            }

            AjaxResult ajax = AjaxResult.success("保存成功");
            ajax.put("attemptId", trainQuizAttempt.getAttemptId());
            return ajax;
        } else {
            return AjaxResult.error("保存失败");
        }
    }

    private boolean isCourseQuizAttempt(TrainQuizAttempt trainQuizAttempt)
    {
        if (trainQuizAttempt == null) {
            return false;
        }
        String attemptScene = trainQuizAttempt.getAttemptScene();
        if (attemptScene != null && "course_quiz".equalsIgnoreCase(attemptScene.trim())) {
            return true;
        }
        String examName = trainQuizAttempt.getExamName();
        return examName != null && examName.contains("结课测验");
    }

    /**
     * 修改整场考试成绩
     */
    @PreAuthorize("@ss.hasPermi('train:quiz:edit')")
    @DataSource(DataSourceType.SLAVE)
    @Log(title = "整场考试成绩", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody TrainQuizAttempt trainQuizAttempt)
    {
        return toAjax(trainQuizAttemptService.updateTrainQuizAttempt(trainQuizAttempt));
    }

    /**
     * 删除整场考试成绩
     */
    @PreAuthorize("@ss.hasPermi('train:quiz:remove')")
    @DataSource(DataSourceType.SLAVE)
    @Log(title = "整场考试成绩", businessType = BusinessType.DELETE)
	@DeleteMapping("/{attemptIds}")
    public AjaxResult remove(@PathVariable Long[] attemptIds)
    {
        return toAjax(trainQuizAttemptService.deleteTrainQuizAttemptByIds(attemptIds));
    }

    /**
     * 用户端：查询当前用户的考试记录列表（从库 hotel_training）
     */
    @PreAuthorize("isAuthenticated()")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping("/my-records")
    public TableDataInfo getMyRecords(TrainQuizAttempt trainQuizAttempt)
    {
        Long userId = getUserId();
        if (userId == null) {
            return getDataTable(new java.util.ArrayList<>());
        }
        
        trainQuizAttempt.setUserId(userId);
        startPage();
        List<TrainQuizAttempt> list = trainQuizAttemptService.selectTrainQuizAttemptList(trainQuizAttempt);
        return getDataTable(list);
    }

    /**
     * 管理端：结课测验看板摘要
     */
    @PreAuthorize("@ss.hasPermi('train:quiz:list')")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping("/course-quiz-dashboard")
    public AjaxResult getCourseQuizDashboard(
        @RequestParam(required = false) String beginTime,
        @RequestParam(required = false) String endTime)
    {
        StringBuilder where = new StringBuilder();
        java.util.List<Object> args = new java.util.ArrayList<>();
        where.append(" WHERE COALESCE(NULLIF(attempt_scene, ''), CASE ")
             .append("WHEN attempt_type = 'exam' THEN 'exam' ")
             .append("WHEN exam_name LIKE '%结课测验%' THEN 'course_quiz' ")
             .append("ELSE 'practice' END) = 'course_quiz' ");
        if (beginTime != null && !beginTime.trim().isEmpty()) {
            where.append(" AND COALESCE(submitted_at, create_time) >= ? ");
            args.add(beginTime.trim());
        }
        if (endTime != null && !endTime.trim().isEmpty()) {
            where.append(" AND COALESCE(submitted_at, create_time) <= ? ");
            args.add(endTime.trim());
        }

        String dedupSql =
            "SELECT user_id, " +
            "COALESCE(NULLIF(course_quiz_key, ''), exam_name, CONCAT('attempt-', attempt_id)) AS dedup_key, " +
            "MIN(attempt_id) AS first_attempt_id " +
            "FROM train_quiz_attempt " +
            where +
            " GROUP BY user_id, COALESCE(NULLIF(course_quiz_key, ''), exam_name, CONCAT('attempt-', attempt_id))";

        String summarySql =
            "SELECT COUNT(*) AS total_attempts, " +
            "COUNT(DISTINCT d.user_id) AS learner_count, " +
            "COUNT(DISTINCT d.dedup_key) AS course_count, " +
            "COALESCE(ROUND(AVG(COALESCE(tqa.score, 0)), 2), 0) AS avg_score, " +
            "COALESCE(ROUND(SUM(CASE WHEN COALESCE(tqa.is_passed, 0) = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 2), 0) AS first_pass_rate " +
            "FROM (" + dedupSql + ") d " +
            "JOIN train_quiz_attempt tqa ON tqa.attempt_id = d.first_attempt_id";

        Map<String, Object> summary = args.isEmpty()
            ? jdbcTemplate.queryForMap(summarySql)
            : jdbcTemplate.queryForMap(summarySql, args.toArray());
        return success(summary);
    }

    /**
     * 管理端：结课测验课程维度明细
     */
    @PreAuthorize("@ss.hasPermi('train:quiz:list')")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping("/course-quiz-course-stats")
    public AjaxResult getCourseQuizCourseStats(
        @RequestParam(required = false) String beginTime,
        @RequestParam(required = false) String endTime)
    {
        StringBuilder where = new StringBuilder();
        java.util.List<Object> args = new java.util.ArrayList<>();
        where.append(" WHERE COALESCE(NULLIF(attempt_scene, ''), CASE ")
             .append("WHEN attempt_type = 'exam' THEN 'exam' ")
             .append("WHEN exam_name LIKE '%结课测验%' THEN 'course_quiz' ")
             .append("ELSE 'practice' END) = 'course_quiz' ");
        if (beginTime != null && !beginTime.trim().isEmpty()) {
            where.append(" AND COALESCE(submitted_at, create_time) >= ? ");
            args.add(beginTime.trim());
        }
        if (endTime != null && !endTime.trim().isEmpty()) {
            where.append(" AND COALESCE(submitted_at, create_time) <= ? ");
            args.add(endTime.trim());
        }

        String dedupSql =
            "SELECT user_id, " +
            "COALESCE(NULLIF(course_quiz_key, ''), exam_name, CONCAT('attempt-', attempt_id)) AS dedup_key, " +
            "COALESCE(NULLIF(exam_name, ''), COALESCE(NULLIF(course_quiz_key, ''), CONCAT('课程-', attempt_id))) AS course_name, " +
            "MIN(attempt_id) AS first_attempt_id " +
            "FROM train_quiz_attempt " +
            where +
            " GROUP BY user_id, COALESCE(NULLIF(course_quiz_key, ''), exam_name, CONCAT('attempt-', attempt_id))";

        String detailSql =
            "SELECT d.dedup_key, d.course_name, " +
            "COUNT(*) AS first_attempt_count, " +
            "COUNT(DISTINCT d.user_id) AS learner_count, " +
            "COALESCE(ROUND(AVG(COALESCE(tqa.score, 0)), 2), 0) AS avg_score, " +
            "COALESCE(ROUND(AVG(COALESCE(tqa.duration_seconds, 0)), 2), 0) AS avg_duration_seconds, " +
            "COALESCE(ROUND(SUM(CASE WHEN COALESCE(tqa.is_passed, 0) = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 2), 0) AS first_pass_rate " +
            "FROM (" + dedupSql + ") d " +
            "JOIN train_quiz_attempt tqa ON tqa.attempt_id = d.first_attempt_id " +
            "GROUP BY d.dedup_key, d.course_name " +
            "ORDER BY first_pass_rate ASC, avg_score ASC, first_attempt_count DESC";

        java.util.List<java.util.Map<String, Object>> rows = args.isEmpty()
            ? jdbcTemplate.queryForList(detailSql)
            : jdbcTemplate.queryForList(detailSql, args.toArray());
        return success(rows);
    }

    /**
     * 管理端：结课测验课程详情（部门拆分 + 人员明细）
     */
    @PreAuthorize("@ss.hasPermi('train:quiz:list')")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping("/course-quiz-course-detail")
    public AjaxResult getCourseQuizCourseDetail(
        @RequestParam String courseQuizKey,
        @RequestParam(required = false) String beginTime,
        @RequestParam(required = false) String endTime)
    {
        String normalizedKey = courseQuizKey == null ? "" : courseQuizKey.trim();
        if (normalizedKey.isEmpty()) {
            return error("课程键不能为空");
        }

        StringBuilder where = new StringBuilder();
        java.util.List<Object> args = new java.util.ArrayList<>();
        where.append(" WHERE COALESCE(NULLIF(attempt_scene, ''), CASE ")
            .append("WHEN attempt_type = 'exam' THEN 'exam' ")
            .append("WHEN exam_name LIKE '%结课测验%' THEN 'course_quiz' ")
            .append("ELSE 'practice' END) = 'course_quiz' ")
            .append("AND COALESCE(NULLIF(course_quiz_key, ''), exam_name, CONCAT('attempt-', attempt_id)) = ? ");
        args.add(normalizedKey);
        if (beginTime != null && !beginTime.trim().isEmpty()) {
            where.append(" AND COALESCE(submitted_at, create_time) >= ? ");
            args.add(beginTime.trim());
        }
        if (endTime != null && !endTime.trim().isEmpty()) {
            where.append(" AND COALESCE(submitted_at, create_time) <= ? ");
            args.add(endTime.trim());
        }

        String dedupSql =
            "SELECT user_id, " +
            "COALESCE(NULLIF(course_quiz_key, ''), exam_name, CONCAT('attempt-', attempt_id)) AS dedup_key, " +
            "COALESCE(NULLIF(exam_name, ''), COALESCE(NULLIF(course_quiz_key, ''), CONCAT('课程-', attempt_id))) AS course_name, " +
            "MIN(attempt_id) AS first_attempt_id " +
            "FROM train_quiz_attempt " +
            where +
            " GROUP BY user_id, COALESCE(NULLIF(course_quiz_key, ''), exam_name, CONCAT('attempt-', attempt_id))";

        String learnerSql =
            "SELECT d.user_id, d.course_name, tqa.score, tqa.is_passed, tqa.duration_seconds, " +
            "tqa.question_count, tqa.correct_count, COALESCE(tqa.submitted_at, tqa.create_time) AS submitted_at " +
            "FROM (" + dedupSql + ") d " +
            "JOIN train_quiz_attempt tqa ON tqa.attempt_id = d.first_attempt_id " +
            "ORDER BY tqa.score DESC, submitted_at ASC";

        java.util.List<java.util.Map<String, Object>> learnerRows = jdbcTemplate.queryForList(learnerSql, args.toArray());
        String courseName = learnerRows.isEmpty() ? normalizedKey : String.valueOf(learnerRows.get(0).get("course_name"));

        org.springframework.jdbc.core.JdbcTemplate masterJdbc = new org.springframework.jdbc.core.JdbcTemplate(masterDataSource);
        java.util.Map<Long, java.util.Map<String, Object>> userInfoMap = new java.util.HashMap<>();
        if (!learnerRows.isEmpty()) {
            StringBuilder inSql = new StringBuilder();
            java.util.List<Object> userArgs = new java.util.ArrayList<>();
            for (int i = 0; i < learnerRows.size(); i++) {
                if (i > 0) inSql.append(",");
                inSql.append("?");
                userArgs.add(((Number) learnerRows.get(i).get("user_id")).longValue());
            }
            String userSql = "SELECT u.user_id, u.user_name, d.dept_name FROM sys_user u " +
                "LEFT JOIN sys_dept d ON u.dept_id = d.dept_id WHERE u.user_id IN (" + inSql + ")";
            java.util.List<java.util.Map<String, Object>> userRows = masterJdbc.queryForList(userSql, userArgs.toArray());
            for (java.util.Map<String, Object> row : userRows) {
                userInfoMap.put(((Number) row.get("user_id")).longValue(), row);
            }
        }

        java.util.Map<String, long[]> deptMetrics = new java.util.LinkedHashMap<>();
        java.util.List<java.util.Map<String, Object>> learners = new java.util.ArrayList<>();
        for (java.util.Map<String, Object> row : learnerRows) {
            Long userId = ((Number) row.get("user_id")).longValue();
            java.util.Map<String, Object> userInfo = userInfoMap.get(userId);
            String deptName = userInfo != null && userInfo.get("dept_name") != null ? String.valueOf(userInfo.get("dept_name")) : "未分配部门";
            String userName = userInfo != null && userInfo.get("user_name") != null ? String.valueOf(userInfo.get("user_name")) : ("用户" + userId);
            long[] metric = deptMetrics.computeIfAbsent(deptName, key -> new long[]{0, 0, 0, 0});
            metric[0] += 1; // learner_count
            metric[1] += row.get("score") != null ? Math.round(Double.parseDouble(row.get("score").toString())) : 0;
            metric[2] += row.get("is_passed") != null && Integer.parseInt(row.get("is_passed").toString()) == 1 ? 1 : 0;
            metric[3] += row.get("duration_seconds") != null ? Math.round(Double.parseDouble(row.get("duration_seconds").toString())) : 0;

            java.util.Map<String, Object> learner = new java.util.HashMap<>();
            learner.put("userId", userId);
            learner.put("userName", userName);
            learner.put("deptName", deptName);
            learner.put("score", row.get("score"));
            learner.put("isPassed", row.get("is_passed"));
            learner.put("durationSeconds", row.get("duration_seconds"));
            learner.put("questionCount", row.get("question_count"));
            learner.put("correctCount", row.get("correct_count"));
            learner.put("submittedAt", row.get("submitted_at"));
            learners.add(learner);
        }

        java.util.List<java.util.Map<String, Object>> deptStats = new java.util.ArrayList<>();
        for (java.util.Map.Entry<String, long[]> entry : deptMetrics.entrySet()) {
            long[] metric = entry.getValue();
            java.util.Map<String, Object> deptRow = new java.util.HashMap<>();
            deptRow.put("deptName", entry.getKey());
            deptRow.put("learnerCount", metric[0]);
            deptRow.put("avgScore", metric[0] == 0 ? 0 : Math.round(metric[1] * 100.0 / metric[0]) / 100.0);
            deptRow.put("firstPassRate", metric[0] == 0 ? 0 : Math.round(metric[2] * 10000.0 / metric[0]) / 100.0);
            deptRow.put("avgDurationSeconds", metric[0] == 0 ? 0 : Math.round(metric[3] * 100.0 / metric[0]) / 100.0);
            deptStats.add(deptRow);
        }
        deptStats.sort((a, b) -> Double.compare(
            Double.parseDouble(String.valueOf(a.get("firstPassRate"))),
            Double.parseDouble(String.valueOf(b.get("firstPassRate")))
        ));

        java.util.Map<String, Object> detail = new java.util.HashMap<>();
        detail.put("courseQuizKey", normalizedKey);
        detail.put("courseName", courseName);
        detail.put("deptStats", deptStats);
        detail.put("learners", learners);
        return success(detail);
    }

    /**
     * 用户端：获取当前用户的考试统计（平均分等）
     */
    @PreAuthorize("isAuthenticated()")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping("/my-stats")
    public AjaxResult getMyStats(Long userId)
    {
        Long uid = getUserId();
        
        if (uid == null) {
            return error("未登录");
        }
        
        java.util.Map<String, Object> stats = trainQuizAttemptService.getUserStats(uid);
        return success(stats);
    }

    /**
     * 用户端：获取当前用户按类型统计的考试信息（考试和测验分开）
     */
    @PreAuthorize("isAuthenticated()")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping("/my-stats-by-type")
    public AjaxResult getMyStatsByType(Long userId)
    {
        Long uid = getUserId();
        
        if (uid == null) {
            return error("未登录");
        }
        
        java.util.Map<String, Object> stats = trainQuizAttemptService.getUserStatsByType(uid);
        return success(stats);
    }

    /**
     * 用户端：获取考试详情（用于回看）
     */
    @PreAuthorize("isAuthenticated()")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping("/detail/{attemptId}")
    public AjaxResult getAttemptDetail(@PathVariable("attemptId") Long attemptId)
    {
        try {
            Long userId = getUserId();
            
            // 使用新的Service方法获取包含题目详情的考试记录
            TrainQuizAttempt attemptDetail = trainQuizAttemptService.getAttemptDetailWithQuestions(attemptId, userId);
            
            if (attemptDetail == null) {
                return error("无权访问该记录或记录不存在");
            }
            
            return success(attemptDetail);
        } catch (Exception e) {
            logger.error("获取考试详情失败 attemptId={}", attemptId, e);
            return error("获取详情失败");
        }
    }
    
    /**
     * 用户端：批量保存考试题目详情（用于考试提交后保存所有题目的答题记录）
     */
    @PreAuthorize("isAuthenticated()")
    @DataSource(DataSourceType.SLAVE)
    @Log(title = "批量保存考试题目详情", businessType = BusinessType.INSERT)
    @PostMapping("/save-questions")
    public AjaxResult saveQuestions(@RequestBody java.util.Map<String, Object> requestData)
    {
        try {
            Long quizAttemptId = Long.valueOf(requestData.get("quizAttemptId").toString());
            @SuppressWarnings("unchecked")
            List<java.util.Map<String, Object>> questions = (List<java.util.Map<String, Object>>) requestData.get("questions");
            
            if (questions == null || questions.isEmpty()) {
                return error("题目列表不能为空");
            }
            
            int result = trainQuizAttemptService.batchSaveQuestionDetails(quizAttemptId, questions);
            return result > 0 ? success("保存成功") : error("保存失败");
        } catch (Exception e) {
            logger.error("批量保存题目详情失败", e);
            return error("保存失败");
        }
    }
}
