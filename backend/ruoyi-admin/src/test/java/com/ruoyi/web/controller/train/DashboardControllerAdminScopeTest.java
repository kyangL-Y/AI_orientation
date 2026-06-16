package com.ruoyi.web.controller.train;

import com.ruoyi.common.core.domain.entity.SysRole;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.domain.model.LoginUser;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.lang.reflect.Method;
import java.util.Collections;
import java.util.HashSet;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class DashboardControllerAdminScopeTest {

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void isSuperAdminUser_platformRoleInTenant_canManageAllTenants() throws Exception {
        SysUser user = new SysUser();
        user.setUserId(122L);
        user.setTenantId("T001");
        user.setAdminLevel(SysUser.ADMIN_LEVEL_COMMON);
        user.setRoles(Collections.singletonList(role(105L, "platform", SysUser.ADMIN_LEVEL_PLATFORM)));

        setLoginUser(user);

        DashboardController controller = new DashboardController();
        Method method = DashboardController.class.getDeclaredMethod("isSuperAdminUser", Long.class, String.class);
        method.setAccessible(true);

        boolean result = (boolean) method.invoke(controller, 122L, "T001");
        assertTrue(result);
    }

    @Test
    void isSuperAdminUser_nonAdminInSuperTenant_isNotElevatedByTenantIdAlone() throws Exception {
        SysUser user = new SysUser();
        user.setUserId(300L);
        user.setTenantId("000000");
        user.setAdminLevel(SysUser.ADMIN_LEVEL_COMMON);

        setLoginUser(user);

        DashboardController controller = new DashboardController();
        Method method = DashboardController.class.getDeclaredMethod("isSuperAdminUser", Long.class, String.class);
        method.setAccessible(true);

        boolean result = (boolean) method.invoke(controller, 300L, "000000");
        assertFalse(result);
    }

    private void setLoginUser(SysUser user) {
        LoginUser loginUser = new LoginUser();
        loginUser.setUserId(user.getUserId());
        loginUser.setUser(user);
        loginUser.setPermissions(new HashSet<>(Collections.singleton("*:*:*")));

        SecurityContextHolder.getContext().setAuthentication(
            new UsernamePasswordAuthenticationToken(loginUser, null, loginUser.getAuthorities())
        );
    }

    private SysRole role(Long roleId, String roleKey, Integer roleLevel) {
        SysRole role = new SysRole();
        role.setRoleId(roleId);
        role.setRoleKey(roleKey);
        role.setRoleLevel(roleLevel);
        return role;
    }
}
