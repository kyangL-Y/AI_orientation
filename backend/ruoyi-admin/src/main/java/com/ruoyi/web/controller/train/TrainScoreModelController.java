package com.ruoyi.web.controller.train;

import java.util.List;

import com.ruoyi.common.utils.SecurityUtils;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.train.domain.TrainScoreModel;
import com.ruoyi.train.domain.TrainScoreDimension;
import com.ruoyi.train.service.ITrainScoreModelService;
import com.ruoyi.common.core.page.TableDataInfo;

/**
 * 评分模型Controller
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/train/assessment/model")
public class TrainScoreModelController extends BaseController {
    
    @Autowired
    private ITrainScoreModelService scoreModelService;

    /**
     * 查询评分模型列表
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:model:list')")
    @GetMapping("/list")
    public TableDataInfo list(TrainScoreModel model) {
        SysUser user = SecurityUtils.getLoginUser().getUser();
        model.setTenantId(user.getTenantId());
        
        startPage();
        List<TrainScoreModel> list = scoreModelService.listModels(model);
        return getDataTable(list);
    }

    /**
     * 查询启用的评分模型列表（下拉选择用）
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:model:query')")
    @GetMapping("/active")
    public AjaxResult activeList() {
        SysUser user = SecurityUtils.getLoginUser().getUser();
        List<TrainScoreModel> list = scoreModelService.listActiveModels(user.getTenantId());
        return AjaxResult.success(list);
    }

    /**
     * 获取评分模型详情
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:model:query')")
    @GetMapping("/{modelId}")
    public AjaxResult getInfo(@PathVariable Long modelId) {
        return AjaxResult.success(scoreModelService.getModelById(modelId));
    }

    /**
     * 新增评分模型
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:model:add')")
    @Log(title = "评分模型", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody TrainScoreModel model) {
        SysUser user = SecurityUtils.getLoginUser().getUser();
        model.setTenantId(user.getTenantId());
        model.setCreateBy(user.getUserName());
        
        // 验证维度权重
        if (model.getDimensions() != null && !model.getDimensions().isEmpty()) {
            if (!scoreModelService.validateWeightSum(model.getDimensions())) {
                return AjaxResult.error("维度权重总和必须为100%");
            }
        }
        
        int result = scoreModelService.createModel(model);
        if (result > 0) {
            // 保存维度配置
            if (model.getDimensions() != null && !model.getDimensions().isEmpty()) {
                scoreModelService.saveDimensions(model.getModelId(), model.getDimensions());
            }
            
            // 保存部门规则关联
            if (model.getDeptIds() != null && !model.getDeptIds().isEmpty()) {
                scoreModelService.saveDeptRules(model.getModelId(), model.getDeptIds());
            }
            
            return AjaxResult.success(model.getModelId());
        }
        
        return AjaxResult.error("新增失败");
    }

    /**
     * 修改评分模型
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:model:edit')")
    @Log(title = "评分模型", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody TrainScoreModel model) {
        SysUser user = SecurityUtils.getLoginUser().getUser();
        model.setUpdateBy(user.getUserName());
        
        // 验证维度权重
        if (model.getDimensions() != null && !model.getDimensions().isEmpty()) {
            if (!scoreModelService.validateWeightSum(model.getDimensions())) {
                return AjaxResult.error("维度权重总和必须为100%");
            }
        }
        
        int result = scoreModelService.updateModel(model);
        if (result > 0) {
            // 保存维度配置
            if (model.getDimensions() != null && !model.getDimensions().isEmpty()) {
                scoreModelService.saveDimensions(model.getModelId(), model.getDimensions());
            }
            
            // 保存部门规则关联
            if (model.getDeptIds() != null) {
                scoreModelService.saveDeptRules(model.getModelId(), model.getDeptIds());
            }
            
            return AjaxResult.success();
        }
        
        return AjaxResult.error("修改失败");
    }

    /**
     * 删除评分模型
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:model:remove')")
    @Log(title = "评分模型", businessType = BusinessType.DELETE)
    @DeleteMapping("/{modelIds}")
    public AjaxResult remove(@PathVariable Long[] modelIds) {
        return toAjax(scoreModelService.deleteModels(modelIds));
    }

    /**
     * 保存维度配置
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:model:edit')")
    @Log(title = "评分维度", businessType = BusinessType.UPDATE)
    @PostMapping("/{modelId}/dimensions")
    public AjaxResult saveDimensions(@PathVariable Long modelId, 
                                      @RequestBody List<TrainScoreDimension> dimensions) {
        // 验证权重
        if (!scoreModelService.validateWeightSum(dimensions)) {
            return AjaxResult.error("维度权重总和必须为100%");
        }
        
        return toAjax(scoreModelService.saveDimensions(modelId, dimensions));
    }

    /**
     * 验证权重总和
     */
    @PostMapping("/validateWeight")
    public AjaxResult validateWeight(@RequestBody List<TrainScoreDimension> dimensions) {
        boolean valid = scoreModelService.validateWeightSum(dimensions);
        return AjaxResult.success("valid", valid);
    }
}
