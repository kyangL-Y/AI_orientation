package com.ruoyi.web.controller.train;

import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.enums.DataSourceType;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.system.service.ITrainUserPointsService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 页面访问记录控制器（前端/移动端）
 */
@RestController
@RequestMapping("/train/page")
public class TrainPageVisitController extends BaseController {

    private static final Logger logger = LoggerFactory.getLogger(TrainPageVisitController.class);

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private ITrainUserPointsService userPointsService;

    /** 首次观看课程积分 */
    private static final int FIRST_VIEW_POINTS = 5;

    /** 每5分钟观看积分 */
    private static final int PER_5MIN_POINTS = 2;

    /** 单课程每日积分上限 */
    private static final int DAILY_COURSE_POINTS_LIMIT = 15;

    /** 最小有效观看时长（秒） */
    private static final int MIN_VALID_DURATION = 60;

    /**
     * 记录页面访问时长
     */
    @PostMapping("/visit")
    @DataSource(DataSourceType.SLAVE)
    @PreAuthorize("isAuthenticated()")
    public AjaxResult recordPageVisit(@RequestBody Map<String, Object> params) {
        try {
            Long userId = SecurityUtils.getUserId();
            String pageName = (String) params.get("pageName");
            Object durationObj = params.get("duration");
            Integer duration = null;
            if (durationObj instanceof Integer) {
                duration = (Integer) durationObj;
            } else if (durationObj instanceof Number) {
                duration = ((Number) durationObj).intValue();
            }

            if (pageName == null || duration == null || duration <= 0) {
                return AjaxResult.error("参数不完整或无效");
            }

            logger.info("📊 记录页面访问 - 用户ID: {}, 页面: {}, 时长: {}秒", userId, pageName, duration);

            // 将访问记录保存到数据库
            String sql = "INSERT INTO train_page_visit (user_id, page_name, visit_time, duration) " +
                        "VALUES (?, ?, NOW(), ?)";
            jdbcTemplate.update(sql, userId, pageName, duration);

            // 如果是课程学习页面，计算并发放积分
            int earnedPoints = 0;
            if (isCoursePage(pageName) && duration >= MIN_VALID_DURATION) {
                earnedPoints = calculateAndAwardCoursePoints(userId, pageName, duration);
            }

            Map<String, Object> result = new HashMap<>();
            result.put("message", "记录成功");
            result.put("earnedPoints", earnedPoints);

            return AjaxResult.success(result);
        } catch (Exception e) {
            logger.error("记录页面访问失败", e);
            return AjaxResult.error("记录失败: " + e.getMessage());
        }
    }

    /**
     * 判断是否为课程学习页面（精确匹配前端定义的课程页面名称）
     */
    private boolean isCoursePage(String pageName) {
        if (pageName == null) {
            return false;
        }
        // 精确匹配课程页面名称（与前端 PageVisitTracker 的 pageName 一致）
        String[] validCoursePages = {
            "绿色饭店培训",  // GreenHotelTraining.vue
            "绿色饭店课程"   // GreenHotelCourses.vue
        };
        for (String validPage : validCoursePages) {
            if (validPage.equals(pageName)) {
                return true;
            }
        }
        return false;
    }

    /**
     * 计算并发放课程观看积分
     * 规则：
     * - 首次观看该课程：+5分
     * - 每观看满5分钟：+2分
     * - 单课程每日上限：15分
     *
     * @return 本次获得的积分
     */
    private int calculateAndAwardCoursePoints(Long userId, String pageName, int duration) {
        try {
            int totalEarnedPoints = 0;

            // 1. 检查是否首次观看该课程
            // 通过积分日志判断（如果没有该课程的首次学习积分记录，则为首次）
            int firstViewPointsEarned = userPointsService.getTodayPointsByReasonKeyword(userId, "首次学习课程: " + pageName);
            // 查询历史是否有首次学习记录（不限今日）
            boolean hasEverReceivedFirstViewBonus = false;
            try {
                String checkSql = "SELECT COUNT(*) FROM train_page_visit " +
                                 "WHERE user_id = ? AND page_name = ?";
                Integer totalVisits = jdbcTemplate.queryForObject(checkSql, Integer.class, userId, pageName);
                // 如果只有1条记录（刚插入的），则为首次
                hasEverReceivedFirstViewBonus = (totalVisits != null && totalVisits > 1);
            } catch (Exception e) {
                logger.debug("检查首次观看失败: {}", e.getMessage());
            }

            boolean isFirstView = !hasEverReceivedFirstViewBonus;

            // 2. 查询今日该课程已获得的积分（通过服务层查主库）
            int todayEarnedPoints = userPointsService.getTodayPointsByReasonKeyword(userId, pageName);

            // 3. 计算可获得的积分（不超过每日上限）
            int remainingQuota = DAILY_COURSE_POINTS_LIMIT - todayEarnedPoints;
            if (remainingQuota <= 0) {
                logger.info("用户 {} 今日课程 {} 积分已达上限", userId, pageName);
                return 0;
            }

            // 4. 首次观看奖励
            if (isFirstView) {
                int firstViewPoints = Math.min(FIRST_VIEW_POINTS, remainingQuota);
                if (firstViewPoints > 0) {
                    userPointsService.addPoints(userId, firstViewPoints, "首次学习课程: " + pageName);
                    totalEarnedPoints += firstViewPoints;
                    remainingQuota -= firstViewPoints;
                    logger.info("🎉 用户 {} 首次观看课程 {}，获得 {} 积分", userId, pageName, firstViewPoints);
                }
            }

            // 5. 时长奖励（每5分钟2分）
            if (remainingQuota > 0 && duration >= 300) { // 至少5分钟
                int durationMinutes = duration / 60;
                int timeBlocks = durationMinutes / 5; // 5分钟为一个时间块
                int durationPoints = timeBlocks * PER_5MIN_POINTS;
                durationPoints = Math.min(durationPoints, remainingQuota);

                if (durationPoints > 0) {
                    userPointsService.addPoints(userId, durationPoints,
                        "课程学习时长奖励: " + pageName + " (" + durationMinutes + "分钟)");
                    totalEarnedPoints += durationPoints;
                    logger.info("⏱️ 用户 {} 观看课程 {} {}分钟，获得 {} 积分",
                               userId, pageName, durationMinutes, durationPoints);
                }
            }

            return totalEarnedPoints;
        } catch (Exception e) {
            logger.error("计算课程积分失败", e);
            return 0;
        }
    }

    /**
     * 获取用户学习时长统计
     * 只统计页面浏览时长
     */
    @GetMapping("/learning-time")
    @DataSource(DataSourceType.SLAVE)
    @PreAuthorize("isAuthenticated()")
    public AjaxResult getLearningTime(@RequestParam(defaultValue = "30") Integer days) {
        try {
            Long userId = SecurityUtils.getUserId();

            logger.info("📊 获取用户学习时长统计 - 用户ID: {}, 天数: {}", userId, days);

            // 查询页面浏览时长
            String visitSql = "SELECT COALESCE(SUM(duration), 0) AS visit_duration " +
                            "FROM train_page_visit " +
                            "WHERE user_id = ? " +
                            "AND visit_time >= DATE_SUB(CURDATE(), INTERVAL ? DAY)";
            Integer visitDuration = jdbcTemplate.queryForObject(visitSql, Integer.class, userId, days);

            // 转换为小时
            Double totalHours = (visitDuration != null ? visitDuration : 0) / 3600.0;

            Map<String, Object> data = new HashMap<>();
            data.put("totalSeconds", visitDuration != null ? visitDuration : 0);
            data.put("totalHours", totalHours);
            data.put("visitDuration", visitDuration);

            return AjaxResult.success(data);
        } catch (Exception e) {
            logger.error("获取学习时长失败", e);
            return AjaxResult.error("获取失败: " + e.getMessage());
        }
    }

    /**
     * 获取按天分组的学习时长趋势
     */
    @GetMapping("/learning-trend")
    @DataSource(DataSourceType.SLAVE)
    @PreAuthorize("isAuthenticated()")
    public AjaxResult getLearningTrend(@RequestParam(defaultValue = "30") Integer days) {
        try {
            Long userId = SecurityUtils.getUserId();

            logger.info("📊 获取用户学习时长趋势 - 用户ID: {}, 天数: {}", userId, days);

            // 只查询页面浏览时长
            String sql = "SELECT " +
                       "DATE_FORMAT(visit_date, '%m-%d') AS label, " +
                       "COALESCE(SUM(duration), 0) / 3600.0 AS hours " +
                       "FROM train_page_visit " +
                       "WHERE user_id = ? " +
                       "  AND visit_time >= DATE_SUB(CURDATE(), INTERVAL ? DAY) " +
                       "GROUP BY visit_date " +
                       "ORDER BY visit_date";

            List<Map<String, Object>> results = jdbcTemplate.queryForList(sql, userId, days);

            // 处理结果
            List<String> labels = new ArrayList<>();
            List<Double> data = new ArrayList<>();

            for (Map<String, Object> row : results) {
                labels.add((String) row.get("label"));
                data.add(((Number) row.get("hours")).doubleValue());
            }

            Map<String, Object> trend = new HashMap<>();
            trend.put("labels", labels.toArray(new String[0]));
            trend.put("data", data.toArray(new Double[0]));

            return AjaxResult.success(trend);
        } catch (Exception e) {
            logger.error("获取学习趋势失败", e);
            return AjaxResult.error("获取失败: " + e.getMessage());
        }
    }
}
