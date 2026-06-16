package com.ruoyi.web.controller.open;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.tenant.TenantContextHolder;
import com.ruoyi.system.domain.SysTenantCustomization;
import com.ruoyi.system.service.ISysTenantCustomizationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * 公开的定制化配置接口（无需登录）
 */
@RestController
@RequestMapping("/open/customization")
public class OpenCustomizationController {

    private static final Logger logger = LoggerFactory.getLogger(OpenCustomizationController.class);

    @Autowired
    private ISysTenantCustomizationService customizationService;

    /**
     * 获取默认/公共配置（公开接口，无需登录）
     * 用于用户端未登录时显示酒店介绍页
     */
    @GetMapping("/default-config")
    public AjaxResult getDefaultConfig(
            @RequestHeader(value = "Tenant-Id", required = false) String tenantIdHeader,
            @RequestParam(value = "tenantId", required = false) String tenantIdParam) {
        String tenantId = null;
        if (tenantIdParam != null && !tenantIdParam.trim().isEmpty()) {
            tenantId = tenantIdParam.trim();
        } else if (tenantIdHeader != null && !tenantIdHeader.trim().isEmpty()) {
            tenantId = tenantIdHeader.trim();
        } else {
            String ctxTenantId = TenantContextHolder.getTenantId();
            if (ctxTenantId != null && !ctxTenantId.trim().isEmpty()) {
                tenantId = ctxTenantId.trim();
            } else {
                tenantId = "000000";
            }
        }

        SysTenantCustomization config = customizationService.selectSysTenantCustomizationByTenantId(tenantId);
        
        if (config == null) {
            config = new SysTenantCustomization();
            config.setTenantId(tenantId);
            config.setThemeColor("#1890ff");
            config.setCompanyName("培训系统");
            logger.info("公开接口返回默认空配置 tenantId={}", tenantId);
        } else {
            if (logger.isDebugEnabled()) {
                String pages = config.getCustomPagesConfig();
                int len = pages == null ? 0 : pages.length();
                String preview = pages == null ? "" : pages.substring(0, Math.min(200, len));
                logger.debug("公开接口获取默认配置 tenantId={}, id={}, customPagesConfigLen={}, preview={}", tenantId, config.getId(), len, preview);
            } else {
                logger.info("公开接口获取默认配置 tenantId={}, id={}", tenantId, config.getId());
            }
        }
        
        return AjaxResult.success(config);
    }
}
