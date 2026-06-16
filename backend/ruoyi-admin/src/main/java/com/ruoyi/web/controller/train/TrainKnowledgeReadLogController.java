package com.ruoyi.web.controller.train;

import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.train.service.ITrainKnowledgeReadLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * 知识文章阅读记录Controller
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/train/knowledge/readlog")
public class TrainKnowledgeReadLogController extends BaseController {
    
    @Autowired
    private ITrainKnowledgeReadLogService readLogService;
    
    /**
     * 开始阅读文章
     */
    @PostMapping("/start")
    public AjaxResult startReading(@RequestParam Long articleId) {
        Long userId = SecurityUtils.getUserId();
        Long logId = readLogService.startReading(userId, articleId);
        return AjaxResult.success(logId);
    }
    
    /**
     * 更新阅读时长（定期调用）
     */
    @PutMapping("/update")
    public AjaxResult updateDuration(@RequestParam Long logId, @RequestParam Integer duration) {
        readLogService.updateReadDuration(logId, duration);
        return AjaxResult.success();
    }
    
    /**
     * 结束阅读
     */
    @PutMapping("/end")
    public AjaxResult endReading(@RequestParam Long logId, @RequestParam Integer duration) {
        readLogService.endReading(logId, duration);
        return AjaxResult.success();
    }
}
