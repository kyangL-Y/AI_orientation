package com.ruoyi.web.controller.open;

import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysRole;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.domain.model.LoginUser;
import com.ruoyi.common.exception.ServiceException;
import com.ruoyi.framework.web.service.MiniappAuthService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OpenMiniappAccountControllerTest
{
    @InjectMocks
    private OpenMiniappAccountController controller;

    @Mock
    private MiniappAuthService miniappAuthService;

    @BeforeEach
    void setUp()
    {
        SecurityContextHolder.clearContext();
        RequestContextHolder.setRequestAttributes(new ServletRequestAttributes(new MockHttpServletRequest()));
    }

    @AfterEach
    void tearDown()
    {
        SecurityContextHolder.clearContext();
        RequestContextHolder.resetRequestAttributes();
    }

    @Test
    void context_delegates_to_current_context_service()
    {
        LoginUser loginUser = buildLoginUser(201L, "小程序用户");
        setSecurityContext(loginUser);
        Map<String, Object> payload = new HashMap<>();
        payload.put("tenantId", "HZ001");
        when(miniappAuthService.buildCurrentContext(loginUser)).thenReturn(payload);

        AjaxResult result = controller.context();

        assertEquals(200, result.get("code"));
        assertEquals(payload, result.get("data"));
        verify(miniappAuthService).buildCurrentContext(loginUser);
    }

    @Test
    void update_profile_delegates_to_profile_service()
    {
        LoginUser loginUser = buildLoginUser(202L, "待补资料用户");
        setSecurityContext(loginUser);
        Map<String, Object> request = new HashMap<>();
        request.put("displayName", "新昵称");
        Map<String, Object> payload = new HashMap<>();
        payload.put("userName", "新昵称");
        when(miniappAuthService.updateProfile(loginUser, request)).thenReturn(payload);

        AjaxResult result = controller.updateProfile(request);

        assertEquals(200, result.get("code"));
        assertEquals(payload, result.get("data"));
        verify(miniappAuthService).updateProfile(loginUser, request);
    }

    @Test
    void update_profile_propagates_service_exception()
    {
        LoginUser loginUser = buildLoginUser(203L, "待补资料用户");
        setSecurityContext(loginUser);
        Map<String, Object> request = new HashMap<>();
        request.put("displayName", "新昵称");
        when(miniappAuthService.updateProfile(loginUser, request))
                .thenThrow(new ServiceException("请先补全资料"));

        ServiceException exception = assertThrows(ServiceException.class, () -> controller.updateProfile(request));

        assertEquals("请先补全资料", exception.getMessage());
        verify(miniappAuthService).updateProfile(loginUser, request);
    }

    @Test
    void accept_invite_delegates_with_device_fingerprint()
    {
        LoginUser loginUser = buildLoginUser(204L, "受邀用户");
        setSecurityContext(loginUser);
        Map<String, Object> request = new HashMap<>();
        request.put("inviteCode", "INV123");
        request.put("inviteToken", "token-1");
        request.put("deviceFingerprint", "brand|model|ios");
        Map<String, Object> payload = new HashMap<>();
        payload.put("tenantId", "HZ001");
        when(miniappAuthService.acceptInvitation(loginUser, "INV123", "token-1", "brand|model|ios"))
                .thenReturn(payload);

        AjaxResult result = controller.acceptInvite(request);

        assertEquals(200, result.get("code"));
        assertEquals(payload, result.get("data"));
        verify(miniappAuthService).acceptInvitation(loginUser, "INV123", "token-1", "brand|model|ios");
    }

    @Test
    void hotels_delegates_to_current_user_service()
    {
        LoginUser loginUser = buildLoginUser(205L, "酒店用户");
        setSecurityContext(loginUser);
        List<Map<String, Object>> hotels = Arrays.asList(hotel("HZ001"), hotel("HZ002"));
        when(miniappAuthService.listHotels(loginUser)).thenReturn(hotels);

        AjaxResult result = controller.hotels();

        assertEquals(200, result.get("code"));
        assertEquals(hotels, result.get("data"));
        verify(miniappAuthService).listHotels(loginUser);
    }

    private LoginUser buildLoginUser(Long userId, String nickName)
    {
        SysRole role = new SysRole();
        role.setRoleKey("common");

        SysUser user = new SysUser();
        user.setUserId(userId);
        user.setNickName(nickName);
        user.setUserName(nickName);
        user.setRoles(Arrays.asList(role));

        LoginUser loginUser = new LoginUser();
        loginUser.setUserId(userId);
        loginUser.setUser(user);
        return loginUser;
    }

    private void setSecurityContext(LoginUser loginUser)
    {
        UsernamePasswordAuthenticationToken authentication =
                new UsernamePasswordAuthenticationToken(loginUser, null, loginUser.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    private Map<String, Object> hotel(String hotelId)
    {
        Map<String, Object> hotel = new HashMap<>();
        hotel.put("hotelId", hotelId);
        hotel.put("tenantId", hotelId);
        return hotel;
    }
}
