package com.ruoyi.web.controller.train;

import java.util.List;
import java.util.HashMap;
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
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.system.domain.LearningPlan;
import com.ruoyi.system.service.ILearningPlanService;
import com.ruoyi.common.utils.poi.ExcelUtil;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.enums.DataSourceType;
import org.springframework.jdbc.core.JdbcTemplate;

/**
 * 学习计划Controller
 * 
 * @author ruoyi
 * @date 2025-01-15
 */
@RestController
@RequestMapping("/train/plans")
public class LearningPlanController extends BaseController
{
    @Autowired
    private ILearningPlanService learningPlanService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    /**
     * 查询学习计划列表
     */
    @PreAuthorize("isAuthenticated()")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping("/list")
    public TableDataInfo list(LearningPlan learningPlan)
    {
        startPage();
        List<LearningPlan> list = learningPlanService.selectLearningPlanList(learningPlan);
        return getDataTable(list);
    }

    /**
     * 根据用户ID查询学习计划列表
     */
    @PreAuthorize("@ss.hasPermi('train:plans:list')")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping("/user/{userId}")
    public AjaxResult listByUserId(@PathVariable("userId") Long userId)
    {
        List<LearningPlan> list = learningPlanService.selectLearningPlanListByUserId(userId);
        return success(list);
    }

    /**
     * 获取当前用户的学习计划列表
     */
    @PreAuthorize("isAuthenticated()")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping("/my")
    public AjaxResult getMyPlans()
    {
        Long userId = SecurityUtils.getUserId();
        List<LearningPlan> list = learningPlanService.selectLearningPlanListByUserId(userId);
        return success(list);
    }

    /**
     * 导出学习计划列表
     */
    @PreAuthorize("@ss.hasPermi('train:plans:export')")
    @Log(title = "学习计划", businessType = BusinessType.EXPORT)
    @DataSource(DataSourceType.SLAVE)
    @PostMapping("/export")
    public void export(HttpServletResponse response, LearningPlan learningPlan)
    {
        List<LearningPlan> list = learningPlanService.selectLearningPlanList(learningPlan);
        ExcelUtil<LearningPlan> util = new ExcelUtil<LearningPlan>(LearningPlan.class);
        util.exportExcel(response, list, "学习计划数据");
    }

    /**
     * 获取日历视图数据（必须放在 /{planId} 之前）
     */
    @PreAuthorize("isAuthenticated()")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping("/calendar")
    public AjaxResult getCalendar()
    {
        Long userId = SecurityUtils.getUserId();
        // 获取用户的所有学习计划，用于日历展示
        List<LearningPlan> list = learningPlanService.selectLearningPlanListByUserId(userId);
        return success(list);
    }

    /**
     * 获取当前用户学习进度统计。
     */
    @PreAuthorize("isAuthenticated()")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping("/progress-stats")
    public AjaxResult getProgressStats()
    {
        Long userId = SecurityUtils.getUserId();
        Map<String, Object> stats = new HashMap<>();
        stats.put("progress", 0);
        stats.put("remainingDays", 0);
        stats.put("completedTasks", 0);
        stats.put("totalTasks", 0);

        List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                "SELECT status, progress FROM hotel_training.train_progress WHERE user_id = ?",
                userId);
        if (rows.isEmpty()) {
            return success(stats);
        }

        int totalTasks = rows.size();
        int completedTasks = 0;
        int progressSum = 0;
        for (Map<String, Object> row : rows) {
            int itemProgress = row.get("progress") == null ? 0 : ((Number) row.get("progress")).intValue();
            progressSum += itemProgress;
            if ("completed".equals(row.get("status")) || itemProgress >= 100) {
                completedTasks++;
            }
        }

        stats.put("progress", Math.round(progressSum * 1.0 / totalTasks));
        stats.put("completedTasks", completedTasks);
        stats.put("totalTasks", totalTasks);
        return success(stats);
    }

    /**
     * 获取学习计划详细信息
     */
    @PreAuthorize("isAuthenticated()")
    @DataSource(DataSourceType.SLAVE)
    @GetMapping(value = "/{planId}")
    public AjaxResult getInfo(@PathVariable("planId") Long planId)
    {
        Long userId = SecurityUtils.getUserId();
        LearningPlan learningPlan = learningPlanService.getLearningPlanDetail(planId, userId);
        return success(learningPlan);
    }

    /**
     * 新增学习计划
     */
    @PreAuthorize("@ss.hasPermi('train:plans:add')")
    @Log(title = "学习计划", businessType = BusinessType.INSERT)
    @DataSource(DataSourceType.SLAVE)
    @PostMapping
    public AjaxResult add(@RequestBody LearningPlan learningPlan)
    {
        try {
            logger.info("📝 开始新增学习计划，接收到的数据: pathId={}, title={}, planItems={}", 
                    learningPlan.getPathId(), learningPlan.getTitle(), 
                    learningPlan.getPlanItems() != null ? learningPlan.getPlanItems().size() : 0);
            
            // 校验必填字段
            if (learningPlan.getTitle() == null || learningPlan.getTitle().trim().isEmpty()) {
                logger.warn("❌ 计划标题为空");
                return error("计划标题不能为空");
            }
            if (learningPlan.getStartDate() == null || learningPlan.getEndDate() == null) {
                logger.warn("❌ 开始日期或结束日期为空");
                return error("开始日期和结束日期不能为空");
            }
            if (learningPlan.getEndDate().before(learningPlan.getStartDate())) {
                logger.warn("❌ 结束日期早于开始日期");
                return error("结束日期必须大于开始日期");
            }
            
            logger.info("✅ 校验通过，开始创建学习计划（hotel_training 数据源）");
            int result = learningPlanService.createLearningPlan(learningPlan);
            
            if (result > 0) {
                logger.info("✅ 学习计划创建成功，planId={}, pathId={}", 
                        learningPlan.getPlanId(), learningPlan.getPathId());
                return success("创建成功").put("planId", learningPlan.getPlanId());
            } else {
                logger.error("❌ 学习计划创建失败，返回结果: {}", result);
                return error("创建失败");
            }
        } catch (Exception e) {
            logger.error("❌ 创建学习计划失败", e);
            return error("创建失败：" + e.getMessage());
        }
    }

    /**
     * 修改学习计划
     */
    @PreAuthorize("@ss.hasPermi('train:plans:edit')")
    @Log(title = "学习计划", businessType = BusinessType.UPDATE)
    @DataSource(DataSourceType.SLAVE)
    @PutMapping
    public AjaxResult edit(@RequestBody LearningPlan learningPlan)
    {
        try {
            // 校验必填字段
            if (learningPlan.getTitle() == null || learningPlan.getTitle().trim().isEmpty()) {
                return error("计划标题不能为空");
            }
            if (learningPlan.getStartDate() == null || learningPlan.getEndDate() == null) {
                return error("开始日期和结束日期不能为空");
            }
            if (learningPlan.getEndDate().before(learningPlan.getStartDate())) {
                return error("结束日期必须大于开始日期");
            }
            
            learningPlan.setUpdateBy(SecurityUtils.getUsername());
            int result = learningPlanService.updateLearningPlan(learningPlan);
            if (result > 0) {
                return success("修改成功");
            } else {
                return error("修改失败");
            }
        } catch (Exception e) {
            logger.error("修改学习计划失败", e);
            return error("修改失败：" + e.getMessage());
        }
    }

    /**
     * 删除学习计划
     */
    @PreAuthorize("@ss.hasPermi('train:plans:remove')")
    @Log(title = "学习计划", businessType = BusinessType.DELETE)
    @DataSource(DataSourceType.SLAVE)
	@DeleteMapping("/{planIds}")
    public AjaxResult remove(@PathVariable Long[] planIds)
    {
        try {
            int result = learningPlanService.deleteLearningPlanByPlanIds(planIds);
            if (result > 0) {
                return success("删除成功");
            } else {
                return error("删除失败");
            }
        } catch (Exception e) {
            logger.error("删除学习计划失败", e);
            return error("删除失败：" + e.getMessage());
        }
    }
}
