package com.ruoyi.web.controller.system;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.annotation.Anonymous;
import com.ruoyi.common.constant.Constants;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysDept;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.tenant.TenantContextHolder;
import com.ruoyi.common.core.domain.model.LoginBody;
import com.ruoyi.common.core.domain.model.RegisterBody;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.framework.web.service.SysLoginService;
import com.ruoyi.framework.web.service.SysRegisterService;
import com.ruoyi.framework.web.service.UserProfileCompletionService;
import com.ruoyi.system.service.ISysConfigService;
import com.ruoyi.system.service.ISysDeptService;
import com.ruoyi.system.service.ISysTenantService;
import com.ruoyi.system.service.ISysUserService;
import com.ruoyi.system.domain.SysTenant;

/**
 * 注册验证
 * 
 * @author ruoyi
 */
@RestController
public class SysRegisterController extends BaseController
{
    @Autowired
    private SysRegisterService registerService;

    @Autowired
    private ISysConfigService configService;

    @Autowired
    private SysLoginService loginService;

    @Autowired
    private ISysUserService userService;

    @Autowired
    private ISysTenantService tenantService;

    @Autowired
    private ISysDeptService deptService;

    @Autowired
    private UserProfileCompletionService profileCompletionService;

    @Anonymous
    @PostMapping("/register")
    public AjaxResult register(@RequestBody RegisterBody user)
    {
        if (!("true".equals(configService.selectConfigByKey("sys.account.registerUser"))))
        {
            return error("当前系统没有开启注册功能！");
        }
        String msg = registerService.register(user);
        return buildRegisterResult(user, msg);
    }

    @Anonymous
    @PostMapping("/register/invite")
    public AjaxResult registerByInvitation(@RequestBody RegisterBody user)
    {
        if (!("true".equals(configService.selectConfigByKey("sys.account.registerUser"))))
        {
            return error("当前系统没有开启注册功能！");
        }
        String msg = registerService.registerByInvitation(user);
        return buildRegisterResult(user, msg);
    }

    private AjaxResult buildRegisterResult(RegisterBody user, String msg)
    {
        if (StringUtils.isEmpty(msg))
        {
            // 注册成功，自动登录
            try {
                String loginName = StringUtils.trim(user.getPhonenumber());
                if (StringUtils.isEmpty(loginName)) {
                    loginName = StringUtils.trim(user.getEmail());
                }
                if (StringUtils.isEmpty(loginName)) {
                    loginName = StringUtils.trim(user.getUsername());
                }
                SysUser currentUser = userService.selectUserByLoginName(loginName);
                if (currentUser != null && StringUtils.isNotEmpty(currentUser.getTenantId()))
                {
                    TenantContextHolder.setTenantId(currentUser.getTenantId());
                }
                String token = loginService.loginWithoutCaptcha(loginName, user.getPassword());
                AjaxResult ajax = AjaxResult.success();
                ajax.put(Constants.TOKEN, token);
                if (currentUser != null)
                {
                    if (StringUtils.isNotEmpty(currentUser.getTenantId()))
                    {
                        ajax.put("tenantId", currentUser.getTenantId());
                        SysTenant tenant = tenantService.selectSysTenantByTenantId(currentUser.getTenantId());
                        if (tenant != null)
                        {
                            ajax.put("tenantName", tenant.getTenantName());
                            ajax.put("companyName", tenant.getTenantName());
                        }
                    }
                    if (currentUser.getDeptId() != null)
                    {
                        SysDept dept = deptService.selectDeptById(currentUser.getDeptId());
                        if (dept != null)
                        {
                            ajax.put("deptId", currentUser.getDeptId());
                            ajax.put("deptName", dept.getDeptName());
                        }
                    }
                    ajax.put("profileCompletion", profileCompletionService.buildProfileCompletion(currentUser));
                }
                ajax.put("msg", "注册成功，自动登录中...");
                return ajax;
            } catch (Exception e) {
                logger.warn("注册成功后自动登录失败", e);
                // 自动登录失败，返回注册成功提示
                return success("注册成功，请手动登录");
            } finally {
                TenantContextHolder.clear();
            }
        }
        return error(msg);
    }
}
