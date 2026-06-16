package com.ruoyi.web.controller.system;

import java.util.List;
import javax.servlet.http.HttpServletResponse;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.annotation.Anonymous;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.system.domain.SysTenant;
import com.ruoyi.system.service.ISysTenantService;
import com.ruoyi.common.core.page.TableDataInfo;

/**
 * 租户信息Controller
 * 
 * @author ruoyi
 * @date 2025-12-04
 */
@RestController
@RequestMapping("/system/tenant")
public class SysTenantController extends BaseController
{
    @Autowired
    private ISysTenantService sysTenantService;

    /**
     * 获取可用租户列表（公开接口，供注册时选择）
     * 不包含超级管理员租户(000000)
     */
    @Anonymous
    @GetMapping("/options")
    public AjaxResult getOptions()
    {
        SysTenant query = new SysTenant();
        query.setStatus("0"); // 只查询正常状态的租户
        List<SysTenant> list = sysTenantService.selectSysTenantList(query);
        // 过滤掉超级管理员租户
        list.removeIf(t -> "000000".equals(t.getTenantId()));
        return success(list);
    }

    /**
     * 查询租户信息列表
     */
    @PreAuthorize("@ss.hasPermi('system:tenant:list')")
    @GetMapping("/list")
    public TableDataInfo list(SysTenant sysTenant)
    {
        startPage();
        List<SysTenant> list = sysTenantService.selectSysTenantList(sysTenant);
        return getDataTable(list);
    }

    /**
     * 获取租户信息详细信息
     */
    @PreAuthorize("@ss.hasPermi('system:tenant:query')")
    @GetMapping(value = "/{tenantId}")
    public AjaxResult getInfo(@PathVariable("tenantId") String tenantId)
    {
        return success(sysTenantService.selectSysTenantByTenantId(tenantId));
    }

    /**
     * 新增租户信息
     */
    @PreAuthorize("@ss.hasPermi('system:tenant:add')")
    @Log(title = "租户信息", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody SysTenant sysTenant)
    {
        return toAjax(sysTenantService.insertSysTenant(sysTenant));
    }

    /**
     * 修改租户信息
     */
    @PreAuthorize("@ss.hasPermi('system:tenant:edit')")
    @Log(title = "租户信息", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody SysTenant sysTenant)
    {
        return toAjax(sysTenantService.updateSysTenant(sysTenant));
    }

    /**
     * 删除租户信息
     */
    @PreAuthorize("@ss.hasPermi('system:tenant:remove')")
    @Log(title = "租户信息", businessType = BusinessType.DELETE)
	@DeleteMapping("/{tenantIds}")
    public AjaxResult remove(@PathVariable String[] tenantIds)
    {
        return toAjax(sysTenantService.deleteSysTenantByTenantIds(tenantIds));
    }
    
    /**
     * 初始化租户（创建新公司）
     */
    @PreAuthorize("@ss.hasPermi('system:tenant:add')")
    @PostMapping("/init")
    public AjaxResult initTenant(@RequestBody SysTenant sysTenant)
    {
        Long userId = SecurityUtils.getUserId();
        String tenantId = sysTenantService.initTenant(sysTenant.getTenantName(), userId);
        return success(tenantId);
    }

    /**
     * 加入租户
     */
    @PreAuthorize("@ss.hasPermi('system:tenant:edit')")
    @PostMapping("/join")
    public AjaxResult joinTenant(@RequestBody SysTenant sysTenant)
    {
        if (sysTenant == null || StringUtils.isEmpty(sysTenant.getTenantId())) {
            return error("租户ID不能为空");
        }
        SysTenant tenant = sysTenantService.selectSysTenantByTenantId(sysTenant.getTenantId());
        if (tenant == null) {
            return error("租户不存在");
        }
        if (!"0".equals(tenant.getStatus())) {
            return error("租户状态异常，无法加入");
        }
        Long userId = SecurityUtils.getUserId();
        // 这里需要从请求中获取deptId，暂时使用null
        return toAjax(sysTenantService.joinTenant(sysTenant.getTenantId(), null, userId));
    }

    /**
     * 获取当前用户可选择的租户列表
     */
    @GetMapping("/user-tenants")
    public AjaxResult getUserTenants()
    {
        Long userId = SecurityUtils.getUserId();
        List<SysTenant> list = sysTenantService.selectTenantsByUserId(userId);
        return success(list);
    }

    /**
     * 切换租户
     */
    @PostMapping("/switch/{tenantId}")
    public AjaxResult switchTenant(@PathVariable("tenantId") String tenantId)
    {
        Long userId = SecurityUtils.getUserId();
        // 验证用户是否有权限访问该租户
        if (!sysTenantService.checkUserTenantAccess(userId, tenantId)) {
            return error("您没有权限访问该租户");
        }
        return success();
    }

    /**
     * 获取当前租户信息
     */
    @GetMapping("/current")
    public AjaxResult getCurrentTenant()
    {
        // 从请求头获取当前租户ID
        String tenantId = com.ruoyi.common.core.tenant.TenantContextHolder.getTenantId();
        if (tenantId == null || tenantId.isEmpty()) {
            tenantId = "000000"; // 默认租户
        }
        SysTenant tenant = sysTenantService.selectSysTenantByTenantId(tenantId);
        return success(tenant);
    }

    /**
     * 获取租户的菜单ID列表
     */
    @PreAuthorize("@ss.hasPermi('system:tenant:query')")
    @GetMapping("/menus/{tenantId}")
    public AjaxResult getTenantMenus(@PathVariable("tenantId") String tenantId)
    {
        List<Long> menuIds = sysTenantService.selectTenantMenuIds(tenantId);
        return success(menuIds);
    }

    /**
     * 保存租户菜单配置
     */
    @PreAuthorize("@ss.hasPermi('system:tenant:edit')")
    @Log(title = "租户菜单配置", businessType = BusinessType.UPDATE)
    @PutMapping("/menus/{tenantId}")
    public AjaxResult saveTenantMenus(@PathVariable("tenantId") String tenantId, @RequestBody List<Long> menuIds)
    {
        return toAjax(sysTenantService.saveTenantMenus(tenantId, menuIds));
    }
}
