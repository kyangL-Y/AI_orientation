package com.ruoyi.web.controller.train;

import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.enums.DataSourceType;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.system.mapper.CourseCategoryMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 首页仪表盘Controller
 * 支持多租户和部门数据隔离
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/train/dashboard")
public class DashboardController extends BaseController
{
    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    @Autowired
    private CourseCategoryMapper courseCategoryMapper;

    /**
     * 获取首页统计数据
     * 根据用户角色过滤数据：
     * - 超级管理员/平台管理员/具备全租户权限的管理员: 查看所有数据
     * - 租户管理员: 只看本租户数据
     * - 部门管理员: 只看本部门数据
     */
    @GetMapping("/stats")
    public AjaxResult getStats()
    {
        Map<String, Object> stats = new HashMap<>();
        
        try {
            logger.info("开始获取首页统计数据...");
            
            // 获取当前用户信息
            Long userId = SecurityUtils.getUserId();
            Long deptId = SecurityUtils.getDeptId();
            String tenantId = null;
            
            // 获取租户ID
            try {
                String tenantSql = "SELECT tenant_id FROM `hz-vue`.sys_user WHERE user_id = ?";
                tenantId = jdbcTemplate.queryForObject(tenantSql, String.class, userId);
            } catch (Exception e) {
                logger.warn("获取租户ID失败: {}", e.getMessage());
            }
            
            logger.info("当前用户: userId={}, deptId={}, tenantId={}", userId, deptId, tenantId);
            boolean isSuperAdmin = isSuperAdminUser(userId, tenantId);
            
            // 从库数据：课程、学习记录
            Map<String, Object> slaveStats = getSlaveStats(userId, deptId, tenantId, isSuperAdmin);
            stats.putAll(slaveStats);
            
            // 主库数据：用户总数
            Integer userCount = getMasterUserCount(userId, deptId, tenantId, isSuperAdmin);
            stats.put("userCount", userCount);
            
            // 计算上周用户数增长率
            Integer lastWeekUserCount = getLastWeekUserCount(userId, deptId, tenantId, isSuperAdmin);
            int userGrowthRate = 0;
            if (lastWeekUserCount > 0) {
                userGrowthRate = (int)(((userCount - lastWeekUserCount) * 100.0) / lastWeekUserCount);
            } else {
                userGrowthRate = 100;
            }
            stats.put("userGrowthRate", userGrowthRate);
            logger.info("用户增长率: {}%, 当前: {}, 上周: {}", userGrowthRate, userCount, lastWeekUserCount);
            
            logger.info("首页统计数据获取成功: {}", stats);
            
        } catch (Exception e) {
            logger.error("获取统计数据失败", e);
            stats.put("courseCount", 0);
            stats.put("userCount", 0);
            stats.put("todayStudyCount", 0);
            stats.put("totalQuestions", 0);
        }
        
        return success(stats);
    }
    
    /**
     * 获取从库统计数据（课程、学习记录）
     */
    @DataSource(DataSourceType.SLAVE)
    public Map<String, Object> getSlaveStats(Long userId, Long deptId, String tenantId, boolean isSuperAdmin) {
        Map<String, Object> stats = new HashMap<>();
        
        try {
            // 课程总数 - 课程是全局的，不按租户/部门过滤
            String courseCountSql = "SELECT COUNT(*) FROM hotel_training.course_category";
            Integer courseCount = jdbcTemplate.queryForObject(courseCountSql, Integer.class);
            stats.put("courseCount", courseCount != null ? courseCount : 0);
            logger.info("课程总数: {}", courseCount);
            
            // 构建用户过滤条件
            String userFilter = buildUserFilterForSlave(userId, deptId, tenantId, isSuperAdmin);
            
            // 今日学习人数
            String todayStudySql;
            if (userFilter.isEmpty()) {
                todayStudySql = "SELECT COUNT(DISTINCT user_id) FROM hotel_training.train_answer_attempt WHERE DATE(attempt_time) = CURDATE()";
            } else {
                todayStudySql = "SELECT COUNT(DISTINCT user_id) FROM hotel_training.train_answer_attempt WHERE DATE(attempt_time) = CURDATE() AND " + userFilter;
            }
            Integer todayStudyCount = jdbcTemplate.queryForObject(todayStudySql, Integer.class);
            stats.put("todayStudyCount", todayStudyCount != null ? todayStudyCount : 0);
            logger.info("今日学习人数: {}", todayStudyCount);
            
            // 累计学习题数
            String totalQuestionsSql;
            if (userFilter.isEmpty()) {
                totalQuestionsSql = "SELECT COUNT(*) FROM hotel_training.train_answer_attempt";
            } else {
                totalQuestionsSql = "SELECT COUNT(*) FROM hotel_training.train_answer_attempt WHERE " + userFilter;
            }
            Integer totalQuestions = jdbcTemplate.queryForObject(totalQuestionsSql, Integer.class);
            stats.put("totalQuestions", totalQuestions != null ? totalQuestions : 0);
            logger.info("答题总数: {}", totalQuestions);
            
            // 计算上个月的答题总数
            String lastMonthQuestionsSql;
            if (userFilter.isEmpty()) {
                lastMonthQuestionsSql = "SELECT COUNT(*) FROM hotel_training.train_answer_attempt WHERE attempt_time < DATE_SUB(CURDATE(), INTERVAL 1 MONTH)";
            } else {
                lastMonthQuestionsSql = "SELECT COUNT(*) FROM hotel_training.train_answer_attempt WHERE attempt_time < DATE_SUB(CURDATE(), INTERVAL 1 MONTH) AND " + userFilter;
            }
            Integer lastMonthQuestions = jdbcTemplate.queryForObject(lastMonthQuestionsSql, Integer.class);
            int lastMonthQuestionsCount = lastMonthQuestions != null ? lastMonthQuestions : 0;
            
            // 计算增长率
            int questionGrowthRate = 0;
            if (lastMonthQuestionsCount > 0) {
                questionGrowthRate = (int)(((totalQuestions - lastMonthQuestionsCount) * 100.0) / lastMonthQuestionsCount);
            } else {
                questionGrowthRate = 100;
            }
            stats.put("questionGrowthRate", questionGrowthRate);
            logger.info("题数增长率: {}%", questionGrowthRate);

            // 本月考试数量
            String monthExamSql = "SELECT COUNT(*) FROM hotel_training.train_exam WHERE status = 'published' AND start_time >= DATE_FORMAT(NOW(), '%Y-%m-01') AND start_time < DATE_ADD(DATE_FORMAT(NOW(), '%Y-%m-01'), INTERVAL 1 MONTH)";
            Integer monthExamCount = jdbcTemplate.queryForObject(monthExamSql, Integer.class);
            stats.put("monthExamCount", monthExamCount != null ? monthExamCount : 0);

            // 平均通过率
            String passRateSql;
            String passRateSqlNoType;
            if (userFilter.isEmpty()) {
                passRateSql = "SELECT COUNT(*) as total, SUM(CASE WHEN is_passed = 1 THEN 1 ELSE 0 END) as passed FROM hotel_training.train_quiz_attempt WHERE attempt_type = 'exam'";
                passRateSqlNoType = "SELECT COUNT(*) as total, SUM(CASE WHEN is_passed = 1 THEN 1 ELSE 0 END) as passed FROM hotel_training.train_quiz_attempt";
            } else {
                passRateSql = "SELECT COUNT(*) as total, SUM(CASE WHEN is_passed = 1 THEN 1 ELSE 0 END) as passed FROM hotel_training.train_quiz_attempt WHERE attempt_type = 'exam' AND " + userFilter;
                passRateSqlNoType = "SELECT COUNT(*) as total, SUM(CASE WHEN is_passed = 1 THEN 1 ELSE 0 END) as passed FROM hotel_training.train_quiz_attempt WHERE " + userFilter;
            }
            try {
                Map<String, Object> passRateResult;
                try {
                    passRateResult = jdbcTemplate.queryForMap(passRateSql);
                } catch (Exception e) {
                    String message = e.getMessage();
                    if (message != null && message.contains("Unknown column") && message.contains("attempt_type")) {
                        passRateResult = jdbcTemplate.queryForMap(passRateSqlNoType);
                    } else {
                        throw e;
                    }
                }
                long totalParams = ((Number) passRateResult.get("total")).longValue();
                Object passedObj = passRateResult.get("passed");
                long passed = passedObj != null ? ((Number) passedObj).longValue() : 0L;
                
                double rate = totalParams > 0 ? (double) passed / totalParams * 100 : 0;
                stats.put("passRate", String.format("%.1f", rate));
            } catch (Exception e) {
                logger.warn("获取通过率失败: {}", e.getMessage());
                stats.put("passRate", "0.0");
            }
            
        } catch (Exception e) {
            logger.error("获取从库统计数据失败", e);
            stats.put("courseCount", 0);
            stats.put("todayStudyCount", 0);
            stats.put("totalQuestions", 0);
            stats.put("monthExamCount", 0);
            stats.put("passRate", "0.0");
        }
        
        return stats;
    }
    
    /**
     * 构建从库用户过滤条件
     */
    private String buildUserFilterForSlave(Long userId, Long deptId, String tenantId, boolean isSuperAdmin) {
        // 超级管理员看所有
        if (isSuperAdmin) {
            return "";
        }
        
        // 获取该租户/部门下的用户ID列表
        List<Long> userIds = getFilteredUserIds(userId, deptId, tenantId);
        if (userIds == null || userIds.isEmpty()) {
            return "1=0"; // 没有用户，返回空结果
        }
        
        StringBuilder sb = new StringBuilder("user_id IN (");
        for (int i = 0; i < userIds.size(); i++) {
            if (i > 0) sb.append(",");
            sb.append(userIds.get(i));
        }
        sb.append(")");
        return sb.toString();
    }
    
    /**
     * 获取过滤后的用户ID列表
     */
    private List<Long> getFilteredUserIds(Long userId, Long deptId, String tenantId) {
        try {
            String sql;
            if (tenantId != null && !tenantId.isEmpty() && !"000000".equals(tenantId)) {
                // 租户管理员：获取本租户所有用户
                sql = "SELECT user_id FROM `hz-vue`.sys_user WHERE tenant_id = ? AND del_flag = '0'";
                return jdbcTemplate.queryForList(sql, Long.class, tenantId);
            } else if (deptId != null && deptId > 0) {
                // 部门管理员：获取本部门及子部门的用户
                sql = "SELECT user_id FROM `hz-vue`.sys_user WHERE del_flag = '0' AND dept_id IN " +
                      "(SELECT dept_id FROM `hz-vue`.sys_dept WHERE dept_id = ? OR FIND_IN_SET(?, ancestors))";
                return jdbcTemplate.queryForList(sql, Long.class, deptId, deptId);
            }
        } catch (Exception e) {
            logger.error("获取过滤用户ID失败", e);
        }
        return null;
    }
    
    /**
     * 获取主库用户总数
     */
    @DataSource(DataSourceType.MASTER)
    public int getMasterUserCount(Long userId, Long deptId, String tenantId, boolean isSuperAdmin) {
        try {
            String sql;
            
            // 超级管理员看所有
            if (isSuperAdmin) {
                sql = "SELECT COUNT(*) FROM sys_user WHERE user_id > 2 AND del_flag = '0'";
                Integer count = jdbcTemplate.queryForObject(sql, Integer.class);
                logger.info("用户总数(全部): {}", count);
                return count != null ? count : 0;
            }
            
            // 租户管理员：只看本租户
            if (tenantId != null && !tenantId.isEmpty() && !"000000".equals(tenantId)) {
                sql = "SELECT COUNT(*) FROM sys_user WHERE user_id > 2 AND del_flag = '0' AND tenant_id = ?";
                Integer count = jdbcTemplate.queryForObject(sql, Integer.class, tenantId);
                logger.info("用户总数(租户{}): {}", tenantId, count);
                return count != null ? count : 0;
            }
            
            // 部门管理员：只看本部门及子部门
            if (deptId != null && deptId > 0) {
                sql = "SELECT COUNT(*) FROM sys_user WHERE user_id > 2 AND del_flag = '0' AND dept_id IN " +
                      "(SELECT dept_id FROM sys_dept WHERE dept_id = ? OR FIND_IN_SET(?, ancestors))";
                Integer count = jdbcTemplate.queryForObject(sql, Integer.class, deptId, deptId);
                logger.info("用户总数(部门{}): {}", deptId, count);
                return count != null ? count : 0;
            }
            
            // 默认返回所有
            sql = "SELECT COUNT(*) FROM sys_user WHERE user_id > 2 AND del_flag = '0'";
            Integer count = jdbcTemplate.queryForObject(sql, Integer.class);
            return count != null ? count : 0;
            
        } catch (Exception e) {
            logger.error("获取用户总数失败", e);
            return 0;
        }
    }
    
    /**
     * 获取上周用户数
     */
    private int getLastWeekUserCount(Long userId, Long deptId, String tenantId, boolean isSuperAdmin) {
        try {
            String sql;
            
            // 超级管理员看所有
            if (isSuperAdmin) {
                sql = "SELECT COUNT(*) FROM `hz-vue`.sys_user WHERE user_id > 2 AND del_flag = '0' AND create_time < DATE_SUB(CURDATE(), INTERVAL 1 WEEK)";
                Integer count = jdbcTemplate.queryForObject(sql, Integer.class);
                return count != null ? count : 0;
            }
            
            // 租户管理员
            if (tenantId != null && !tenantId.isEmpty() && !"000000".equals(tenantId)) {
                sql = "SELECT COUNT(*) FROM `hz-vue`.sys_user WHERE user_id > 2 AND del_flag = '0' AND tenant_id = ? AND create_time < DATE_SUB(CURDATE(), INTERVAL 1 WEEK)";
                Integer count = jdbcTemplate.queryForObject(sql, Integer.class, tenantId);
                return count != null ? count : 0;
            }
            
            // 部门管理员
            if (deptId != null && deptId > 0) {
                sql = "SELECT COUNT(*) FROM `hz-vue`.sys_user WHERE user_id > 2 AND del_flag = '0' AND create_time < DATE_SUB(CURDATE(), INTERVAL 1 WEEK) AND dept_id IN " +
                      "(SELECT dept_id FROM `hz-vue`.sys_dept WHERE dept_id = ? OR FIND_IN_SET(?, ancestors))";
                Integer count = jdbcTemplate.queryForObject(sql, Integer.class, deptId, deptId);
                return count != null ? count : 0;
            }
            
            sql = "SELECT COUNT(*) FROM `hz-vue`.sys_user WHERE user_id > 2 AND del_flag = '0' AND create_time < DATE_SUB(CURDATE(), INTERVAL 1 WEEK)";
            Integer count = jdbcTemplate.queryForObject(sql, Integer.class);
            return count != null ? count : 0;
            
        } catch (Exception e) {
            logger.error("获取上周用户数失败", e);
            return 0;
        }
    }

    /**
     * 获取学习趋势（最近7天）
     */
    @GetMapping("/trend")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getStudyTrend()
    {
        List<Map<String, Object>> trendList = new ArrayList<>();
        
        try {
            // 获取当前用户信息
            Long userId = SecurityUtils.getUserId();
            Long deptId = SecurityUtils.getDeptId();
            String tenantId = null;
            
            try {
                String tenantSql = "SELECT tenant_id FROM `hz-vue`.sys_user WHERE user_id = ?";
                tenantId = jdbcTemplate.queryForObject(tenantSql, String.class, userId);
            } catch (Exception e) {
                logger.warn("获取租户ID失败");
            }
            
            // 构建用户过滤条件
            boolean isSuperAdmin = isSuperAdminUser(userId, tenantId);
            String userFilter = buildUserFilterForSlave(userId, deptId, tenantId, isSuperAdmin);
            
            // 最近7天的学习人数统计
            String sql;
            if (userFilter.isEmpty()) {
                sql = "SELECT DATE(attempt_time) as date, COUNT(DISTINCT user_id) as count " +
                      "FROM hotel_training.train_answer_attempt " +
                      "WHERE attempt_time >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) " +
                      "GROUP BY DATE(attempt_time) " +
                      "ORDER BY DATE(attempt_time)";
            } else {
                sql = "SELECT DATE(attempt_time) as date, COUNT(DISTINCT user_id) as count " +
                      "FROM hotel_training.train_answer_attempt " +
                      "WHERE attempt_time >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) AND " + userFilter + " " +
                      "GROUP BY DATE(attempt_time) " +
                      "ORDER BY DATE(attempt_time)";
            }
            
            List<Map<String, Object>> dbResult = jdbcTemplate.queryForList(sql);
            
            logger.info("学习趋势查询结果: {} 条记录", dbResult.size());
            
            // 补全7天数据
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("M/d");
            for (int i = 6; i >= 0; i--) {
                LocalDate date = LocalDate.now().minusDays(i);
                String dateStr = date.format(formatter);
                
                Map<String, Object> trend = new HashMap<>();
                trend.put("date", dateStr);
                
                boolean found = false;
                for (Map<String, Object> row : dbResult) {
                    Object dateObj = row.get("date");
                    if (dateObj != null) {
                        LocalDate dbDate;
                        if (dateObj instanceof java.sql.Date) {
                            dbDate = ((java.sql.Date) dateObj).toLocalDate();
                        } else if (dateObj instanceof LocalDate) {
                            dbDate = (LocalDate) dateObj;
                        } else {
                            dbDate = LocalDate.parse(dateObj.toString());
                        }
                        
                        if (dbDate.equals(date)) {
                            trend.put("count", row.get("count"));
                            found = true;
                            break;
                        }
                    }
                }
                
                if (!found) {
                    trend.put("count", 0);
                }
                
                trendList.add(trend);
            }
            
        } catch (Exception e) {
            logger.error("获取学习趋势数据失败", e);
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("M/d");
            for (int i = 6; i >= 0; i--) {
                LocalDate date = LocalDate.now().minusDays(i);
                Map<String, Object> trend = new HashMap<>();
                trend.put("date", date.format(formatter));
                trend.put("count", 0);
                trendList.add(trend);
            }
        }
        
        return success(trendList);
    }

    /**
     * Dashboard 的“全量可见”能力应与统一管理员模型保持一致，
     * 包括超级管理员、平台管理员，以及通过角色叠加得到全租户权限的账号。
     */
    private boolean isSuperAdminUser(Long userId, String tenantId) {
        try {
            SysUser user = SecurityUtils.getLoginUser().getUser();
            return user != null && user.canManageAllTenants();
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 获取热门课程（前5个课程）
     */
    @GetMapping("/hotCourses")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getHotCourses()
    {
        List<Map<String, Object>> hotCourses = new ArrayList<>();
        
        try {
            String sql = "SELECT course_category_id, third_level_c as courseName, 0 as studyCount " +
                        "FROM course_category " +
                        "ORDER BY sort_order ASC, course_category_id ASC " +
                        "LIMIT 5";
            
            hotCourses = jdbcTemplate.queryForList(sql);
            
        } catch (Exception e) {
            logger.error("获取热门课程数据失败", e);
        }
        
        return success(hotCourses);
    }
    
    /**
     * 获取总学习时长
     */
    @GetMapping("/totalStudyDuration")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getTotalStudyDuration()
    {
        Map<String, Object> result = new HashMap<>();
        try {
            // 获取当前用户信息
            Long userId = SecurityUtils.getUserId();
            Long deptId = SecurityUtils.getDeptId();
            String tenantId = null;
            
            try {
                String tenantSql = "SELECT tenant_id FROM `hz-vue`.sys_user WHERE user_id = ?";
                tenantId = jdbcTemplate.queryForObject(tenantSql, String.class, userId);
            } catch (Exception e) {
                logger.warn("获取租户ID失败");
            }
            
            // 构建用户过滤条件
            boolean isSuperAdmin = isSuperAdminUser(userId, tenantId);
            String userFilter = buildUserFilterForSlave(userId, deptId, tenantId, isSuperAdmin);
            
            // 统计在线时长
            String sql;
            if (userFilter.isEmpty()) {
                sql = "SELECT COALESCE(SUM(duration), 0) FROM train_page_visit WHERE duration >= 2";
            } else {
                sql = "SELECT COALESCE(SUM(duration), 0) FROM train_page_visit WHERE duration >= 2 AND " + userFilter;
            }
            Long total = jdbcTemplate.queryForObject(sql, Long.class);
            if (total == null) {
                total = 0L;
            }
            result.put("totalDurationSec", total);
            
            // 计算上周学习时长
            String lastWeekSql;
            if (userFilter.isEmpty()) {
                lastWeekSql = "SELECT COALESCE(SUM(duration), 0) FROM train_page_visit WHERE duration >= 2 AND visit_time < DATE_SUB(CURDATE(), INTERVAL 1 WEEK)";
            } else {
                lastWeekSql = "SELECT COALESCE(SUM(duration), 0) FROM train_page_visit WHERE duration >= 2 AND visit_time < DATE_SUB(CURDATE(), INTERVAL 1 WEEK) AND " + userFilter;
            }
            Long lastWeekTotal = jdbcTemplate.queryForObject(lastWeekSql, Long.class);
            if (lastWeekTotal == null) {
                lastWeekTotal = 0L;
            }
            
            // 计算增长率
            int durationGrowthRate = 0;
            if (lastWeekTotal > 0) {
                durationGrowthRate = (int)(((total - lastWeekTotal) * 100.0) / lastWeekTotal);
            } else {
                durationGrowthRate = 100;
            }
            result.put("durationGrowthRate", durationGrowthRate);
            
            logger.info("总学习时长: {} 秒, 增长率: {}%", total, durationGrowthRate);
        } catch (Exception e) {
            logger.error("统计总学习时长失败", e);
            result.put("totalDurationSec", 0);
            result.put("durationGrowthRate", 0);
        }
        return success(result);
    }
    
    /**
     * 测试数据库连接
     */
    @GetMapping("/test")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult testDatabase()
    {
        Map<String, Object> result = new HashMap<>();
        
        try {
            String slaveTestSql = "SELECT 1 as test";
            Integer slaveResult = jdbcTemplate.queryForObject(slaveTestSql, Integer.class);
            result.put("slaveConnection", "成功: " + slaveResult);
            
            String courseCountSql = "SELECT COUNT(*) FROM course_category";
            Integer courseCount = jdbcTemplate.queryForObject(courseCountSql, Integer.class);
            result.put("courseCategoryCount", courseCount != null ? courseCount : 0);
            
            String sampleSql = "SELECT course_category_id, third_level_c FROM course_category LIMIT 3";
            List<Map<String, Object>> sampleRecords = jdbcTemplate.queryForList(sampleSql);
            result.put("sampleRecords", sampleRecords);
            
        } catch (Exception e) {
            logger.error("测试数据库连接失败", e);
            result.put("error", e.getMessage());
        }
        
        return success(result);
    }
}
