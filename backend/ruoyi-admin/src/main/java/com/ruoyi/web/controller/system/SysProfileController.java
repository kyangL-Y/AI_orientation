package com.ruoyi.web.controller.system;

import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.annotation.Anonymous;
import com.ruoyi.common.config.RuoYiConfig;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.domain.model.LoginUser;
import com.ruoyi.common.core.domain.model.ProfileCompletionInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.utils.DateUtils;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.common.utils.file.FileUploadUtils;
import com.ruoyi.common.utils.file.FileUtils;
import com.ruoyi.common.utils.file.MimeTypeUtils;
import com.ruoyi.framework.web.service.TokenService;
import com.ruoyi.framework.web.service.UserProfileCompletionService;
import com.ruoyi.system.service.ISysDeptService;
import com.ruoyi.system.service.ISysTenantService;
import com.ruoyi.system.service.ITrainUserGuideOnboardingService;
import com.ruoyi.system.service.ISysUserService;
import com.ruoyi.common.core.domain.entity.SysDept;
import com.ruoyi.system.domain.SysTenant;

/**
 * 个人信息 业务处理
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/system/user/profile")
public class SysProfileController extends BaseController
{
    @Autowired
    private ISysUserService userService;

    @Autowired
    private TokenService tokenService;

    @Autowired
    private ISysDeptService deptService;

    @Autowired
    private ISysTenantService tenantService;

    @Autowired
    private ITrainUserGuideOnboardingService guideOnboardingService;

    @Autowired
    private UserProfileCompletionService profileCompletionService;

    /**
     * 个人信息
     */
    @GetMapping
    public AjaxResult profile()
    {
        try {
            LoginUser loginUser = getLoginUser();
            if (loginUser == null) {
                throw new RuntimeException("用户未登录");
            }
            SysUser user = loginUser.getUser();
            user.setGuideOnboarding(guideOnboardingService.buildClientState(user.getUserId()));
            
            // 获取部门和公司信息
            String deptName = null;
            String companyName = null;
            if (user.getDeptId() != null)
            {
                SysDept dept = deptService.selectDeptById(user.getDeptId());
                if (dept != null)
                {
                    // 判断是否为顶级部门（parent_id = 0）
                    if (dept.getParentId() == null || dept.getParentId() == 0)
                    {
                        // 顶级部门：当前部门就是公司，部门显示为"总部"
                        companyName = dept.getDeptName();
                        deptName = "总部";
                    }
                    else
                    {
                        // 非顶级部门：公司是父部门，部门是当前部门
                        deptName = dept.getDeptName();
                        SysDept parentDept = deptService.selectDeptById(dept.getParentId());
                        if (parentDept != null)
                        {
                            companyName = parentDept.getDeptName();
                        }
                    }
                }
            }
            if (StringUtils.isEmpty(companyName) && StringUtils.isNotEmpty(user.getTenantId()))
            {
                SysTenant tenant = tenantService.selectSysTenantByTenantId(user.getTenantId());
                if (tenant != null)
                {
                    companyName = tenant.getTenantName();
                }
            }
            
            AjaxResult ajax = AjaxResult.success(user);
            ajax.put("roleGroup", userService.selectUserRoleGroup(loginUser.getUsername()));
            ajax.put("postGroup", userService.selectUserPostGroup(loginUser.getUsername()));
            ajax.put("deptName", deptName);
            ajax.put("companyName", companyName);
            ajax.put("profileCompletion", profileCompletionService.buildProfileCompletion(user));
            return ajax;
        } catch (Exception e) {
            // 记录错误日志
            logger.error("获取用户信息失败: " + e.getMessage(), e);
            
            // 如果获取用户信息失败，返回错误信息，而不是返回默认的"管理员"信息
            return error("获取用户信息失败，请重新登录");
        }
    }

    /**
     * 修改用户
     */
    @Log(title = "个人信息", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult updateProfile(@RequestBody SysUser user)
    {
        LoginUser loginUser = getLoginUser();
        SysUser currentUser = loginUser.getUser();
        String nextUserName = normalizeDisplayName(user.getUserName());
        if (StringUtils.isNotEmpty(nextUserName) && !StringUtils.equals(nextUserName, currentUser.getUserName()))
        {
            if (!shouldAllowDisplayNameUpdate(currentUser))
            {
                return error("当前账号无需通过个人资料修改显示名称");
            }
            currentUser.setUserName(nextUserName);
        }
        if (StringUtils.isNotEmpty(currentUser.getUserName()) && !userService.checkUserNameUnique(currentUser))
        {
            return error("修改用户'" + loginUser.getUsername() + "'失败，显示名称已存在");
        }
        if (StringUtils.isNotEmpty(nextUserName)) {
            currentUser.setNickName(nextUserName);
        } else if (StringUtils.isNotEmpty(user.getNickName())) {
            currentUser.setNickName(StringUtils.trim(user.getNickName()));
        }
        currentUser.setEmail(normalizeEmail(user.getEmail()));
        currentUser.setPhonenumber(normalizePhone(user.getPhonenumber()));
        currentUser.setSex(user.getSex());
        // 允许更新部门
        if (user.getDeptId() != null) {
            currentUser.setDeptId(user.getDeptId());
        }
        // 更新职位
        if (StringUtils.isNotEmpty(user.getPosition())) {
            currentUser.setPosition(user.getPosition());
        }
        // 处理头像和封面照片
        if (StringUtils.isNotEmpty(user.getAvatar())) {
            currentUser.setAvatar(user.getAvatar());
        }
        if (StringUtils.isNotEmpty(user.getCoverPhoto())) {
            currentUser.setCoverPhoto(user.getCoverPhoto());
        }
        if (StringUtils.isNotEmpty(user.getPhonenumber()) && !userService.checkPhoneUnique(currentUser))
        {
            return error("修改用户'" + loginUser.getUsername() + "'失败，手机号码已存在");
        }
        if (StringUtils.isNotEmpty(user.getEmail()) && !userService.checkEmailUnique(currentUser))
        {
            return error("修改用户'" + loginUser.getUsername() + "'失败，邮箱账号已存在");
        }
        if (userService.updateUserProfile(currentUser) > 0)
        {
            // 更新缓存用户信息
            tokenService.setLoginUser(loginUser);
            return success();
        }
        return error("修改个人信息异常，请联系管理员");
    }

    private boolean shouldAllowDisplayNameUpdate(SysUser currentUser)
    {
        if (currentUser == null)
        {
            return false;
        }

        ProfileCompletionInfo profileCompletion = profileCompletionService.buildProfileCompletion(currentUser);
        return profileCompletion == null || profileCompletion.isNeedsProfileCompletion()
                || UserProfileCompletionService.isTemporaryDisplayName(currentUser.getUserName());
    }

    private String normalizeDisplayName(String value)
    {
        return StringUtils.trim(value);
    }

    private String normalizePhone(String value)
    {
        return StringUtils.isEmpty(value) ? value : StringUtils.trim(value).replaceAll("\\s+", "");
    }

    private String normalizeEmail(String value)
    {
        return StringUtils.isEmpty(value) ? value : StringUtils.trim(value).toLowerCase();
    }

    /**
     * 重置密码
     */
    @Log(title = "个人信息", businessType = BusinessType.UPDATE)
    @PutMapping("/updatePwd")
    public AjaxResult updatePwd(@RequestBody Map<String, String> params)
    {
        String oldPassword = params.get("oldPassword");
        String newPassword = params.get("newPassword");
        LoginUser loginUser = getLoginUser();
        Long userId = loginUser.getUserId();
        String password = loginUser.getPassword();
        if (!SecurityUtils.matchesPassword(oldPassword, password))
        {
            return error("修改密码失败，旧密码错误");
        }
        if (SecurityUtils.matchesPassword(newPassword, password))
        {
            return error("新密码不能与旧密码相同");
        }
        newPassword = SecurityUtils.encryptPassword(newPassword);
        if (userService.resetUserPwd(userId, newPassword) > 0)
        {
            // 更新缓存用户密码&密码最后更新时间
            loginUser.getUser().setPwdUpdateDate(DateUtils.getNowDate());
            loginUser.getUser().setPassword(newPassword);
            tokenService.setLoginUser(loginUser);
            return success();
        }
        return error("修改密码异常，请联系管理员");
    }

    /**
     * 头像上传
     */
    @Log(title = "用户头像", businessType = BusinessType.UPDATE)
    @PostMapping("/avatar")
    public AjaxResult avatar(@RequestParam("avatarfile") MultipartFile file) throws Exception
    {
        if (!file.isEmpty())
        {
            LoginUser loginUser = getLoginUser();
            String avatar = FileUploadUtils.upload(RuoYiConfig.getAvatarPath(), file, MimeTypeUtils.IMAGE_EXTENSION, true);
            if (userService.updateUserAvatar(loginUser.getUserId(), avatar))
            {
                String oldAvatar = loginUser.getUser().getAvatar();
                if (StringUtils.isNotEmpty(oldAvatar))
                {
                    FileUtils.deleteFile(RuoYiConfig.getProfile() + FileUtils.stripPrefix(oldAvatar));
                }
                AjaxResult ajax = AjaxResult.success();
                ajax.put("imgUrl", avatar);
                // 更新缓存用户头像
                loginUser.getUser().setAvatar(avatar);
                tokenService.setLoginUser(loginUser);
                return ajax;
            }
        }
        return error("上传图片异常，请联系管理员");
    }

    /**
     * 注销账号（逻辑删除）
     */
    @Log(title = "注销账号", businessType = BusinessType.DELETE)
    @DeleteMapping("/delete")
    public AjaxResult deleteAccount()
    {
        LoginUser loginUser = getLoginUser();
        Long userId = loginUser.getUserId();
        
        // 不允许删除管理员账号
        if (userId != null && userId <= 2)
        {
            return error("管理员账号不允许注销");
        }
        
        // 执行逻辑删除
        int result = userService.deleteUserById(userId);
        if (result > 0)
        {
            // 删除用户缓存
            tokenService.delLoginUser(loginUser.getToken());
            return success("账号已成功注销");
        }
        return error("注销账号失败，请稍后重试");
    }

    @GetMapping("/guide-onboarding")
    public AjaxResult guideOnboarding()
    {
        LoginUser loginUser = getLoginUser();
        return success(guideOnboardingService.buildClientState(loginUser.getUserId()));
    }

    @PostMapping("/guide-onboarding/complete")
    public AjaxResult completeGuideScenario(@RequestParam("scenarioId") String scenarioId)
    {
        LoginUser loginUser = getLoginUser();
        return success(guideOnboardingService.completeScenario(loginUser.getUserId(), scenarioId));
    }

    @PostMapping("/guide-onboarding/reset")
    public AjaxResult resetGuideScenario(@RequestParam("scenarioId") String scenarioId)
    {
        LoginUser loginUser = getLoginUser();
        return success(guideOnboardingService.resetScenario(loginUser.getUserId(), scenarioId));
    }

    @PostMapping("/guide-onboarding/resetAll")
    public AjaxResult resetAllGuideScenarios()
    {
        LoginUser loginUser = getLoginUser();
        return success(guideOnboardingService.resetAll(loginUser.getUserId()));
    }
}
