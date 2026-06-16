package com.ruoyi.web.controller.train;

import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.DataSourceType;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 学习进度管理Controller（管理端）
 */
@RestController
@RequestMapping("/train/progress-admin")
public class TrainProgressController extends BaseController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    /**
     * 查询学习进度列表（分页）
     * 注意：不使用@DataSource注解，因为需要跨库查询
     */
    @PreAuthorize("@ss.hasPermi('train:progress:list')")
    @GetMapping("/list")
    public TableDataInfo list(
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String userName,
            @RequestParam(required = false) String courseName,
            @RequestParam(required = false) String status) {

        // 获取当前登录用户信息
        com.ruoyi.common.core.domain.entity.SysUser currentUser = getLoginUser().getUser();
        String currentTenantId = currentUser.getTenantId();
        Integer adminLevel = currentUser.getAdminLevel();
        boolean isPlatformAdmin = (adminLevel != null && adminLevel <= 5);

        logger.info("📊 查询学习进度列表 - tenantId: {}, adminLevel: {}, isPlatformAdmin: {}, userId: {}, userName: {}",
                   currentTenantId, adminLevel, isPlatformAdmin, userId, userName);

        startPage();

        StringBuilder sql = new StringBuilder();
        sql.append("SELECT p.id, p.user_id, p.course_id, p.course_name, p.status, p.progress, ");
        sql.append("p.study_duration, p.started_at, p.completed_at, p.create_time, p.update_time, ");
        sql.append("u.user_name as userName, u.phonenumber as phone, ");
        sql.append("d.dept_name as deptName ");
        sql.append("FROM hotel_training.train_progress p ");
        sql.append("LEFT JOIN `hz-vue`.sys_user u ON p.user_id = u.user_id ");
        sql.append("LEFT JOIN `hz-vue`.sys_dept d ON u.dept_id = d.dept_id ");
        sql.append("WHERE 1=1 ");

        // 【修复】只有非平台管理员才过滤集团ID
        if (!isPlatformAdmin) {
            sql.append("AND u.tenant_id = '").append(currentTenantId).append("' ");
        }
        
        if (userId != null) {
            sql.append("AND p.user_id = ").append(userId).append(" ");
        }
        if (userName != null && !userName.isEmpty()) {
            sql.append("AND u.user_name LIKE '%").append(userName).append("%' ");
        }
        if (courseName != null && !courseName.isEmpty()) {
            sql.append("AND p.course_name LIKE '%").append(courseName).append("%' ");
        }
        if (status != null && !status.isEmpty()) {
            sql.append("AND p.status = '").append(status).append("' ");
        }
        sql.append("ORDER BY p.update_time DESC");
        
        List<Map<String, Object>> list = jdbcTemplate.queryForList(sql.toString());
        return getDataTable(list);
    }

    /**
     * 获取学习进度统计概览
     * 注意：不使用@DataSource注解，直接查询从库表
     */
    @PreAuthorize("@ss.hasPermi('train:progress:list')")
    @GetMapping({"/stats", "/progress-stats"})
    public AjaxResult getStats() {
        // 获取当前登录用户信息
        com.ruoyi.common.core.domain.entity.SysUser currentUser = getLoginUser().getUser();
        String currentTenantId = currentUser.getTenantId();
        Integer adminLevel = currentUser.getAdminLevel();
        boolean isPlatformAdmin = (adminLevel != null && adminLevel <= 5);

        logger.info("📊 获取学习进度统计 - tenantId: {}, adminLevel: {}, isPlatformAdmin: {}",
                   currentTenantId, adminLevel, isPlatformAdmin);

        Map<String, Object> stats = new HashMap<>();

        try {
            // 构建租户过滤条件
            String tenantFilter = "";
            if (!isPlatformAdmin) {
                tenantFilter = " AND user_id IN (SELECT user_id FROM `hz-vue`.sys_user WHERE tenant_id = '" + currentTenantId + "')";
            }

            // 总记录数
            Integer total = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM hotel_training.train_progress WHERE 1=1" + tenantFilter, Integer.class);
            stats.put("total", total != null ? total : 0);

            // 学习中数量
            Integer inProgress = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM hotel_training.train_progress WHERE status = 'in_progress'" + tenantFilter, Integer.class);
            stats.put("inProgress", inProgress != null ? inProgress : 0);

            // 已完成数量
            Integer completed = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM hotel_training.train_progress WHERE status = 'completed'" + tenantFilter, Integer.class);
            stats.put("completed", completed != null ? completed : 0);

            // 未开始数量
            Integer notStarted = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM hotel_training.train_progress WHERE status = 'not_started'" + tenantFilter, Integer.class);
            stats.put("notStarted", notStarted != null ? notStarted : 0);

            // 总学习时长（小时）
            Integer totalDuration = jdbcTemplate.queryForObject(
                "SELECT COALESCE(SUM(study_duration), 0) FROM hotel_training.train_progress WHERE 1=1" + tenantFilter, Integer.class);
            stats.put("totalHours", totalDuration != null ? Math.round(totalDuration / 3600.0 * 10) / 10.0 : 0);

            // 学习人数
            Integer userCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(DISTINCT user_id) FROM hotel_training.train_progress WHERE 1=1" + tenantFilter, Integer.class);
            stats.put("userCount", userCount != null ? userCount : 0);

            // 课程数
            Integer courseCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(DISTINCT course_id) FROM hotel_training.train_progress WHERE 1=1" + tenantFilter, Integer.class);
            stats.put("courseCount", courseCount != null ? courseCount : 0);

            // 完成率
            double completionRate = total != null && total > 0 ?
                Math.round((completed != null ? completed : 0) * 100.0 / total * 10) / 10.0 : 0;
            stats.put("completionRate", completionRate);
            
        } catch (Exception e) {
            logger.error("获取学习进度统计失败", e);
        }
        
        return success(stats);
    }

    /**
     * 获取学习进度详情
     * 注意：不使用@DataSource注解，因为需要跨库查询
     */
    @PreAuthorize("@ss.hasPermi('train:progress:query')")
    @GetMapping("/{id:\\d+}")
    public AjaxResult getInfo(@PathVariable Long id) {
        String sql = "SELECT p.*, u.user_name as userName " +
                    "FROM hotel_training.train_progress p " +
                    "LEFT JOIN `hz-vue`.sys_user u ON p.user_id = u.user_id " +
                    "WHERE p.id = ?";
        List<Map<String, Object>> list = jdbcTemplate.queryForList(sql, id);
        return success(list.isEmpty() ? null : list.get(0));
    }

    /**
     * 删除学习进度记录
     * 注意：不使用@DataSource注解，直接操作从库表
     */
    @PreAuthorize("@ss.hasPermi('train:progress:remove')")
    @DeleteMapping("/{ids:\\d+(,\\d+)*}")
    public AjaxResult remove(@PathVariable Long[] ids) {
        if (ids == null || ids.length == 0) {
            return error("请选择要删除的记录");
        }
        
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < ids.length; i++) {
            if (i > 0) sb.append(",");
            sb.append(ids[i]);
        }
        
        String sql = "DELETE FROM hotel_training.train_progress WHERE id IN (" + sb.toString() + ")";
        int rows = jdbcTemplate.update(sql);
        return toAjax(rows);
    }

    /**
     * 重置学习进度
     * 注意：不使用@DataSource注解，直接操作从库表
     */
    @PreAuthorize("@ss.hasPermi('train:progress:edit')")
    @PutMapping("/reset/{id:\\d+}")
    public AjaxResult reset(@PathVariable Long id) {
        String sql = "UPDATE hotel_training.train_progress SET status = 'not_started', progress = 0, " +
                    "study_duration = 0, completed_at = NULL, update_time = NOW() WHERE id = ?";
        int rows = jdbcTemplate.update(sql, id);
        return toAjax(rows);
    }
}
