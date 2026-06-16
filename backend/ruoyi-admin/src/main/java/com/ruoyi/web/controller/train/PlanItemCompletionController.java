package com.ruoyi.web.controller.train;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
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
import com.ruoyi.system.domain.PlanItemCompletion;
import com.ruoyi.system.service.IPlanItemCompletionService;
import com.ruoyi.system.service.IPlanItemService;
import com.ruoyi.system.service.ILearningPlanService;
import com.ruoyi.system.domain.PlanItem;
import com.ruoyi.system.domain.LearningPlan;
import com.ruoyi.common.utils.poi.ExcelUtil;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.utils.SecurityUtils;

/**
 * 任务完成记录Controller
 * 
 * @author ruoyi
 * @date 2025-01-15
 */
@RestController
@RequestMapping("/train/plan-item-completions")
public class PlanItemCompletionController extends BaseController
{
    @Autowired
    private IPlanItemCompletionService planItemCompletionService;

    @Autowired
    private IPlanItemService planItemService;

    @Autowired
    private ILearningPlanService learningPlanService;

    /**
     * 查询任务完成记录列表
     */
    @PreAuthorize("@ss.hasPermi('train:plans:list')")
    @GetMapping("/list")
    public TableDataInfo list(PlanItemCompletion planItemCompletion)
    {
        startPage();
        List<PlanItemCompletion> list = planItemCompletionService.selectPlanItemCompletionList(planItemCompletion);
        return getDataTable(list);
    }

    /**
     * 根据用户ID查询完成记录列表
     */
    @PreAuthorize("@ss.hasPermi('train:plans:list')")
    @GetMapping("/user/{userId}")
    public AjaxResult listByUserId(@PathVariable("userId") Long userId)
    {
        List<PlanItemCompletion> list = planItemCompletionService.selectPlanItemCompletionListByUserId(userId);
        return success(list);
    }

    /**
     * 获取当前用户的完成记录列表
     */
    @PreAuthorize("@ss.hasPermi('train:plans:list')")
    @GetMapping("/my")
    public AjaxResult getMyCompletions()
    {
        Long userId = SecurityUtils.getUserId();
        List<PlanItemCompletion> list = planItemCompletionService.selectPlanItemCompletionListByUserId(userId);
        return success(list);
    }

    /**
     * 导出任务完成记录列表
     */
    @PreAuthorize("@ss.hasPermi('train:plans:export')")
    @Log(title = "任务完成记录", businessType = BusinessType.EXPORT)
    @PostMapping("/export")
    public void export(HttpServletResponse response, PlanItemCompletion planItemCompletion)
    {
        List<PlanItemCompletion> list = planItemCompletionService.selectPlanItemCompletionList(planItemCompletion);
        ExcelUtil<PlanItemCompletion> util = new ExcelUtil<PlanItemCompletion>(PlanItemCompletion.class);
        util.exportExcel(response, list, "任务完成记录数据");
    }

    /**
     * 获取任务完成记录详细信息
     */
    @PreAuthorize("@ss.hasPermi('train:plans:query')")
    @GetMapping(value = "/{completionId}")
    public AjaxResult getInfo(@PathVariable("completionId") Long completionId)
    {
        return success(planItemCompletionService.selectPlanItemCompletionByCompletionId(completionId));
    }

    /**
     * 新增任务完成记录
     */
    @PreAuthorize("@ss.hasPermi('train:plans:add')")
    @Log(title = "任务完成记录", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody PlanItemCompletion planItemCompletion)
    {
        try {
            // 校验必填字段
            if (planItemCompletion.getItemId() == null) {
                return error("任务项ID不能为空");
            }
            if (planItemCompletion.getUserId() == null) {
                return error("用户ID不能为空");
            }
            
            planItemCompletion.setCreateBy(SecurityUtils.getUsername());
            int result = planItemCompletionService.insertPlanItemCompletion(planItemCompletion);
            if (result > 0) {
                return success("新增成功");
            } else {
                return error("新增失败");
            }
        } catch (Exception e) {
            logger.error("新增任务完成记录失败", e);
            return error("新增失败：" + e.getMessage());
        }
    }

    /**
     * 修改任务完成记录
     */
    @PreAuthorize("@ss.hasPermi('train:plans:edit')")
    @Log(title = "任务完成记录", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody PlanItemCompletion planItemCompletion)
    {
        try {
            planItemCompletion.setUpdateBy(SecurityUtils.getUsername());
            int result = planItemCompletionService.updatePlanItemCompletion(planItemCompletion);
            if (result > 0) {
                return success("修改成功");
            } else {
                return error("修改失败");
            }
        } catch (Exception e) {
            logger.error("修改任务完成记录失败", e);
            return error("修改失败：" + e.getMessage());
        }
    }

    /**
     * 删除任务完成记录
     */
    @PreAuthorize("@ss.hasPermi('train:plans:remove')")
    @Log(title = "任务完成记录", businessType = BusinessType.DELETE)
	@DeleteMapping("/{completionIds}")
    public AjaxResult remove(@PathVariable Long[] completionIds)
    {
        try {
            int result = planItemCompletionService.deletePlanItemCompletionByCompletionIds(completionIds);
            if (result > 0) {
                return success("删除成功");
            } else {
                return error("删除失败");
            }
        } catch (Exception e) {
            logger.error("删除任务完成记录失败", e);
            return error("删除失败：" + e.getMessage());
        }
    }

    /**
     * 标记任务项完成
     */
    @PreAuthorize("@ss.hasPermi('train:plans:edit')")
    @Log(title = "标记任务完成", businessType = BusinessType.UPDATE)
    @PostMapping("/complete/{itemId}")
    public AjaxResult completeItem(@PathVariable("itemId") Long itemId, @RequestBody Map<String, Object> requestBody)
    {
        try {
            Long userId = SecurityUtils.getUserId();
            java.math.BigDecimal score = null;
            String feedback = null;
            
            if (requestBody.containsKey("score")) {
                Object scoreObj = requestBody.get("score");
                if (scoreObj != null) {
                    score = new java.math.BigDecimal(scoreObj.toString());
                }
            }
            if (requestBody.containsKey("feedback")) {
                feedback = requestBody.get("feedback").toString();
            }
            
            // 检查任务项是否存在
            PlanItem planItem = planItemService.selectPlanItemByItemId(itemId);
            if (planItem == null) {
                return error("任务项不存在");
            }
            
            // 检查用户是否有权限完成此任务项
            LearningPlan learningPlan = learningPlanService.selectLearningPlanByPlanId(planItem.getPlanId());
            if (learningPlan == null || !learningPlan.getAssignedTo().equals(userId)) {
                return error("您没有权限完成此任务项");
            }
            
            // 检查任务项是否已完成
            if (planItemCompletionService.checkItemCompleted(itemId, userId)) {
                return error("任务项已完成，不能重复完成");
            }
            
            int result = planItemCompletionService.completePlanItem(itemId, userId, score, feedback);
            if (result > 0) {
                return success("任务完成成功");
            } else {
                return error("任务完成失败");
            }
        } catch (Exception e) {
            logger.error("标记任务完成失败", e);
            return error("任务完成失败：" + e.getMessage());
        }
    }

    /**
     * 检查任务项完成状态
     */
    @PreAuthorize("@ss.hasPermi('train:plans:query')")
    @GetMapping("/check/{itemId}")
    public AjaxResult checkCompletion(@PathVariable("itemId") Long itemId)
    {
        try {
            Long userId = SecurityUtils.getUserId();
            boolean completed = planItemCompletionService.checkItemCompleted(itemId, userId);
            
            Map<String, Object> result = new HashMap<>();
            result.put("completed", completed);
            
            if (completed) {
                PlanItemCompletion completion = planItemCompletionService.selectPlanItemCompletionByItemIdAndUserId(itemId, userId);
                result.put("completion", completion);
            }
            
            return success(result);
        } catch (Exception e) {
            logger.error("检查任务完成状态失败", e);
            return error("检查失败：" + e.getMessage());
        }
    }
}