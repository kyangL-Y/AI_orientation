package com.ruoyi.web.controller.train;

import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.constant.MembershipLimitConstants;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.train.domain.TrainUserMembership;
import com.ruoyi.train.service.IMembershipService;
import com.ruoyi.system.service.ISysUserService;
import com.ruoyi.common.core.domain.entity.SysUser;

/**
 * 用户会员Controller
 * 
 * @author ruoyi
 * @date 2026-01-14
 */
@RestController
@RequestMapping("/train/membership/user")
public class UserMembershipController extends BaseController
{
    private static final Logger logger = LoggerFactory.getLogger(UserMembershipController.class);

    @Autowired
    private IMembershipService membershipService;
    
    @Autowired
    private ISysUserService userService;

    /**
     * 获取当前用户会员信息
     */
    @GetMapping("/info")
    public AjaxResult getMyMembership()
    {
        Long userId = SecurityUtils.getUserId();
        TrainUserMembership membership = membershipService.getUserMembershipInfo(userId);
        return AjaxResult.success(membership);
    }

    /**
     * 获取会员限制配置（用户侧使用）
     */
    @GetMapping("/limits")
    public AjaxResult getUsageLimits()
    {
        java.util.Map<String, Object> limits = new java.util.HashMap<>();
        limits.put("freePracticeDailyLimit", MembershipLimitConstants.FREE_PRACTICE_DAILY_LIMIT);
        limits.put("freeAiDailyLimit", MembershipLimitConstants.FREE_AI_DAILY_LIMIT);
        limits.put("freeQuizDailyLimit", MembershipLimitConstants.FREE_QUIZ_DAILY_LIMIT);
        return AjaxResult.success(limits);
    }
    
    /**
     * 获取指定用户的有效会员信息
     */
    @PreAuthorize("@ss.hasAnyPermi('system:user:query,system:user:list')")
    @GetMapping("/active/{userId}")
    public AjaxResult getActiveMembership(@PathVariable Long userId)
    {
        userService.checkUserDataScope(userId);
        TrainUserMembership membership = membershipService.getUserMembership(userId);
        return AjaxResult.success(membership);
    }
    
    /**
     * 检查当前用户是否有权限访问内容
     */
    @GetMapping("/check-access")
    public AjaxResult checkAccess(@RequestParam String contentType, @RequestParam Long contentId)
    {
        Long userId = SecurityUtils.getUserId();
        boolean hasAccess = membershipService.checkContentAccess(userId, contentType, contentId);
        return AjaxResult.success(hasAccess);
    }
    
    /**
     * 查询会员列表（管理端）
     */
    @PreAuthorize("@ss.hasPermi('train:membership:list')")
    @GetMapping("/list")
    public TableDataInfo list(TrainUserMembership query)
    {
        startPage();
        List<Map<String, Object>> list = membershipService.selectMembershipList(query);
        return getDataTable(list);
    }
    
    /**
     * 查询会员统计（管理端）
     */
    @PreAuthorize("@ss.hasPermi('train:membership:list')")
    @GetMapping("/stats")
    public AjaxResult stats(TrainUserMembership query)
    {
        Map<String, Object> stats = membershipService.selectMembershipStats(query);
        return AjaxResult.success(stats);
    }

    /**
     * 获取可选用户列表（未开通会员的用户）
     */
    @PreAuthorize("@ss.hasPermi('train:membership:list')")
    @GetMapping("/available-users")
    public AjaxResult getAvailableUsers()
    {
        SysUser query = new SysUser();
        query.setStatus("0"); // 只查询正常状态的用户
        List<SysUser> users = userService.selectUserList(query);
        return AjaxResult.success(users);
    }
    
    /**
     * 开通会员
     */
    @PreAuthorize("@ss.hasPermi('train:membership:add')")
    @Log(title = "用户会员", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody TrainUserMembership membership)
    {
        try
        {
            membership.setSource(normalizeSource(membership.getSource()));
            membership.setCreateBy(getUsername());
            return toAjax(membershipService.createMembership(membership));
        }
        catch (Exception e)
        {
            logger.warn("开通会员失败 userId={}", membership.getUserId(), e);
            return error(e.getMessage());
        }
    }
    
    /**
     * 续费会员
     */
    @PreAuthorize("@ss.hasPermi('train:membership:edit')")
    @Log(title = "用户会员", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody TrainUserMembership membership)
    {
        membership.setSource(normalizeSource(membership.getSource()));
        membership.setUpdateBy(getUsername());
        return toAjax(membershipService.renewMembership(membership));
    }
    
    /**
     * 取消会员
     */
    @PreAuthorize("@ss.hasPermi('train:membership:remove')")
    @Log(title = "用户会员", businessType = BusinessType.DELETE)
    @DeleteMapping("/{membershipId}")
    public AjaxResult remove(@PathVariable Long membershipId)
    {
        return toAjax(membershipService.cancelMembership(membershipId));
    }
    
    /**
     * 批量开通会员（支持按用户、部门、公司、租户）
     */
    @PreAuthorize("@ss.hasPermi('train:membership:add')")
    @Log(title = "批量开通会员", businessType = BusinessType.INSERT)
    @PostMapping("/batch-preview")
    public AjaxResult batchPreview(@RequestBody java.util.Map<String, Object> params)
    {
        try
        {
            return success(membershipService.previewBatchMembership(params));
        }
        catch (Exception e)
        {
            logger.warn("批量开通会员预览失败 params={}", params, e);
            return error(e.getMessage());
        }
    }

    /**
     * 批量开通会员（支持按用户、部门、公司、租户）
     */
    @PreAuthorize("@ss.hasPermi('train:membership:add')")
    @Log(title = "批量开通会员", businessType = BusinessType.INSERT)
    @PostMapping("/batch")
    public AjaxResult batchAdd(@RequestBody java.util.Map<String, Object> params)
    {
        try
        {
            String scope = (String) params.get("scope");
            String levelCode = (String) params.get("levelCode");
            Integer duration = params.get("duration") != null ? Integer.parseInt(params.get("duration").toString()) : 365;
            String source = (String) params.getOrDefault("source", "gift");
            source = normalizeSource(source);
            String tenantId = params.get("tenantId") != null ? params.get("tenantId").toString() : null;

            if (levelCode == null || levelCode.isEmpty()) {
                return error("请选择会员等级");
            }

            java.util.List<Long> userIds = new java.util.ArrayList<>();

            if ("user".equals(scope)) {
                Object userIdObj = params.get("userId");
                if (userIdObj == null) {
                    return error("请选择用户");
                }
                userIds.add(Long.parseLong(userIdObj.toString()));
            } else if ("dept".equals(scope)) {
                Object deptIdObj = params.get("deptId");
                if (deptIdObj == null) {
                    return error("请选择部门");
                }
                Long deptId = Long.parseLong(deptIdObj.toString());
                userIds = membershipService.getUserIdsByDept(deptId);
            } else if ("company".equals(scope)) {
                Object companyIdObj = params.get("companyId");
                if (companyIdObj == null) {
                    return error("请选择公司");
                }
                Long companyId = Long.parseLong(companyIdObj.toString());
                userIds = membershipService.getUserIdsByCompany(companyId);
            } else if ("tenant".equals(scope)) {
                if (tenantId != null && !tenantId.isEmpty()) {
                    userIds = membershipService.getUserIdsByTenantId(tenantId);
                } else {
                    userIds = membershipService.getUserIdsByTenant();
                }
            } else {
                return error("无效的开通范围");
            }

            logger.info("批量开通会员 scope={}, tenantId={}, userCount={}", scope, tenantId, userIds != null ? userIds.size() : 0);

            if (userIds == null || userIds.isEmpty()) {
                return error("未找到符合条件的用户");
            }

            Map<String, Object> summary = membershipService.batchCreateMembershipWithSummary(userIds, levelCode, duration, source, getUsername());
            int successCount = summary.get("successCount") instanceof Number ? ((Number) summary.get("successCount")).intValue() : 0;
            int createdCount = summary.get("createdCount") instanceof Number ? ((Number) summary.get("createdCount")).intValue() : 0;
            int renewedCount = summary.get("renewedCount") instanceof Number ? ((Number) summary.get("renewedCount")).intValue() : 0;
            int failedCount = summary.get("failedCount") instanceof Number ? ((Number) summary.get("failedCount")).intValue() : 0;

            summary.put("scope", scope);
            summary.put("scopeLabel", "user".equals(scope) ? "指定用户" : "dept".equals(scope) ? "按部门" : "company".equals(scope) ? "按公司" : "整个租户");
            String msg = "共处理 " + userIds.size() + " 人，成功 " + successCount + " 人";
            if (createdCount > 0) {
                msg += "，新开通 " + createdCount + " 人";
            }
            if (renewedCount > 0) {
                msg += "，续费 " + renewedCount + " 人";
            }
            if (failedCount > 0) {
                msg += "，失败 " + failedCount + " 人";
            }
            if (successCount <= 0) {
                msg = "未成功开通任何用户";
                if (failedCount > 0) {
                    msg += "，失败 " + failedCount + " 人";
                }
                summary.put("resultStatus", "failed");
            } else if (failedCount > 0) {
                summary.put("resultStatus", "partial");
            } else {
                summary.put("resultStatus", "success");
            }
            return AjaxResult.success(msg, summary);
        }
        catch (Exception e)
        {
            logger.warn("批量开通会员失败 params={}", params, e);
            return error(e.getMessage());
        }
    }

    private String normalizeSource(String source)
    {
        if (source == null) {
            return "gift";
        }
        String normalized = source.trim().toLowerCase();
        if ("purchase".equals(normalized) || "gift".equals(normalized) || "trial".equals(normalized)) {
            return normalized;
        }
        return "gift";
    }
}
