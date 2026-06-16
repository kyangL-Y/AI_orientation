package com.ruoyi.web.controller.monitor;

import java.util.List;
import javax.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysRole;
import com.ruoyi.common.core.domain.model.LoginUser;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.common.utils.poi.ExcelUtil;
import com.ruoyi.framework.web.service.SysPasswordService;
import com.ruoyi.system.domain.SysLogininfor;
import com.ruoyi.system.service.ISysLogininforService;

/**
 * 系统访问记录
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/monitor/logininfor")
public class SysLogininforController extends BaseController
{
    @Autowired
    private ISysLogininforService logininforService;

    @Autowired
    private SysPasswordService passwordService;

    @PreAuthorize("@ss.hasPermi('monitor:logininfor:list')")
    @GetMapping("/list")
    public TableDataInfo list(SysLogininfor logininfor)
    {
        // 根据角色层级过滤日志
        // 超级管理员: 看所有日志
        // 集团/公司管理员: 看自己租户的日志
        // 部门管理员: 只看自己的日志
        LoginUser loginUser = SecurityUtils.getLoginUser();
        if (loginUser != null && loginUser.getUser() != null) {
            if (!loginUser.getUser().canManageAllTenants()) {
                String roleKey = getHighestRoleKey(loginUser);
                if ("dept_admin".equals(roleKey)) {
                    // 部门管理员只能看自己的日志
                    logininfor.setUserName(loginUser.getUser().getUserName());
                } else {
                    // 集团/公司管理员看自己租户的日志
                    String tenantId = loginUser.getUser().getTenantId();
                    if (tenantId != null && !tenantId.isEmpty()) {
                        logininfor.setTenantId(tenantId);
                    }
                }
            }
        }
        
        startPage();
        List<SysLogininfor> list = logininforService.selectLogininforList(logininfor);
        return getDataTable(list);
    }
    
    /**
     * 获取用户最高角色
     */
    private String getHighestRoleKey(LoginUser loginUser) {
        if (loginUser.getUser().getRoles() == null || loginUser.getUser().getRoles().isEmpty()) {
            return "common";
        }
        String[] roleOrder = {"admin", "platform", "tenant_admin", "company_admin", "dept_admin", "common"};
        for (String roleKey : roleOrder) {
            for (SysRole role : loginUser.getUser().getRoles()) {
                if (roleKey.equals(role.getRoleKey())) {
                    return roleKey;
                }
            }
        }
        return "common";
    }

    @Log(title = "登录日志", businessType = BusinessType.EXPORT)
    @PreAuthorize("@ss.hasPermi('monitor:logininfor:export')")
    @PostMapping("/export")
    public void export(HttpServletResponse response, SysLogininfor logininfor)
    {
        // 非超级管理员只能导出自己租户的登录日志
        LoginUser loginUser = SecurityUtils.getLoginUser();
        if (loginUser != null && loginUser.getUser() != null) {
            Long userId = loginUser.getUserId();
            String tenantId = loginUser.getUser().getTenantId();
            if (userId != 1L && tenantId != null && !tenantId.isEmpty()) {
                logininfor.setTenantId(tenantId);
            }
        }
        
        List<SysLogininfor> list = logininforService.selectLogininforList(logininfor);
        ExcelUtil<SysLogininfor> util = new ExcelUtil<SysLogininfor>(SysLogininfor.class);
        util.exportExcel(response, list, "登录日志");
    }

    @PreAuthorize("@ss.hasPermi('monitor:logininfor:remove')")
    @Log(title = "登录日志", businessType = BusinessType.DELETE)
    @DeleteMapping("/{infoIds}")
    public AjaxResult remove(@PathVariable Long[] infoIds)
    {
        return toAjax(logininforService.deleteLogininforByIds(infoIds));
    }

    @PreAuthorize("@ss.hasPermi('monitor:logininfor:remove')")
    @Log(title = "登录日志", businessType = BusinessType.CLEAN)
    @DeleteMapping("/clean")
    public AjaxResult clean()
    {
        logininforService.cleanLogininfor();
        return success();
    }

    @PreAuthorize("@ss.hasPermi('monitor:logininfor:unlock')")
    @Log(title = "账户解锁", businessType = BusinessType.OTHER)
    @GetMapping("/unlock/{userName}")
    public AjaxResult unlock(@PathVariable("userName") String userName)
    {
        passwordService.clearLoginRecordCache(userName);
        return success();
    }
}
