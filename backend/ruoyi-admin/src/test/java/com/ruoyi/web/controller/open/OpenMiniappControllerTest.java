package com.ruoyi.web.controller.open;

import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysRole;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.domain.model.LoginUser;
import com.ruoyi.framework.web.service.MiniappAuthService;
import com.ruoyi.train.service.ITrainAiService;
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

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicLong;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OpenMiniappControllerTest
{
    @InjectMocks
    private OpenMiniappController controller;

    @Mock
    private MiniappAuthService miniappAuthService;

    @Mock
    private ITrainAiService trainAiService;

    @BeforeEach
    void setUp() throws Exception
    {
        SecurityContextHolder.clearContext();
        RequestContextHolder.setRequestAttributes(new ServletRequestAttributes(new MockHttpServletRequest()));
        clearControllerState();
    }

    @AfterEach
    void tearDown() throws Exception
    {
        SecurityContextHolder.clearContext();
        RequestContextHolder.resetRequestAttributes();
        clearControllerState();
    }

    @Test
    void ask_anonymous_hotel_request_requires_login()
    {
        Map<String, Object> request = new HashMap<>();
        request.put("question", "早餐几点开始");
        request.put("hotelId", "HZ001");

        AjaxResult result = controller.ask(request);

        assertEquals(401, result.get("code"));
        assertEquals("选择酒店咨询前请先登录", result.get("msg"));
    }

    @Test
    void ask_logged_in_without_hotel_requires_selection_when_user_has_access()
    {
        setSecurityContext(buildLoginUser(101L, "咨询用户", false, role("common")));
        when(miniappAuthService.listAccessibleHotels(101L))
                .thenReturn(Arrays.asList(hotel("HZ001"), hotel("HZ002")));

        Map<String, Object> request = new HashMap<>();
        request.put("question", "我想咨询入住");

        AjaxResult result = controller.ask(request);

        assertEquals(403, result.get("code"));
        assertEquals("请先选择服务酒店后再发起咨询", result.get("msg"));
    }

    @Test
    void transfer_anonymous_public_session_is_allowed()
    {
        seedSession("S-PUBLIC", "PUBLIC", "游客咨询", "AI_REPLIED");

        Map<String, Object> request = new HashMap<>();
        request.put("sessionId", "S-PUBLIC");
        request.put("reason", "未解决");

        AjaxResult result = controller.transfer(request);

        assertEquals(200, result.get("code"));
        Map<String, Object> session = getSessions().get("S-PUBLIC");
        assertEquals("WAITING_STAFF", session.get("status"));
        assertEquals("已转人工，等待员工接入", session.get("queueStatus"));
    }

    @Test
    void transfer_anonymous_hotel_session_requires_login()
    {
        seedSession("S-HOTEL", "HZ001", "测试酒店", "AI_REPLIED");

        Map<String, Object> request = new HashMap<>();
        request.put("sessionId", "S-HOTEL");

        AjaxResult result = controller.transfer(request);

        assertEquals(401, result.get("code"));
        assertEquals("登录状态已失效，请重新登录", result.get("msg"));
    }

    @Test
    void tickets_common_user_is_forbidden()
    {
        setSecurityContext(buildLoginUser(102L, "普通用户", false, role("common")));

        AjaxResult result = controller.tickets("");

        assertEquals(403, result.get("code"));
        assertEquals("当前账号没有员工处理权限", result.get("msg"));
    }

    @Test
    void staff_reply_uses_authenticated_operator_name()
    {
        setSecurityContext(buildLoginUser(103L, "值班小张", false, role("leader")));
        seedSession("S-STAFF", "HZ001", "测试酒店", "WAITING_STAFF");
        doNothing().when(miniappAuthService).validateHotelAccess(103L, "HZ001");

        Map<String, Object> request = new HashMap<>();
        request.put("sessionId", "S-STAFF");
        request.put("content", "我来处理");
        request.put("staffName", "前端伪造名字");

        AjaxResult result = controller.staffReply(request);

        assertEquals(200, result.get("code"));
        verify(miniappAuthService).validateHotelAccess(103L, "HZ001");
        Map<String, Object> session = getSessions().get("S-STAFF");
        assertEquals("值班小张", session.get("assignedStaff"));
        assertEquals("IN_SERVICE", session.get("status"));
    }

    @Test
    void todo_requires_existing_session()
    {
        setSecurityContext(buildLoginUser(104L, "值班小李", false, role("leader")));

        Map<String, Object> request = new HashMap<>();
        request.put("sessionId", "NOT-FOUND");
        request.put("issue", "补知识库");

        AjaxResult result = controller.todo(request);

        assertEquals(500, result.get("code"));
        assertEquals("会话不存在", result.get("msg"));
    }

    @Test
    void overview_filters_todo_and_teach_counts_by_accessible_hotels()
    {
        setSecurityContext(buildLoginUser(105L, "店长", true, role("company_admin")));
        when(miniappAuthService.listAccessibleHotels(105L)).thenReturn(Arrays.asList(hotel("HZ001")));
        seedSession("S-H1", "HZ001", "酒店一", "WAITING_STAFF");
        seedSession("S-H2", "HZ002", "酒店二", "WAITING_STAFF");
        seedTodo("TD-1", "S-H1");
        seedTodo("TD-2", "S-H2");
        seedTeach("TE-1", "S-H1");
        seedTeach("TE-2", "S-H2");

        AjaxResult result = controller.overview("");

        assertEquals(200, result.get("code"));
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) result.get("data");
        assertNotNull(data);
        assertEquals(1, data.get("consultCount"));
        assertEquals(1, data.get("waitingCount"));
        assertEquals(1, data.get("todoCount"));
        assertEquals(1, data.get("teachEntryCount"));
    }

    private LoginUser buildLoginUser(Long userId, String nickName, boolean canAccessAdmin, SysRole... roles)
    {
        SysUser user = new SysUser();
        user.setUserId(userId);
        user.setNickName(nickName);
        user.setUserName(nickName);
        user.setCanAccessAdmin(canAccessAdmin);
        user.setRoles(Arrays.asList(roles));

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

    private SysRole role(String roleKey)
    {
        SysRole role = new SysRole();
        role.setRoleKey(roleKey);
        return role;
    }

    private Map<String, Object> hotel(String hotelId)
    {
        Map<String, Object> hotel = new HashMap<>();
        hotel.put("hotelId", hotelId);
        hotel.put("tenantId", hotelId);
        return hotel;
    }

    private void seedSession(String sessionId, String hotelId, String hotelName, String status)
    {
        Map<String, Object> session = new HashMap<>();
        session.put("sessionId", sessionId);
        session.put("hotelId", hotelId);
        session.put("hotelName", hotelName);
        session.put("status", status);
        session.put("queueStatus", "");
        session.put("updateTime", "2026-04-21 12:00:00");
        session.put("messages", new ArrayList<Map<String, Object>>());
        session.put("transferCount", 0);
        getSessions().put(sessionId, session);
    }

    private void seedTodo(String todoId, String sessionId)
    {
        Map<String, Object> item = new HashMap<>();
        item.put("todoId", todoId);
        item.put("sessionId", sessionId);
        getTodos().add(item);
    }

    private void seedTeach(String teachId, String sessionId)
    {
        Map<String, Object> item = new HashMap<>();
        item.put("teachEntryId", teachId);
        item.put("sessionId", sessionId);
        getTeachEntries().add(item);
    }

    @SuppressWarnings("unchecked")
    private ConcurrentHashMap<String, Map<String, Object>> getSessions()
    {
        return (ConcurrentHashMap<String, Map<String, Object>>) getStaticField("SESSIONS");
    }

    @SuppressWarnings("unchecked")
    private CopyOnWriteArrayList<Map<String, Object>> getTodos()
    {
        return (CopyOnWriteArrayList<Map<String, Object>>) getStaticField("TODOS");
    }

    @SuppressWarnings("unchecked")
    private CopyOnWriteArrayList<Map<String, Object>> getTeachEntries()
    {
        return (CopyOnWriteArrayList<Map<String, Object>>) getStaticField("TEACH_ENTRIES");
    }

    private Object getStaticField(String fieldName)
    {
        try
        {
            Field field = OpenMiniappController.class.getDeclaredField(fieldName);
            field.setAccessible(true);
            return field.get(null);
        }
        catch (Exception e)
        {
            throw new IllegalStateException("读取静态字段失败: " + fieldName, e);
        }
    }

    private void clearControllerState() throws Exception
    {
        getSessions().clear();
        getTodos().clear();
        getTeachEntries().clear();
        resetSequence("SESSION_SEQ");
        resetSequence("TODO_SEQ");
        resetSequence("TEACH_SEQ");
    }

    private void resetSequence(String fieldName) throws Exception
    {
        Field field = OpenMiniappController.class.getDeclaredField(fieldName);
        field.setAccessible(true);
        AtomicLong sequence = (AtomicLong) field.get(null);
        sequence.set(1L);
    }
}
