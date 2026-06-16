package com.ruoyi.web.controller.open;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.annotation.Anonymous;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.system.service.ISysInvitationService;

@Anonymous
@RestController
@RequestMapping("/open/invite")
public class OpenInvitationController extends BaseController
{
    @Autowired
    private ISysInvitationService invitationService;

    @GetMapping("/resolve")
    public AjaxResult resolve(@RequestParam(value = "inviteCode", required = false) String inviteCode,
            @RequestParam(value = "inviteToken", required = false) String inviteToken,
            @RequestParam(value = "scenario", required = false) String scenario)
    {
        String resolveScenario = StringUtils.isEmpty(scenario) ? "register" : scenario;
        return success(invitationService.resolveInvitation(inviteCode, inviteToken, resolveScenario));
    }
}
