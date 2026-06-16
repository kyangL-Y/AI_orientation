package com.ruoyi.web.controller.train;

import java.util.List;
import java.util.Map;

import com.ruoyi.common.utils.SecurityUtils;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.train.domain.TrainKnowledgeArticle;
import com.ruoyi.train.service.ITrainKnowledgeStatisticsService;

/**
 * 知识文章统计Controller
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/train/knowledge/statistics")
public class TrainKnowledgeStatisticsController extends BaseController {
    
    @Autowired
    private ITrainKnowledgeStatisticsService statisticsService;
    
    /**
     * 获取租户ID（超级管理员不受租户限制）
     */
    private String getTenantId() {
        SysUser user = SecurityUtils.getLoginUser().getUser();
        return user != null && user.canManageAllTenants() ? null : (user != null ? user.getTenantId() : null);
    }

    /**
     * 查询统计数据
     */
    @PreAuthorize("@ss.hasPermi('train:knowledge:statistics')")
    @GetMapping
    public AjaxResult getStatistics() {
        Map<String, Object> statistics = statisticsService.getStatistics(getTenantId());
        return success(statistics);
    }

    /**
     * 查询热门文章
     */
    @PreAuthorize("@ss.hasPermi('train:knowledge:statistics')")
    @GetMapping("/hot")
    public AjaxResult getHotArticles(
            @RequestParam(defaultValue = "view") String type,
            @RequestParam(defaultValue = "10") int limit) {
        List<TrainKnowledgeArticle> articles = statisticsService.getHotArticles(getTenantId(), type, limit);
        return success(articles);
    }

    /**
     * 查询活跃作者
     */
    @PreAuthorize("@ss.hasPermi('train:knowledge:statistics')")
    @GetMapping("/authors")
    public AjaxResult getActiveAuthors(@RequestParam(defaultValue = "10") int limit) {
        List<Map<String, Object>> authors = statisticsService.getActiveAuthors(getTenantId(), limit);
        return success(authors);
    }
}
