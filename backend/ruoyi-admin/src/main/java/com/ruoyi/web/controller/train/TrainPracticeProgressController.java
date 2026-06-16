package com.ruoyi.web.controller.train;

import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.train.domain.TrainPracticeProgress;
import com.ruoyi.train.service.ITrainPracticeProgressService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 刷题进度Controller
 */
@RestController
@RequestMapping("/train/practice/progress")
public class TrainPracticeProgressController extends BaseController {

    @Autowired
    private ITrainPracticeProgressService progressService;

    /**
     * 获取当前用户的刷题进度
     */
    @GetMapping("/get")
    public AjaxResult getProgress(
            @RequestParam(required = false) String mode,
            @RequestParam(required = false) String categoryId) {
        Long userId = SecurityUtils.getUserId();
        
        TrainPracticeProgress progress;
        if (mode != null && !mode.isEmpty()) {
            progress = progressService.getProgress(userId, mode, categoryId);
        } else {
            // 获取最新的进度（任意模式）
            progress = progressService.getLatestProgress(userId);
        }
        
        return AjaxResult.success(progress);
    }

    /**
     * 保存刷题进度
     */
    @PostMapping("/save")
    public AjaxResult saveProgress(@RequestBody Map<String, Object> params) {
        Long userId = SecurityUtils.getUserId();
        
        TrainPracticeProgress progress = new TrainPracticeProgress();
        progress.setUserId(userId);
        progress.setMode((String) params.get("mode"));
        progress.setCategoryId(params.get("categoryId") != null ? String.valueOf(params.get("categoryId")) : null);
        progress.setCategoryName((String) params.get("categoryName"));
        progress.setCurrentIndex(params.get("currentIndex") != null ? 
            Integer.parseInt(String.valueOf(params.get("currentIndex"))) : 0);
        progress.setQuestionsData((String) params.get("questionsData"));
        
        int result = progressService.saveProgress(progress);
        return result > 0 ? AjaxResult.success("保存成功") : AjaxResult.error("保存失败");
    }

    /**
     * 清除刷题进度
     */
    @DeleteMapping("/clear")
    public AjaxResult clearProgress(
            @RequestParam(required = false) String mode,
            @RequestParam(required = false) String categoryId) {
        Long userId = SecurityUtils.getUserId();
        if (mode == null || mode.isEmpty()) {
            progressService.clearAllProgress(userId);
            return AjaxResult.success("清除成功");
        }
        progressService.clearProgress(userId, mode, categoryId);
        return AjaxResult.success("清除成功");
    }

    /**
     * 清除所有进度
     */
    @DeleteMapping("/clearAll")
    public AjaxResult clearAllProgress() {
        Long userId = SecurityUtils.getUserId();
        progressService.clearAllProgress(userId);
        return AjaxResult.success("清除成功");
    }
}
