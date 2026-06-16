package com.ruoyi.web.controller.train;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import javax.servlet.http.HttpServletResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysUser;
import org.springframework.security.access.prepost.PreAuthorize;

/**
 * 学习统计Controller
 * 
 * @author ruoyi
 * @date 2024-01-01
 */
@RestController
@RequestMapping("/train/statistics")
@PreAuthorize("isAuthenticated()")
public class LearningStatisticsController extends BaseController {

    private boolean canAccessUser(Long userId) {
        if (userId == null) {
            return false;
        }
        try {
            SysUser currentUser = getLoginUser().getUser();
            if (currentUser == null || currentUser.getUserId() == null) {
                return false;
            }
            if (currentUser.isSuperAdmin() || currentUser.isPlatformAdmin()) {
                return true;
            }
            return currentUser.getUserId().equals(userId);
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 获取用户学习统计概览
     */
    @GetMapping("/overview/{userId}")
    public AjaxResult getLearningOverview(@PathVariable("userId") Long userId) {
        if (!canAccessUser(userId)) {
            return error("无权限查看其他用户统计");
        }
        Map<String, Object> overview = new HashMap<>();
        overview.put("totalQuestions", 156);
        overview.put("correctAnswers", 128);
        overview.put("accuracyRate", 82.05);
        overview.put("totalStudyHours", 12.5);
        overview.put("studyRanking", 3);
        overview.put("learningActivityLevel", "优秀");
        return success(overview);
    }

    /**
     * 获取学习时长统计
     */
    @GetMapping("/duration/{userId}")
    public AjaxResult getLearningDuration(@PathVariable("userId") Long userId) {
        if (!canAccessUser(userId)) {
            return error("无权限查看其他用户统计");
        }
        Map<String, Object> duration = new HashMap<>();
        duration.put("totalStudyHours", 12.5);
        duration.put("monthlyStudyHours", 8.2);
        duration.put("weeklyStudyHours", 2.1);
        duration.put("dailyStudyHours", 0.5);
        duration.put("lastStudyTime", "2024-10-18 09:30:00");
        return success(duration);
    }

    /**
     * 获取答题统计
     */
    @GetMapping("/answers/{userId}")
    public AjaxResult getAnswerStatistics(@PathVariable("userId") Long userId) {
        if (!canAccessUser(userId)) {
            return error("无权限查看其他用户统计");
        }
        Map<String, Object> answers = new HashMap<>();
        answers.put("totalQuestions", 156);
        answers.put("correctAnswers", 128);
        answers.put("wrongAnswers", 28);
        answers.put("accuracyRate", 82.05);
        answers.put("avgAnswerDuration", 45.2);
        answers.put("totalAnswerDuration", 7200);
        answers.put("monthlyQuestions", 45);
        answers.put("weeklyQuestions", 12);
        answers.put("dailyQuestions", 3);
        answers.put("lastAnswerTime", "2024-10-18 09:30:00");
        return success(answers);
    }

    /**
     * 获取学习趋势数据
     */
    @GetMapping("/trend/{userId}")
    public AjaxResult getLearningTrend(
            @PathVariable("userId") Long userId,
            @RequestParam(defaultValue = "daily") String period) {
        if (!canAccessUser(userId)) {
            return error("无权限查看其他用户统计");
        }
        List<Map<String, Object>> trend = new ArrayList<>();
        
        Map<String, Object> day1 = new HashMap<>();
        day1.put("date", "2024-10-15");
        day1.put("questions", 5);
        day1.put("correct", 4);
        day1.put("accuracy", 80.0);
        day1.put("duration", 15.5);
        trend.add(day1);
        
        Map<String, Object> day2 = new HashMap<>();
        day2.put("date", "2024-10-16");
        day2.put("questions", 8);
        day2.put("correct", 7);
        day2.put("accuracy", 87.5);
        day2.put("duration", 22.3);
        trend.add(day2);
        
        Map<String, Object> day3 = new HashMap<>();
        day3.put("date", "2024-10-17");
        day3.put("questions", 6);
        day3.put("correct", 5);
        day3.put("accuracy", 83.3);
        day3.put("duration", 18.7);
        trend.add(day3);
        
        Map<String, Object> day4 = new HashMap<>();
        day4.put("date", "2024-10-18");
        day4.put("questions", 3);
        day4.put("correct", 3);
        day4.put("accuracy", 100.0);
        day4.put("duration", 12.1);
        trend.add(day4);
        
        return success(trend);
    }

    /**
     * 获取学习成就
     */
    @GetMapping("/achievements/{userId}")
    public AjaxResult getLearningAchievements(@PathVariable("userId") Long userId) {
        if (!canAccessUser(userId)) {
            return error("无权限查看其他用户统计");
        }
        Map<String, Object> achievements = new HashMap<>();
        achievements.put("userId", userId);
        achievements.put("totalQuestions", 156);
        achievements.put("totalCorrect", 128);
        achievements.put("totalHours", 12.5);
        achievements.put("consecutiveDays", 7);
        achievements.put("maxAccuracy", 95.0);
        achievements.put("achievement_100_questions", 1);
        achievements.put("achievement_500_questions", 0);
        achievements.put("achievement_1000_questions", 0);
        achievements.put("achievement_10_hours", 1);
        achievements.put("achievement_50_hours", 0);
        achievements.put("achievement_100_hours", 0);
        achievements.put("achievement_7_days", 1);
        achievements.put("achievement_30_days", 0);
        achievements.put("achievement_90_accuracy", 1);
        achievements.put("achievement_95_accuracy", 1);
        return success(achievements);
    }

    /**
     * 获取学习排名
     */
    @GetMapping("/ranking/{userId}")
    public AjaxResult getLearningRanking(@PathVariable("userId") Long userId) {
        if (!canAccessUser(userId)) {
            return error("无权限查看其他用户统计");
        }
        Map<String, Object> ranking = new HashMap<>();
        ranking.put("studyRanking", 3);
        ranking.put("totalStudyHours", 12.5);
        ranking.put("totalQuestions", 156);
        ranking.put("accuracyRate", 82.05);
        return success(ranking);
    }

    /**
     * 获取综合学习统计
     */
    @GetMapping("/comprehensive/{userId}")
    public AjaxResult getComprehensiveStats(@PathVariable("userId") Long userId) {
        if (!canAccessUser(userId)) {
            return error("无权限查看其他用户统计");
        }
        Map<String, Object> stats = new HashMap<>();
        stats.put("userId", userId);
        stats.put("userName", "测试用户");
        stats.put("nickName", "学习达人");
        stats.put("avatar", "/profile/avatar/default.jpg");
        stats.put("totalStudyHours", 12.5);
        stats.put("monthlyStudyHours", 8.2);
        stats.put("weeklyStudyHours", 2.1);
        stats.put("dailyStudyHours", 0.5);
        stats.put("lastStudyTime", "2024-10-18 09:30:00");
        stats.put("totalQuestions", 156);
        stats.put("correctAnswers", 128);
        stats.put("wrongAnswers", 28);
        stats.put("accuracyRate", 82.05);
        stats.put("avgAnswerDuration", 45.2);
        stats.put("totalAnswerDuration", 7200);
        stats.put("monthlyQuestions", 45);
        stats.put("weeklyQuestions", 12);
        stats.put("dailyQuestions", 3);
        stats.put("lastAnswerTime", "2024-10-18 09:30:00");
        stats.put("learningActivityLevel", "优秀");
        stats.put("consecutiveDays", 7);
        stats.put("studyRanking", 3);
        return success(stats);
    }

    /**
     * 获取学习时长分布
     */
    @GetMapping("/duration-distribution/{userId}")
    public AjaxResult getDurationDistribution(@PathVariable("userId") Long userId) {
        if (!canAccessUser(userId)) {
            return error("无权限查看其他用户统计");
        }
        List<Map<String, Object>> distribution = new ArrayList<>();
        
        Map<String, Object> video = new HashMap<>();
        video.put("type", "video");
        video.put("name", "视频学习");
        video.put("hours", 5.2);
        video.put("color", "#3B82F6");
        distribution.add(video);
        
        Map<String, Object> practice = new HashMap<>();
        practice.put("type", "practice");
        practice.put("name", "在线练习");
        practice.put("hours", 4.8);
        practice.put("color", "#10B981");
        distribution.add(practice);
        
        Map<String, Object> exam = new HashMap<>();
        exam.put("type", "exam");
        exam.put("name", "考试答题");
        exam.put("hours", 2.5);
        exam.put("color", "#F59E0B");
        distribution.add(exam);
        
        return success(distribution);
    }

    /**
     * 获取答题类型统计
     */
    @GetMapping("/question-types/{userId}")
    public AjaxResult getQuestionTypeStats(@PathVariable("userId") Long userId) {
        if (!canAccessUser(userId)) {
            return error("无权限查看其他用户统计");
        }
        List<Map<String, Object>> typeStats = new ArrayList<>();
        
        Map<String, Object> single = new HashMap<>();
        single.put("type", "single");
        single.put("name", "单选题");
        single.put("count", 89);
        single.put("color", "#3B82F6");
        typeStats.add(single);
        
        Map<String, Object> multiple = new HashMap<>();
        multiple.put("type", "multiple");
        multiple.put("name", "多选题");
        multiple.put("count", 45);
        multiple.put("color", "#10B981");
        typeStats.add(multiple);
        
        Map<String, Object> judgment = new HashMap<>();
        judgment.put("type", "judgment");
        judgment.put("name", "判断题");
        judgment.put("count", 22);
        judgment.put("color", "#F59E0B");
        typeStats.add(judgment);
        
        return success(typeStats);
    }

    /**
     * 获取学习建议
     */
    @GetMapping("/suggestions/{userId}")
    public AjaxResult getLearningSuggestions(@PathVariable("userId") Long userId) {
        if (!canAccessUser(userId)) {
            return error("无权限查看其他用户统计");
        }
        List<Map<String, Object>> suggestions = new ArrayList<>();
        
        Map<String, Object> weakness = new HashMap<>();
        weakness.put("type", "weakness");
        weakness.put("title", "加强薄弱环节");
        weakness.put("description", "您在消防安全模块的正确率较低，建议重点复习相关知识点");
        weakness.put("icon", "fa fa-lightbulb-o");
        weakness.put("level", "warning");
        suggestions.add(weakness);
        
        Map<String, Object> consistency = new HashMap<>();
        consistency.put("type", "consistency");
        consistency.put("title", "保持学习节奏");
        consistency.put("description", "您最近的学习表现很好，建议继续保持每日学习习惯");
        consistency.put("icon", "fa fa-clock-o");
        consistency.put("level", "success");
        suggestions.add(consistency);
        
        Map<String, Object> challenge = new HashMap<>();
        challenge.put("type", "challenge");
        challenge.put("title", "挑战更高难度");
        challenge.put("description", "您的正确率已经很高，可以尝试更难的题目来提升自己");
        challenge.put("icon", "fa fa-arrow-up");
        challenge.put("level", "info");
        suggestions.add(challenge);
        
        return success(suggestions);
    }

    /**
     * 导出学习统计报告
     */
    @GetMapping("/export/{userId}")
    public AjaxResult exportLearningReport(@PathVariable("userId") Long userId, HttpServletResponse response) {
        if (!canAccessUser(userId)) {
            return error("无权限查看其他用户统计");
        }
        try {
            // 暂时返回成功消息
            return success("导出功能开发中，请稍后使用");
        } catch (Exception e) {
            return error("导出失败：" + e.getMessage());
        }
    }
}
