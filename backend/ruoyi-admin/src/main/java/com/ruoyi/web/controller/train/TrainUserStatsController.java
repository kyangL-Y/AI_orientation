package com.ruoyi.web.controller.train;

import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.DataSourceType;
import com.ruoyi.common.utils.poi.ExcelUtil;
import com.ruoyi.system.service.ISysUserService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletResponse;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 用户学习时长统计控制器（管理端）
 */
@RestController
@RequestMapping("/train/admin/userStats")
public class TrainUserStatsController extends BaseController {

    private static final Logger logger = LoggerFactory.getLogger(TrainUserStatsController.class);

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private ISysUserService userService;

    /**
     * 获取用户学习时长统计列表
     * 整合：页面访问时长 + 课程学习时长 + 答题时长
     * 注意：不使用@DataSource注解，使用主库连接以支持跨库查询
     */
    @GetMapping("/list")
    public TableDataInfo list(
            @RequestParam(required = false) String userName,
            @RequestParam(required = false) Long deptId,
            @RequestParam(required = false) String beginTime,
            @RequestParam(required = false) String endTime,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize
    ) {
        try {
            // 获取当前登录用户信息
            com.ruoyi.common.core.domain.entity.SysUser currentUser = getLoginUser().getUser();
            String currentTenantId = currentUser.getTenantId();
            Integer adminLevel = currentUser.getAdminLevel();
            boolean isPlatformAdmin = (adminLevel != null && adminLevel <= 5);

            logger.info("📊 获取用户学习时长统计列表 - tenantId: {}, adminLevel: {}, isPlatformAdmin: {}, userName: {}, deptId: {}, beginTime: {}, endTime: {}",
                       currentTenantId, adminLevel, isPlatformAdmin, userName, deptId, beginTime, endTime);

            // 构建SQL查询 - 整合页面访问时长 + 课程学习时长 + 答题时长
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT ")
               .append("  u.user_id, ")
               .append("  u.user_name, ")
               .append("  CASE ")
               .append("    WHEN p.dept_name IS NOT NULL AND p.dept_name != d.dept_name THEN CONCAT(p.dept_name, '-', d.dept_name) ")
               .append("    ELSE d.dept_name ")
               .append("  END AS dept_name, ")
               .append("  u.phonenumber, ")
               .append("  COALESCE(page_stats.page_seconds, 0) + COALESCE(course_stats.course_seconds, 0) + COALESCE(answer_stats.answer_seconds, 0) AS total_seconds, ")
               .append("  COALESCE(answer_stats.total_questions, 0) AS total_questions, ")
               .append("  COALESCE(answer_stats.correct_answers, 0) AS correct_answers, ")
               .append("  COALESCE(answer_stats.accuracy_rate, 0) AS accuracy_rate, ")
               .append("  GREATEST(COALESCE(page_stats.last_page_time, '1970-01-01'), ")
               .append("           COALESCE(course_stats.last_course_time, '1970-01-01'), ")
               .append("           COALESCE(answer_stats.last_answer_time, '1970-01-01')) AS last_study_time ")
               .append("FROM `hz-vue`.sys_user u ")
               .append("LEFT JOIN `hz-vue`.sys_dept d ON u.dept_id = d.dept_id ")
               .append("LEFT JOIN `hz-vue`.sys_dept p ON d.parent_id = p.dept_id ")
               // 页面访问时长
               .append("LEFT JOIN (")
               .append("  SELECT ")
               .append("    user_id, ")
               .append("    SUM(duration) AS page_seconds, ")
               .append("    MAX(visit_time) AS last_page_time ")
               .append("  FROM hotel_training.train_page_visit ")
               .append("  WHERE 1=1 ");

            List<Object> params = new ArrayList<>();

            // 添加时间范围条件
            if (beginTime != null && !beginTime.isEmpty()) {
                sql.append("AND visit_time >= ? ");
                params.add(beginTime + " 00:00:00");
            }
            if (endTime != null && !endTime.isEmpty()) {
                sql.append("AND visit_time <= ? ");
                params.add(endTime + " 23:59:59");
            }

            sql.append("  GROUP BY user_id")
               .append(") page_stats ON u.user_id = page_stats.user_id ")
               // 课程学习时长
               .append("LEFT JOIN (")
               .append("  SELECT ")
               .append("    user_id, ")
               .append("    SUM(study_duration) AS course_seconds, ")
               .append("    MAX(update_time) AS last_course_time ")
               .append("  FROM hotel_training.train_progress ")
               .append("  WHERE 1=1 ");

            // 添加课程学习的时间范围条件
            if (beginTime != null && !beginTime.isEmpty()) {
                sql.append("AND started_at >= ? ");
                params.add(beginTime + " 00:00:00");
            }
            if (endTime != null && !endTime.isEmpty()) {
                sql.append("AND started_at <= ? ");
                params.add(endTime + " 23:59:59");
            }

            sql.append("  GROUP BY user_id")
               .append(") course_stats ON u.user_id = course_stats.user_id ")
               // 答题学习时长和答题统计
               .append("LEFT JOIN (")
               .append("  SELECT ")
               .append("    user_id, ")
               .append("    COALESCE(SUM(duration), 0) AS answer_seconds, ")
               .append("    COUNT(*) AS total_questions, ")
               .append("    SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) AS correct_answers, ")
               .append("    ROUND(SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 0) AS accuracy_rate, ")
               .append("    MAX(attempt_time) AS last_answer_time ")
               .append("  FROM hotel_training.train_answer_attempt ")
               .append("  WHERE 1=1 ");

            if (beginTime != null && !beginTime.isEmpty()) {
                sql.append("AND attempt_time >= ? ");
                params.add(beginTime + " 00:00:00");
            }
            if (endTime != null && !endTime.isEmpty()) {
                sql.append("AND attempt_time <= ? ");
                params.add(endTime + " 23:59:59");
            }

            sql.append("  GROUP BY user_id")
               .append(") answer_stats ON u.user_id = answer_stats.user_id ")
               .append("WHERE u.del_flag = '0' ");

            // 【修复】只有非平台管理员才过滤集团ID，平台管理员(admin_level<=5)可以看到所有集团
            if (!isPlatformAdmin) {
                sql.append("AND u.tenant_id = ? ");
                params.add(currentTenantId);
            }

            sql.append("AND (page_stats.user_id IS NOT NULL OR course_stats.user_id IS NOT NULL OR answer_stats.user_id IS NOT NULL) ");

            // 添加用户名筛选
            if (userName != null && !userName.isEmpty()) {
                sql.append("AND u.user_name LIKE ? ");
                params.add("%" + userName + "%");
            }

            // 添加部门筛选
            if (deptId != null) {
                sql.append("AND (u.dept_id = ? OR u.dept_id IN (SELECT t.dept_id FROM `hz-vue`.sys_dept t WHERE FIND_IN_SET(?, t.ancestors))) ");
                params.add(deptId);
                params.add(deptId);
            }

            sql.append("ORDER BY total_seconds DESC ");

            logger.info("📊 执行SQL: {}", sql.toString());
            logger.info("📊 参数: {}", params);

            // 执行查询
            List<Map<String, Object>> results = jdbcTemplate.queryForList(sql.toString(), params.toArray());
            
            logger.info("📊 查询结果数量: {}", results.size());

            // 格式化结果
            List<Map<String, Object>> formattedResults = new ArrayList<>();
            for (Map<String, Object> row : results) {
                Map<String, Object> item = new HashMap<>();
                Long userId = ((Number) row.get("user_id")).longValue();
                item.put("userId", userId);
                item.put("userName", row.get("user_name"));
                item.put("deptName", row.get("dept_name"));
                item.put("phonenumber", row.get("phonenumber"));
                item.put("totalSeconds", ((Number) row.get("total_seconds")).intValue());
                item.put("lastStudyTime", row.get("last_study_time"));
                item.put("totalQuestions", ((Number) row.get("total_questions")).intValue());
                item.put("correctAnswers", ((Number) row.get("correct_answers")).intValue());
                item.put("accuracyRate", ((Number) row.get("accuracy_rate")).intValue());
                formattedResults.add(item);
            }

            // 分页处理
            int start = (pageNum - 1) * pageSize;
            int end = Math.min(start + pageSize, formattedResults.size());
            List<Map<String, Object>> pageData = start < formattedResults.size() ? 
                formattedResults.subList(start, end) : new ArrayList<>();

            // 返回分页结果
            TableDataInfo dataInfo = new TableDataInfo();
            dataInfo.setRows(pageData);
            dataInfo.setTotal(formattedResults.size());
            dataInfo.setCode(200);
            dataInfo.setMsg("查询成功");

            return dataInfo;

        } catch (Exception e) {
            logger.error("❌ 获取用户学习时长统计失败", e);
            TableDataInfo dataInfo = new TableDataInfo();
            dataInfo.setCode(500);
            dataInfo.setMsg("查询失败: " + e.getMessage());
            return dataInfo;
        }
    }

    /**
     * 获取用户学习趋势数据（页面访问时长 + 答题数量）
     */
    @PreAuthorize("@ss.hasAnyPermi('system:user:query,system:user:list,train:userStats:list')")
    @GetMapping("/trend/{userId}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getTrend(@PathVariable Long userId, @RequestParam(defaultValue = "7") Integer days) {
        try {
            userService.checkUserDataScope(userId);
            logger.info("📈 获取用户学习趋势 - userId: {}, days: {}", userId, days);

            // 生成最近N天的日期列表
            String datesSql = "SELECT DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL n DAY), '%Y-%m-%d') AS date_str, " +
                             "DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL n DAY), '%m-%d') AS label " +
                             "FROM (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 " +
                             "UNION SELECT 4 UNION SELECT 5 UNION SELECT 6) numbers " +
                             "WHERE n < ? ORDER BY date_str";
            
            List<Map<String, Object>> dates = jdbcTemplate.queryForList(datesSql, days);
            
            // 查询页面访问时长（按日期分组）
            String pageSql = "SELECT " +
                        "  DATE_FORMAT(visit_date, '%Y-%m-%d') AS date_str, " +
                        "  COALESCE(SUM(duration), 0) / 3600.0 AS hours " +
                        "FROM hotel_training.train_page_visit " +
                        "WHERE user_id = ? " +
                        "  AND visit_time >= DATE_SUB(CURDATE(), INTERVAL ? DAY) " +
                        "GROUP BY visit_date";

            List<Map<String, Object>> pageResults = jdbcTemplate.queryForList(pageSql, userId, days);
            Map<String, Double> hoursMap = new HashMap<>();
            for (Map<String, Object> row : pageResults) {
                hoursMap.put((String) row.get("date_str"), ((Number) row.get("hours")).doubleValue());
            }
            
            // 查询答题数量（按日期分组）
            String answerSql = "SELECT " +
                        "  DATE_FORMAT(attempt_time, '%Y-%m-%d') AS date_str, " +
                        "  COUNT(*) AS question_count " +
                        "FROM hotel_training.train_answer_attempt " +
                        "WHERE user_id = ? " +
                        "  AND attempt_time >= DATE_SUB(CURDATE(), INTERVAL ? DAY) " +
                        "GROUP BY DATE_FORMAT(attempt_time, '%Y-%m-%d')";

            List<Map<String, Object>> answerResults = jdbcTemplate.queryForList(answerSql, userId, days);
            Map<String, Integer> questionsMap = new HashMap<>();
            for (Map<String, Object> row : answerResults) {
                questionsMap.put((String) row.get("date_str"), ((Number) row.get("question_count")).intValue());
            }

            // 组装结果，确保每天都有数据（没有数据的填0）
            List<String> labels = new ArrayList<>();
            List<Double> hours = new ArrayList<>();
            List<Integer> questions = new ArrayList<>();

            for (Map<String, Object> date : dates) {
                String dateStr = (String) date.get("date_str");
                String label = (String) date.get("label");
                labels.add(label);
                hours.add(hoursMap.getOrDefault(dateStr, 0.0));
                questions.add(questionsMap.getOrDefault(dateStr, 0));
            }

            Map<String, Object> trend = new HashMap<>();
            trend.put("labels", labels);
            trend.put("hours", hours);
            trend.put("questions", questions);

            logger.info("📈 趋势数据: labels={}, hours={}, questions={}", labels, hours, questions);

            return success(trend);

        } catch (Exception e) {
            logger.error("❌ 获取用户学习趋势失败", e);
            return error("获取趋势数据失败: " + e.getMessage());
        }
    }

    /**
     * 获取用户最近学习记录（含学习时长和答题统计）
     */
    @PreAuthorize("@ss.hasAnyPermi('system:user:query,system:user:list,train:userStats:list')")
    @GetMapping("/recentRecords/{userId}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getRecentRecords(@PathVariable Long userId, @RequestParam(defaultValue = "7") Integer days) {
        try {
            userService.checkUserDataScope(userId);
            logger.info("📋 获取用户最近学习记录 - userId: {}, days: {}", userId, days);

            // 查询答题统计
            String answerSql = "SELECT " +
                        "  DATE(attempt_time) AS study_date, " +
                        "  COUNT(*) AS question_count, " +
                        "  ROUND(SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 0) AS accuracy " +
                        "FROM hotel_training.train_answer_attempt " +
                        "WHERE user_id = ? " +
                        "  AND attempt_time >= DATE_SUB(CURDATE(), INTERVAL ? DAY) " +
                        "GROUP BY DATE(attempt_time)";

            List<Map<String, Object>> answerResults = jdbcTemplate.queryForList(answerSql, userId, days);
            
            // 查询页面访问时长
            String pageSql = "SELECT " +
                        "  visit_date AS study_date, " +
                        "  SUM(duration) AS page_duration " +
                        "FROM hotel_training.train_page_visit " +
                        "WHERE user_id = ? " +
                        "  AND visit_time >= DATE_SUB(CURDATE(), INTERVAL ? DAY) " +
                        "GROUP BY visit_date";
            
            List<Map<String, Object>> pageResults = jdbcTemplate.queryForList(pageSql, userId, days);
            
            // 查询课程学习时长
            String courseSql = "SELECT " +
                        "  DATE(started_at) AS study_date, " +
                        "  SUM(study_duration) AS course_duration " +
                        "FROM hotel_training.train_progress " +
                        "WHERE user_id = ? " +
                        "  AND started_at >= DATE_SUB(CURDATE(), INTERVAL ? DAY) " +
                        "GROUP BY DATE(started_at)";
            
            List<Map<String, Object>> courseResults = jdbcTemplate.queryForList(courseSql, userId, days);
            
            // 合并数据，以日期为key
            Map<String, Map<String, Object>> mergedMap = new HashMap<>();
            
            // 添加答题数据
            for (Map<String, Object> row : answerResults) {
                String date = row.get("study_date").toString();
                Map<String, Object> record = mergedMap.computeIfAbsent(date, k -> {
                    Map<String, Object> m = new HashMap<>();
                    m.put("study_date", date);
                    m.put("duration", 0);
                    m.put("question_count", 0);
                    m.put("accuracy", 0);
                    return m;
                });
                record.put("question_count", ((Number) row.get("question_count")).intValue());
                record.put("accuracy", ((Number) row.get("accuracy")).intValue());
            }
            
            // 添加页面访问时长
            for (Map<String, Object> row : pageResults) {
                String date = row.get("study_date").toString();
                Map<String, Object> record = mergedMap.computeIfAbsent(date, k -> {
                    Map<String, Object> m = new HashMap<>();
                    m.put("study_date", date);
                    m.put("duration", 0);
                    m.put("question_count", 0);
                    m.put("accuracy", 0);
                    return m;
                });
                int currentDuration = ((Number) record.get("duration")).intValue();
                int pageDuration = ((Number) row.get("page_duration")).intValue();
                record.put("duration", currentDuration + pageDuration);
            }
            
            // 添加课程学习时长
            for (Map<String, Object> row : courseResults) {
                String date = row.get("study_date").toString();
                Map<String, Object> record = mergedMap.computeIfAbsent(date, k -> {
                    Map<String, Object> m = new HashMap<>();
                    m.put("study_date", date);
                    m.put("duration", 0);
                    m.put("question_count", 0);
                    m.put("accuracy", 0);
                    return m;
                });
                int currentDuration = ((Number) record.get("duration")).intValue();
                int courseDuration = ((Number) row.get("course_duration")).intValue();
                record.put("duration", currentDuration + courseDuration);
            }
            
            // 转换为列表并按日期倒序排序
            List<Map<String, Object>> results = new ArrayList<>(mergedMap.values());
            results.sort((a, b) -> b.get("study_date").toString().compareTo(a.get("study_date").toString()));

            return success(results);

        } catch (Exception e) {
            logger.error("❌ 获取用户最近学习记录失败", e);
            return error("获取学习记录失败: " + e.getMessage());
        }
    }

    /**
     * 导出用户学习时长统计
     */
    @GetMapping("/export")
    public void export(HttpServletResponse response,
            @RequestParam(required = false) String userName,
            @RequestParam(required = false) Long deptId,
            @RequestParam(required = false) String beginTime,
            @RequestParam(required = false) String endTime) {
        try {
            // 获取当前登录用户信息
            com.ruoyi.common.core.domain.entity.SysUser currentUser = getLoginUser().getUser();
            String currentTenantId = currentUser.getTenantId();
            Integer adminLevel = currentUser.getAdminLevel();
            boolean isPlatformAdmin = (adminLevel != null && adminLevel <= 5);

            logger.info("📤 导出用户学习时长统计 - tenantId: {}, adminLevel: {}, isPlatformAdmin: {}, userName: {}, deptId: {}",
                       currentTenantId, adminLevel, isPlatformAdmin, userName, deptId);

            // 构建SQL查询（与list方法相同，但不分页）
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT ")
               .append("  u.user_id, ")
               .append("  u.user_name, ")
               .append("  CASE ")
               .append("    WHEN p.dept_name IS NOT NULL AND p.dept_name != d.dept_name THEN CONCAT(p.dept_name, '-', d.dept_name) ")
               .append("    ELSE d.dept_name ")
               .append("  END AS dept_name, ")
               .append("  u.phonenumber, ")
               .append("  COALESCE(page_stats.page_seconds, 0) + COALESCE(course_stats.course_seconds, 0) + COALESCE(answer_stats.answer_seconds, 0) AS total_seconds, ")
               .append("  COALESCE(answer_stats.total_questions, 0) AS total_questions, ")
               .append("  COALESCE(answer_stats.correct_answers, 0) AS correct_answers, ")
               .append("  COALESCE(answer_stats.accuracy_rate, 0) AS accuracy_rate, ")
               .append("  GREATEST(COALESCE(page_stats.last_page_time, '1970-01-01'), ")
               .append("           COALESCE(course_stats.last_course_time, '1970-01-01'), ")
               .append("           COALESCE(answer_stats.last_answer_time, '1970-01-01')) AS last_study_time ")
               .append("FROM `hz-vue`.sys_user u ")
               .append("LEFT JOIN `hz-vue`.sys_dept d ON u.dept_id = d.dept_id ")
               .append("LEFT JOIN `hz-vue`.sys_dept p ON d.parent_id = p.dept_id ")
               .append("LEFT JOIN (")
               .append("  SELECT user_id, SUM(duration) AS page_seconds, MAX(visit_time) AS last_page_time ")
               .append("  FROM hotel_training.train_page_visit WHERE 1=1 ");

            List<Object> params = new ArrayList<>();
            if (beginTime != null && !beginTime.isEmpty()) {
                sql.append("AND visit_time >= ? ");
                params.add(beginTime + " 00:00:00");
            }
            if (endTime != null && !endTime.isEmpty()) {
                sql.append("AND visit_time <= ? ");
                params.add(endTime + " 23:59:59");
            }

            sql.append("  GROUP BY user_id) page_stats ON u.user_id = page_stats.user_id ")
               .append("LEFT JOIN (")
               .append("  SELECT user_id, SUM(study_duration) AS course_seconds, MAX(update_time) AS last_course_time ")
               .append("  FROM hotel_training.train_progress WHERE 1=1 ");

            if (beginTime != null && !beginTime.isEmpty()) {
                sql.append("AND started_at >= ? ");
                params.add(beginTime + " 00:00:00");
            }
            if (endTime != null && !endTime.isEmpty()) {
                sql.append("AND started_at <= ? ");
                params.add(endTime + " 23:59:59");
            }

            sql.append("  GROUP BY user_id) course_stats ON u.user_id = course_stats.user_id ")
               .append("LEFT JOIN (")
               .append("  SELECT user_id, ")
               .append("         COALESCE(SUM(duration), 0) AS answer_seconds, ")
               .append("         COUNT(*) AS total_questions, ")
               .append("         SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) AS correct_answers, ")
               .append("         ROUND(SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 0) AS accuracy_rate, ")
               .append("         MAX(attempt_time) AS last_answer_time ")
               .append("  FROM hotel_training.train_answer_attempt WHERE 1=1 ");

            if (beginTime != null && !beginTime.isEmpty()) {
                sql.append("AND attempt_time >= ? ");
                params.add(beginTime + " 00:00:00");
            }
            if (endTime != null && !endTime.isEmpty()) {
                sql.append("AND attempt_time <= ? ");
                params.add(endTime + " 23:59:59");
            }

            sql.append("  GROUP BY user_id) answer_stats ON u.user_id = answer_stats.user_id ")
               .append("WHERE u.del_flag = '0' ");

            // 【修复】只有非平台管理员才过滤集团ID，平台管理员(admin_level<=5)可以看到所有集团
            if (!isPlatformAdmin) {
                sql.append("AND u.tenant_id = ? ");
                params.add(currentTenantId);
            }

            sql.append("AND (page_stats.user_id IS NOT NULL OR course_stats.user_id IS NOT NULL OR answer_stats.user_id IS NOT NULL) ");

            if (userName != null && !userName.isEmpty()) {
                sql.append("AND u.user_name LIKE ? ");
                params.add("%" + userName + "%");
            }
            if (deptId != null) {
                sql.append("AND (u.dept_id = ? OR u.dept_id IN (SELECT t.dept_id FROM `hz-vue`.sys_dept t WHERE FIND_IN_SET(?, t.ancestors))) ");
                params.add(deptId);
                params.add(deptId);
            }

            sql.append("ORDER BY total_seconds DESC ");

            List<Map<String, Object>> results = jdbcTemplate.queryForList(sql.toString(), params.toArray());

            // 构建导出数据
            List<UserStatsExport> exportList = new ArrayList<>();
            for (Map<String, Object> row : results) {
                UserStatsExport export = new UserStatsExport();
                Long userId = ((Number) row.get("user_id")).longValue();
                export.setUserName((String) row.get("user_name"));
                export.setDeptName((String) row.get("dept_name"));
                export.setPhonenumber((String) row.get("phonenumber"));
                
                int totalSeconds = ((Number) row.get("total_seconds")).intValue();
                export.setTotalDuration(formatDuration(totalSeconds));
                export.setTotalQuestions(((Number) row.get("total_questions")).intValue());
                export.setCorrectAnswers(((Number) row.get("correct_answers")).intValue());
                export.setAccuracyRate(((Number) row.get("accuracy_rate")).intValue() + "%");
                
                Object lastStudyTime = row.get("last_study_time");
                export.setLastStudyTime(lastStudyTime != null ? lastStudyTime.toString() : "");
                
                exportList.add(export);
            }

            ExcelUtil<UserStatsExport> util = new ExcelUtil<>(UserStatsExport.class);
            util.exportExcel(response, exportList, "用户学习时长统计");

        } catch (Exception e) {
            logger.error("❌ 导出用户学习时长统计失败", e);
        }
    }

    /**
     * 格式化时长
     */
    private String formatDuration(int seconds) {
        if (seconds <= 0) return "0分钟";
        int hours = seconds / 3600;
        int minutes = (seconds % 3600) / 60;
        if (hours > 0) {
            return minutes > 0 ? hours + "小时" + minutes + "分钟" : hours + "小时";
        }
        return Math.max(1, minutes) + "分钟";
    }

    /**
     * 用户统计导出实体
     */
    public static class UserStatsExport {
        @com.ruoyi.common.annotation.Excel(name = "用户名")
        private String userName;
        
        @com.ruoyi.common.annotation.Excel(name = "部门")
        private String deptName;
        
        @com.ruoyi.common.annotation.Excel(name = "手机号")
        private String phonenumber;
        
        @com.ruoyi.common.annotation.Excel(name = "学习时长")
        private String totalDuration;
        
        @com.ruoyi.common.annotation.Excel(name = "答题总数")
        private Integer totalQuestions;
        
        @com.ruoyi.common.annotation.Excel(name = "正确数")
        private Integer correctAnswers;
        
        @com.ruoyi.common.annotation.Excel(name = "正确率")
        private String accuracyRate;
        
        @com.ruoyi.common.annotation.Excel(name = "最后学习时间")
        private String lastStudyTime;

        // Getters and Setters
        public String getUserName() { return userName; }
        public void setUserName(String userName) { this.userName = userName; }
        public String getDeptName() { return deptName; }
        public void setDeptName(String deptName) { this.deptName = deptName; }
        public String getPhonenumber() { return phonenumber; }
        public void setPhonenumber(String phonenumber) { this.phonenumber = phonenumber; }
        public String getTotalDuration() { return totalDuration; }
        public void setTotalDuration(String totalDuration) { this.totalDuration = totalDuration; }
        public Integer getTotalQuestions() { return totalQuestions; }
        public void setTotalQuestions(Integer totalQuestions) { this.totalQuestions = totalQuestions; }
        public Integer getCorrectAnswers() { return correctAnswers; }
        public void setCorrectAnswers(Integer correctAnswers) { this.correctAnswers = correctAnswers; }
        public String getAccuracyRate() { return accuracyRate; }
        public void setAccuracyRate(String accuracyRate) { this.accuracyRate = accuracyRate; }
        public String getLastStudyTime() { return lastStudyTime; }
        public void setLastStudyTime(String lastStudyTime) { this.lastStudyTime = lastStudyTime; }
    }
}
