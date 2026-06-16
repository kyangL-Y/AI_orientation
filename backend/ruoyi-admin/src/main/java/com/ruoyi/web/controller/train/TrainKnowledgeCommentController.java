package com.ruoyi.web.controller.train;

import java.util.List;

import com.ruoyi.common.utils.SecurityUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.train.domain.TrainKnowledgeComment;
import com.ruoyi.train.service.ITrainKnowledgeCommentService;
import com.ruoyi.common.core.page.TableDataInfo;

/**
 * 知识文章评论Controller
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/train/knowledge/comment")
public class TrainKnowledgeCommentController extends BaseController {
    
    @Autowired
    private ITrainKnowledgeCommentService commentService;

    /**
     * 查询文章评论列表
     */
    @GetMapping("/{articleId}")
    public TableDataInfo list(@PathVariable Long articleId) {
        startPage();
        List<TrainKnowledgeComment> list = commentService.listComments(articleId);
        return getDataTable(list);
    }

    /**
     * 添加评论
     */
    @Log(title = "文章评论", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody TrainKnowledgeComment comment) {
        SysUser user = SecurityUtils.getLoginUser().getUser();
        comment.setUserId(user.getUserId());
        comment.setUserName(user.getNickName());
        comment.setUserAvatar(user.getAvatar());
        
        // 判断是否领导（这里简化处理，实际应该根据角色判断）
        // 可以通过角色key判断，例如：leader、manager等
        boolean isLeader = SecurityUtils.getLoginUser().getUser().isAdmin() || 
                          hasRole("leader") || hasRole("manager");
        
        return toAjax(commentService.addComment(comment, isLeader));
    }

    /**
     * 删除评论
     */
    @Log(title = "文章评论", businessType = BusinessType.DELETE)
    @DeleteMapping("/{commentId}")
    public AjaxResult remove(@PathVariable Long commentId) {
        Long userId = SecurityUtils.getUserId();
        boolean isAdmin = SecurityUtils.getLoginUser().getUser().isAdmin();
        return toAjax(commentService.deleteComment(commentId, userId, isAdmin));
    }
    
    /**
     * 判断用户是否有指定角色
     */
    private boolean hasRole(String roleKey) {
        return SecurityUtils.getLoginUser().getUser().getRoles().stream()
                .anyMatch(role -> roleKey.equals(role.getRoleKey()));
    }
}
