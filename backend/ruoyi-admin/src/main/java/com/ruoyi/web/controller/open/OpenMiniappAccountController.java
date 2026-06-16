package com.ruoyi.web.controller.open;

import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.model.LoginUser;
import com.ruoyi.framework.web.service.MiniappAuthService;

/**
 * 小程序账号相关接口。
 */
@RestController
@RequestMapping("/miniapp/user")
public class OpenMiniappAccountController extends BaseController
{
    @Autowired
    private MiniappAuthService miniappAuthService;

    @GetMapping("/context")
    public AjaxResult context()
    {
        return success(miniappAuthService.buildCurrentContext(getLoginUser()));
    }

    @PostMapping("/accept-invite")
    public AjaxResult acceptInvite(@RequestBody Map<String, Object> request)
    {
        String inviteCode = request.get("inviteCode") == null ? null : String.valueOf(request.get("inviteCode"));
        String inviteToken = request.get("inviteToken") == null ? null : String.valueOf(request.get("inviteToken"));
        String deviceFingerprint = request.get("deviceFingerprint") == null ? null
                : String.valueOf(request.get("deviceFingerprint"));
        return success(miniappAuthService.acceptInvitation(getLoginUser(), inviteCode, inviteToken, deviceFingerprint));
    }

    @PutMapping("/profile")
    public AjaxResult updateProfile(@RequestBody Map<String, Object> request)
    {
        return success(miniappAuthService.updateProfile(getLoginUser(), request));
    }

    @GetMapping("/tenants")
    public AjaxResult tenants()
    {
        LoginUser loginUser = getLoginUser();
        AjaxResult ajax = success();
        ajax.put("joinedTenants", miniappAuthService.listJoinedTenants(loginUser));
        ajax.put("availableTenants", miniappAuthService.listAvailableTenants(loginUser));
        return ajax;
    }

    @GetMapping("/hotels")
    public AjaxResult hotels()
    {
        return success(miniappAuthService.listHotels(getLoginUser()));
    }
}
