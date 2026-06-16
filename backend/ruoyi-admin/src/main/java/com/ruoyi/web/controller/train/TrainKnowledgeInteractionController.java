package com.ruoyi.web.controller.train;

import java.util.List;
import java.util.Map;

import com.ruoyi.common.utils.SecurityUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.train.domain.TrainKnowledgeArticle;
import com.ruoyi.train.service.ITrainKnowledgeInteractionService;
import com.ruoyi.common.core.page.TableDataInfo;

/**
 * 知识文章互动Controller
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/train/knowledge")
public class TrainKnowledgeInteractionController extends BaseController {
    
    @Autowired
    private ITrainKnowledgeInteractionService interactionService;

    /**
     * 点赞/取消点赞
     */
    @Log(title = "文章点赞", businessType = BusinessType.UPDATE)
    @PostMapping("/like/{articleId}")
    public AjaxResult toggleLike(@PathVariable Long articleId) {
        Long userId = SecurityUtils.getUserId();
        Map<String, Object> result = interactionService.toggleLike(articleId, userId);
        return success(result);
    }

    /**
     * 收藏/取消收藏
     */
    @Log(title = "文章收藏", businessType = BusinessType.UPDATE)
    @PostMapping("/favorite/{articleId}")
    public AjaxResult toggleFavorite(@PathVariable Long articleId) {
        Long userId = SecurityUtils.getUserId();
        Map<String, Object> result = interactionService.toggleFavorite(articleId, userId);
        return success(result);
    }

    /**
     * 查询我的收藏列表
     */
    @GetMapping("/favorite/my")
    public TableDataInfo myFavorites() {
        Long userId = SecurityUtils.getUserId();
        startPage();
        List<TrainKnowledgeArticle> list = interactionService.listMyFavorites(userId);
        return getDataTable(list);
    }
}
