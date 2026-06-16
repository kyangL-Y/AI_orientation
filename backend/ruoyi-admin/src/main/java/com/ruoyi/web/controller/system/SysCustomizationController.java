package com.ruoyi.web.controller.system;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.system.domain.SysTenantCustomization;
import com.ruoyi.system.service.ISysTenantCustomizationService;

/**
 * 系统定制化配置Controller（用户端使用）
 */
@RestController
@RequestMapping("/system/customization")
public class SysCustomizationController extends BaseController {

    @Autowired
    private ISysTenantCustomizationService customizationService;

    /**
     * 获取当前登录用户所属租户的配置
     */
    @GetMapping("/my-config")
    public AjaxResult getMyConfig() {
        SysUser user = getLoginUser().getUser();
        String tenantId = user.getTenantId();
        SysTenantCustomization config = null;
        if (tenantId != null && !tenantId.isEmpty()) {
            config = customizationService.selectSysTenantCustomizationByTenantId(tenantId);
        }
        if (config == null) {
            // 返回空的默认配置
            config = new SysTenantCustomization();
            config.setTenantId(tenantId);
            config.setThemeColor("#1890ff");
            config.setCompanyName("培训系统");
        }
        return success(config);
    }
}
