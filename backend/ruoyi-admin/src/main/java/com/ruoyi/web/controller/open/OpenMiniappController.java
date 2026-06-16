package com.ruoyi.web.controller.open;

import com.ruoyi.common.annotation.Anonymous;
import com.ruoyi.common.constant.HttpStatus;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysRole;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.domain.model.LoginUser;
import com.ruoyi.common.exception.ServiceException;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.framework.web.service.MiniappAuthService;
import com.ruoyi.train.service.ITrainAiService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Collectors;

/**
 * 微信小程序开放接口（MVP骨架）。
 *
 * 说明：
 * 1) 当前使用内存态会话/待办/教导库，便于先跑通端到端流程；
 * 2) 后续可平滑替换为数据库实现；
 * 3) 核心业务规则已内置：未解决即刻转人工、待办沉淀教导库。
 */
@RestController
@RequestMapping("/miniapp")
public class OpenMiniappController extends BaseController
{
    private static final ConcurrentHashMap<String, Map<String, Object>> SESSIONS = new ConcurrentHashMap<>();
    private static final CopyOnWriteArrayList<Map<String, Object>> TODOS = new CopyOnWriteArrayList<>();
    private static final CopyOnWriteArrayList<Map<String, Object>> TEACH_ENTRIES = new CopyOnWriteArrayList<>();

    private static final AtomicLong SESSION_SEQ = new AtomicLong(1);
    private static final AtomicLong TODO_SEQ = new AtomicLong(1);
    private static final AtomicLong TEACH_SEQ = new AtomicLong(1);

    @Autowired(required = false)
    private ITrainAiService trainAiService;

    @Autowired
    private MiniappAuthService miniappAuthService;

    @Anonymous
    @PostMapping("/auth/wechat-login")
    public AjaxResult wechatLogin(@RequestBody Map<String, Object> request)
    {
        return success(miniappAuthService.loginWithWechat(
                asString(request.get("code")),
                asString(request.get("role")),
                asString(request.get("inviteCode")),
                asString(request.get("inviteToken"))));
    }

    /**
     * 客户咨询 AI。
     */
    @Anonymous
    @PostMapping("/consult/ask")
    public AjaxResult ask(@RequestBody Map<String, Object> request)
    {
        String question = asString(request.get("question"));
        if (StringUtils.isEmpty(question))
        {
            return AjaxResult.error("问题不能为空");
        }

        String hotelId = asString(request.get("hotelId"));
        String hotelName = asString(request.get("hotelName"));
        Long currentUserId = resolveCurrentUserId();
        if (currentUserId == null && StringUtils.isNotEmpty(hotelId))
        {
            return AjaxResult.error(HttpStatus.UNAUTHORIZED, "选择酒店咨询前请先登录");
        }
        if (StringUtils.isNotEmpty(hotelId) && currentUserId != null)
        {
            try
            {
                miniappAuthService.validateHotelAccess(currentUserId, hotelId);
            }
            catch (ServiceException e)
            {
                return AjaxResult.error(HttpStatus.FORBIDDEN, e.getMessage());
            }
        }
        if (StringUtils.isEmpty(hotelId))
        {
            if (currentUserId != null && !resolveAccessibleHotelIds(currentUserId).isEmpty())
            {
                return AjaxResult.error(HttpStatus.FORBIDDEN, "请先选择服务酒店后再发起咨询");
            }
            hotelId = "PUBLIC";
        }
        if (StringUtils.isEmpty(hotelName))
        {
            hotelName = "PUBLIC".equals(hotelId) ? "游客咨询" : hotelId;
        }

        String sessionId = asString(request.get("sessionId"));
        if (StringUtils.isEmpty(sessionId))
        {
            sessionId = nextId("MS", SESSION_SEQ);
        }

        Map<String, Object> session = SESSIONS.get(sessionId);
        if (session == null)
        {
            session = new HashMap<>();
            session.put("sessionId", sessionId);
            session.put("hotelId", hotelId);
            session.put("hotelName", hotelName);
            session.put("status", "AI_REPLIED");
            session.put("queueStatus", "");
            session.put("createTime", now());
            session.put("messages", new ArrayList<Map<String, Object>>());
            session.put("transferCount", 0);
        }

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> messages = (List<Map<String, Object>>) session.get("messages");
        messages.add(msg("user", question));

        String aiReply = generateAiReply(sessionId, question);
        messages.add(msg("ai", aiReply));

        session.put("status", "AI_REPLIED");
        session.put("lastQuestion", question);
        session.put("lastAiReply", aiReply);
        session.put("updateTime", now());
        SESSIONS.put(sessionId, session);

        Map<String, Object> data = new HashMap<>();
        data.put("sessionId", sessionId);
        data.put("aiReply", aiReply);
        data.put("status", session.get("status"));
        data.put("queueStatus", session.get("queueStatus"));
        return AjaxResult.success(data);
    }

    /**
     * 未解决即刻转人工。
     */
    @Anonymous
    @PostMapping("/consult/transfer")
    public AjaxResult transfer(@RequestBody Map<String, Object> request)
    {
        String sessionId = asString(request.get("sessionId"));
        if (StringUtils.isEmpty(sessionId))
        {
            return AjaxResult.error("sessionId 不能为空");
        }

        Map<String, Object> session = SESSIONS.get(sessionId);
        if (session == null)
        {
            return AjaxResult.error("会话不存在");
        }
        Long currentUserId = resolveCurrentUserId();
        AjaxResult sessionAccessError = validateSessionAccess(session, currentUserId, true);
        if (sessionAccessError != null)
        {
            return sessionAccessError;
        }

        int transferCount = asInt(session.get("transferCount")) + 1;
        session.put("transferCount", transferCount);
        session.put("status", "WAITING_STAFF");
        session.put("queueStatus", "已转人工，等待员工接入");
        session.put("transferReason", asString(request.get("reason")));
        session.put("transferAt", now());
        session.put("updateTime", now());

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> messages = (List<Map<String, Object>>) session.get("messages");
        messages.add(msg("system", "用户问题未解决，系统已即时转人工。"));
        SESSIONS.put(sessionId, session);

        Map<String, Object> data = new HashMap<>();
        data.put("sessionId", sessionId);
        data.put("queueStatus", session.get("queueStatus"));
        data.put("notifiedStaffCount", 3);
        data.put("status", session.get("status"));
        return AjaxResult.success(data);
    }

    /**
     * 员工工单列表。
     */
    @GetMapping("/staff/tickets")
    public AjaxResult tickets(@RequestParam(value = "hotelId", required = false) String hotelId)
    {
        LoginUser loginUser = requireLoginUser();
        if (loginUser == null)
        {
            return AjaxResult.error(HttpStatus.UNAUTHORIZED, "登录状态已失效，请重新登录");
        }
        if (!hasStaffAccess(loginUser.getUser()))
        {
            return AjaxResult.error(HttpStatus.FORBIDDEN, "当前账号没有员工处理权限");
        }
        Long currentUserId = loginUser.getUserId();
        if (StringUtils.isNotEmpty(hotelId))
        {
            try
            {
                miniappAuthService.validateHotelAccess(currentUserId, hotelId);
            }
            catch (ServiceException e)
            {
                return AjaxResult.error(HttpStatus.FORBIDDEN, e.getMessage());
            }
        }
        Set<String> accessibleHotelIds = StringUtils.isEmpty(hotelId)
                ? resolveAccessibleHotelIds(currentUserId)
                : Collections.emptySet();
        List<Map<String, Object>> list = new ArrayList<>(SESSIONS.values());
        list = list.stream()
            .filter(item -> {
                String status = asString(item.get("status"));
                boolean statusMatch = "WAITING_STAFF".equals(status) || "IN_SERVICE".equals(status);
                boolean hotelMatch = StringUtils.isNotEmpty(hotelId)
                        ? hotelId.equals(asString(item.get("hotelId")))
                        : accessibleHotelIds.contains(asString(item.get("hotelId")));
                return statusMatch && hotelMatch;
            })
            .sorted(Comparator.comparing(item -> asString(item.get("updateTime")), Comparator.reverseOrder()))
            .collect(Collectors.toList());

        return AjaxResult.success(list);
    }

    /**
     * 员工回复。
     */
    @PostMapping("/staff/reply")
    public AjaxResult staffReply(@RequestBody Map<String, Object> request)
    {
        LoginUser loginUser = requireLoginUser();
        if (loginUser == null)
        {
            return AjaxResult.error(HttpStatus.UNAUTHORIZED, "登录状态已失效，请重新登录");
        }
        if (!hasStaffAccess(loginUser.getUser()))
        {
            return AjaxResult.error(HttpStatus.FORBIDDEN, "当前账号没有员工处理权限");
        }
        String sessionId = asString(request.get("sessionId"));
        String content = asString(request.get("content"));
        if (StringUtils.isEmpty(sessionId) || StringUtils.isEmpty(content))
        {
            return AjaxResult.error("sessionId 和 content 不能为空");
        }

        Map<String, Object> session = SESSIONS.get(sessionId);
        if (session == null)
        {
            return AjaxResult.error("会话不存在");
        }
        AjaxResult sessionAccessError = validateSessionAccess(session, loginUser.getUserId(), false);
        if (sessionAccessError != null)
        {
            return sessionAccessError;
        }

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> messages = (List<Map<String, Object>>) session.get("messages");
        messages.add(msg("staff", content));

        String staffName = resolveOperatorName(loginUser);
        if (StringUtils.isEmpty(staffName))
        {
            staffName = "值班员工";
        }

        session.put("assignedStaff", staffName);
        session.put("status", "IN_SERVICE");
        session.put("queueStatus", "员工处理中");
        session.put("updateTime", now());

        boolean resolved = Boolean.TRUE.equals(request.get("resolved"));
        if (resolved)
        {
            session.put("status", "RESOLVED");
            session.put("queueStatus", "已解决");
            messages.add(msg("system", "会话已标记为已解决。"));
        }

        SESSIONS.put(sessionId, session);

        Map<String, Object> data = new HashMap<>();
        data.put("sessionId", sessionId);
        data.put("status", session.get("status"));
        data.put("queueStatus", session.get("queueStatus"));
        return AjaxResult.success(data);
    }

    /**
     * 待办沉淀 + 教导数据库候选入库。
     */
    @PostMapping("/staff/todo")
    public AjaxResult todo(@RequestBody Map<String, Object> request)
    {
        LoginUser loginUser = requireLoginUser();
        if (loginUser == null)
        {
            return AjaxResult.error(HttpStatus.UNAUTHORIZED, "登录状态已失效，请重新登录");
        }
        if (!hasStaffAccess(loginUser.getUser()))
        {
            return AjaxResult.error(HttpStatus.FORBIDDEN, "当前账号没有员工处理权限");
        }
        String sessionId = asString(request.get("sessionId"));
        String issue = asString(request.get("issue"));
        if (StringUtils.isEmpty(issue))
        {
            return AjaxResult.error("issue 不能为空");
        }
        Map<String, Object> session = SESSIONS.get(sessionId);
        if (session == null)
        {
            return AjaxResult.error("会话不存在");
        }
        if (session != null)
        {
            AjaxResult sessionAccessError = validateSessionAccess(session, loginUser.getUserId(), false);
            if (sessionAccessError != null)
            {
                return sessionAccessError;
            }
        }

        String todoId = nextId("TD", TODO_SEQ);
        String teachEntryId = nextId("TE", TEACH_SEQ);

        Map<String, Object> todo = new HashMap<>();
        todo.put("todoId", todoId);
        todo.put("sessionId", sessionId);
        todo.put("issue", issue);
        todo.put("todoType", asString(request.get("todoType")));
        todo.put("teachCategory", asString(request.get("teachCategory")));
        todo.put("source", asString(request.get("source")));
        todo.put("status", "PENDING_LEARN");
        todo.put("createTime", now());
        TODOS.add(todo);

        Map<String, Object> teach = new HashMap<>();
        teach.put("teachEntryId", teachEntryId);
        teach.put("sessionId", sessionId);
        teach.put("issue", issue);
        teach.put("wrongAnswer", asString(request.get("wrongAnswer")));
        teach.put("correctAnswer", asString(request.get("correctAnswer")));
        teach.put("trainStatus", "PENDING_REVIEW");
        teach.put("createTime", now());
        TEACH_ENTRIES.add(teach);

        session = SESSIONS.get(sessionId);
        if (session != null)
        {
            session.put("lastTodoId", todoId);
            session.put("lastTeachEntryId", teachEntryId);
            session.put("updateTime", now());
            SESSIONS.put(sessionId, session);
        }

        Map<String, Object> data = new HashMap<>();
        data.put("todoId", todoId);
        data.put("teachEntryId", teachEntryId);
        data.put("trainStatus", "PENDING_REVIEW");
        return AjaxResult.success(data);
    }

    /**
     * 管理看板概览。
     */
    @GetMapping("/admin/overview")
    public AjaxResult overview(@RequestParam(value = "hotelId", required = false) String hotelId)
    {
        LoginUser loginUser = requireLoginUser();
        if (loginUser == null)
        {
            return AjaxResult.error(HttpStatus.UNAUTHORIZED, "登录状态已失效，请重新登录");
        }
        if (!hasAdminAccess(loginUser.getUser()))
        {
            return AjaxResult.error(HttpStatus.FORBIDDEN, "当前账号没有管理看板权限");
        }
        Long currentUserId = loginUser.getUserId();
        if (StringUtils.isNotEmpty(hotelId))
        {
            try
            {
                miniappAuthService.validateHotelAccess(currentUserId, hotelId);
            }
            catch (ServiceException e)
            {
                return AjaxResult.error(HttpStatus.FORBIDDEN, e.getMessage());
            }
        }
        Set<String> accessibleHotelIds = StringUtils.isEmpty(hotelId)
                ? resolveAccessibleHotelIds(currentUserId)
                : Collections.emptySet();
        List<Map<String, Object>> sessions = new ArrayList<>(SESSIONS.values());
        sessions = sessions.stream()
            .filter(item -> StringUtils.isNotEmpty(hotelId)
                    ? hotelId.equals(asString(item.get("hotelId")))
                    : accessibleHotelIds.contains(asString(item.get("hotelId"))))
            .collect(Collectors.toList());

        int consultCount = sessions.size();
        int waitingCount = (int) sessions.stream().filter(item -> "WAITING_STAFF".equals(asString(item.get("status")))).count();
        int inServiceCount = (int) sessions.stream().filter(item -> "IN_SERVICE".equals(asString(item.get("status")))).count();
        int resolvedCount = (int) sessions.stream().filter(item -> "RESOLVED".equals(asString(item.get("status")))).count();
        int transferCount = sessions.stream().mapToInt(item -> asInt(item.get("transferCount"))).sum();

        int todoCount = (int) TODOS.stream().filter(item -> {
            if (StringUtils.isEmpty(hotelId))
            {
                String sid = asString(item.get("sessionId"));
                Map<String, Object> session = SESSIONS.get(sid);
                return session != null && accessibleHotelIds.contains(asString(session.get("hotelId")));
            }
            String sid = asString(item.get("sessionId"));
            Map<String, Object> session = SESSIONS.get(sid);
            return session != null && hotelId.equals(asString(session.get("hotelId")));
        }).count();

        int teachCount = (int) TEACH_ENTRIES.stream().filter(item -> {
            if (StringUtils.isEmpty(hotelId))
            {
                String sid = asString(item.get("sessionId"));
                Map<String, Object> session = SESSIONS.get(sid);
                return session != null && accessibleHotelIds.contains(asString(session.get("hotelId")));
            }
            String sid = asString(item.get("sessionId"));
            Map<String, Object> session = SESSIONS.get(sid);
            return session != null && hotelId.equals(asString(session.get("hotelId")));
        }).count();

        String repeatErrorRate = "0.00%";
        if (consultCount > 0)
        {
            double rate = (teachCount * 100.0D) / consultCount;
            repeatErrorRate = String.format("%.2f%%", rate);
        }

        Map<String, Object> data = new HashMap<>();
        data.put("consultCount", consultCount);
        data.put("immediateTransferCount", transferCount);
        data.put("waitingCount", waitingCount);
        data.put("inServiceCount", inServiceCount);
        data.put("resolvedCount", resolvedCount);
        data.put("todoCount", todoCount);
        data.put("teachEntryCount", teachCount);
        data.put("repeatErrorRate", repeatErrorRate);
        data.put("updateTime", now());
        return AjaxResult.success(data);
    }

    private String generateAiReply(String sessionId, String question)
    {
        if (trainAiService != null)
        {
            try
            {
                long pseudoUserId = Math.abs((long) sessionId.hashCode()) + 100000L;
                String ai = trainAiService.chatWithAi(pseudoUserId, sessionId, question);
                if (StringUtils.isNotEmpty(ai))
                {
                    return ai;
                }
            }
            catch (Exception ignored)
            {
            }
        }

        if (question.contains("早餐"))
        {
            return "早餐一般在 07:00-10:00，建议以酒店前台当日通知为准。";
        }
        if (question.contains("空调"))
        {
            return "建议先确认温度设定与电源，如仍异常我可以立即帮您转人工处理。";
        }
        if (question.contains("发票"))
        {
            return "您可在退房时或通过前台登记开票信息办理发票。";
        }
        return "已收到您的问题，我可以继续为您查询；若未解决可立即转人工。";
    }

    private static String asString(Object value)
    {
        return value == null ? "" : String.valueOf(value).trim();
    }

    private static int asInt(Object value)
    {
        if (value == null)
        {
            return 0;
        }
        if (value instanceof Number)
        {
            return ((Number) value).intValue();
        }
        try
        {
            return Integer.parseInt(String.valueOf(value));
        }
        catch (Exception e)
        {
            return 0;
        }
    }

    private static Map<String, Object> msg(String role, String content)
    {
        Map<String, Object> map = new HashMap<>();
        map.put("role", role);
        map.put("content", content);
        map.put("time", now());
        return map;
    }

    private static Map<String, Object> hotel(String id, String name)
    {
        Map<String, Object> map = new HashMap<>();
        map.put("id", id);
        map.put("name", name);
        return map;
    }

    private static String nextId(String prefix, AtomicLong seq)
    {
        String ts = new SimpleDateFormat("yyyyMMddHHmmss").format(new Date());
        return prefix + ts + String.format("%04d", seq.getAndIncrement());
    }

    private static String now()
    {
        return new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());
    }

    private Long resolveCurrentUserId()
    {
        try
        {
            return SecurityUtils.getUserId();
        }
        catch (Exception e)
        {
            return null;
        }
    }

    private LoginUser requireLoginUser()
    {
        try
        {
            return SecurityUtils.getLoginUser();
        }
        catch (Exception e)
        {
            return null;
        }
    }

    private AjaxResult validateSessionAccess(Map<String, Object> session, Long currentUserId, boolean allowAnonymousPublic)
    {
        String sessionHotelId = asString(session.get("hotelId"));
        if (isPublicSession(sessionHotelId))
        {
            if (allowAnonymousPublic || currentUserId != null)
            {
                return null;
            }
            return AjaxResult.error(HttpStatus.UNAUTHORIZED, "登录状态已失效，请重新登录");
        }
        if (currentUserId == null)
        {
            return AjaxResult.error(HttpStatus.UNAUTHORIZED, "登录状态已失效，请重新登录");
        }
        try
        {
            miniappAuthService.validateHotelAccess(currentUserId, sessionHotelId);
            return null;
        }
        catch (ServiceException e)
        {
            return AjaxResult.error(HttpStatus.FORBIDDEN, e.getMessage());
        }
    }

    private boolean isPublicSession(String hotelId)
    {
        return StringUtils.isEmpty(hotelId) || "PUBLIC".equalsIgnoreCase(StringUtils.trim(hotelId));
    }

    private boolean hasStaffAccess(SysUser user)
    {
        return hasAnyRole(user, "admin", "platform", "tenant_admin", "company_admin", "dept_admin", "leader", "manager");
    }

    private boolean hasAdminAccess(SysUser user)
    {
        if (user == null)
        {
            return false;
        }
        if (user.hasAdminAccess())
        {
            return true;
        }
        return hasAnyRole(user, "admin", "platform", "tenant_admin", "company_admin");
    }

    private boolean hasAnyRole(SysUser user, String... roleKeys)
    {
        if (user == null || user.getRoles() == null || user.getRoles().isEmpty())
        {
            return false;
        }
        Set<String> currentRoles = user.getRoles().stream()
                .map(SysRole::getRoleKey)
                .filter(StringUtils::isNotEmpty)
                .collect(Collectors.toSet());
        for (String roleKey : roleKeys)
        {
            if (currentRoles.contains(roleKey))
            {
                return true;
            }
        }
        return false;
    }

    private String resolveOperatorName(LoginUser loginUser)
    {
        if (loginUser == null || loginUser.getUser() == null)
        {
            return "";
        }
        SysUser user = loginUser.getUser();
        if (StringUtils.isNotEmpty(user.getNickName()))
        {
            return user.getNickName();
        }
        if (StringUtils.isNotEmpty(user.getUserName()))
        {
            return user.getUserName();
        }
        return "";
    }

    private Set<String> resolveAccessibleHotelIds(Long userId)
    {
        if (userId == null)
        {
            return Collections.emptySet();
        }
        List<Map<String, Object>> hotels = miniappAuthService.listAccessibleHotels(userId);
        Set<String> hotelIds = new HashSet<>();
        for (Map<String, Object> hotel : hotels)
        {
            String hotelId = asString(hotel.get("hotelId"));
            if (StringUtils.isEmpty(hotelId))
            {
                hotelId = asString(hotel.get("tenantId"));
            }
            if (StringUtils.isNotEmpty(hotelId))
            {
                hotelIds.add(hotelId);
            }
        }
        return hotelIds;
    }
}
