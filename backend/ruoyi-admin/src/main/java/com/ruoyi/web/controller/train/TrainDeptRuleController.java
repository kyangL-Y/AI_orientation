package com.ruoyi.web.controller.train;

import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.train.domain.TrainDeptRule;
import com.ruoyi.train.domain.TrainScoreModel;
import com.ruoyi.train.service.ITrainDeptRuleService;
import com.ruoyi.train.service.ITrainScoreModelService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 部门规则配置Controller
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/train/assessment/deptRule")
public class TrainDeptRuleController extends BaseController {
    
    @Autowired
    private ITrainDeptRuleService deptRuleService;
    
    @Autowired
    private ITrainScoreModelService scoreModelService;

    /**
     * 查询部门规则配置列表
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:deptRule:query')")
    @GetMapping("/list")
    public TableDataInfo list(TrainDeptRule deptRule) {
        String tenantId = SecurityUtils.getLoginUser().getUser().getTenantId();
        deptRule.setTenantId(tenantId);
        startPage();
        List<TrainDeptRule> list = deptRuleService.selectDeptRuleList(deptRule);
        return getDataTable(list);
    }

    /**
     * 根据部门ID查询规则配置
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:deptRule:query')")
    @GetMapping("/dept/{deptId}")
    public AjaxResult getByDeptId(@PathVariable Long deptId) {
        TrainDeptRule deptRule = deptRuleService.selectDeptRuleByDeptId(deptId);
        return AjaxResult.success(deptRule);
    }

    /**
     * 获取部门有效的评分规则ID
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:deptRule:query')")
    @GetMapping("/effective/{deptId}")
    public AjaxResult getEffectiveModelId(@PathVariable Long deptId) {
        Long modelId = deptRuleService.getEffectiveModelId(deptId);
        return AjaxResult.success(modelId);
    }

    /**
     * 保存部门规则配置
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:deptRule:edit')")
    @Log(title = "部门规则配置", businessType = BusinessType.UPDATE)
    @PostMapping
    public AjaxResult save(@RequestBody TrainDeptRule deptRule) {
        return toAjax(deptRuleService.saveDeptRule(deptRule));
    }

    /**
     * 删除部门规则配置
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:deptRule:edit')")
    @Log(title = "部门规则配置", businessType = BusinessType.DELETE)
    @DeleteMapping("/{id}")
    public AjaxResult remove(@PathVariable Long id) {
        return toAjax(deptRuleService.deleteDeptRuleById(id));
    }

    /**
     * 批量删除部门规则配置
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:deptRule:edit')")
    @Log(title = "部门规则配置", businessType = BusinessType.DELETE)
    @DeleteMapping("/{ids}")
    public AjaxResult removeBatch(@PathVariable Long[] ids) {
        return toAjax(deptRuleService.deleteDeptRuleByIds(ids));
    }

    /**
     * 获取可用的评分规则列表
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:deptRule:query')")
    @GetMapping("/models")
    public AjaxResult listModels() {
        String tenantId = SecurityUtils.getLoginUser().getUser().getTenantId();
        List<TrainScoreModel> models = scoreModelService.listActiveModels(tenantId);
        return AjaxResult.success(models);
    }
}
