package com.ruoyi.web.controller.train;

import com.alibaba.fastjson2.JSON;
import com.ruoyi.common.annotation.Anonymous;
import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.enums.DataSourceType;
import com.ruoyi.common.utils.SecurityUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 培训用户相关API控制器（用户端/移动端）
 */
@RestController
@RequestMapping("/train/user")
public class TrainUserController extends BaseController {

    private static final String TRAIN_PROGRESS_TABLE = "hotel_training.train_progress";
    private static final String DEFAULT_COURSE_TYPE = "ota";

    @Autowired
    private JdbcTemplate jdbcTemplate;

    /**
     * 获取用户统计信息
     * 需要登录才能访问，通过Token获取用户ID
     */
    @GetMapping("/stats")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getUserStats() {
        Map<String, Object> stats = new HashMap<>();
        
        try {
            Long userId = SecurityUtils.getUserId();
            
            // 检查用户ID是否有效
            if (userId == null || userId <= 0) {
                logger.warn("⚠️ 无法获取用户ID，可能未登录");
                return error("请先登录");
            }
            
            logger.info("📊 开始获取用户统计数据, userId: {}", userId);
            
            // 课程完成统计 - 基于train_progress表
            String courseStatsSql = "SELECT " +
                                   "COUNT(*) as totalCourses, " +
                                   "COALESCE(SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END), 0) as completedCourses, " +
                                   "COALESCE(SUM(study_duration), 0) as courseStudySeconds " +
                                   "FROM " + TRAIN_PROGRESS_TABLE + " WHERE user_id = ?";
            
            Map<String, Object> courseStats = jdbcTemplate.queryForMap(courseStatsSql, userId);
            int completedCourses = courseStats.get("completedCourses") != null ? ((Number) courseStats.get("completedCourses")).intValue() : 0;
            int courseStudySeconds = courseStats.get("courseStudySeconds") != null ? ((Number) courseStats.get("courseStudySeconds")).intValue() : 0;
            logger.info("✅ 课程统计查询结果: completedCourses={}, courseStudySeconds={}", completedCourses, courseStudySeconds);
            
            // 答题统计 - 基于train_answer_attempt表（不含答题时长）
            String answerStatsSql = "SELECT " +
                                   "COUNT(*) as totalQuestions, " +
                                   "COALESCE(SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END), 0) as correctAnswers, " +
                                   "COALESCE(ROUND(SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 0), 0) as accuracyRate " +
                                   "FROM train_answer_attempt WHERE user_id = ?";
            
            Map<String, Object> answerStats = jdbcTemplate.queryForMap(answerStatsSql, userId);
            
            // 答题数和正确率
            int totalQuestions = answerStats.get("totalQuestions") != null ? ((Number) answerStats.get("totalQuestions")).intValue() : 0;
            int correctAnswers = answerStats.get("correctAnswers") != null ? ((Number) answerStats.get("correctAnswers")).intValue() : 0;
            int accuracyRate = answerStats.get("accuracyRate") != null ? ((Number) answerStats.get("accuracyRate")).intValue() : 0;
            
            // 查询页面访问时长
            String pageVisitSql = "SELECT COALESCE(SUM(duration), 0) as pageSeconds FROM train_page_visit WHERE user_id = ?";
            Integer pageSeconds = jdbcTemplate.queryForObject(pageVisitSql, Integer.class, userId);
            
            // 学习时长 = 课程学习时长 + 页面访问时长
            int totalSeconds = courseStudySeconds + (pageSeconds != null ? pageSeconds : 0);
            double totalHours = Math.round(totalSeconds / 3600.0 * 10.0) / 10.0;
            
            // 前端期望的字段
            stats.put("coursesCompleted", completedCourses);
            stats.put("totalHours", totalHours);
            stats.put("totalSeconds", totalSeconds);
            stats.put("certificates", completedCourses >= 10 ? 2 : (completedCourses >= 5 ? 1 : 0));
            stats.put("averageScore", accuracyRate);
            
            // 今日学习时长（课程学习时长 + 页面访问时长）
            String todaySql = "SELECT COALESCE(SUM(total_duration), 0) AS today_seconds " +
                            "FROM (" +
                            "  SELECT COALESCE(SUM(study_duration), 0) AS total_duration " +
                            "  FROM " + TRAIN_PROGRESS_TABLE + " " +
                            "  WHERE user_id = ? AND DATE(started_at) = CURDATE() " +
                            "  UNION ALL " +
                            "  SELECT COALESCE(SUM(duration), 0) AS total_duration " +
                            "  FROM train_page_visit " +
                            "  WHERE user_id = ? AND visit_date = CURDATE()" +
                            ") AS today_data";
            Integer todaySeconds = jdbcTemplate.queryForObject(todaySql, Integer.class, userId, userId);
            
            // 其他统计
            stats.put("totalQuestions", totalQuestions);
            stats.put("accuracyRate", accuracyRate);
            stats.put("studyHours", totalHours);
            stats.put("todaySeconds", todaySeconds != null ? todaySeconds : 0);
            
            // 排名（按答题正确率排名）
            String rankingSql = "SELECT COUNT(*) + 1 FROM (" +
                               "SELECT user_id, " +
                               "SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) as accuracy " +
                               "FROM train_answer_attempt GROUP BY user_id HAVING COUNT(*) >= 10" +
                               ") t WHERE accuracy > ?";
            Integer ranking = jdbcTemplate.queryForObject(rankingSql, Integer.class, accuracyRate);
            stats.put("ranking", ranking != null ? ranking : 0);
            
            // 连续学习天数
            String currentStreakSql = "SELECT COUNT(DISTINCT DATE(attempt_time)) FROM train_answer_attempt " +
                                     "WHERE user_id = ? AND attempt_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)";
            Integer currentStreak = jdbcTemplate.queryForObject(currentStreakSql, Integer.class, userId);
            stats.put("currentStreak", currentStreak != null ? currentStreak : 0);
            
            logger.info("✅ 用户统计数据计算完成, userId={}: coursesCompleted={}, totalHours={}, todaySeconds={}", 
                       userId, completedCourses, totalHours, todaySeconds);
            
        } catch (Exception e) {
            logger.error("❌ 获取用户统计信息失败", e);
            // 返回默认值而不是错误，避免前端崩溃
            stats.put("coursesCompleted", 0);
            stats.put("totalHours", 0);
            stats.put("totalSeconds", 0);
            stats.put("certificates", 0);
            stats.put("averageScore", 0);
            stats.put("totalQuestions", 0);
            stats.put("accuracyRate", 0);
            stats.put("studyHours", 0);
            stats.put("todaySeconds", 0);
            stats.put("ranking", 0);
            stats.put("currentStreak", 0);
        }
        
        return success(stats);
    }

    /**
     * 获取用户学习时长趋势
     * 需要登录才能访问
     */
    @GetMapping("/learning-trend")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getLearningTrend(@RequestParam(defaultValue = "monthly") String period, 
                                       @RequestParam(defaultValue = "30") Integer days) {
        Map<String, Object> trend = new HashMap<>();
        
        try {
            // 去除period中的空格
            period = period.trim();
            Long userId = SecurityUtils.getUserId();
            
            // 检查用户ID是否有效
            if (userId == null || userId <= 0) {
                logger.warn("⚠️ 无法获取用户ID，可能未登录");
                trend.put("labels", new String[0]);
                trend.put("data", new Double[0]);
                return success(trend);
            }
            
            logger.info("📊 接收到图表请求 - period: '{}', days: {}, userId: {}", period, days, userId);
            
            // 按天趋势：每天学习时长（小时），只统计页面访问时长
            if ("daily".equals(period)) {
                logger.info("📊 获取每日学习趋势 - userId: {}, days: {}", userId, days);
                
                // 只统计页面访问时长
                String sql = "SELECT " +
                             "DATE_FORMAT(visit_date, '%m-%d') AS label, " +
                             "COALESCE(SUM(duration), 0) / 3600.0 AS hours " +
                             "FROM train_page_visit " +
                             "WHERE user_id = ? " +
                             "  AND visit_time >= DATE_SUB(CURDATE(), INTERVAL ? DAY) " +
                             "GROUP BY visit_date " +
                             "ORDER BY visit_date";
                
                logger.info("📊 执行SQL: {}", sql);
                logger.info("📊 参数: userId={}, days={}", userId, days);
                
                List<Map<String, Object>> results;
                try {
                    results = jdbcTemplate.queryForList(sql, userId, days);
                    logger.info("📊 查询结果数量: {}", results.size());
                } catch (Exception e) {
                    logger.error("📊 执行查询时出错", e);
                    results = new ArrayList<>();
                }
                List<String> labels = new ArrayList<>();
                List<Double> data = new ArrayList<>();
                for (Map<String, Object> row : results) {
                    labels.add((String) row.get("label"));
                    data.add(((Number) row.get("hours")).doubleValue());
                }
                
                trend.put("labels", labels.toArray(new String[0]));
                trend.put("data", data.toArray(new Double[0]));
            }
            // 月度趋势：最近 6 个月，每月学习时长（小时），只统计页面访问时长
            else if ("monthly".equals(period)) {
                String sql = "SELECT " +
                             "  DATE_FORMAT(visit_time, '%m月') AS label, " +
                             "  ROUND(SUM(duration) / 3600.0, 2) AS hours " +
                             "FROM train_page_visit " +
                             "WHERE user_id = ? " +
                             "  AND visit_time >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH) " +
                             "GROUP BY DATE_FORMAT(visit_time, '%Y-%m'), DATE_FORMAT(visit_time, '%m月') " +
                             "ORDER BY DATE_FORMAT(visit_time, '%Y-%m')";

                logger.info("📊 月度图表SQL: {}", sql);
                
                try {
                    List<Map<String, Object>> results = jdbcTemplate.queryForList(sql, userId);
                    logger.info("📊 月度查询结果数量: {}", results.size());
                    
                    List<String> labels = new ArrayList<>();
                    List<Double> data = new ArrayList<>();
                    for (Map<String, Object> row : results) {
                        labels.add((String) row.get("label"));
                        data.add(((Number) row.get("hours")).doubleValue());
                    }
                    
                    trend.put("labels", labels.toArray(new String[0]));
                    trend.put("data", data.toArray(new Double[0]));
                } catch (Exception e) {
                    logger.error("📊 月度查询出错", e);
                    trend.put("labels", new String[0]);
                    trend.put("data", new Double[0]);
                }
            }
            // 其他情况：最近 7 天，按日期统计学习时长（小时），只统计页面访问时长
            else {
                String sql = "SELECT " +
                             "DATE_FORMAT(visit_date, '%m-%d') AS label, " +
                             "COALESCE(SUM(duration), 0) / 3600.0 AS hours " +
                             "FROM train_page_visit " +
                             "WHERE user_id = ? " +
                             "  AND visit_time >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) " +
                             "GROUP BY visit_date " +
                             "ORDER BY visit_date";
                
                List<Map<String, Object>> results = jdbcTemplate.queryForList(sql, userId);
                List<String> labels = new ArrayList<>();
                List<Integer> data = new ArrayList<>();
                for (Map<String, Object> row : results) {
                    labels.add((String) row.get("label"));
                    data.add(((Number) row.get("hours")).intValue());
                }
                
                trend.put("labels", labels.toArray(new String[0]));
                trend.put("data", data.toArray(new Integer[0]));
            }
        } catch (Exception e) {
            logger.error("获取学习趋势失败", e);
            trend.put("labels", new String[0]);
            trend.put("data", new Integer[0]);
        }
        
        return success(trend);
    }

    /**
     * 获取每日学习记录（答题统计，不含时长）
     */
    @GetMapping("/daily-records")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getDailyRecords(@RequestParam(defaultValue = "30") Integer days) {
        try {
            Long userId = SecurityUtils.getUserId();
            logger.info("📅 获取每日学习记录 - userId: {}, days: {}", userId, days);
            
            String sql = "SELECT " +
                         "DATE(MIN(attempt_time)) AS date, " +
                         "DATE_FORMAT(MIN(attempt_time), '%Y年%m月%d日') AS dateLabel, " +
                         "CASE DAYOFWEEK(MIN(attempt_time)) " +
                         "  WHEN 1 THEN '周日' " +
                         "  WHEN 2 THEN '周一' " +
                         "  WHEN 3 THEN '周二' " +
                         "  WHEN 4 THEN '周三' " +
                         "  WHEN 5 THEN '周四' " +
                         "  WHEN 6 THEN '周五' " +
                         "  WHEN 7 THEN '周六' " +
                         "END AS weekday, " +
                         "COUNT(*) AS totalQuestions, " +
                         "SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) AS correctQuestions " +
                         "FROM train_answer_attempt " +
                         "WHERE user_id = ? " +
                         "  AND attempt_time >= DATE_SUB(CURDATE(), INTERVAL ? DAY) " +
                         "GROUP BY DATE(attempt_time) " +
                         "ORDER BY DATE(attempt_time) DESC";
            
            logger.info("📅 执行 SQL 查询...");
            List<Map<String, Object>> records = jdbcTemplate.queryForList(sql, userId, days);
            logger.info("📅 查询结果数量: {}", records.size());
            return success(records);
        } catch (Exception e) {
            logger.error("📅 获取每日学习记录失败", e);
            return error("获取每日学习记录失败");
        }
    }

    /**
     * 获取用户培训分类统计
     */
    @GetMapping("/category-stats")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getCategoryStats() {
        List<Map<String, Object>> categories = new ArrayList<>();
        return success(categories);
    }

    /**
     * 开始学习课程 - 创建或更新学习进度记录
     */
    @PostMapping("/course/start")
    @DataSource(DataSourceType.MASTER)
    public AjaxResult startCourse(@RequestBody Map<String, Object> params) {
        try {
            Long userId = SecurityUtils.getUserId();
            if (userId == null || userId == 0L) {
                logger.warn("❌ 用户未登录，无法记录学习进度");
                return error("请先登录");
            }
            Long courseId = Long.valueOf(params.get("courseId").toString());
            String courseName = params.get("courseName") != null ? params.get("courseName").toString() : "";
            String courseType = resolveCourseType(params);
            String courseMeta = resolveCourseMeta(params);
            boolean hasCourseContext = hasCourseContextColumns();
            
            logger.info("📚 用户{}开始学习课程: courseId={}, courseType={}, courseName={}", userId, courseId, courseType, courseName);
            
            // 检查是否已有进度记录
            List<Map<String, Object>> existing = selectCourseProgressRows(userId, courseId, courseType, hasCourseContext);
            
            if (existing.isEmpty()) {
                // 创建新记录
                if (hasCourseContext) {
                    String insertSql = "INSERT INTO " + TRAIN_PROGRESS_TABLE + " (user_id, course_id, course_name, course_type, course_meta, status, progress, started_at, create_time, update_time) " +
                                      "VALUES (?, ?, ?, ?, ?, 'in_progress', 0, NOW(), NOW(), NOW())";
                    jdbcTemplate.update(insertSql, userId, courseId, courseName, courseType, courseMeta);
                } else {
                    String insertSql = "INSERT INTO " + TRAIN_PROGRESS_TABLE + " (user_id, course_id, course_name, status, progress, started_at, create_time, update_time) " +
                                      "VALUES (?, ?, ?, 'in_progress', 0, NOW(), NOW(), NOW())";
                    jdbcTemplate.update(insertSql, userId, courseId, courseName);
                }
                logger.info("✅ 创建新的学习进度记录");
            } else {
                // 更新最后访问时间
                if (hasCourseContext) {
                    String updateSql = "UPDATE " + TRAIN_PROGRESS_TABLE + " SET course_name = ?, course_type = ?, course_meta = ?, last_access_time = NOW(), update_time = NOW() WHERE id = ?";
                    jdbcTemplate.update(updateSql, courseName, courseType, courseMeta, existing.get(0).get("id"));
                } else {
                    String updateSql = "UPDATE " + TRAIN_PROGRESS_TABLE + " SET last_access_time = NOW(), update_time = NOW() WHERE user_id = ? AND course_id = ?";
                    jdbcTemplate.update(updateSql, userId, courseId);
                }
                logger.info("✅ 更新学习进度记录的访问时间");
            }
            
            return success("开始学习");
        } catch (Exception e) {
            logger.error("❌ 开始学习课程失败", e);
            return error("开始学习失败: " + e.getMessage());
        }
    }

    /**
     * 更新课程学习进度
     */
    @PostMapping("/course/progress")
    @DataSource(DataSourceType.MASTER)
    public AjaxResult updateCourseProgress(@RequestBody Map<String, Object> params) {
        try {
            Long userId = SecurityUtils.getUserId();
            if (userId == null || userId == 0L) {
                return error("请先登录");
            }
            Long courseId = Long.valueOf(params.get("courseId").toString());
            Integer progress = params.get("progress") != null ? Integer.valueOf(params.get("progress").toString()) : 0;
            Integer studyDuration = params.get("studyDuration") != null ? Integer.valueOf(params.get("studyDuration").toString()) : 0;
            String courseType = resolveCourseType(params);
            String courseMeta = resolveCourseMeta(params);
            boolean hasCourseContext = hasCourseContextColumns();
            
            logger.info("📚 更新课程进度: userId={}, courseId={}, courseType={}, progress={}%, duration={}s", userId, courseId, courseType, progress, studyDuration);
            
            // 确定状态
            String status = progress >= 100 ? "completed" : "in_progress";
            
            // 更新进度
            int rows;
            if (hasCourseContext) {
                List<Map<String, Object>> existing = selectCourseProgressRows(userId, courseId, courseType, true);
                if (existing.isEmpty()) {
                    rows = 0;
                } else {
                    String updateSql = "UPDATE " + TRAIN_PROGRESS_TABLE + " SET " +
                                      "course_type = ?, " +
                                      "course_meta = ?, " +
                                      "progress = ?, " +
                                      "status = ?, " +
                                      "study_duration = GREATEST(study_duration, ?), " +
                                      "last_access_time = NOW(), " +
                                      "update_time = NOW(), " +
                                      "completed_at = CASE WHEN ? >= 100 THEN NOW() ELSE completed_at END " +
                                      "WHERE id = ?";
                    rows = jdbcTemplate.update(updateSql, courseType, courseMeta, progress, status, studyDuration, progress, existing.get(0).get("id"));
                }
            } else {
                String updateSql = "UPDATE " + TRAIN_PROGRESS_TABLE + " SET " +
                                  "progress = ?, " +
                                  "status = ?, " +
                                  "study_duration = GREATEST(study_duration, ?), " +
                                  "last_access_time = NOW(), " +
                                  "update_time = NOW(), " +
                                  "completed_at = CASE WHEN ? >= 100 THEN NOW() ELSE completed_at END " +
                                  "WHERE user_id = ? AND course_id = ?";
                rows = jdbcTemplate.update(updateSql, progress, status, studyDuration, progress, userId, courseId);
            }
            
            if (rows == 0) {
                // 如果没有记录，先创建
                String courseName = params.get("courseName") != null ? params.get("courseName").toString() : "";
                if (hasCourseContext) {
                    String insertSql = "INSERT INTO " + TRAIN_PROGRESS_TABLE + " (user_id, course_id, course_name, course_type, course_meta, status, progress, study_duration, started_at, create_time, update_time) " +
                                      "VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), NOW())";
                    jdbcTemplate.update(insertSql, userId, courseId, courseName, courseType, courseMeta, status, progress, studyDuration);
                } else {
                    String insertSql = "INSERT INTO " + TRAIN_PROGRESS_TABLE + " (user_id, course_id, course_name, status, progress, study_duration, started_at, create_time, update_time) " +
                                      "VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW(), NOW())";
                    jdbcTemplate.update(insertSql, userId, courseId, courseName, status, progress, studyDuration);
                }
            }
            
            logger.info("✅ 课程进度更新成功, status={}", status);
            return success("进度更新成功");
        } catch (Exception e) {
            logger.error("❌ 更新课程进度失败", e);
            return error("更新进度失败: " + e.getMessage());
        }
    }

    /**
     * 完成课程学习
     */
    @PostMapping("/course/complete")
    @DataSource(DataSourceType.MASTER)
    public AjaxResult completeCourse(@RequestBody Map<String, Object> params) {
        try {
            Long userId = SecurityUtils.getUserId();
            Long courseId = Long.valueOf(params.get("courseId").toString());
            String courseType = resolveCourseType(params);
            String courseMeta = resolveCourseMeta(params);
            boolean hasCourseContext = hasCourseContextColumns();
            
            logger.info("🎉 用户{}完成课程: courseId={}, courseType={}", userId, courseId, courseType);
            
            // 检查是否已有进度记录
            List<Map<String, Object>> existing = selectCourseProgressRows(userId, courseId, courseType, hasCourseContext);
            
            if (existing.isEmpty()) {
                // 创建完成记录
                String courseName = params.get("courseName") != null ? params.get("courseName").toString() : "";
                if (hasCourseContext) {
                    String insertSql = "INSERT INTO " + TRAIN_PROGRESS_TABLE + " (user_id, course_id, course_name, course_type, course_meta, status, progress, started_at, completed_at, create_time, update_time) " +
                                      "VALUES (?, ?, ?, ?, ?, 'completed', 100, NOW(), NOW(), NOW(), NOW())";
                    jdbcTemplate.update(insertSql, userId, courseId, courseName, courseType, courseMeta);
                } else {
                    String insertSql = "INSERT INTO " + TRAIN_PROGRESS_TABLE + " (user_id, course_id, course_name, status, progress, started_at, completed_at, create_time, update_time) " +
                                      "VALUES (?, ?, ?, 'completed', 100, NOW(), NOW(), NOW(), NOW())";
                    jdbcTemplate.update(insertSql, userId, courseId, courseName);
                }
            } else {
                // 更新为完成状态
                if (hasCourseContext) {
                    String updateSql = "UPDATE " + TRAIN_PROGRESS_TABLE + " SET " +
                                      "course_type = ?, " +
                                      "course_meta = ?, " +
                                      "status = 'completed', " +
                                      "progress = 100, " +
                                      "completed_at = NOW(), " +
                                      "update_time = NOW() " +
                                      "WHERE id = ?";
                    jdbcTemplate.update(updateSql, courseType, courseMeta, existing.get(0).get("id"));
                } else {
                    String updateSql = "UPDATE " + TRAIN_PROGRESS_TABLE + " SET " +
                                      "status = 'completed', " +
                                      "progress = 100, " +
                                      "completed_at = NOW(), " +
                                      "update_time = NOW() " +
                                      "WHERE user_id = ? AND course_id = ?";
                    jdbcTemplate.update(updateSql, userId, courseId);
                }
            }
            
            logger.info("✅ 课程完成记录已保存");
            return success("课程已完成");
        } catch (Exception e) {
            logger.error("❌ 完成课程失败", e);
            return error("完成课程失败: " + e.getMessage());
        }
    }

    /**
     * 获取用户的课程学习进度列表
     */
    @GetMapping("/course/progress-list")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getCourseProgressList() {
        try {
            Long userId = SecurityUtils.getUserId();
            if (userId == null || userId <= 0) {
                return error("请先登录");
            }
            logger.info("📚 获取用户{}的课程进度列表", userId);
            
            String sql;
            if (hasCourseContextColumns()) {
                sql = "SELECT id, course_id as courseId, course_name as courseName, course_type as courseType, course_meta as courseMeta, status, progress, " +
                      "study_duration as studyDuration, started_at as startedAt, completed_at as completedAt, " +
                      "update_time as updateTime " +
                      "FROM " + TRAIN_PROGRESS_TABLE + " WHERE user_id = ? ORDER BY update_time DESC";
            } else {
                sql = "SELECT id, course_id as courseId, course_name as courseName, status, progress, " +
                      "study_duration as studyDuration, started_at as startedAt, completed_at as completedAt, " +
                      "update_time as updateTime " +
                      "FROM " + TRAIN_PROGRESS_TABLE + " WHERE user_id = ? ORDER BY update_time DESC";
            }
            
            List<Map<String, Object>> progressList = jdbcTemplate.queryForList(sql, userId);
            logger.info("✅ 查询到{}条进度记录", progressList.size());
            
            return success(progressList);
        } catch (Exception e) {
            logger.error("❌ 获取课程进度列表失败", e);
            return error("获取进度列表失败: " + e.getMessage());
        }
    }

    private String resolveCourseType(Map<String, Object> params) {
        Object rawCourseType = params.get("courseType");
        String courseType = rawCourseType == null ? DEFAULT_COURSE_TYPE : rawCourseType.toString().trim();
        return courseType.isEmpty() ? DEFAULT_COURSE_TYPE : courseType;
    }

    private String resolveCourseMeta(Map<String, Object> params) {
        Object courseMeta = params.get("courseMeta");
        if (courseMeta == null) {
            return null;
        }
        if (courseMeta instanceof String) {
            String courseMetaText = ((String) courseMeta).trim();
            return courseMetaText.isEmpty() ? null : courseMetaText;
        }
        return JSON.toJSONString(courseMeta);
    }

    private boolean hasCourseContextColumns() {
        try {
            Integer columnCount = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM information_schema.COLUMNS " +
                    "WHERE TABLE_SCHEMA = 'hotel_training' AND TABLE_NAME = 'train_progress' " +
                    "AND COLUMN_NAME IN ('course_type', 'course_meta')",
                    Integer.class);
            return columnCount != null && columnCount == 2;
        } catch (Exception e) {
            logger.warn("检测课程进度上下文字段失败，按旧表结构运行: {}", e.getMessage());
            return false;
        }
    }

    private List<Map<String, Object>> selectCourseProgressRows(Long userId, Long courseId, String courseType, boolean hasCourseContext) {
        if (hasCourseContext) {
            String sql = "SELECT id, status FROM " + TRAIN_PROGRESS_TABLE + " " +
                         "WHERE user_id = ? AND course_id = ? AND (course_type = ? OR course_type IS NULL OR course_type = '') " +
                         "ORDER BY CASE WHEN course_type = ? THEN 0 ELSE 1 END, update_time DESC LIMIT 1";
            return jdbcTemplate.queryForList(sql, userId, courseId, courseType, courseType);
        }
        String sql = "SELECT id, status FROM " + TRAIN_PROGRESS_TABLE + " WHERE user_id = ? AND course_id = ?";
        return jdbcTemplate.queryForList(sql, userId, courseId);
    }
}
