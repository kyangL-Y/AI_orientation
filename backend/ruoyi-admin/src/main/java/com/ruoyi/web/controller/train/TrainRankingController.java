package com.ruoyi.web.controller.train;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.servlet.http.HttpServletResponse;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.enums.DataSourceType;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.system.service.ITrainRankingService;
import com.ruoyi.system.service.ITrainUserPointsService;
import com.ruoyi.common.utils.poi.ExcelUtil;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.exception.ServiceException;

/**
 * 培训排行榜Controller
 * 
 * @author ruoyi
 * @date 2024-01-01
 */
import com.ruoyi.system.domain.TrainAnswerAttempt;
import com.ruoyi.system.mapper.TrainAnswerAttemptMapper;
import com.ruoyi.framework.datasource.DynamicDataSourceContextHolder;
import java.text.SimpleDateFormat;

/**
 * 培训排行榜Controller
 * 
 * @author ruoyi
 * @date 2024-01-01
 */
@RestController
@RequestMapping("/train/ranking")
public class TrainRankingController extends BaseController
{
    @Autowired
    private ITrainRankingService trainRankingService;
    
    @Autowired
    private ITrainUserPointsService trainUserPointsService;
    
    @Autowired
    private TrainAnswerAttemptMapper attemptMapper;
    
    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    @Autowired
    private javax.sql.DataSource masterDataSource;
    
    @Autowired(required = false)
    @org.springframework.beans.factory.annotation.Qualifier("slaveDataSource")
    private javax.sql.DataSource slaveDataSource;

    private javax.sql.DataSource requireSlaveDataSource()
    {
        if (slaveDataSource != null)
        {
            return slaveDataSource;
        }
        throw new ServiceException("从库数据源未配置或已禁用（DB_SLAVE_ENABLED=false），无法查询排行榜统计数据");
    }

    /**
     * 获取个人排行榜（用户端）
     */
    @GetMapping("/personal")
    public AjaxResult getPersonalRanking(
            @RequestParam(value = "timeRange", defaultValue = "month") String timeRange,
            @RequestParam(value = "scope", defaultValue = "tenant") String scope,
            @RequestParam(value = "type", defaultValue = "personal") String type) {
        if ("course_quiz".equals(type)) {
            return getCourseQuizRanking(timeRange, scope);
        }
        List<Map<String, Object>> list = new ArrayList<>();
        try {
            logger.info("=== 开始查询个人排行榜, timeRange={}, scope={} ===", timeRange, scope);

            // 1. 获取当前登录用户信息
            Long currentUserId = com.ruoyi.common.utils.SecurityUtils.getUserId();
            com.ruoyi.common.core.domain.entity.SysUser currentUser = com.ruoyi.common.utils.SecurityUtils.getLoginUser().getUser();
            String tenantId = currentUser.getTenantId();
            Integer adminLevel = currentUser.getAdminLevel();
            boolean isPlatformAdmin = (adminLevel != null && adminLevel <= 5);
            Long userDeptId = currentUser.getDeptId();

            logger.info("📊 查询个人排行榜 - tenantId: {}, adminLevel: {}, isPlatformAdmin: {}",
                       tenantId, adminLevel, isPlatformAdmin);

            // 手动创建主库 JdbcTemplate（不受 @DataSource 注解影响）
            org.springframework.jdbc.core.JdbcTemplate masterJdbc = new org.springframework.jdbc.core.JdbcTemplate(masterDataSource);

            // 2. 根据Scope构建部门过滤条件
            StringBuilder scopeFilter = new StringBuilder();
            // 【修复】只有非平台管理员才过滤租户
            if (!isPlatformAdmin) {
                scopeFilter.append(" AND u.tenant_id = '").append(tenantId).append("'");
            }

            if ("company".equals(scope) || "department".equals(scope)) {
                // 查询当前用户的部门信息以获取ancestors
                Map<String, Object> myDept = masterJdbc.queryForMap("SELECT dept_id, ancestors FROM sys_dept WHERE dept_id = ?", userDeptId);
                String ancestors = (String) myDept.get("ancestors"); // e.g., "0,100,200"
                
                Long targetDeptId = null;
                if ("department".equals(scope)) {
                    targetDeptId = userDeptId;
                } else if ("company".equals(scope)) {
                    // 解析ancestors获取公司ID (Level 2)
                    if (ancestors != null && !ancestors.isEmpty()) {
                        String[] parts = ancestors.split(",");
                        if (parts.length >= 3) {
                            targetDeptId = Long.parseLong(parts[2]);
                        } else if (parts.length == 2) {
                            targetDeptId = userDeptId;
                        } else {
                            targetDeptId = userDeptId;
                        }
                    } else {
                        targetDeptId = userDeptId;
                    }
                }
                
                if (targetDeptId != null) {
                    scopeFilter.append(" AND (d.dept_id = ").append(targetDeptId)
                               .append(" OR FIND_IN_SET(").append(targetDeptId).append(", d.ancestors))");
                }
            }

            // 3. 从主库获取用户信息（包含部门和公司/上级部门）
            Map<Long, Map<String, Object>> userMap = new HashMap<>();
            String userSql = "SELECT u.user_id, u.user_name, u.avatar, d.dept_name, p.dept_name as company_name " +
                           "FROM sys_user u " +
                           "LEFT JOIN sys_dept d ON u.dept_id = d.dept_id " +
                           "LEFT JOIN sys_dept p ON d.parent_id = p.dept_id " +
                           "WHERE u.user_id > 2 AND u.del_flag = '0' AND u.status = '0'" + scopeFilter.toString();
            
            logger.info("用户查询SQL: {}", userSql);
            
            List<Map<String, Object>> users = masterJdbc.queryForList(userSql);
            logger.info("从主库查询到 {} 个用户", users.size());
            for (Map<String, Object> user : users) {
                Long userId = ((Number) user.get("user_id")).longValue();
                userMap.put(userId, user);
            }
            
            // 4. 从从库获取答题统计 (使用Mapper的统一逻辑)
            TrainAnswerAttempt query = new TrainAnswerAttempt();
            Map<String, Object> params = new HashMap<>();
            
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            params.put("endTime", sdf.format(new Date()));
            
            Calendar cal = Calendar.getInstance();
            cal.set(Calendar.HOUR_OF_DAY, 0);
            cal.set(Calendar.MINUTE, 0);
            cal.set(Calendar.SECOND, 0);
            
            boolean hasTimeCondition = true;
            if ("today".equals(timeRange)) {
                // cal is today 00:00
            } else if ("week".equals(timeRange)) {
                cal.add(Calendar.DAY_OF_YEAR, -7);
            } else if ("month".equals(timeRange)) {
                cal.add(Calendar.DAY_OF_YEAR, -30);
            } else {
                hasTimeCondition = false;
            }
            
            if (hasTimeCondition) {
                params.put("beginTime", sdf.format(cal.getTime()));
            }
            query.setParams(params);
            
            logger.info("调用Mapper查询排行榜数据, params: {}", params);
            List<TrainAnswerAttempt> stats = selectAttemptLeaderboardAnySource(query);
            logger.info("从Mapper查询到 {} 条答题统计", stats.size());

            // 4.5 查询用户真实积分
            Map<Long, Integer> pointsMap = new HashMap<>();
            if (!stats.isEmpty()) {
                StringBuilder userIdList = new StringBuilder();
                for (int i = 0; i < stats.size(); i++) {
                    if (i > 0) userIdList.append(",");
                    userIdList.append(stats.get(i).getUserId());
                }
                String pointsSql = "SELECT user_id, total_points FROM train_user_points WHERE user_id IN (" + userIdList + ")";
                List<Map<String, Object>> pointsList = masterJdbc.queryForList(pointsSql);
                for (Map<String, Object> p : pointsList) {
                    Object idObj = p.get("user_id");
                    Object pointsObj = p.get("total_points");
                    if (idObj != null) {
                        pointsMap.put(((Number) idObj).longValue(), pointsObj != null ? ((Number) pointsObj).intValue() : 0);
                    }
                }
            }

            // 5. 合并数据（先收集，再按积分排序）
            List<Map<String, Object>> tempList = new ArrayList<>();
            for (TrainAnswerAttempt stat : stats) {
                Long userId = stat.getUserId();
                Map<String, Object> user = userMap.get(userId);

                // 只显示在当前Scope下的用户
                if (user == null) {
                    continue;
                }

                Map<String, Object> row = new HashMap<>();
                row.put("userId", userId);
                row.put("nickName", user.get("user_name"));
                row.put("avatar", user.get("avatar"));
                row.put("deptName", user.get("dept_name"));
                row.put("companyName", user.get("company_name"));

                // 统计数据
                row.put("answerCount", stat.getQuestionCount()); // 答题数
                row.put("correctCount", stat.getCorrectCount()); // 正确数
                row.put("correctRate", stat.getAccuracy());      // 正确率

                // 使用真实积分
                Integer realPoints = pointsMap.get(userId);
                row.put("score", realPoints != null ? realPoints : 0);

                tempList.add(row);
            }

            // 按积分降序排序
            tempList.sort((a, b) -> {
                int scoreA = ((Number) a.get("score")).intValue();
                int scoreB = ((Number) b.get("score")).intValue();
                if (scoreA != scoreB) {
                    return Integer.compare(scoreB, scoreA);
                }
                int correctA = ((Number) a.get("correctCount")).intValue();
                int correctB = ((Number) b.get("correctCount")).intValue();
                return Integer.compare(correctB, correctA);
            });

            // 添加排名
            int rank = 0;
            for (Map<String, Object> row : tempList) {
                row.put("rank", ++rank);
                list.add(row);
            }
            logger.info("=== 个人排行榜查询完成，共 {} 条记录 ===", list.size());
        } catch (Exception e) {
            logger.error("查询个人排行榜失败", e);
        }
        return success(list);
    }

    @GetMapping("/courseQuiz")
    public AjaxResult getCourseQuizRanking(
            @RequestParam(value = "timeRange", defaultValue = "month") String timeRange,
            @RequestParam(value = "scope", defaultValue = "tenant") String scope) {
        List<Map<String, Object>> list = new ArrayList<>();
        try {
            logger.info("=== 开始查询结课测验排行榜, timeRange={}, scope={} ===", timeRange, scope);

            com.ruoyi.common.core.domain.entity.SysUser currentUser = com.ruoyi.common.utils.SecurityUtils.getLoginUser().getUser();
            String tenantId = currentUser.getTenantId();
            Integer adminLevel = currentUser.getAdminLevel();
            boolean isPlatformAdmin = (adminLevel != null && adminLevel <= 5);
            Long userDeptId = currentUser.getDeptId();

            logger.info("📊 查询结课测验排行榜 - tenantId: {}, adminLevel: {}, isPlatformAdmin: {}",
                       tenantId, adminLevel, isPlatformAdmin);

            org.springframework.jdbc.core.JdbcTemplate masterJdbc = new org.springframework.jdbc.core.JdbcTemplate(masterDataSource);
            org.springframework.jdbc.core.JdbcTemplate slaveJdbc = new org.springframework.jdbc.core.JdbcTemplate(requireSlaveDataSource());

            StringBuilder scopeFilter = new StringBuilder();
            // 【修复】只有非平台管理员才过滤租户
            if (!isPlatformAdmin) {
                scopeFilter.append(" AND u.tenant_id = '").append(tenantId).append("'");
            }
            if ("company".equals(scope) || "department".equals(scope)) {
                Map<String, Object> myDept = masterJdbc.queryForMap("SELECT dept_id, ancestors FROM sys_dept WHERE dept_id = ?", userDeptId);
                String ancestors = (String) myDept.get("ancestors");
                Long targetDeptId = null;
                if ("department".equals(scope)) {
                    targetDeptId = userDeptId;
                } else if (ancestors != null && !ancestors.isEmpty()) {
                    String[] parts = ancestors.split(",");
                    targetDeptId = parts.length >= 3 ? Long.parseLong(parts[2]) : userDeptId;
                } else {
                    targetDeptId = userDeptId;
                }
                if (targetDeptId != null) {
                    scopeFilter.append(" AND (d.dept_id = ").append(targetDeptId)
                        .append(" OR FIND_IN_SET(").append(targetDeptId).append(", d.ancestors))");
                }
            }

            Map<Long, Map<String, Object>> userMap = new HashMap<>();
            String userSql = "SELECT u.user_id, u.user_name, u.avatar, d.dept_name, p.dept_name as company_name " +
                "FROM sys_user u " +
                "LEFT JOIN sys_dept d ON u.dept_id = d.dept_id " +
                "LEFT JOIN sys_dept p ON d.parent_id = p.dept_id " +
                "WHERE u.user_id > 2 AND u.del_flag = '0' AND u.status = '0'" + scopeFilter;
            List<Map<String, Object>> users = masterJdbc.queryForList(userSql);
            for (Map<String, Object> user : users) {
                userMap.put(((Number) user.get("user_id")).longValue(), user);
            }

            StringBuilder sql = new StringBuilder();
            sql.append("SELECT tqa.user_id, COUNT(*) AS attemptCount, ")
                .append("SUM(COALESCE(tqa.question_count, 0)) AS questionCount, ")
                .append("SUM(COALESCE(tqa.correct_count, 0)) AS correctCount, ")
                .append("ROUND(SUM(COALESCE(tqa.correct_count, 0)) * 100.0 / NULLIF(SUM(COALESCE(tqa.question_count, 0)), 0), 2) AS accuracyRate, ")
                .append("ROUND(AVG(COALESCE(tqa.score, 0)), 2) AS avgScore ")
                .append("FROM train_quiz_attempt tqa ")
                .append("INNER JOIN ( ")
                .append("SELECT user_id, COALESCE(NULLIF(course_quiz_key, ''), exam_name) AS dedup_key, MIN(attempt_id) AS first_attempt_id ")
                .append("FROM train_quiz_attempt WHERE user_id > 2 ")
                .append("AND COALESCE(NULLIF(attempt_scene, ''), CASE ")
                .append("WHEN attempt_type = 'exam' THEN 'exam' ")
                .append("WHEN exam_name LIKE '%结课测验%' THEN 'course_quiz' ")
                .append("ELSE 'practice' END) = 'course_quiz' ");

            List<Object> args = new ArrayList<>();
            appendTimeRangeFilter(sql, args, "COALESCE(submitted_at, create_time)", timeRange);
            sql.append("GROUP BY user_id, COALESCE(NULLIF(course_quiz_key, ''), exam_name) ")
                .append(") dedup ON tqa.attempt_id = dedup.first_attempt_id ")
                .append("GROUP BY tqa.user_id ORDER BY avgScore DESC, accuracyRate DESC, attemptCount DESC LIMIT 100");

            List<Map<String, Object>> stats = args.isEmpty()
                ? slaveJdbc.queryForList(sql.toString())
                : slaveJdbc.queryForList(sql.toString(), args.toArray());

            int rank = 0;
            for (Map<String, Object> stat : stats) {
                Long userId = ((Number) stat.get("user_id")).longValue();
                Map<String, Object> user = userMap.get(userId);
                if (user == null) {
                    continue;
                }
                Map<String, Object> row = new HashMap<>();
                row.put("rank", ++rank);
                row.put("userId", userId);
                row.put("nickName", user.get("user_name"));
                row.put("avatar", user.get("avatar"));
                row.put("deptName", user.get("dept_name"));
                row.put("companyName", user.get("company_name"));
                row.put("answerCount", stat.get("attemptCount"));
                row.put("correctCount", stat.get("correctCount"));
                row.put("correctRate", stat.get("accuracyRate"));
                row.put("score", stat.get("avgScore"));
                list.add(row);
            }
        } catch (Exception e) {
            logger.error("查询结课测验排行榜失败", e);
        }
        return success(list);
    }

    /**
     * 获取部门排行榜（用户端）
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/department")
    public AjaxResult getDepartmentRanking(
            @RequestParam(value = "timeRange", defaultValue = "month") String timeRange,
            @RequestParam(value = "scope", defaultValue = "tenant") String scope,
            @RequestParam(value = "type", defaultValue = "personal") String type) {
        List<Map<String, Object>> list = new ArrayList<>();
        try {
            logger.info("=== 开始查询部门排行榜, timeRange={}, scope={}, type={} ===", timeRange, scope, type);
            
            // 1. 构建查询条件
            TrainAnswerAttempt query = new TrainAnswerAttempt();
            Map<String, Object> params = new HashMap<>();
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            params.put("endTime", sdf.format(new Date()));
            
            Calendar cal = Calendar.getInstance();
            cal.set(Calendar.HOUR_OF_DAY, 0);
            cal.set(Calendar.MINUTE, 0);
            cal.set(Calendar.SECOND, 0);
            
            boolean hasTimeCondition = true;
            if ("today".equals(timeRange)) {
                // today 00:00
            } else if ("week".equals(timeRange)) {
                cal.add(Calendar.DAY_OF_YEAR, -7);
            } else if ("month".equals(timeRange)) {
                cal.add(Calendar.DAY_OF_YEAR, -30);
            } else {
                hasTimeCondition = false;
            }
            
            if (hasTimeCondition) {
                params.put("beginTime", sdf.format(cal.getTime()));
            }
            query.setParams(params);
            
            // 2. 从从库获取所有用户的统计
            List<TrainAnswerAttempt> stats;
            if ("course_quiz".equals(type)) {
                stats = selectCourseQuizLeaderboard(query);
            } else {
                stats = selectAttemptLeaderboardAnySource(query);
            }
            
            // 3. 从主库获取部门和用户映射
            org.springframework.jdbc.core.JdbcTemplate masterJdbc = new org.springframework.jdbc.core.JdbcTemplate(masterDataSource);
            com.ruoyi.common.core.domain.entity.SysUser currentUser = com.ruoyi.common.utils.SecurityUtils.getLoginUser().getUser();
            String tenantId = currentUser.getTenantId();
            Integer adminLevel = currentUser.getAdminLevel();
            boolean isPlatformAdmin = (adminLevel != null && adminLevel <= 5);
            Long rankingRootDeptId = resolveRankingRootDeptId(masterJdbc, currentUser.getDeptId(), scope);

            logger.info("📊 查询部门排行榜 - tenantId: {}, adminLevel: {}, isPlatformAdmin: {}",
                       tenantId, adminLevel, isPlatformAdmin);

            StringBuilder deptSql = new StringBuilder();
            List<Object> deptArgs = new ArrayList<>();
            deptSql.append("SELECT d.dept_id, d.dept_name, COUNT(u.user_id) as memberCount ")
                .append("FROM sys_dept d LEFT JOIN sys_user u ON d.dept_id = u.dept_id AND u.del_flag = '0'");
            // 【修复】只有非平台管理员才过滤租户
            if (!isPlatformAdmin) {
                deptSql.append(" AND u.tenant_id = ? ");
            }
            deptSql.append(" WHERE d.del_flag = '0'");
            if (!isPlatformAdmin) {
                deptSql.append(" AND d.tenant_id = ? ");
                deptArgs.add(tenantId);
                deptArgs.add(tenantId);
            }
            if (rankingRootDeptId != null) {
                deptSql.append("AND (d.dept_id = ? OR FIND_IN_SET(?, d.ancestors)) ");
                deptArgs.add(rankingRootDeptId);
                deptArgs.add(rankingRootDeptId);
            }
            deptSql.append("GROUP BY d.dept_id, d.dept_name");
            List<Map<String, Object>> depts = masterJdbc.queryForList(deptSql.toString(), deptArgs.toArray());

            StringBuilder userDeptSql = new StringBuilder();
            List<Object> userDeptArgs = new ArrayList<>();
            userDeptSql.append("SELECT u.user_id, u.dept_id FROM sys_user u ")
                .append("LEFT JOIN sys_dept d ON u.dept_id = d.dept_id ")
                .append("WHERE u.del_flag = '0'");
            // 【修复】只有非平台管理员才过滤租户
            if (!isPlatformAdmin) {
                userDeptSql.append(" AND u.tenant_id = ? ");
                userDeptArgs.add(tenantId);
            }
            userDeptSql.append(" AND u.dept_id IS NOT NULL ");
            if (rankingRootDeptId != null) {
                userDeptSql.append("AND (d.dept_id = ? OR FIND_IN_SET(?, d.ancestors)) ");
                userDeptArgs.add(rankingRootDeptId);
                userDeptArgs.add(rankingRootDeptId);
            }
            List<Map<String, Object>> userDepts = masterJdbc.queryForList(userDeptSql.toString(), userDeptArgs.toArray());
            Map<Long, Long> userToDept = new HashMap<>();
            for (Map<String, Object> ud : userDepts) {
                if (ud.get("user_id") != null && ud.get("dept_id") != null) {
                    userToDept.put(((Number) ud.get("user_id")).longValue(), ((Number) ud.get("dept_id")).longValue());
                }
            }

            // 获取所有用户的真实积分
            StringBuilder pointsSql = new StringBuilder();
            List<Object> pointsArgs = new ArrayList<>();
            pointsSql.append("SELECT p.user_id, p.total_points FROM train_user_points p ")
                .append("INNER JOIN sys_user u ON p.user_id = u.user_id WHERE u.del_flag = '0'");
            // 【修复】只有非平台管理员才过滤租户
            if (!isPlatformAdmin) {
                pointsSql.append(" AND u.tenant_id = ?");
                pointsArgs.add(tenantId);
            }
            List<Map<String, Object>> pointsList = masterJdbc.queryForList(pointsSql.toString(), pointsArgs.toArray());
            Map<Long, Integer> userPointsMap = new HashMap<>();
            for (Map<String, Object> p : pointsList) {
                Object idObj = p.get("user_id");
                Object pointsObj = p.get("total_points");
                if (idObj != null) {
                    userPointsMap.put(((Number) idObj).longValue(), pointsObj != null ? ((Number) pointsObj).intValue() : 0);
                }
            }

            // 4. 按部门聚合
            Map<Long, double[]> deptStats = new HashMap<>(); // [totalQuestions, totalCorrect, scoreSum, scoreCount]
            for (TrainAnswerAttempt stat : stats) {
                Long userId = stat.getUserId();
                Long deptId = userToDept.get(userId);
                if (deptId == null) continue;

                double[] arr = deptStats.computeIfAbsent(deptId, k -> new double[]{0, 0, 0, 0});
                arr[0] += stat.getQuestionCount();
                arr[1] += stat.getCorrectCount();
                if ("course_quiz".equals(type)) {
                    arr[2] += stat.getScore() != null ? stat.getScore() : 0;
                    arr[3] += 1;
                } else {
                    arr[2] += userPointsMap.getOrDefault(userId, 0);
                }
            }

            // 5. 构建结果
            for (Map<String, Object> dept : depts) {
                Long deptId = ((Number) dept.get("dept_id")).longValue();
                double[] arr = deptStats.getOrDefault(deptId, new double[]{0, 0, 0, 0});
                if (arr[0] == 0) continue; // 跳过无答题记录的部门

                Map<String, Object> row = new HashMap<>();
                row.put("deptId", deptId);
                row.put("deptName", dept.get("dept_name"));
                row.put("memberCount", dept.get("memberCount"));
                row.put("totalAnswers", Math.round(arr[0]));
                row.put("totalCorrect", Math.round(arr[1]));
                double rate = arr[0] > 0 ? Math.round(arr[1] * 1000.0 / arr[0]) / 10.0 : 0;
                row.put("avgCorrectRate", rate);

                if ("course_quiz".equals(type)) {
                    double scoreCount = Math.max(1, arr[3]);
                    row.put("avgScore", Math.round(arr[2] * 10.0 / scoreCount) / 10.0);
                } else {
                    double totalScore = arr[2];
                    int memberCount = Math.max(1, ((Number) dept.get("memberCount")).intValue());
                    row.put("avgScore", Math.round(totalScore / memberCount));
                }

                list.add(row);
            }
            
            // 6. 按平均分排序
            list.sort((a, b) -> {
                double scoreA = ((Number) a.get("avgScore")).doubleValue();
                double scoreB = ((Number) b.get("avgScore")).doubleValue();
                return Double.compare(scoreB, scoreA);
            });
            logger.info("=== 部门排行榜查询完成，共 {} 条记录 ===", list.size());
            
        } catch (Exception e) {
            logger.error("查询部门排行榜失败", e);
        }
        return success(list);
    }

    /**
     * 获取我的排名（用户端）
     */
    @GetMapping("/my")
    public AjaxResult getMyRanking(
            @RequestParam(value = "timeRange", defaultValue = "month") String timeRange,
            @RequestParam(value = "type", defaultValue = "personal") String type) {
        if ("course_quiz".equals(type)) {
            return getMyCourseQuizRanking(timeRange);
        }
        Long userId = getUserId();
        if (userId == null || userId <= 0) {
            logger.warn("获取我的排名失败：用户未登录");
            return success(null);
        }
        
        try {
            logger.info("=== 开始查询我的排名, userId={}, timeRange={} ===", userId, timeRange);
            
            // 1. 构建查询条件
            TrainAnswerAttempt query = new TrainAnswerAttempt();
            Map<String, Object> params = new HashMap<>();
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            params.put("endTime", sdf.format(new Date()));
            
            Calendar cal = Calendar.getInstance();
            cal.set(Calendar.HOUR_OF_DAY, 0);
            cal.set(Calendar.MINUTE, 0);
            cal.set(Calendar.SECOND, 0);
            
            boolean hasTimeCondition = true;
            if ("today".equals(timeRange)) {
                // today 00:00
            } else if ("week".equals(timeRange)) {
                cal.add(Calendar.DAY_OF_YEAR, -7);
            } else if ("month".equals(timeRange)) {
                cal.add(Calendar.DAY_OF_YEAR, -30);
            } else {
                hasTimeCondition = false;
            }
            
            if (hasTimeCondition) {
                params.put("beginTime", sdf.format(cal.getTime()));
            }
            query.setParams(params);
            
            // 2. 获取全量排行榜
            List<TrainAnswerAttempt> stats = selectAttemptLeaderboardAnySource(query);
            
            // 3. 查找我的位置
            int rank = 0;
            TrainAnswerAttempt myStat = null;
            for (int i = 0; i < stats.size(); i++) {
                if (stats.get(i).getUserId().equals(userId)) {
                    rank = i + 1;
                    myStat = stats.get(i);
                    break;
                }
            }
            
            // 4. 从主库获取用户信息
            org.springframework.jdbc.core.JdbcTemplate masterJdbc = new org.springframework.jdbc.core.JdbcTemplate(masterDataSource);
            String userSql = "SELECT u.user_id, u.user_name, u.avatar, d.dept_name " +
                           "FROM sys_user u LEFT JOIN sys_dept d ON u.dept_id = d.dept_id " +
                           "WHERE u.user_id = ?";
            Map<String, Object> user = masterJdbc.queryForMap(userSql, userId);
            
            Map<String, Object> result = new HashMap<>();
            result.put("userId", userId);
            result.put("nickName", user.get("user_name"));
            result.put("avatar", user.get("avatar"));
            result.put("deptName", user.get("dept_name"));
            
            if (myStat != null) {
                result.put("answerCount", myStat.getQuestionCount());
                result.put("correctCount", myStat.getCorrectCount());
                // 使用真实积分
                int realPoints = trainUserPointsService.getUserTotalPoints(userId);
                result.put("score", realPoints);
                result.put("rank", rank);
            } else {
                result.put("answerCount", 0);
                result.put("correctCount", 0);
                result.put("score", 0);
                result.put("rank", 0);
            }

            // 查询总积分（与score相同）
            try {
                result.put("totalPoints", trainUserPointsService.getUserTotalPoints(userId));
            } catch (Exception e) {
                result.put("totalPoints", 0);
            }
            
            logger.info("=== 我的排名查询完成: rank={}, score={} ===", rank, result.get("score"));
            return success(result);
        } catch (Exception e) {
            logger.error("查询我的排名失败", e);
            return success(null);
        }
    }

    private AjaxResult getMyCourseQuizRanking(String timeRange) {
        Long userId = getUserId();
        if (userId == null || userId <= 0) {
            return success(null);
        }
        try {
            AjaxResult rankingResult = getCourseQuizRanking(timeRange, "tenant");
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> rankingList = (List<Map<String, Object>>) rankingResult.get(AjaxResult.DATA_TAG);
            if (rankingList == null) {
                return success(null);
            }
            for (Map<String, Object> row : rankingList) {
                Object rowUserId = row.get("userId");
                if (rowUserId != null && userId.equals(((Number) rowUserId).longValue())) {
                    return success(row);
                }
            }
        } catch (Exception e) {
            logger.error("查询我的结课测验排名失败", e);
        }
        return success(null);
    }

    private Long resolveRankingRootDeptId(org.springframework.jdbc.core.JdbcTemplate masterJdbc, Long userDeptId, String scope) {
        if (userDeptId == null) {
            return null;
        }
        if ("department".equals(scope)) {
            return userDeptId;
        }
        if (!"company".equals(scope)) {
            return null;
        }
        try {
            Map<String, Object> myDept = masterJdbc.queryForMap("SELECT dept_id, ancestors FROM sys_dept WHERE dept_id = ?", userDeptId);
            Object ancestorsValue = myDept.get("ancestors");
            String ancestors = ancestorsValue != null ? String.valueOf(ancestorsValue) : "";
            if (!ancestors.isEmpty()) {
                String[] parts = ancestors.split(",");
                if (parts.length >= 3) {
                    return Long.parseLong(parts[2]);
                }
            }
        } catch (Exception e) {
            logger.warn("解析部门榜公司范围失败 deptId={}", userDeptId, e);
        }
        return userDeptId;
    }

    private void appendTimeRangeFilter(StringBuilder sql, List<Object> args, String columnExpr, String timeRange) {
        if ("all".equals(timeRange)) {
            return;
        }
        Calendar cal = Calendar.getInstance();
        cal.set(Calendar.HOUR_OF_DAY, 0);
        cal.set(Calendar.MINUTE, 0);
        cal.set(Calendar.SECOND, 0);
        cal.set(Calendar.MILLISECOND, 0);
        if ("week".equals(timeRange)) {
            cal.add(Calendar.DAY_OF_YEAR, -7);
        } else if ("month".equals(timeRange)) {
            cal.add(Calendar.DAY_OF_YEAR, -30);
        } else if (!"today".equals(timeRange)) {
            return;
        }
        sql.append("AND ").append(columnExpr).append(" >= ? ");
        args.add(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(cal.getTime()));
    }
    
    private String getTimeCondition(String timeRange, String field) {
        switch (timeRange) {
            case "week":
                return "AND " + field + " >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
            case "month":
                return "AND " + field + " >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)";
            case "quarter":
                return "AND " + field + " >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)";
            default:
                return "";
        }
    }

    private List<TrainAnswerAttempt> selectAttemptLeaderboardAnySource(TrainAnswerAttempt query) {
        List<TrainAnswerAttempt> stats = selectAttemptLeaderboardByDataSource(query, DataSourceType.SLAVE, false);
        if (stats != null && !stats.isEmpty()) {
            return stats;
        }

        stats = selectAttemptLeaderboardByDataSource(query, DataSourceType.MASTER, false);
        if (stats != null && !stats.isEmpty()) {
            return stats;
        }

        stats = selectAttemptLeaderboardByDataSource(query, DataSourceType.SLAVE, true);
        if (stats != null && !stats.isEmpty()) {
            return stats;
        }

        stats = selectAttemptLeaderboardByDataSource(query, DataSourceType.MASTER, true);
        if (stats != null && !stats.isEmpty()) {
            return stats;
        }

        return new ArrayList<>();
    }

    private List<TrainAnswerAttempt> selectCourseQuizLeaderboard(TrainAnswerAttempt query) {
        List<TrainAnswerAttempt> list = new ArrayList<>();
        try {
            org.springframework.jdbc.core.JdbcTemplate slaveJdbc = new org.springframework.jdbc.core.JdbcTemplate(requireSlaveDataSource());
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT tqa.user_id AS userId, SUM(COALESCE(tqa.question_count, 0)) AS questionCount, ")
                .append("SUM(COALESCE(tqa.correct_count, 0)) AS correctCount, ")
                .append("ROUND(SUM(COALESCE(tqa.correct_count, 0)) * 1.0 / NULLIF(SUM(COALESCE(tqa.question_count, 0)), 0), 4) AS accuracy, ")
                .append("ROUND(AVG(COALESCE(tqa.score, 0)), 2) AS score ")
                .append("FROM train_quiz_attempt tqa ")
                .append("INNER JOIN ( ")
                .append("SELECT user_id, COALESCE(NULLIF(course_quiz_key, ''), exam_name) AS dedup_key, MIN(attempt_id) AS first_attempt_id ")
                .append("FROM train_quiz_attempt ")
                .append("WHERE user_id > 2 ")
                .append("AND COALESCE(NULLIF(attempt_scene, ''), CASE ")
                .append("WHEN attempt_type = 'exam' THEN 'exam' ")
                .append("WHEN exam_name LIKE '%结课测验%' THEN 'course_quiz' ")
                .append("ELSE 'practice' END) = 'course_quiz' ");
            List<Object> args = new ArrayList<>();
            Map<String, Object> params = query != null ? query.getParams() : null;
            Object beginTime = params != null ? params.get("beginTime") : null;
            Object endTime = params != null ? params.get("endTime") : null;
            if (beginTime != null && String.valueOf(beginTime).trim().length() > 0) {
                sql.append("AND COALESCE(submitted_at, create_time) >= ? ");
                args.add(beginTime);
            }
            if (endTime != null && String.valueOf(endTime).trim().length() > 0) {
                sql.append("AND COALESCE(submitted_at, create_time) <= ? ");
                args.add(endTime);
            }
            sql.append("GROUP BY user_id, COALESCE(NULLIF(course_quiz_key, ''), exam_name) ")
                .append(") dedup ON tqa.attempt_id = dedup.first_attempt_id ")
                .append("GROUP BY tqa.user_id ORDER BY score DESC, accuracy DESC, questionCount DESC");

            List<Map<String, Object>> rows = args.isEmpty()
                ? slaveJdbc.queryForList(sql.toString())
                : slaveJdbc.queryForList(sql.toString(), args.toArray());
            for (Map<String, Object> row : rows) {
                TrainAnswerAttempt stat = new TrainAnswerAttempt();
                stat.setUserId(row.get("userId") != null ? ((Number) row.get("userId")).longValue() : null);
                stat.setQuestionCount(row.get("questionCount") != null ? ((Number) row.get("questionCount")).intValue() : 0);
                stat.setCorrectCount(row.get("correctCount") != null ? ((Number) row.get("correctCount")).intValue() : 0);
                stat.setAccuracy(row.get("accuracy") != null ? ((Number) row.get("accuracy")).doubleValue() : 0.0);
                stat.setScore(row.get("score") != null ? ((Number) row.get("score")).doubleValue() : 0.0);
                list.add(stat);
            }
        } catch (Exception e) {
            logger.error("查询结课测验排行榜失败", e);
        }
        return list;
    }

    private List<TrainAnswerAttempt> selectAttemptLeaderboardByDataSource(TrainAnswerAttempt query, DataSourceType dataSourceType, boolean legacy) {
        DynamicDataSourceContextHolder.setDataSourceType(dataSourceType.name());
        try {
            if (legacy) {
                return attemptMapper.selectAttemptLeaderboardLegacy(query);
            }
            return attemptMapper.selectAttemptLeaderboard(query);
        } catch (Exception e) {
            logger.error("查询排行榜失败 dataSource={}, legacy={}", dataSourceType, legacy, e);
            return new ArrayList<>();
        } finally {
            DynamicDataSourceContextHolder.clearDataSourceType();
        }
    }

    /**
     * 查询总排行榜（显示所有用户，包括未答题的）
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/total")
    public TableDataInfo getTotalRanking(TrainAnswerAttempt query)
    {
        List<Map<String, Object>> list = new ArrayList<>();
        
        try {
            logger.info("=== 开始查询排行榜数据 ===");
            
            // 先查主库获取用户列表
            String userSql = "SELECT user_id, user_name FROM sys_user WHERE user_id > 2 AND del_flag = '0' ORDER BY user_id LIMIT 100";
            List<Map<String, Object>> users = getUsersFromMaster();
            logger.info("从主库查询到 {} 个用户", users.size());
            
            // 再查从库获取答题统计
            Map<Long, Map<String, Object>> statsMap = getAnswerStatsFromSlave();
            logger.info("从库统计数据Map大小: {}", statsMap.size());
            
            // 合并数据
            for (Map<String, Object> user : users) {
                Map<String, Object> row = new HashMap<>();
                Long userId = ((Number) user.get("user_id")).longValue();
                
                row.put("userId", userId);
                row.put("userName", user.get("user_name"));
                
                Map<String, Object> stats = statsMap.get(userId);
                if (stats != null) {
                    row.put("totalQuestions", stats.get("totalQuestions"));
                    row.put("correctAnswers", stats.get("correctAnswers"));
                    row.put("accuracyRate", stats.get("accuracyRate"));
                    row.put("totalTimeSpent", stats.get("totalTimeSpent"));
                    row.put("avgTimePerQuestion", stats.get("avgTimePerQuestion"));
                    logger.debug("用户 {} ({}) 有统计数据: 题数={}, 正确率={}%", 
                        userId, user.get("user_name"), stats.get("totalQuestions"), stats.get("accuracyRate"));
                } else {
                    // 未答题的显示0
                    row.put("totalQuestions", 0);
                    row.put("correctAnswers", 0);
                    row.put("accuracyRate", 0);
                    row.put("totalTimeSpent", 0);
                    row.put("avgTimePerQuestion", 0);
                    logger.debug("用户 {} ({}) 无统计数据,设置为0", userId, user.get("user_name"));
                }
                
                list.add(row);
            }
            
            // 按正确率和答题数排序
            list.sort((a, b) -> {
                double rateA = ((Number) a.get("accuracyRate")).doubleValue();
                double rateB = ((Number) b.get("accuracyRate")).doubleValue();
                if (rateA != rateB) {
                    return Double.compare(rateB, rateA);
                }
                int qA = ((Number) a.get("totalQuestions")).intValue();
                int qB = ((Number) b.get("totalQuestions")).intValue();
                return Integer.compare(qB, qA);
            });

            list = filterRankingMapByUserName(list, query != null ? query.getUserName() : null);
            
            logger.info("=== 排行榜数据查询完成,共 {} 条记录 ===", list.size());
            
        } catch (Exception e) {
            logger.error("查询总排行榜失败", e);
        }
        
        return getDataTable(list);
    }
    
    /**
     * 从主库获取用户列表
     */
    public List<Map<String, Object>> getUsersFromMaster() {
        String sql = "SELECT user_id, user_name FROM sys_user WHERE user_id > 2 AND del_flag = '0' ORDER BY user_id LIMIT 100";
        org.springframework.jdbc.core.JdbcTemplate masterJdbc = new org.springframework.jdbc.core.JdbcTemplate(masterDataSource);
        return masterJdbc.queryForList(sql);
    }
    
    /**
     * 从从库获取答题统计
     */
    public Map<Long, Map<String, Object>> getAnswerStatsFromSlave() {
        Map<Long, Map<String, Object>> statsMap = new HashMap<>();
        
        try {
            String sql = "SELECT " +
                        "user_id, " +
                        "COUNT(*) as totalQuestions, " +
                        "SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correctAnswers, " +
                        "ROUND(SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as accuracyRate " +
                        "FROM train_answer_attempt " +
                        "GROUP BY user_id";
            
            org.springframework.jdbc.core.JdbcTemplate slaveJdbc = new org.springframework.jdbc.core.JdbcTemplate(requireSlaveDataSource());
            List<Map<String, Object>> stats = slaveJdbc.queryForList(sql);
            
            logger.info("从库查询到 {} 条答题统计记录", stats.size());
            
            for (Map<String, Object> stat : stats) {
                Long userId = ((Number) stat.get("user_id")).longValue();
                logger.info("用户 {} 统计数据: {}", userId, stat);
                statsMap.put(userId, stat);
            }
        } catch (Exception e) {
            logger.error("查询答题统计失败", e);
        }
        
        return statsMap;
    }

    /**
     * 查询考试排行榜（暂时返回空数据）
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/exam")
    public TableDataInfo getExamRanking(TrainAnswerAttempt query)
    {
        List<TrainAnswerAttempt> list = new ArrayList<>();
        try {
            org.springframework.jdbc.core.JdbcTemplate slaveJdbc = new org.springframework.jdbc.core.JdbcTemplate(requireSlaveDataSource());

            StringBuilder sql = new StringBuilder();
            List<Object> args = new ArrayList<>();
            sql.append("SELECT ")
                .append("user_id AS userId, ")
                .append("SUM(COALESCE(question_count, 0)) AS questionCount, ")
                .append("SUM(COALESCE(correct_count, 0)) AS correctCount, ")
                .append("CASE WHEN SUM(COALESCE(question_count, 0)) = 0 THEN 0 ")
                .append("ELSE CAST(SUM(COALESCE(correct_count, 0)) AS DECIMAL(10,4)) / SUM(COALESCE(question_count, 0)) END AS accuracy, ")
                .append("SUM(COALESCE(score, 0)) AS score ")
                .append("FROM train_quiz_attempt ")
                .append("WHERE user_id > 2 AND attempt_type = 'exam' ");

            Map<String, Object> params = query != null ? query.getParams() : null;
            Object beginTime = params != null ? params.get("beginTime") : null;
            Object endTime = params != null ? params.get("endTime") : null;
            if (beginTime != null && String.valueOf(beginTime).trim().length() > 0) {
                sql.append("AND COALESCE(submitted_at, create_time) >= ? ");
                args.add(beginTime);
            }
            if (endTime != null && String.valueOf(endTime).trim().length() > 0) {
                sql.append("AND COALESCE(submitted_at, create_time) <= ? ");
                args.add(endTime);
            }

            sql.append("GROUP BY user_id ")
                .append("ORDER BY correctCount DESC, accuracy DESC ")
                .append("LIMIT 100");

            List<Map<String, Object>> rows = args.isEmpty()
                ? slaveJdbc.queryForList(sql.toString())
                : slaveJdbc.queryForList(sql.toString(), args.toArray());

            for (Map<String, Object> row : rows) {
                TrainAnswerAttempt stat = new TrainAnswerAttempt();
                Object userIdObj = row.get("userId");
                if (userIdObj == null) {
                    continue;
                }
                Long userId = ((Number) userIdObj).longValue();
                stat.setUserId(userId);
                stat.setQuestionCount(row.get("questionCount") != null ? ((Number) row.get("questionCount")).intValue() : 0);
                stat.setCorrectCount(row.get("correctCount") != null ? ((Number) row.get("correctCount")).intValue() : 0);
                stat.setAccuracy(row.get("accuracy") != null ? ((Number) row.get("accuracy")).doubleValue() : 0.0);
                stat.setScore(row.get("score") != null ? ((Number) row.get("score")).doubleValue() : 0.0);
                list.add(stat);
            }

            fillUserInfoFromMaster(list);
            list = filterLeaderboardByUserName(list, query != null ? query.getUserName() : null);
        } catch (Exception e) {
            logger.error("查询考试排行榜失败", e);
        }

        return getDataTable(list);
    }

    /**
     * 查询练习排行榜（同总排行榜）
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/practice")
    public TableDataInfo getPracticeRanking(TrainAnswerAttempt query)
    {
        List<TrainAnswerAttempt> list = new ArrayList<>();
        try {
            TrainAnswerAttempt q = query != null ? query : new TrainAnswerAttempt();
            List<TrainAnswerAttempt> stats = selectAttemptLeaderboardAnySource(q);
            if (stats != null) {
                list = stats;
            }
            fillUserInfoFromMaster(list);
            list = filterLeaderboardByUserName(list, query != null ? query.getUserName() : null);
        } catch (Exception e) {
            logger.error("查询练习排行榜失败", e);
        }
        return getDataTable(list);
    }

    private List<TrainAnswerAttempt> filterLeaderboardByUserName(List<TrainAnswerAttempt> leaderboard, String keyword) {
        if (leaderboard == null || leaderboard.isEmpty() || keyword == null) {
            return leaderboard;
        }

        String normalizedKeyword = keyword.trim().toLowerCase();
        if (normalizedKeyword.isEmpty()) {
            return leaderboard;
        }

        return leaderboard.stream()
            .filter(item -> containsKeyword(item.getUserName(), normalizedKeyword)
                || containsKeyword(item.getNickName(), normalizedKeyword))
            .collect(java.util.stream.Collectors.toList());
    }

    private List<Map<String, Object>> filterRankingMapByUserName(List<Map<String, Object>> rankingList, String keyword) {
        if (rankingList == null || rankingList.isEmpty() || keyword == null) {
            return rankingList;
        }

        String normalizedKeyword = keyword.trim().toLowerCase();
        if (normalizedKeyword.isEmpty()) {
            return rankingList;
        }

        return rankingList.stream()
            .filter(item -> containsKeyword(asString(item.get("userName")), normalizedKeyword)
                || containsKeyword(asString(item.get("nickName")), normalizedKeyword))
            .collect(java.util.stream.Collectors.toList());
    }

    private String asString(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private boolean containsKeyword(String source, String keyword) {
        return source != null && source.toLowerCase().contains(keyword);
    }

    /**
     * 获取带排名的排行榜（跨库查询）
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/withPosition/{type}")
    public AjaxResult getRankingWithPosition(@PathVariable("type") String type)
    {
        List<Map<String, Object>> list = new ArrayList<>();
        
        try {
            // 从主库获取用户信息
            Map<Long, Map<String, Object>> userMap = new HashMap<>();
            List<Map<String, Object>> users = getUsersFromMaster();
            for (Map<String, Object> user : users) {
                Long userId = ((Number) user.get("user_id")).longValue();
                userMap.put(userId, user);
            }
            
            // 从从库获取统计数据
            List<Map<String, Object>> stats = getStatsFromSlaveByType(type);
            
            // 合并数据并添加排名
            int rank = 0;
            for (Map<String, Object> stat : stats) {
                Long userId = ((Number) stat.get("user_id")).longValue();
                Map<String, Object> user = userMap.get(userId);
                
                Map<String, Object> row = new HashMap<>();
                row.put("rank_position", ++rank);
                row.put("user_id", userId);
                row.put("user_name", user != null ? user.get("user_name") : "未知用户");
                row.put("total_questions", stat.get("total_questions"));
                row.put("correct_answers", stat.get("correct_answers"));
                row.put("accuracy_rate", stat.get("accuracy_rate"));
                
                if ("total".equals(type)) {
                    row.put("total_time_spent", stat.get("total_time_spent"));
                    row.put("avg_time_per_question", stat.get("avg_time_per_question"));
                }
                
                list.add(row);
            }
        } catch (Exception e) {
            logger.error("查询排行榜失败", e);
        }
        
        return success(list);
    }
    
    /**
     * 从从库获取统计数据（按类型）
     */
    private List<Map<String, Object>> getStatsFromSlaveByType(String type) {
        String sql;
        if ("total".equals(type)) {
            sql = "SELECT user_id, total_questions, correct_answers, accuracy_rate, " +
                  "total_time_spent, avg_time_per_question " +
                  "FROM user_statistics WHERE stat_type = 'total' AND total_questions > 0 " +
                  "ORDER BY accuracy_rate DESC, total_questions DESC LIMIT 100";
        } else if ("exam".equals(type)) {
            sql = "SELECT user_id, total_questions, correct_answers, accuracy_rate " +
                  "FROM user_statistics WHERE stat_type = 'exam' AND total_questions > 0 " +
                  "ORDER BY accuracy_rate DESC, total_questions DESC LIMIT 100";
        } else if ("course_quiz".equals(type)) {
            sql = "SELECT user_id, total_questions, correct_answers, accuracy_rate " +
                  "FROM user_statistics WHERE stat_type = 'course_quiz' AND total_questions > 0 " +
                  "ORDER BY accuracy_rate DESC, total_questions DESC LIMIT 100";
        } else {
            sql = "SELECT user_id, total_questions, correct_answers, accuracy_rate " +
                  "FROM user_statistics WHERE stat_type = 'practice' AND total_questions > 0 " +
                  "ORDER BY accuracy_rate DESC, total_questions DESC LIMIT 100";
        }
        
        try {
            org.springframework.jdbc.core.JdbcTemplate slaveJdbc = new org.springframework.jdbc.core.JdbcTemplate(requireSlaveDataSource());
            return slaveJdbc.queryForList(sql);
        } catch (Exception e) {
            logger.error("查询从库统计数据失败", e);
            return new ArrayList<>();
        }
    }

    private void fillUserInfoFromMaster(List<TrainAnswerAttempt> leaderboard) {
        if (leaderboard == null || leaderboard.isEmpty()) {
            return;
        }

        List<Long> userIds = new ArrayList<>();
        for (TrainAnswerAttempt a : leaderboard) {
            if (a != null && a.getUserId() != null) {
                userIds.add(a.getUserId());
            }
        }
        if (userIds.isEmpty()) {
            return;
        }

        StringBuilder in = new StringBuilder();
        for (int i = 0; i < userIds.size(); i++) {
            if (i > 0) {
                in.append(",");
            }
            in.append("?");
        }

        org.springframework.jdbc.core.JdbcTemplate masterJdbc = new org.springframework.jdbc.core.JdbcTemplate(masterDataSource);

        // 查询用户信息
        String sql = "SELECT u.user_id, u.user_name, d.dept_name " +
                     "FROM sys_user u LEFT JOIN sys_dept d ON u.dept_id = d.dept_id " +
                     "WHERE u.user_id IN (" + in + ")";

        List<Map<String, Object>> users = masterJdbc.queryForList(sql, userIds.toArray());
        Map<Long, Map<String, Object>> userMap = new HashMap<>();
        for (Map<String, Object> u : users) {
            Object idObj = u.get("user_id");
            if (idObj != null) {
                userMap.put(((Number) idObj).longValue(), u);
            }
        }

        // 查询用户积分
        String pointsSql = "SELECT user_id, total_points FROM train_user_points WHERE user_id IN (" + in + ")";
        List<Map<String, Object>> pointsList = masterJdbc.queryForList(pointsSql, userIds.toArray());
        Map<Long, Integer> pointsMap = new HashMap<>();
        for (Map<String, Object> p : pointsList) {
            Object idObj = p.get("user_id");
            Object pointsObj = p.get("total_points");
            if (idObj != null) {
                pointsMap.put(((Number) idObj).longValue(), pointsObj != null ? ((Number) pointsObj).intValue() : 0);
            }
        }

        for (TrainAnswerAttempt a : leaderboard) {
            if (a == null || a.getUserId() == null) {
                continue;
            }
            Map<String, Object> u = userMap.get(a.getUserId());
            if (u == null) {
                a.setUserName("用户" + a.getUserId());
                a.setNickName("用户" + a.getUserId());
                a.setIsAdmin(a.getUserId() <= 2);
            } else {
                Object userName = u.get("user_name");
                Object deptName = u.get("dept_name");
                a.setUserName(userName != null ? String.valueOf(userName) : null);
                a.setNickName(userName != null ? String.valueOf(userName) : null);
                a.setDepartment(deptName != null ? String.valueOf(deptName) : null);
                a.setIsAdmin(a.getUserId() <= 2);
            }

            // 设置真实积分
            Integer realPoints = pointsMap.get(a.getUserId());
            a.setScore(realPoints != null ? realPoints.doubleValue() : 0.0);
        }

        // 按积分降序重新排序
        leaderboard.sort((a, b) -> {
            double scoreA = a.getScore() != null ? a.getScore() : 0;
            double scoreB = b.getScore() != null ? b.getScore() : 0;
            if (scoreA != scoreB) {
                return Double.compare(scoreB, scoreA);
            }
            int correctA = a.getCorrectCount() != null ? a.getCorrectCount() : 0;
            int correctB = b.getCorrectCount() != null ? b.getCorrectCount() : 0;
            return Integer.compare(correctB, correctA);
        });
    }

    /**
     * 查询用户个人统计
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/userStats/{userId}")
    public AjaxResult getUserStatistics(@PathVariable("userId") Long userId)
    {
        Long currentUserId = getUserId();
        if (currentUserId == null || !currentUserId.equals(userId)) {
            return error("无权限查看其他用户统计");
        }
        Map<String, Object> stats = trainRankingService.getUserStatistics(userId);
        return success(stats);
    }

    /**
     * 查询用户统计列表
     */
    @PreAuthorize("@ss.hasPermi('train:ranking:list')")
    @GetMapping("/userStatistics")
    public TableDataInfo getUserStatisticsList(@RequestParam Map<String, Object> params)
    {
        startPage();
        List<Map<String, Object>> list = trainRankingService.getUserStatisticsList(params);
        return getDataTable(list);
    }

    /**
     * 查询题目统计列表
     */
    @PreAuthorize("@ss.hasPermi('train:ranking:list')")
    @GetMapping("/questionStatistics")
    public TableDataInfo getQuestionStatisticsList(@RequestParam Map<String, Object> params)
    {
        startPage();
        List<Map<String, Object>> list = trainRankingService.getQuestionStatisticsList(params);
        return getDataTable(list);
    }

    /**
     * 查询排行榜缓存列表
     */
    @PreAuthorize("@ss.hasPermi('train:ranking:list')")
    @GetMapping("/cache")
    public TableDataInfo getRankingCacheList(@RequestParam Map<String, Object> params)
    {
        startPage();
        List<Map<String, Object>> list = trainRankingService.getRankingCacheList(params);
        return getDataTable(list);
    }

    /**
     * 刷新排行榜缓存
     */
    @PreAuthorize("@ss.hasPermi('train:ranking:refresh')")
    @Log(title = "培训排行榜", businessType = BusinessType.UPDATE)
    @PostMapping("/refreshCache")
    public AjaxResult refreshRankingCache(@RequestBody Map<String, Object> params)
    {
        String type = (String) params.get("type");
        trainRankingService.refreshRankingCache(type);
        return success("刷新成功");
    }

    /**
     * 删除排行榜缓存
     */
    @PreAuthorize("@ss.hasPermi('train:ranking:remove')")
    @Log(title = "培训排行榜", businessType = BusinessType.DELETE)
    @DeleteMapping("/cache/{cacheId}")
    public AjaxResult deleteRankingCache(@PathVariable("cacheId") Long cacheId)
    {
        trainRankingService.deleteRankingCache(cacheId);
        return success("删除成功");
    }

    /**
     * 导出排行榜数据
     */
    @PreAuthorize("@ss.hasPermi('train:ranking:export')")
    @Log(title = "培训排行榜", businessType = BusinessType.EXPORT)
    @PostMapping("/export")
    public void export(HttpServletResponse response, @RequestBody Map<String, Object> params)
    {
        String type = (String) params.get("type");
        List<Map<String, Object>> list = trainRankingService.getRankingWithPosition(type, 1000);
        // 由于ExcelUtil需要具体的实体类，这里暂时返回成功消息
        // 实际项目中可以创建RankingVO实体类来支持导出
        try {
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"code\":200,\"msg\":\"导出功能暂未实现\"}");
        } catch (Exception e) {
            logger.error("导出排行榜响应写入失败", e);
        }
    }
}
