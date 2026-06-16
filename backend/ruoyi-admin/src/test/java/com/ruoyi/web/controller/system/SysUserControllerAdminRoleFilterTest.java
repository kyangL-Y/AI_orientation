package com.ruoyi.web.controller.system;

import com.ruoyi.common.core.domain.entity.SysRole;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.domain.model.LoginUser;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertEquals;

class SysUserControllerAdminRoleFilterTest {

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @SuppressWarnings("unchecked")
    void filterRolesByCurrentUser_platformLevelWithoutPlatformRole_canStillAssignPlatformAndBelow() throws Exception {
        SysUser currentUser = new SysUser();
        currentUser.setUserId(200L);
        currentUser.setAdminLevel(SysUser.ADMIN_LEVEL_PLATFORM);
        currentUser.setRoles(Collections.singletonList(role(999L, "common", SysUser.ADMIN_LEVEL_COMMON)));

        LoginUser loginUser = new LoginUser();
        loginUser.setUserId(currentUser.getUserId());
        loginUser.setUser(currentUser);
        loginUser.setPermissions(new HashSet<>(Collections.singleton("*:*:*")));

        SecurityContextHolder.getContext().setAuthentication(
            new UsernamePasswordAuthenticationToken(loginUser, null, loginUser.getAuthorities())
        );

        SysUserController controller = new SysUserController();
        Method method = SysUserController.class.getDeclaredMethod(
            "filterRolesByCurrentUser", List.class, List.class
        );
        method.setAccessible(true);

        List<SysRole> filtered = (List<SysRole>) method.invoke(
            controller,
            Arrays.asList(
                role(1L, "admin", SysUser.ADMIN_LEVEL_SUPER),
                role(2L, "platform", SysUser.ADMIN_LEVEL_PLATFORM),
                role(3L, "tenant_admin", SysUser.ADMIN_LEVEL_TENANT),
                role(4L, "company_admin", SysUser.ADMIN_LEVEL_COMPANY),
                role(5L, "dept_admin", SysUser.ADMIN_LEVEL_DEPT),
                role(6L, "common", SysUser.ADMIN_LEVEL_COMMON)
            ),
            Collections.emptyList()
        );

        Set<String> roleKeys = filtered.stream().map(SysRole::getRoleKey).collect(Collectors.toSet());
        assertEquals(new HashSet<>(Arrays.asList("platform", "tenant_admin", "company_admin", "dept_admin", "common")), roleKeys);
    }

    private SysRole role(Long roleId, String roleKey, Integer roleLevel) {
        SysRole role = new SysRole();
        role.setRoleId(roleId);
        role.setRoleKey(roleKey);
        role.setRoleLevel(roleLevel);
        return role;
    }
}
