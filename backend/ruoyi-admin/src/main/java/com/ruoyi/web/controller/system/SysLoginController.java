package com.ruoyi.web.controller.system;

import java.util.Date;
import java.util.List;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.annotation.Anonymous;
import com.ruoyi.common.constant.Constants;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysMenu;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.domain.model.LoginBody;
import com.ruoyi.common.core.domain.model.LoginUser;
import com.ruoyi.common.core.redis.RedisCache;
import com.ruoyi.common.core.text.Convert;
import com.ruoyi.common.utils.DateUtils;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.framework.web.service.SysLoginService;
import com.ruoyi.framework.web.service.SysPermissionService;
import com.ruoyi.framework.web.service.TokenService;
import com.ruoyi.framework.web.service.UserProfileCompletionService;
import com.ruoyi.system.service.ISysConfigService;
import com.ruoyi.system.service.ISysDeptService;
import com.ruoyi.system.service.ISysMenuService;
import com.ruoyi.system.service.ISysUserService;
import com.ruoyi.system.service.ISysTenantService;
import com.ruoyi.system.domain.SysTenant;
import com.ruoyi.system.mapper.SysUserMapper;
import com.ruoyi.common.core.domain.entity.SysDept;
import com.ruoyi.train.service.IMembershipService;
import com.ruoyi.train.domain.TrainUserMembership;

/**
 * 登录验证
 * 
 * @author ruoyi
 */
@RestController
public class SysLoginController
{
    private static final Logger log = LoggerFactory.getLogger(SysLoginController.class);

    @Autowired
    private SysLoginService loginService;

    @Autowired
    private ISysMenuService menuService;

    @Autowired
    private SysPermissionService permissionService;

    @Autowired
    private TokenService tokenService;

    @Autowired
    private ISysConfigService configService;

    @Autowired
    private RedisCache redisCache;

    @Autowired
    private ISysUserService userService;
    
    @Autowired
    private SysUserMapper userMapper;

    @Autowired
    private ISysDeptService deptService;

    @Autowired
    private ISysTenantService tenantService;

    @Autowired
    private IMembershipService membershipService;

    @Autowired
    private UserProfileCompletionService profileCompletionService;

    /**
     * 检查手机号是否已注册
     * 
     * @param phone 手机号
     * @return 结果
     */
    @Anonymous
    @GetMapping("/checkPhone")
    public AjaxResult checkPhone(String phone)
    {
        if (StringUtils.isEmpty(phone))
        {
            return AjaxResult.error("手机号不能为空");
        }
        
        // 先检查用户名是否为该手机号（用户名可能就是手机号）
        // 使用 Mapper 直接查询，绕过数据权限过滤
        SysUser user = userMapper.selectUserByUserName(phone);
        
        // 如果用户名不是手机号，再检查手机号字段
        if (user == null)
        {
            user = userMapper.checkPhoneUnique(phone);
        }
        
        if (user == null)
        {
            return AjaxResult.error("手机号未注册");
        }
        
        return AjaxResult.success("手机号已注册");
    }

    /**
     * 登录方法（用户端和管理端通用）
     * 
     * @param loginBody 登录信息
     * @return 结果
     */
    @Anonymous
    @PostMapping("/login")
    public AjaxResult login(@RequestBody LoginBody loginBody)
    {
        try
        {
            normalizePasswordLoginBody(loginBody);
            String tenantId = resolveLoginTenantId(loginBody);

            AjaxResult ajax = AjaxResult.success();
            String token = loginService.login(loginBody.getUsername(), loginBody.getPassword(), loginBody.getCode(),
                    loginBody.getUuid());
            ajax.put(Constants.TOKEN, token);

            if (StringUtils.isNotEmpty(tenantId)) {
                ajax.put("tenantId", tenantId);
            }
            SysUser currentUser = userService.selectUserByLoginName(loginBody.getUsername());
            if (currentUser != null)
            {
                ajax.put("profileCompletion", profileCompletionService.buildProfileCompletion(currentUser));
            }
            return ajax;
        }
        finally
        {
            com.ruoyi.common.core.tenant.TenantContextHolder.clear();
        }
    }

    /**
     * 管理端登录方法（仅允许管理员角色）
     * 
     * @param loginBody 登录信息
     * @return 结果
     */
    @Anonymous
    @PostMapping("/admin/login")
    public AjaxResult adminLogin(@RequestBody LoginBody loginBody)
    {
        try
        {
            normalizePasswordLoginBody(loginBody);
            String tenantId = resolveLoginTenantId(loginBody);

            String token = loginService.login(loginBody.getUsername(), loginBody.getPassword(), loginBody.getCode(),
                    loginBody.getUuid());

            SysUser user = userService.selectUserByLoginName(loginBody.getUsername());
            if (user == null) {
                tokenService.delLoginUser(token);
                return AjaxResult.error("用户不存在");
            }

            if (!hasAdminAccess(user)) {
                tokenService.delLoginUser(token);
                return AjaxResult.error("您没有管理员权限，无法登录管理端");
            }

            AjaxResult ajax = AjaxResult.success();
            ajax.put(Constants.TOKEN, token);
            if (StringUtils.isNotEmpty(tenantId)) {
                ajax.put("tenantId", tenantId);
            } else if (user.getTenantId() != null) {
                ajax.put("tenantId", user.getTenantId());
            }
            ajax.put("profileCompletion", profileCompletionService.buildProfileCompletion(user));
            return ajax;
        }
        finally
        {
            com.ruoyi.common.core.tenant.TenantContextHolder.clear();
        }
    }

    private String resolveLoginTenantId(LoginBody loginBody)
    {
        if (loginBody == null)
        {
            return null;
        }

        String tenantId = StringUtils.trim(loginBody.getTenantId());
        if (StringUtils.isNotEmpty(tenantId))
        {
            com.ruoyi.common.core.tenant.TenantContextHolder.setTenantId(tenantId);
            return tenantId;
        }

        String username = normalizeLoginIdentifier(loginBody.getUsername());
        if (StringUtils.isEmpty(username))
        {
            return null;
        }

        loginBody.setUsername(username);

        SysUser matchedUser = userMapper.selectUserByUserName(username);
        if (matchedUser == null && username.matches("^1[3-9]\\d{9}$"))
        {
            SysUser phoneUser = userMapper.checkPhoneUnique(username);
            if (phoneUser != null && phoneUser.getUserId() != null)
            {
                matchedUser = userService.selectUserById(phoneUser.getUserId());
            }
        }
        if (matchedUser == null && username.contains("@"))
        {
            SysUser emailUser = userMapper.checkEmailUnique(username.toLowerCase());
            if (emailUser != null && emailUser.getUserId() != null)
            {
                matchedUser = userService.selectUserById(emailUser.getUserId());
            }
        }

        if (matchedUser == null || StringUtils.isEmpty(matchedUser.getTenantId()))
        {
            return null;
        }

        tenantId = matchedUser.getTenantId();
        loginBody.setTenantId(tenantId);
        com.ruoyi.common.core.tenant.TenantContextHolder.setTenantId(tenantId);
        return tenantId;
    }

    private boolean hasAdminAccess(SysUser user)
    {
        if (user == null)
        {
            return false;
        }
        return user.hasAdminAccess();
    }

    /**
     * 手机验证码登录方法
     * 
     * @param loginBody 登录信息（包含phone和smsCode）
     * @return 结果
     */
    @Anonymous
    @PostMapping("/smsLogin")
    public AjaxResult smsLogin(@RequestBody LoginBody loginBody)
    {
        try
        {
            String phone = normalizePhone(loginBody.getPhone());
            String smsCode = normalizeCode(loginBody.getSmsCode());
            loginBody.setPhone(phone);
            loginBody.setSmsCode(smsCode);

            if (StringUtils.isEmpty(phone))
            {
                return AjaxResult.error("手机号不能为空");
            }
            if (StringUtils.isEmpty(smsCode))
            {
                return AjaxResult.error("验证码不能为空");
            }

            String cacheKey = "sms_code_" + phone;
            Object cachedCodeObject = redisCache.getCacheObject(cacheKey);
            if (cachedCodeObject == null)
            {
                return AjaxResult.error("验证码已过期，请重新获取");
            }
            String cachedCode = String.valueOf(cachedCodeObject);
            if (!smsCode.equals(cachedCode))
            {
                return AjaxResult.error("验证码错误");
            }

            redisCache.deleteObject(cacheKey);

            String token = loginService.smsLogin(phone);
            AjaxResult ajax = AjaxResult.success("登录成功");
            ajax.put(Constants.TOKEN, token);
            SysUser user = userService.selectUserByLoginName(phone);
            if (user == null)
            {
                user = userMapper.checkPhoneUnique(phone);
            }
            if (user != null)
            {
                ajax.put("tenantId", user.getTenantId());
                ajax.put("profileCompletion", profileCompletionService.buildProfileCompletion(user));
            }
            return ajax;
        }
        catch (Exception e)
        {
            log.error("手机验证码登录失败", e);
            return AjaxResult.error("登录失败，请稍后重试");
        }
    }

    /**
     * 邮箱验证码登录方法
     *
     * @param loginBody 登录信息（包含email和emailCode）
     * @return 结果
     */
    @Anonymous
    @PostMapping("/emailLogin")
    public AjaxResult emailLogin(@RequestBody LoginBody loginBody)
    {
        try
        {
            String email = normalizeEmail(loginBody.getEmail());
            String emailCode = normalizeCode(loginBody.getEmailCode());
            loginBody.setEmail(email);
            loginBody.setEmailCode(emailCode);

            if (StringUtils.isEmpty(email))
            {
                return AjaxResult.error("邮箱不能为空");
            }
            if (StringUtils.isEmpty(emailCode))
            {
                return AjaxResult.error("验证码不能为空");
            }

            String cacheKey = "email_code_" + email;
            Object cachedCodeObject = redisCache.getCacheObject(cacheKey);
            if (cachedCodeObject == null)
            {
                return AjaxResult.error("验证码已过期，请重新获取");
            }
            String cachedCode = String.valueOf(cachedCodeObject);
            if (!emailCode.equals(cachedCode))
            {
                return AjaxResult.error("验证码错误");
            }

            redisCache.deleteObject(cacheKey);

            String token = loginService.emailLogin(email);
            AjaxResult ajax = AjaxResult.success("登录成功");
            ajax.put(Constants.TOKEN, token);
            SysUser user = userService.selectUserByLoginName(email);
            if (user == null)
            {
                user = userMapper.checkEmailUnique(email);
            }
            if (user != null && StringUtils.isNotEmpty(user.getTenantId()))
            {
                ajax.put("tenantId", user.getTenantId());
            }
            if (user != null)
            {
                ajax.put("profileCompletion", profileCompletionService.buildProfileCompletion(user));
            }
            return ajax;
        }
        catch (Exception e)
        {
            log.error("邮箱验证码登录失败", e);
            return AjaxResult.error("登录失败，请稍后重试");
        }
    }

    /**
     * 手机验证码重置密码
     * 
     * @param loginBody 登录信息（包含phone, smsCode, password）
     * @return 结果
     */
    @Anonymous
    @PostMapping("/resetPwd")
    public AjaxResult resetPwd(@RequestBody LoginBody loginBody)
    {
        String password = loginBody.getPassword();
        if (StringUtils.isEmpty(password))
        {
            return AjaxResult.error("新密码不能为空");
        }
        if (password.length() < 5 || password.length() > 20)
        {
            return AjaxResult.error("密码长度必须在5到20个字符之间");
        }

        String phone = normalizePhone(loginBody.getPhone());
        String email = normalizeEmail(loginBody.getEmail());
        loginBody.setPhone(phone);
        loginBody.setEmail(email);
        SysUser user = null;
        String cacheKey = "";
        String consumeLockKey = "";

        if (StringUtils.isNotEmpty(phone))
        {
            cacheKey = "sms_code_" + phone;
        }
        else if (StringUtils.isNotEmpty(email))
        {
            cacheKey = "email_code_" + email;
        }

        if (StringUtils.isEmpty(cacheKey))
        {
            return AjaxResult.error("请输入手机号或邮箱");
        }

        consumeLockKey = cacheKey + ":consume_lock";
        if (!redisCache.setCacheObjectIfAbsent(consumeLockKey, "1", 10, TimeUnit.SECONDS))
        {
            return AjaxResult.error("验证码正在处理中，请稍后重试");
        }

        try
        {
            if (StringUtils.isNotEmpty(phone)) {
                // 手机号找回
                String smsCode = normalizeCode(loginBody.getSmsCode());
                if (StringUtils.isEmpty(smsCode))
                {
                    return AjaxResult.error("验证码不能为空");
                }
                Object cachedCodeObject = redisCache.getCacheObject(cacheKey);
                if (cachedCodeObject == null)
                {
                    return AjaxResult.error("验证码已过期，请重新获取");
                }
                String cachedCode = String.valueOf(cachedCodeObject);
                if (!smsCode.equals(cachedCode))
                {
                    return AjaxResult.error("验证码错误");
                }

                // 匿名找回密码不能依赖带数据权限的用户列表查询
                user = userMapper.selectUserByLoginName(phone);
                if (user == null)
                {
                    user = userMapper.checkPhoneUnique(phone);
                }
                if (user == null) return AjaxResult.error("该手机号未注册");

            } else if (StringUtils.isNotEmpty(email)) {
                // 邮箱找回
                String emailCode = normalizeCode(loginBody.getEmailCode());
                if (StringUtils.isEmpty(emailCode))
                {
                    return AjaxResult.error("验证码不能为空");
                }
                Object cachedCodeObject = redisCache.getCacheObject(cacheKey);
                if (cachedCodeObject == null)
                {
                    return AjaxResult.error("验证码已过期，请重新获取");
                }
                String cachedCode = String.valueOf(cachedCodeObject);
                if (!emailCode.equals(cachedCode))
                {
                    return AjaxResult.error("验证码错误");
                }

                // 匿名找回密码不能依赖带数据权限的用户列表查询
                user = userMapper.selectUserByLoginName(email);
                if (user == null)
                {
                    user = userMapper.checkEmailUnique(email);
                }
                if (user == null) return AjaxResult.error("该邮箱未注册");

            } else {
                return AjaxResult.error("请输入手机号或邮箱");
            }

            // 重置密码
            user.setPassword(SecurityUtils.encryptPassword(password));
            user.setPwdUpdateDate(DateUtils.getNowDate());
            if (userService.resetUserPwd(user.getUserId(), user.getPassword()) > 0)
            {
                // 验证码正确且重置成功，删除Redis中的验证码
                redisCache.deleteObject(cacheKey);
                return AjaxResult.success("密码重置成功，请使用新密码登录");
            }

            return AjaxResult.error("密码重置失败，请联系管理员");
        }
        finally
        {
            redisCache.deleteObject(consumeLockKey);
        }
    }

    /**
     * 获取用户信息
     * 
     * @return 用户信息
     */
    @GetMapping("getInfo")
    public AjaxResult getInfo()
    {
        LoginUser loginUser = SecurityUtils.getLoginUser();
        SysUser user = loginUser.getUser();
        // 角色集合
        Set<String> roles = permissionService.getRolePermission(user);
        // 权限集合
        Set<String> permissions = permissionService.getMenuPermission(user);
        if (!loginUser.getPermissions().equals(permissions))
        {
            loginUser.setPermissions(permissions);
            tokenService.refreshToken(loginUser);
        }
        
        // 获取公司信息：部门的父部门
        String companyName = null;
        if (user.getDeptId() != null)
        {
            SysDept dept = deptService.selectDeptById(user.getDeptId());
            if (dept != null && dept.getParentId() != null && dept.getParentId() != 0)
            {
                SysDept parentDept = deptService.selectDeptById(dept.getParentId());
                if (parentDept != null)
                {
                    companyName = parentDept.getDeptName();
                }
            }
        }
        
        // 获取租户名称
        String tenantName = null;
        if (StringUtils.isNotEmpty(user.getTenantId())) {
            SysTenant tenant = tenantService.selectSysTenantByTenantId(user.getTenantId());
            if (tenant != null) {
                tenantName = tenant.getTenantName();
            }
        }
        
        // 获取用户会员信息
        TrainUserMembership membership = null;
        try {
            membership = membershipService.getUserMembership(user.getUserId());
        } catch (Exception e) {
            // 会员信息获取失败不影响登录
            log.debug("会员信息获取失败 userId={}", user.getUserId(), e);
        }
        
        AjaxResult ajax = AjaxResult.success();
        ajax.put("user", user);
        ajax.put("roles", roles);
        ajax.put("permissions", permissions);
        ajax.put("companyName", companyName);
        ajax.put("tenantName", tenantName);
        ajax.put("isSuperAdmin", user.isSuperAdmin());
        ajax.put("isPlatformAdmin", user.isPlatformAdmin());
        ajax.put("hasAdminAccess", user.hasAdminAccess());
        ajax.put("canManageAllTenants", user.canManageAllTenants());
        ajax.put("effectiveAdminLevel", user.getHighestAdminLevel());
        ajax.put("membership", membership);
        ajax.put("profileCompletion", profileCompletionService.buildProfileCompletion(user));
        ajax.put("isDefaultModifyPwd", initPasswordIsModify(user.getPwdUpdateDate()));
        ajax.put("isPasswordExpired", passwordIsExpiration(user.getPwdUpdateDate()));
        return ajax;
    }

    /**
     * 获取路由信息
     * 
     * @return 路由信息
     */
    @GetMapping("getRouters")
    public AjaxResult getRouters()
    {
        Long userId = SecurityUtils.getUserId();
        List<SysMenu> menus = menuService.selectMenuTreeByUserId(userId);
        return AjaxResult.success(menuService.buildMenus(menus));
    }
    
    // 检查初始密码是否提醒修改
    public boolean initPasswordIsModify(Date pwdUpdateDate)
    {
        Integer initPasswordModify = Convert.toInt(configService.selectConfigByKey("sys.account.initPasswordModify"));
        return initPasswordModify != null && initPasswordModify == 1 && pwdUpdateDate == null;
    }

    // 检查密码是否过期
    public boolean passwordIsExpiration(Date pwdUpdateDate)
    {
        Integer passwordValidateDays = Convert.toInt(configService.selectConfigByKey("sys.account.passwordValidateDays"));
        if (passwordValidateDays != null && passwordValidateDays > 0)
        {
            if (StringUtils.isNull(pwdUpdateDate))
            {
                // 如果从未修改过初始密码，直接提醒过期
                return true;
            }
            Date nowDate = DateUtils.getNowDate();
            return DateUtils.differentDaysByMillisecond(nowDate, pwdUpdateDate) > passwordValidateDays;
        }
        return false;
    }

    private void normalizePasswordLoginBody(LoginBody loginBody)
    {
        if (loginBody == null)
        {
            return;
        }
        loginBody.setUsername(normalizeLoginIdentifier(loginBody.getUsername()));
        loginBody.setCode(normalizeCode(loginBody.getCode()));
        loginBody.setUuid(normalizeCode(loginBody.getUuid()));
    }

    private String normalizeLoginIdentifier(String value)
    {
        String normalized = StringUtils.trim(value);
        if (StringUtils.isEmpty(normalized))
        {
            return normalized;
        }
        return normalized.contains("@") ? normalized.toLowerCase() : normalized;
    }

    private String normalizePhone(String value)
    {
        return StringUtils.isEmpty(value) ? value : StringUtils.trim(value).replaceAll("\\s+", "");
    }

    private String normalizeEmail(String value)
    {
        return StringUtils.isEmpty(value) ? value : StringUtils.trim(value).toLowerCase();
    }

    private String normalizeCode(String value)
    {
        return StringUtils.trim(value);
    }
}
