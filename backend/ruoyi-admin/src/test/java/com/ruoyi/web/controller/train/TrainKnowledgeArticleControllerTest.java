package com.ruoyi.web.controller.train;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.domain.model.LoginUser;
import com.ruoyi.train.domain.TrainKnowledgeArticle;
import com.ruoyi.train.service.ITrainKnowledgeArticleService;
import com.ruoyi.system.service.ISysDeptService;
import com.ruoyi.system.service.ISysUserService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import com.ruoyi.common.core.domain.AjaxResult;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * 知识文章 Controller 单元测试
 *
 * 测试策略：直接调用 Controller 方法（非 MockMvc），
 * 通过 SecurityContextHolder 注入 LoginUser 模拟认证上下文。
 */
@ExtendWith(MockitoExtension.class)
class TrainKnowledgeArticleControllerTest {

    @InjectMocks
    private TrainKnowledgeArticleController controller;

    @Mock
    private ITrainKnowledgeArticleService articleService;

    @Mock
    private ISysDeptService deptService;

    @Mock
    private ISysUserService userService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    // ---- helpers ----

    private LoginUser buildLoginUser(Long userId, String nickName, String tenantId,
                                     Long deptId, boolean admin) {
        SysUser sysUser = new SysUser();
        sysUser.setUserId(userId);
        sysUser.setNickName(nickName);
        sysUser.setTenantId(tenantId);
        sysUser.setDeptId(deptId);
        if (admin) {
            sysUser.setUserId(1L); // admin userId=1
        }

        LoginUser loginUser = new LoginUser();
        loginUser.setUserId(sysUser.getUserId());
        loginUser.setDeptId(deptId);
        loginUser.setUser(sysUser);
        loginUser.setPermissions(new HashSet<>(Arrays.asList("*:*:*")));
        return loginUser;
    }

    private void setSecurityContext(LoginUser loginUser) {
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken(loginUser, null, loginUser.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @BeforeEach
    void setUp() {
        SecurityContextHolder.clearContext();
        MockHttpServletRequest request = new MockHttpServletRequest();
        RequestContextHolder.setRequestAttributes(new ServletRequestAttributes(request));
    }

    // ---- getInfo tests ----

    @Test
    void getInfo_published_article_returns_success() {
        LoginUser loginUser = buildLoginUser(100L, "张三", "T001", 10L, false);
        setSecurityContext(loginUser);

        TrainKnowledgeArticle article = new TrainKnowledgeArticle();
        article.setArticleId(1L);
        article.setStatus("published");
        article.setAuthorId(200L);
        when(articleService.getArticleDetail(1L, 100L)).thenReturn(article);

        AjaxResult result = controller.getInfo(1L);
        assertEquals(200, result.get("code"));
    }

    @Test
    void getInfo_draft_by_other_user_returns_error() {
        LoginUser loginUser = buildLoginUser(100L, "张三", "T001", 10L, false);
        setSecurityContext(loginUser);

        TrainKnowledgeArticle article = new TrainKnowledgeArticle();
        article.setArticleId(1L);
        article.setStatus("draft");
        article.setAuthorId(200L); // different author
        when(articleService.getArticleDetail(1L, 100L)).thenReturn(article);

        AjaxResult result = controller.getInfo(1L);
        assertEquals(500, result.get("code")); // error
    }

    @Test
    void getInfo_draft_by_author_returns_success() {
        LoginUser loginUser = buildLoginUser(100L, "张三", "T001", 10L, false);
        setSecurityContext(loginUser);

        TrainKnowledgeArticle article = new TrainKnowledgeArticle();
        article.setArticleId(1L);
        article.setStatus("draft");
        article.setAuthorId(100L); // same author
        when(articleService.getArticleDetail(1L, 100L)).thenReturn(article);

        AjaxResult result = controller.getInfo(1L);
        assertEquals(200, result.get("code"));
    }

    // ---- add (create article) tests ----

    @Test
    void add_tenant_article_sets_tenant_id_from_user() {
        LoginUser loginUser = buildLoginUser(100L, "张三", "T001", 10L, false);
        setSecurityContext(loginUser);

        TrainKnowledgeArticle article = new TrainKnowledgeArticle();
        article.setTitle("测试文章");
        article.setContent("内容");
        article.setPublishScope("tenant");

        when(articleService.createArticle(any())).thenReturn(1);

        AjaxResult result = controller.add(article);
        assertEquals(200, result.get("code"));
        assertEquals(100L, article.getAuthorId());
        assertEquals("T001", article.getTenantId());
        assertEquals("张三", article.getAuthorName());
    }

    @Test
    void add_platform_article_by_non_admin_returns_error() {
        LoginUser loginUser = buildLoginUser(100L, "张三", "T001", 10L, false);
        setSecurityContext(loginUser);

        TrainKnowledgeArticle article = new TrainKnowledgeArticle();
        article.setTitle("全平台文章");
        article.setPublishScope("platform");

        AjaxResult result = controller.add(article);
        assertEquals(500, result.get("code")); // non-admin cannot publish platform
    }

    // ---- edit tests ----

    @Test
    void edit_calls_service_with_user_id() {
        LoginUser loginUser = buildLoginUser(100L, "张三", "T001", 10L, false);
        setSecurityContext(loginUser);

        TrainKnowledgeArticle article = new TrainKnowledgeArticle();
        article.setArticleId(1L);
        article.setTitle("更新标题");
        when(articleService.updateArticle(any(), eq(100L))).thenReturn(1);

        AjaxResult result = controller.edit(article);
        assertEquals(200, result.get("code"));
        verify(articleService).updateArticle(article, 100L);
    }

    // ---- remove tests ----

    @Test
    void remove_admin_can_delete_any_article() {
        LoginUser loginUser = buildLoginUser(1L, "管理员", "T001", 10L, true);
        setSecurityContext(loginUser);

        when(articleService.deleteArticle(eq(1L), eq(1L), eq(true))).thenReturn(1);

        AjaxResult result = controller.remove(1L);
        assertEquals(200, result.get("code"));
        verify(articleService).deleteArticle(1L, 1L, true);
    }

    @Test
    void remove_normal_user_passes_isAdmin_false() {
        LoginUser loginUser = buildLoginUser(100L, "张三", "T001", 10L, false);
        setSecurityContext(loginUser);

        when(articleService.deleteArticle(eq(1L), eq(100L), eq(false))).thenReturn(1);

        AjaxResult result = controller.remove(1L);
        assertEquals(200, result.get("code"));
        verify(articleService).deleteArticle(1L, 100L, false);
    }

    // ---- incrementView test ----

    @Test
    void incrementView_calls_service() {
        when(articleService.incrementViewCount(5L)).thenReturn(1);
        AjaxResult result = controller.incrementView(5L);
        assertEquals(200, result.get("code"));
    }

    // ---- search tests ----

    @Test
    void search_non_admin_forces_published_status() {
        LoginUser loginUser = buildLoginUser(100L, "张三", "T001", 10L, false);
        setSecurityContext(loginUser);

        when(articleService.searchArticles(eq("T001"), eq("关键词"), eq("published")))
                .thenReturn(new ArrayList<>());

        controller.search("关键词", "draft", "OTHER_TENANT");
        // non-admin: tenantId forced to user's, status forced to "published"
        verify(articleService).searchArticles("T001", "关键词", "published");
    }

    @Test
    void search_admin_can_specify_status_and_tenant() {
        LoginUser loginUser = buildLoginUser(1L, "管理员", "T001", 10L, true);
        setSecurityContext(loginUser);

        when(articleService.searchArticles(eq("T002"), eq("关键词"), eq("draft")))
                .thenReturn(new ArrayList<>());

        controller.search("关键词", "draft", "T002");
        verify(articleService).searchArticles("T002", "关键词", "draft");
    }
}
