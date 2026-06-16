package com.ruoyi.web.controller.train;

import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import java.util.HashMap;

import com.ruoyi.common.core.domain.entity.SysDept;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.system.service.ISysDeptService;
import com.ruoyi.system.service.ISysUserService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.train.domain.TrainKnowledgeArticle;
import com.ruoyi.train.service.ITrainKnowledgeArticleService;
import com.ruoyi.train.service.ITrainKnowledgeReadLogService;
import com.ruoyi.common.core.page.TableDataInfo;

/**
 * 知识文章Controller
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/train/knowledge/article")
public class TrainKnowledgeArticleController extends BaseController {
    
    @Autowired
    private ITrainKnowledgeArticleService articleService;
    
    @Autowired
    private ISysDeptService deptService;

    @Autowired
    private ISysUserService userService;

    @Autowired
    private ITrainKnowledgeReadLogService readLogService;

    /**
     * 查询知识文章列表
     */
    @GetMapping("/list")
    public TableDataInfo list(TrainKnowledgeArticle article) {
        SysUser user = SecurityUtils.getLoginUser().getUser();
        boolean privileged = user != null && user.canManageAllTenants();
        if (!privileged) {
            String tenantId = user != null ? user.getTenantId() : null;
            article.setTenantId(tenantId);
        } else {
            String tenantId = article.getTenantId();
            if (tenantId != null && tenantId.isEmpty()) {
                article.setTenantId(null);
            }
        }
        
        startPage();
        List<TrainKnowledgeArticle> list = articleService.listArticles(article);
        return getDataTable(list);
    }

    /**
     * 搜索知识文章
     */
    @GetMapping("/search")
    public TableDataInfo search(@RequestParam(required = false) String keyword,
                                @RequestParam(required = false) String status,
                                @RequestParam(required = false) String tenantId) {
        SysUser user = SecurityUtils.getLoginUser().getUser();
        boolean privileged = user != null && user.canManageAllTenants();
        String effectiveTenantId = privileged ? tenantId : (user != null ? user.getTenantId() : null);
        String effectiveStatus = privileged ? status : "published";

        startPage();
        List<TrainKnowledgeArticle> list = articleService.searchArticles(effectiveTenantId, keyword, effectiveStatus);
        return getDataTable(list);
    }

    /**
     * 查询我的文章列表
     */
    @GetMapping("/my")
    public TableDataInfo myArticles(@RequestParam(required = false) String status) {
        Long userId = SecurityUtils.getUserId();
        logger.debug("查询我的文章 userId={}, status={}", userId, status);
        startPage();
        List<TrainKnowledgeArticle> list = articleService.listMyArticles(userId, status);
        return getDataTable(list);
    }

    /**
     * 获取知识文章详细信息
     */
    @GetMapping("/{articleId}")
    public AjaxResult getInfo(@PathVariable Long articleId) {
        Long userId = SecurityUtils.getUserId();
        TrainKnowledgeArticle article = articleService.getArticleDetail(articleId, userId);
        
        // 检查权限：草稿只能作者查看
        if ("draft".equals(article.getStatus()) && !article.getAuthorId().equals(userId)) {
            return error("无权访问此文章");
        }
        
        return success(article);
    }

    /**
     * 新增知识文章
     */
    @Log(title = "知识文章", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody TrainKnowledgeArticle article) {
        SysUser user = SecurityUtils.getLoginUser().getUser();
        article.setAuthorId(user.getUserId());
        article.setAuthorName(user.getNickName());

        // 根据发布范围设置 tenant_id
        String publishScope = article.getPublishScope();
        if ("platform".equals(publishScope)) {
            // 全平台发布：只有超管/平台管理员可以
            if (user.isSuperAdmin() || user.isPlatformAdmin()) {
                article.setTenantId("000000"); // 公共数据
            } else {
                return error("只有平台管理员可以发布全平台文章");
            }
        } else {
            // 本租户发布
            article.setPublishScope("tenant");
            article.setTenantId(user.getTenantId());
        }

        // 设置部门信息（用于部门隔离审核）
        article.setDeptId(user.getDeptId());
        if (user.getDeptId() != null) {
            SysDept dept = deptService.selectDeptById(user.getDeptId());
            if (dept != null) {
                article.setDeptName(dept.getDeptName());
            }
        }

        return toAjax(articleService.createArticle(article));
    }

    /**
     * 修改知识文章
     */
    @Log(title = "知识文章", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody TrainKnowledgeArticle article) {
        Long userId = SecurityUtils.getUserId();
        return toAjax(articleService.updateArticle(article, userId));
    }

    /**
     * 设置文章置顶
     */
    @PreAuthorize("@ss.hasPermi('train:knowledge:manage')")
    @Log(title = "知识文章置顶", businessType = BusinessType.UPDATE)
    @PutMapping("/top/{articleId}")
    public AjaxResult setTop(@PathVariable Long articleId, @RequestParam Integer isTop) {
        return toAjax(articleService.setTop(articleId, isTop));
    }

    /**
     * 删除知识文章
     */
    @Log(title = "知识文章", businessType = BusinessType.DELETE)
    @DeleteMapping("/{articleId}")
    public AjaxResult remove(@PathVariable Long articleId) {
        Long userId = SecurityUtils.getUserId();
        boolean isAdmin = SecurityUtils.getLoginUser().getUser().canManageAllTenants();
        return toAjax(articleService.deleteArticle(articleId, userId, isAdmin));
    }

    /**
     * 增加浏览次数
     */
    @PostMapping("/{articleId}/view")
    public AjaxResult incrementView(@PathVariable Long articleId) {
        return toAjax(articleService.incrementViewCount(articleId));
    }

    /**
     * 获取未读用户列表
     */
    @GetMapping("/{articleId}/unread-users")
    public AjaxResult getUnreadUsers(@PathVariable Long articleId) {
        Long userId = SecurityUtils.getUserId();
        
        // 1. 获取文章详情，确认权限（只有作者或管理员可以查看）
        TrainKnowledgeArticle article = articleService.getArticleDetail(articleId, userId);
        boolean isAdmin = SecurityUtils.getLoginUser().getUser().canManageAllTenants();
        
        if (!isAdmin && !article.getAuthorId().equals(userId)) {
            return error("无权查看此数据");
        }
        
        // 2. 获取文章已读用户ID列表
        List<Long> readUserIds = readLogService.getReadUserIds(articleId);
        
        // 3. 获取作者所在部门的所有下级用户
        // 如果是管理员，或者文章没有部门信息，则查询所有用户（这里假设文章必须有部门信息才能统计下级）
        // 实际上，我们应该查询作者所在部门及其子部门的所有用户
        
        SysUser queryUser = new SysUser();
        queryUser.setTenantId(article.getTenantId());
        
        // 如果不是管理员，且文章有部门ID，则限定查询该部门及子部门的用户
        if (!isAdmin && article.getDeptId() != null) {
            queryUser.setDeptId(article.getDeptId());
        }
        
        List<SysUser> allUsers = userService.selectUserList(queryUser);
        
        // 4. 过滤出未读用户
        List<Map<String, Object>> unreadUsers = new ArrayList<>();
        
        for (SysUser user : allUsers) {
            // 排除作者自己
            if (user.getUserId().equals(article.getAuthorId())) {
                continue;
            }
            // 排除已读用户
            if (readUserIds.contains(user.getUserId())) {
                continue;
            }
            
            Map<String, Object> userInfo = new HashMap<>();
            userInfo.put("userId", user.getUserId());
            userInfo.put("userName", user.getUserName());
            userInfo.put("nickName", user.getNickName());
            userInfo.put("deptName", user.getDept() != null ? user.getDept().getDeptName() : "");
            unreadUsers.add(userInfo);
        }
        
        return success(unreadUsers);
    }
}
