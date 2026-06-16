package com.ruoyi.web.controller.train;

import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.domain.model.LoginUser;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.system.domain.TrainUserPointsLog;
import com.ruoyi.system.service.ITrainUserPointsService;
import com.ruoyi.system.service.ISysUserService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TrainUserPointsControllerTest {

    @InjectMocks
    private TrainUserPointsController controller;

    @Mock
    private ITrainUserPointsService trainUserPointsService;

    @Mock
    private com.ruoyi.system.service.ISysConfigService sysConfigService;

    @Mock
    private ISysUserService userService;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.clearContext();
        MockHttpServletRequest request = new MockHttpServletRequest();
        RequestContextHolder.setRequestAttributes(new ServletRequestAttributes(request));
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
        RequestContextHolder.resetRequestAttributes();
    }

    @Test
    void myLog_ignores_input_userId_and_uses_current_login_user_id() {
        setSecurityContext(100L);

        TrainUserPointsLog query = new TrainUserPointsLog();
        query.setUserId(999L);
        when(trainUserPointsService.selectTrainUserPointsLogList(any(TrainUserPointsLog.class)))
                .thenReturn(Collections.singletonList(new TrainUserPointsLog()));

        TableDataInfo result = controller.myLog(query);

        ArgumentCaptor<TrainUserPointsLog> captor = ArgumentCaptor.forClass(TrainUserPointsLog.class);
        verify(trainUserPointsService).selectTrainUserPointsLogList(captor.capture());
        assertEquals(100L, captor.getValue().getUserId());
        assertEquals(100L, query.getUserId());
        assertEquals(200, result.getCode());
    }

    private void setSecurityContext(Long userId) {
        SysUser sysUser = new SysUser();
        sysUser.setUserId(userId);

        LoginUser loginUser = new LoginUser();
        loginUser.setUserId(userId);
        loginUser.setDeptId(10L);
        loginUser.setUser(sysUser);
        loginUser.setPermissions(new HashSet<>(Arrays.asList("*:*:*")));

        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken(loginUser, null, loginUser.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }
}
