package com.ruoyi.web.controller.train;

import java.util.ArrayList;
import java.util.List;

import com.ruoyi.common.core.domain.entity.SysDept;
import com.ruoyi.common.core.domain.entity.SysRole;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.system.mapper.SysDeptMapper;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.train.domain.TrainKnowledgeArticle;
import com.ruoyi.train.service.ITrainKnowledgeReviewService;
import com.ruoyi.common.core.page.TableDataInfo;

/**
 * 知识文章审核Controller（支持分层级审核权限）
 *
 * 审核权限层级（从高到低）：
 * - 超管 (admin_level=0): 审核整个系统所有待审核文章
 * - 平台管理员 (admin_level=1): 审核整个系统所有待审核文章
 * - 集团管理员 (tenant_admin): 审核本租户/集团所有待审核文章
 * - 公司管理员 (company_admin): 审核本公司（及下级部门）所有待审核文章
 * - 部门管理员 (dept_admin): 审核本部门（及下级部门）所有待审核文章
 *
 * @author ruoyi
 */
@RestController
@RequestMapping("/train/knowledge/review")
public class TrainKnowledgeReviewController extends BaseController {

    @Autowired
    private ITrainKnowledgeReviewService reviewService;

    @Autowired
    private SysDeptMapper deptMapper;

    /**
     * 查询待审核文章列表（分层级权限控制）
     */
    @PreAuthorize("@ss.hasPermi('train:knowledge:review')")
    @GetMapping("/pending")
    public TableDataInfo pending() {
        SysUser user = SecurityUtils.getLoginUser().getUser();

        // 获取用户最高角色级别
        String highestRole = getHighestRoleKey(user);

        String tenantId = null;
        List<Long> deptIds = null;

        // 超管/平台管理员：查所有系统待审核文章
        if (user.isSuperAdmin() || user.isPlatformAdmin()) {
            tenantId = null;
            deptIds = null;
        }
        // 集团管理员(tenant_admin)：查本租户所有待审核文章
        else if ("tenant_admin".equals(highestRole)) {
            tenantId = user.getTenantId();
            deptIds = null;
        }
        // 公司管理员(company_admin) / 部门管理员(dept_admin)：查本部门及下级
        else if ("company_admin".equals(highestRole) || "dept_admin".equals(highestRole)) {
            tenantId = user.getTenantId();
            if (user.getDeptId() != null) {
                deptIds = getReviewableDeptIds(user.getDeptId());
            }
        }
        // 其他角色(common等)：也按部门限制
        else {
            tenantId = user.getTenantId();
            if (user.getDeptId() != null) {
                deptIds = getReviewableDeptIds(user.getDeptId());
            }
        }

        startPage();
        List<TrainKnowledgeArticle> list = reviewService.listPendingArticles(tenantId, deptIds);
        return getDataTable(list);
    }

    /**
     * 获取用户最高角色级别
     * 优先级: admin > platform > tenant_admin > company_admin > dept_admin > common
     */
    private String getHighestRoleKey(SysUser user) {
        if (user.getRoles() == null || user.getRoles().isEmpty()) {
            return "common";
        }
        String[] roleOrder = {"admin", "platform", "tenant_admin", "company_admin", "dept_admin", "common"};
        for (String roleKey : roleOrder) {
            for (SysRole role : user.getRoles()) {
                if (roleKey.equals(role.getRoleKey())) {
                    return roleKey;
                }
            }
        }
        return "common";
    }

    /**
     * 获取可审核的部门ID列表（本部门及所有下级部门）
     * 在Controller层调用，使用主库
     */
    private List<Long> getReviewableDeptIds(Long deptId) {
        List<Long> deptIds = new ArrayList<>();
        deptIds.add(deptId);

        // 查询下级部门（主库 hz-vue）
        List<SysDept> childDepts = deptMapper.selectChildrenDeptById(deptId);
        if (childDepts != null) {
            for (SysDept dept : childDepts) {
                deptIds.add(dept.getDeptId());
            }
        }

        return deptIds;
    }

    /**
     * 审核通过
     */
    @PreAuthorize("@ss.hasPermi('train:knowledge:review')")
    @Log(title = "知识文章审核", businessType = BusinessType.UPDATE)
    @PostMapping("/{articleId}/approve")
    public AjaxResult approve(@PathVariable Long articleId) {
        SysUser user = SecurityUtils.getLoginUser().getUser();
        
        return toAjax(reviewService.approveArticle(
            articleId, 
            user.getUserId(), 
            user.getNickName()
        ));
    }

    /**
     * 审核拒绝
     */
    @PreAuthorize("@ss.hasPermi('train:knowledge:review')")
    @Log(title = "知识文章审核", businessType = BusinessType.UPDATE)
    @PostMapping("/{articleId}/reject")
    public AjaxResult reject(@PathVariable Long articleId, @RequestBody String rejectReason) {
        SysUser user = SecurityUtils.getLoginUser().getUser();
        
        return toAjax(reviewService.rejectArticle(
            articleId, 
            user.getUserId(), 
            user.getNickName(), 
            rejectReason
        ));
    }
}
