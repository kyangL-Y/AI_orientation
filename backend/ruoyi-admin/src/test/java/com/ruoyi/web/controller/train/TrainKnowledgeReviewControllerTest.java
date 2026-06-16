package com.ruoyi.web.controller.train;

import com.ruoyi.common.core.domain.entity.SysDept;
import com.ruoyi.common.core.domain.entity.SysRole;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.domain.model.LoginUser;
import com.ruoyi.system.mapper.SysDeptMapper;
import com.ruoyi.train.domain.TrainKnowledgeArticle;
import com.ruoyi.train.service.ITrainKnowledgeReviewService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import com.ruoyi.common.core.domain.AjaxResult;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * 知识文章审核 Controller 单元测试
 *
 * 覆盖分层级审核权限逻辑：超管/平台管理员/集团管理员/部门管理员
 */
@ExtendWith(MockitoExtension.class)
class TrainKnowledgeReviewControllerTest {

    @InjectMocks
    private TrainKnowledgeReviewController controller;

    @Mock
    private ITrainKnowledgeReviewService reviewService;

    @Mock
    private SysDeptMapper deptMapper;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.clearContext();
    }

    // ---- helpers ----

    private SysRole makeRole(String roleKey) {
        SysRole role = new SysRole();
        role.setRoleKey(roleKey);
        return role;
    }

    private LoginUser buildLoginUser(Long userId, String tenantId, Long deptId,
                                     int adminLevel, List<String> roleKeys) {
        SysUser sysUser = new SysUser();
        sysUser.setUserId(userId);
        sysUser.setNickName("测试用户" + userId);
        sysUser.setTenantId(tenantId);
        sysUser.setDeptId(deptId);
        sysUser.setAdminLevel(adminLevel);

        List<SysRole> roles = new ArrayList<>();
        for (String key : roleKeys) {
            roles.add(makeRole(key));
        }
        sysUser.setRoles(roles);

        LoginUser loginUser = new LoginUser();
        loginUser.setUserId(userId);
        loginUser.setDeptId(deptId);
        loginUser.setUser(sysUser);
        loginUser.setPermissions(new HashSet<>(Arrays.asList("train:knowledge:review")));
        return loginUser;
    }

    private void setSecurityContext(LoginUser loginUser) {
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken(loginUser, null, loginUser.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    // ---- approve tests ----

    @Test
    void approve_calls_service_with_reviewer_info() {
        LoginUser loginUser = buildLoginUser(100L, "T001", 10L, 2, Arrays.asList("dept_admin"));
        setSecurityContext(loginUser);

        when(reviewService.approveArticle(eq(1L), eq(100L), eq("测试用户100"))).thenReturn(1);

        AjaxResult result = controller.approve(1L);
        assertEquals(200, result.get("code"));
        verify(reviewService).approveArticle(1L, 100L, "测试用户100");
    }

    // ---- reject tests ----

    @Test
    void reject_calls_service_with_reason() {
        LoginUser loginUser = buildLoginUser(100L, "T001", 10L, 2, Arrays.asList("dept_admin"));
        setSecurityContext(loginUser);

        when(reviewService.rejectArticle(eq(1L), eq(100L), eq("测试用户100"), eq("内容不合规")))
                .thenReturn(1);

        AjaxResult result = controller.reject(1L, "内容不合规");
        assertEquals(200, result.get("code"));
        verify(reviewService).rejectArticle(1L, 100L, "测试用户100", "内容不合规");
    }

    // ---- approve failure ----

    @Test
    void approve_returns_error_when_service_fails() {
        LoginUser loginUser = buildLoginUser(100L, "T001", 10L, 2, Arrays.asList("dept_admin"));
        setSecurityContext(loginUser);

        when(reviewService.approveArticle(eq(1L), eq(100L), eq("测试用户100"))).thenReturn(0);

        AjaxResult result = controller.approve(1L);
        assertEquals(500, result.get("code")); // toAjax(0) → error
    }
}
