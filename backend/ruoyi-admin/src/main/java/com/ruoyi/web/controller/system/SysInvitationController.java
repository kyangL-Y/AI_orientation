package com.ruoyi.web.controller.system;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.common.utils.ip.IpUtils;
import com.ruoyi.system.domain.SysInvitation;
import com.ruoyi.system.domain.SysInvitationRecord;
import com.ruoyi.system.domain.dto.InviteAcceptRequest;
import com.ruoyi.system.service.ISysInvitationService;

@RestController
@RequestMapping("/system/invite")
public class SysInvitationController extends BaseController
{
    @Autowired
    private ISysInvitationService invitationService;

    @PreAuthorize("@ss.hasPermi('system:tenant:query')")
    @GetMapping("/list")
    public TableDataInfo list(SysInvitation invitation)
    {
        bindCurrentTenant(invitation);
        startPage();
        List<SysInvitation> list = invitationService.selectInvitationList(invitation);
        return getDataTable(list);
    }

    @PreAuthorize("@ss.hasPermi('system:tenant:edit')")
    @Log(title = "租户邀请", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody SysInvitation invitation)
    {
        bindCurrentTenant(invitation);
        invitation.setInviterUserId(SecurityUtils.getUserId());
        invitation.setCreateBy(resolveUsername());
        return success(invitationService.createInvitation(invitation));
    }

    @PreAuthorize("@ss.hasPermi('system:tenant:edit')")
    @Log(title = "租户邀请", businessType = BusinessType.UPDATE)
    @PutMapping("/{inviteId}/status")
    public AjaxResult updateStatus(@PathVariable("inviteId") Long inviteId, @RequestBody SysInvitation invitation)
    {
        return toAjax(invitationService.updateInvitationStatus(inviteId, invitation.getStatus(), resolveUsername()));
    }

    @PreAuthorize("@ss.hasPermi('system:tenant:query')")
    @GetMapping("/{inviteId}/records")
    public AjaxResult records(@PathVariable("inviteId") Long inviteId)
    {
        List<SysInvitationRecord> records = invitationService.selectInvitationRecords(inviteId);
        return success(records);
    }

    @PostMapping("/accept")
    public AjaxResult accept(@RequestBody InviteAcceptRequest request)
    {
        return success(invitationService.acceptInvitation(SecurityUtils.getUserId(), request.getInviteCode(),
                request.getInviteToken(), IpUtils.getIpAddr(), request.getDeviceFingerprint()));
    }

    private void bindCurrentTenant(SysInvitation invitation)
    {
        SysUser currentUser = null;
        try
        {
            currentUser = SecurityUtils.getLoginUser().getUser();
        }
        catch (Exception e)
        {
            return;
        }
        if (currentUser == null)
        {
            return;
        }
        if (StringUtils.isEmpty(invitation.getTenantId()))
        {
            invitation.setTenantId(currentUser.getTenantId());
        }
    }

    private String resolveUsername()
    {
        try
        {
            return SecurityUtils.getUsername();
        }
        catch (Exception e)
        {
            return "system";
        }
    }
}
