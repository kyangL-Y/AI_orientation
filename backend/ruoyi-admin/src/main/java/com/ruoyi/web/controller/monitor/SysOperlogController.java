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
import com.ruoyi.system.domain.SysOperLog;
import com.ruoyi.system.service.ISysOperLogService;

/**
 * 操作日志记录
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/monitor/operlog")
public class SysOperlogController extends BaseController
{
    @Autowired
    private ISysOperLogService operLogService;

    @PreAuthorize("@ss.hasPermi('monitor:operlog:list')")
    @GetMapping("/list")
    public TableDataInfo list(SysOperLog operLog)
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
                    operLog.setOperName(loginUser.getUser().getUserName());
                } else {
                    // 集团/公司管理员看自己租户的日志
                    String tenantId = loginUser.getUser().getTenantId();
                    if (tenantId != null && !tenantId.isEmpty()) {
                        operLog.setTenantId(tenantId);
                    }
                }
            }
        }
        
        startPage();
        List<SysOperLog> list = operLogService.selectOperLogList(operLog);
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
    
    /**
     * 测试接口 - 直接查询不分页
     */
    @GetMapping("/test")
    public AjaxResult test()
    {
        logger.info("📋 测试接口被调用");
        List<SysOperLog> list = operLogService.selectOperLogList(new SysOperLog());
        logger.info("📋 测试查询结果数量: {}", list.size());
        return success("查询到 " + list.size() + " 条记录");
    }

    @Log(title = "操作日志", businessType = BusinessType.EXPORT)
    @PreAuthorize("@ss.hasPermi('monitor:operlog:export')")
    @PostMapping("/export")
    public void export(HttpServletResponse response, SysOperLog operLog)
    {
        // 非超级管理员只能导出自己租户的日志
        LoginUser loginUser = SecurityUtils.getLoginUser();
        if (loginUser != null && loginUser.getUser() != null) {
            Long userId = loginUser.getUserId();
            String tenantId = loginUser.getUser().getTenantId();
            if (userId != 1L && tenantId != null && !tenantId.isEmpty()) {
                operLog.setTenantId(tenantId);
            }
        }
        
        List<SysOperLog> list = operLogService.selectOperLogList(operLog);
        ExcelUtil<SysOperLog> util = new ExcelUtil<SysOperLog>(SysOperLog.class);
        util.exportExcel(response, list, "操作日志");
    }

    @Log(title = "操作日志", businessType = BusinessType.DELETE)
    @PreAuthorize("@ss.hasPermi('monitor:operlog:remove')")
    @DeleteMapping("/{operIds}")
    public AjaxResult remove(@PathVariable Long[] operIds)
    {
        return toAjax(operLogService.deleteOperLogByIds(operIds));
    }

    @Log(title = "操作日志", businessType = BusinessType.CLEAN)
    @PreAuthorize("@ss.hasPermi('monitor:operlog:remove')")
    @DeleteMapping("/clean")
    public AjaxResult clean()
    {
        operLogService.cleanOperLog();
        return success();
    }
}
