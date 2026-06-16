package com.ruoyi.web.controller.system;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import javax.servlet.http.HttpServletResponse;
import org.apache.commons.lang3.ArrayUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysDept;
import com.ruoyi.common.core.domain.entity.SysRole;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.common.utils.poi.ExcelUtil;
import com.ruoyi.framework.web.service.TokenService;
import com.ruoyi.system.service.ISysDeptService;
import com.ruoyi.system.service.ISysPostService;
import com.ruoyi.system.service.ISysRoleService;
import com.ruoyi.system.service.ISysUserService;

/**
 * 用户信息
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/system/user")
public class SysUserController extends BaseController
{
    @Autowired
    private ISysUserService userService;

    @Autowired
    private ISysRoleService roleService;

    @Autowired
    private ISysDeptService deptService;

    @Autowired
    private ISysPostService postService;

    @Autowired
    private TokenService tokenService;

    /**
     * 获取用户列表
     */
    @PreAuthorize("@ss.hasPermi('system:user:list')")
    @GetMapping("/list")
    public TableDataInfo list(SysUser user)
    {
        startPage();
        List<SysUser> list = userService.selectUserList(user);
        return getDataTable(list);
    }

    @Log(title = "用户管理", businessType = BusinessType.EXPORT)
    @PreAuthorize("@ss.hasPermi('system:user:export')")
    @PostMapping("/export")
    public void export(HttpServletResponse response, SysUser user)
    {
        List<SysUser> list = userService.selectUserList(user);
        ExcelUtil<SysUser> util = new ExcelUtil<SysUser>(SysUser.class);
        util.exportExcel(response, list, "用户数据");
    }

    @Log(title = "用户管理", businessType = BusinessType.IMPORT)
    @PreAuthorize("@ss.hasPermi('system:user:import')")
    @PostMapping("/importData")
    public AjaxResult importData(MultipartFile file, boolean updateSupport) throws Exception
    {
        ExcelUtil<SysUser> util = new ExcelUtil<SysUser>(SysUser.class);
        List<SysUser> userList = util.importExcel(file.getInputStream());
        String operName = getUsername();
        String message = userService.importUser(userList, updateSupport, operName);
        return success(message);
    }

    @PostMapping("/importTemplate")
    public void importTemplate(HttpServletResponse response)
    {
        ExcelUtil<SysUser> util = new ExcelUtil<SysUser>(SysUser.class);
        util.importTemplateExcel(response, "用户数据");
    }

    /**
     * 获取按角色分组的用户列表（用于部门负责人选择）
     * 注意：此方法必须放在 getInfo 之前，否则会被 /{userId} 路径匹配
     */
    @PreAuthorize("@ss.hasPermi('system:dept:list')")
    @GetMapping("/listGroupByRole")
    public AjaxResult listGroupByRole()
    {
        // 获取所有正常状态的用户
        SysUser queryUser = new SysUser();
        queryUser.setStatus("0");
        List<SysUser> allUsers = userService.selectUserList(queryUser);
        
        // 角色显示名称映射
        Map<String, String> roleNameMap = new LinkedHashMap<>();
        roleNameMap.put("tenant_admin", "集团管理员");
        roleNameMap.put("company_admin", "公司管理员");
        roleNameMap.put("dept_admin", "部门管理员");
        roleNameMap.put("common", "普通员工");
        
        // 按角色分组
        List<Map<String, Object>> result = new ArrayList<>();
        for (Map.Entry<String, String> entry : roleNameMap.entrySet()) {
            String roleKey = entry.getKey();
            String roleName = entry.getValue();
            
            List<Map<String, Object>> users = allUsers.stream()
                .filter(user -> {
                    if (user.getRoles() == null || user.getRoles().isEmpty()) {
                        return "common".equals(roleKey);
                    }
                    return user.getRoles().stream().anyMatch(r -> roleKey.equals(r.getRoleKey()));
                })
                .map(user -> {
                    Map<String, Object> userMap = new HashMap<>();
                    userMap.put("userId", user.getUserId());
                    userMap.put("userName", user.getUserName());
                    userMap.put("nickName", user.getNickName());
                    return userMap;
                })
                .collect(Collectors.toList());
            
            if (!users.isEmpty()) {
                Map<String, Object> group = new HashMap<>();
                group.put("label", roleName);
                group.put("options", users);
                result.add(group);
            }
        }
        
        return success(result);
    }

    /**
     * 根据用户编号获取详细信息
     */
    @PreAuthorize("@ss.hasAnyPermi('system:user:query,system:user:list')")
    @GetMapping(value = { "/", "/{userId}" })
    public AjaxResult getInfo(@PathVariable(value = "userId", required = false) Long userId)
    {
        AjaxResult ajax = AjaxResult.success();
        List<Long> existingRoleIds = new ArrayList<>();
        if (StringUtils.isNotNull(userId))
        {
            userService.checkUserDataScope(userId);
            SysUser sysUser = userService.selectUserById(userId);
            ajax.put(AjaxResult.DATA_TAG, sysUser);
            ajax.put("postIds", postService.selectPostListByUserId(userId));
            existingRoleIds = sysUser.getRoles().stream().map(SysRole::getRoleId).collect(Collectors.toList());
            ajax.put("roleIds", existingRoleIds);
        }
        List<SysRole> roles = roleService.selectRoleAll();
        // 根据当前用户角色过滤可分配的角色，同时保留被编辑用户已有的角色（用于显示）
        ajax.put("roles", filterRolesByCurrentUser(roles, existingRoleIds));
        ajax.put("posts", postService.selectPostAll());
        return ajax;
    }

    /**
     * 根据当前登录用户的角色过滤可分配的角色列表
     * 角色层级: admin > platform > tenant_admin(集团管理员) > company_admin(公司管理员) > dept_admin(部门管理员) > common(普通角色)
     * @param allRoles 所有角色列表
     * @param existingRoleIds 被编辑用户已有的角色ID（用于显示，即使当前用户无权分配也要显示）
     */
    private List<SysRole> filterRolesByCurrentUser(List<SysRole> allRoles, List<Long> existingRoleIds) {
        SysUser currentUser = SecurityUtils.getLoginUser().getUser();
        if (currentUser == null) {
            return new ArrayList<>();
        }

        int currentAdminLevel = resolveAssignableAdminLevel(currentUser);
        if (currentAdminLevel == SysUser.ADMIN_LEVEL_SUPER) {
            return allRoles;
        }

        // 平台管理员可以分配除超级管理员外的所有角色，其余管理员只能分配低于自己级别的角色。
        return allRoles.stream().filter(role -> {
            Long roleId = role.getRoleId();
            if (existingRoleIds != null && existingRoleIds.contains(roleId)) {
                return true;
            }

            int roleAdminLevel = getRoleAdminLevel(role);
            if (roleAdminLevel == SysUser.ADMIN_LEVEL_SUPER) {
                return false;
            }

            if (currentAdminLevel <= SysUser.ADMIN_LEVEL_PLATFORM) {
                return roleAdminLevel >= SysUser.ADMIN_LEVEL_PLATFORM;
            }

            return roleAdminLevel > currentAdminLevel;
        }).collect(Collectors.toList());
    }

    private int resolveAssignableAdminLevel(SysUser currentUser) {
        int roleAdminLevel = currentUser.getHighestAdminLevel();
        Integer storedAdminLevel = currentUser.getAdminLevel();
        if (roleAdminLevel > SysUser.ADMIN_LEVEL_PLATFORM
                && storedAdminLevel != null
                && storedAdminLevel == SysUser.ADMIN_LEVEL_PLATFORM) {
            return SysUser.ADMIN_LEVEL_PLATFORM;
        }
        return roleAdminLevel;
    }
    
    /**
     * 重载方法，用于新增用户时（无已有角色）
     */
    private List<SysRole> filterRolesByCurrentUser(List<SysRole> allRoles) {
        return filterRolesByCurrentUser(allRoles, new ArrayList<>());
    }

    private int getRoleAdminLevel(SysRole role) {
        if (role == null) {
            return SysUser.ADMIN_LEVEL_COMMON;
        }

        String roleKey = role.getRoleKey();
        if ("admin".equals(roleKey)) {
            return SysUser.ADMIN_LEVEL_SUPER;
        }
        if ("platform".equals(roleKey)) {
            return SysUser.ADMIN_LEVEL_PLATFORM;
        }
        if ("tenant_admin".equals(roleKey)) {
            return SysUser.ADMIN_LEVEL_TENANT;
        }
        if ("company_admin".equals(roleKey)) {
            return SysUser.ADMIN_LEVEL_COMPANY;
        }
        if ("dept_admin".equals(roleKey)) {
            return SysUser.ADMIN_LEVEL_DEPT;
        }

        Integer roleLevel = role.getRoleLevel();
        if (roleLevel == null) {
            return SysUser.ADMIN_LEVEL_COMMON;
        }
        if (roleLevel < SysUser.ADMIN_LEVEL_SUPER) {
            return SysUser.ADMIN_LEVEL_SUPER;
        }
        if (roleLevel > SysUser.ADMIN_LEVEL_DEPT) {
            return SysUser.ADMIN_LEVEL_COMMON;
        }
        return roleLevel;
    }

    /**
     * 新增用户
     */
    @PreAuthorize("@ss.hasPermi('system:user:add')")
    @Log(title = "用户管理", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@Validated @RequestBody SysUser user)
    {
        deptService.checkDeptDataScope(user.getDeptId());
        roleService.checkRoleDataScope(user.getRoleIds());
        if (!userService.checkUserNameUnique(user))
        {
            return error("新增用户'" + user.getUserName() + "'失败，登录账号已存在");
        }
        else if (StringUtils.isNotEmpty(user.getPhonenumber()) && !userService.checkPhoneUnique(user))
        {
            return error("新增用户'" + user.getUserName() + "'失败，手机号码已存在");
        }
        else if (StringUtils.isNotEmpty(user.getEmail()) && !userService.checkEmailUnique(user))
        {
            return error("新增用户'" + user.getUserName() + "'失败，邮箱账号已存在");
        }
        user.setCreateBy(getUsername());
        user.setPassword(SecurityUtils.encryptPassword(user.getPassword()));
        // 继承当前登录用户的租户ID
        SysUser currentUser = SecurityUtils.getLoginUser().getUser();
        if (currentUser != null && StringUtils.isNotEmpty(currentUser.getTenantId())) {
            user.setTenantId(currentUser.getTenantId());
        }
        return toAjax(userService.insertUser(user));
    }

    /**
     * 修改用户
     */
    @PreAuthorize("@ss.hasPermi('system:user:edit')")
    @Log(title = "用户管理", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@Validated @RequestBody SysUser user)
    {
        userService.checkUserAllowed(user);
        userService.checkUserDataScope(user.getUserId());
        deptService.checkDeptDataScope(user.getDeptId());
        roleService.checkRoleDataScope(user.getRoleIds());
        if (!userService.checkUserNameUnique(user))
        {
            return error("修改用户'" + user.getUserName() + "'失败，登录账号已存在");
        }
        else if (StringUtils.isNotEmpty(user.getPhonenumber()) && !userService.checkPhoneUnique(user))
        {
            return error("修改用户'" + user.getUserName() + "'失败，手机号码已存在");
        }
        else if (StringUtils.isNotEmpty(user.getEmail()) && !userService.checkEmailUnique(user))
        {
            return error("修改用户'" + user.getUserName() + "'失败，邮箱账号已存在");
        }
        user.setUpdateBy(getUsername());
        int rows = userService.updateUser(user);
        if (rows > 0)
        {
            tokenService.forceLogoutByUserId(user.getUserId());
        }
        return toAjax(rows);
    }

    /**
     * 删除用户
     */
    @PreAuthorize("@ss.hasPermi('system:user:remove')")
    @Log(title = "用户管理", businessType = BusinessType.DELETE)
    @DeleteMapping("/{userIds}")
    public AjaxResult remove(@PathVariable Long[] userIds)
    {
        if (ArrayUtils.contains(userIds, getUserId()))
        {
            return error("当前用户不能删除");
        }
        return toAjax(userService.deleteUserByIds(userIds));
    }

    /**
     * 重置密码
     */
    @PreAuthorize("@ss.hasPermi('system:user:resetPwd')")
    @Log(title = "用户管理", businessType = BusinessType.UPDATE)
    @PutMapping("/resetPwd")
    public AjaxResult resetPwd(@RequestBody SysUser user)
    {
        userService.checkUserAllowed(user);
        userService.checkUserDataScope(user.getUserId());
        user.setPassword(SecurityUtils.encryptPassword(user.getPassword()));
        user.setUpdateBy(getUsername());
        int rows = userService.resetPwd(user);
        if (rows > 0)
        {
            tokenService.forceLogoutByUserId(user.getUserId());
        }
        return toAjax(rows);
    }

    /**
     * 状态修改
     */
    @PreAuthorize("@ss.hasPermi('system:user:edit')")
    @Log(title = "用户管理", businessType = BusinessType.UPDATE)
    @PutMapping("/changeStatus")
    public AjaxResult changeStatus(@RequestBody SysUser user)
    {
        userService.checkUserAllowed(user);
        userService.checkUserDataScope(user.getUserId());
        user.setUpdateBy(getUsername());
        int rows = userService.updateUserStatus(user);
        if (rows > 0)
        {
            tokenService.forceLogoutByUserId(user.getUserId());
        }
        return toAjax(rows);
    }

    /**
     * 根据用户编号获取授权角色
     */
    @PreAuthorize("@ss.hasPermi('system:user:query')")
    @GetMapping("/authRole/{userId}")
    public AjaxResult authRole(@PathVariable("userId") Long userId)
    {
        AjaxResult ajax = AjaxResult.success();
        SysUser user = userService.selectUserById(userId);
        List<SysRole> roles = roleService.selectRolesByUserId(userId);
        ajax.put("user", user);
        // 根据当前用户角色过滤可分配的角色
        ajax.put("roles", filterRolesByCurrentUser(roles));
        return ajax;
    }

    /**
     * 用户授权角色
     */
    @PreAuthorize("@ss.hasPermi('system:user:edit')")
    @Log(title = "用户管理", businessType = BusinessType.GRANT)
    @PutMapping("/authRole")
    public AjaxResult insertAuthRole(Long userId, Long[] roleIds)
    {
        userService.checkUserDataScope(userId);
        roleService.checkRoleDataScope(roleIds);
        userService.insertUserAuth(userId, roleIds);
        tokenService.forceLogoutByUserId(userId);
        return success();
    }

    /**
     * 获取部门树列表
     */
    @PreAuthorize("@ss.hasPermi('system:user:list')")
    @GetMapping("/deptTree")
    public AjaxResult deptTree(SysDept dept)
    {
        return success(deptService.selectDeptTreeList(dept));
    }
}
