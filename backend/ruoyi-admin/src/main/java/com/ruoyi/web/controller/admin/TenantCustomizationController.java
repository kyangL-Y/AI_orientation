package com.ruoyi.web.controller.admin;

import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.system.domain.SysTenantCustomization;
import com.ruoyi.system.service.ISysTenantCustomizationService;

/**
 * 租户定制化配置Controller
 */
@RestController
@RequestMapping("/admin/customization")
public class TenantCustomizationController extends BaseController {

    private static final Logger log = LoggerFactory.getLogger(TenantCustomizationController.class);

    @Autowired
    private ISysTenantCustomizationService customizationService;

    private static final String DEFAULT_TENANT_ID = "000000";
    private static final String HUAZHI_TENANT_ID = "HZ001";

    /**
     * 查询租户定制化配置列表（超级管理员可查看所有）
     */
    @PreAuthorize("@ss.hasPermi('admin:customization:list')")
    @GetMapping("/list")
    public TableDataInfo list(SysTenantCustomization query) {
        startPage();
        List<SysTenantCustomization> list = customizationService.selectSysTenantCustomizationList(query);
        return getDataTable(list);
    }

    /**
     * 获取租户定制化配置详细信息
     */
    @PreAuthorize("@ss.hasPermi('admin:customization:query')")
    @GetMapping("/{id}")
    public AjaxResult getInfo(@PathVariable Long id) {
        return success(customizationService.selectSysTenantCustomizationById(id));
    }

    /**
     * 获取当前租户的配置（租户管理员使用）
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/my-config")
    public AjaxResult getMyConfig() {
        SysUser user = getLoginUser().getUser();
        String tenantId = user.getTenantId();

        if (tenantId == null || tenantId.isEmpty()) {
            return error("无法获取租户信息");
        }
        
        SysTenantCustomization config = customizationService.selectSysTenantCustomizationByTenantId(tenantId);
        
        if (config == null) {
            // 返回默认配置
            config = new SysTenantCustomization();
            config.setTenantId(tenantId);
            config.setThemeColor("#1890ff");
            config.setCompanyName("");
            config.setWelcomeMessage("欢迎使用培训系统");
        }
        
        return success(config);
    }

    /**
     * 获取默认/公共配置（公开接口，无需登录）
     * 用于用户端未登录时显示酒店介绍页
     * 返回 tenant_id = '000000' 的配置
     */
    @GetMapping("/default-config")
    public AjaxResult getDefaultConfig() {
        SysTenantCustomization config = customizationService.selectSysTenantCustomizationByTenantId("000000");
        if (config == null) {
            // 返回空的默认配置
            config = new SysTenantCustomization();
            config.setTenantId("000000");
            config.setThemeColor("#1890ff");
            config.setCompanyName("培训系统");
        }
        return success(config);
    }

    /**
     * 保存默认/公共配置（仅超级管理员 user_id=1 可用）
     * 保存 tenant_id = '000000' 的配置
     */
    @PreAuthorize("isAuthenticated()")
    @Log(title = "保存默认配置", businessType = BusinessType.UPDATE)
    @PostMapping("/save-default-config")
    public AjaxResult saveDefaultConfig(@RequestBody SysTenantCustomization config) {
        if (!canManageAllTenants()) {
            return error("只有超级管理员或平台管理员可以修改默认配置");
        }
        
        // 强制设置为默认租户ID
        config.setTenantId("000000");
        
        // 检查是否已有配置
        SysTenantCustomization existing = customizationService.selectSysTenantCustomizationByTenantId("000000");
        
        if (existing != null) {
            config.setId(existing.getId());
            config.setUpdateBy(getUsername());
            return toAjax(customizationService.updateSysTenantCustomization(config));
        } else {
            config.setCreateBy(getUsername());
            return toAjax(customizationService.insertSysTenantCustomization(config));
        }
    }

    /**
     * 获取指定租户的配置（仅超级管理员可用）
     */
    @GetMapping("/tenant-config/{tenantId}")
    public AjaxResult getTenantConfig(@PathVariable String tenantId) {
        if (!canManageAllTenants()) {
            return error("只有超级管理员或平台管理员可以查看其他租户配置");
        }
        
        SysTenantCustomization config = customizationService.selectSysTenantCustomizationByTenantId(tenantId);
        if (config == null) {
            // 返回空的默认配置
            config = new SysTenantCustomization();
            config.setTenantId(tenantId);
            config.setThemeColor("#1890ff");
            config.setCompanyName("");
        }
        return success(config);
    }

    /**
     * 保存指定租户的配置（仅超级管理员可用）
     */
    @PreAuthorize("isAuthenticated()")
    @Log(title = "保存租户配置", businessType = BusinessType.UPDATE)
    @PostMapping("/save-tenant-config")
    public AjaxResult saveTenantConfig(@RequestBody SysTenantCustomization config) {
        if (!canManageAllTenants()) {
            return error("只有超级管理员或平台管理员可以修改其他租户配置");
        }
        
        String tenantId = config.getTenantId();
        if (tenantId == null || tenantId.isEmpty()) {
            return error("租户ID不能为空");
        }
        
        // 检查是否已有配置
        SysTenantCustomization existing = customizationService.selectSysTenantCustomizationByTenantId(tenantId);
        
        if (existing != null) {
            config.setId(existing.getId());
            config.setUpdateBy(getUsername());
            return toAjax(customizationService.updateSysTenantCustomization(config));
        } else {
            config.setCreateBy(getUsername());
            return toAjax(customizationService.insertSysTenantCustomization(config));
        }
    }

    /**
     * 默认租户(000000)与华智租户(HZ001)之间同步酒店介绍页配置（仅超级管理员可用）
     */
    @PreAuthorize("isAuthenticated()")
    @Log(title = "同步酒店介绍页配置", businessType = BusinessType.UPDATE)
    @PostMapping("/sync-hotel-page")
    public AjaxResult syncHotelPage(@RequestBody SyncHotelPageRequest request) {
        if (!canManageAllTenants()) {
            return error("只有超级管理员或平台管理员可以同步配置");
        }
        if (request == null || request.getSourceTenantId() == null || request.getTargetTenantId() == null) {
            return error("同步参数不能为空");
        }

        String sourceTenantId = request.getSourceTenantId().trim();
        String targetTenantId = request.getTargetTenantId().trim();
        if (sourceTenantId.isEmpty() || targetTenantId.isEmpty()) {
            return error("同步参数不能为空");
        }
        if (sourceTenantId.equals(targetTenantId)) {
            return error("源租户与目标租户不能相同");
        }

        boolean isAllowedPair =
                (DEFAULT_TENANT_ID.equals(sourceTenantId) && HUAZHI_TENANT_ID.equals(targetTenantId)) ||
                (HUAZHI_TENANT_ID.equals(sourceTenantId) && DEFAULT_TENANT_ID.equals(targetTenantId));
        if (!isAllowedPair) {
            return error("仅允许默认租户与华智租户之间互相同步");
        }

        SysTenantCustomization source = customizationService.selectSysTenantCustomizationByTenantId(sourceTenantId);
        if (source == null || source.getHotelPageContent() == null || source.getHotelPageContent().trim().isEmpty()) {
            return error("源租户未配置酒店介绍页内容");
        }

        SysTenantCustomization existingTarget = customizationService.selectSysTenantCustomizationByTenantId(targetTenantId);
        SysTenantCustomization toSave = new SysTenantCustomization();
        toSave.setTenantId(targetTenantId);
        toSave.setHotelPageContent(source.getHotelPageContent());

        if (existingTarget != null) {
            toSave.setId(existingTarget.getId());
            toSave.setUpdateBy(getUsername());
            return toAjax(customizationService.updateSysTenantCustomization(toSave));
        }

        toSave.setCreateBy(getUsername());
        return toAjax(customizationService.insertSysTenantCustomization(toSave));
    }

    private boolean canManageAllTenants()
    {
        try
        {
            SysUser currentUser = SecurityUtils.getLoginUser().getUser();
            return currentUser != null && currentUser.canManageAllTenants();
        }
        catch (Exception e)
        {
            return false;
        }
    }

    /**
     * 新增租户定制化配置
     */
    @PreAuthorize("@ss.hasPermi('admin:customization:add')")
    @Log(title = "租户定制化配置", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody SysTenantCustomization config) {
        config.setCreateBy(getUsername());
        return toAjax(customizationService.insertSysTenantCustomization(config));
    }

    /**
     * 修改租户定制化配置
     */
    @PreAuthorize("@ss.hasPermi('admin:customization:edit')")
    @Log(title = "租户定制化配置", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody SysTenantCustomization config) {
        config.setUpdateBy(getUsername());
        return toAjax(customizationService.updateSysTenantCustomization(config));
    }

    /**
     * 保存当前租户的配置（租户管理员使用，自动关联租户ID）
     */
    @PreAuthorize("isAuthenticated()")
    @Log(title = "保存我的租户配置", businessType = BusinessType.UPDATE)
    @PostMapping("/save-my-config")
    public AjaxResult saveMyConfig(@RequestBody SysTenantCustomization config) {
        SysUser user = getLoginUser().getUser();
        String tenantId = user.getTenantId();

        if (tenantId == null || tenantId.isEmpty()) {
            return error("无法获取租户信息");
        }
        
        // 强制设置为当前租户ID，防止越权
        config.setTenantId(tenantId);
        
        // 检查是否已有配置
        SysTenantCustomization existing = customizationService.selectSysTenantCustomizationByTenantId(tenantId);
        
        if (existing != null) {
            config.setId(existing.getId());
            config.setUpdateBy(getUsername());
            int result = customizationService.updateSysTenantCustomization(config);
            log.debug("更新租户配置 tenantId={}, userId={}, result={}", tenantId, user.getUserId(), result);
            return toAjax(result);
        } else {
            config.setCreateBy(getUsername());
            int result = customizationService.insertSysTenantCustomization(config);
            log.debug("创建租户配置 tenantId={}, userId={}, result={}", tenantId, user.getUserId(), result);
            return toAjax(result);
        }
    }

    /**
     * 删除租户定制化配置
     */
    @PreAuthorize("@ss.hasPermi('admin:customization:remove')")
    @Log(title = "租户定制化配置", businessType = BusinessType.DELETE)
    @DeleteMapping("/{ids}")
    public AjaxResult remove(@PathVariable Long[] ids) {
        return toAjax(customizationService.deleteSysTenantCustomizationByIds(ids));
    }

    public static class SyncHotelPageRequest {
        private String sourceTenantId;
        private String targetTenantId;

        public String getSourceTenantId() {
            return sourceTenantId;
        }

        public void setSourceTenantId(String sourceTenantId) {
            this.sourceTenantId = sourceTenantId;
        }

        public String getTargetTenantId() {
            return targetTenantId;
        }

        public void setTargetTenantId(String targetTenantId) {
            this.targetTenantId = targetTenantId;
        }
    }
}
