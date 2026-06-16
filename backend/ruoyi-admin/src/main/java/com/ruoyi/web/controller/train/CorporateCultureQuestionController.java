package com.ruoyi.web.controller.train;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.Collections;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.system.domain.CorporateCultureQuestion;
import com.ruoyi.system.service.ICorporateCultureQuestionService;
import com.ruoyi.system.service.ISysUserService;

/**
 * 企业文化题目Controller
 */
@RestController
@RequestMapping("/train/culture-question")
public class CorporateCultureQuestionController extends BaseController {

    private static final Logger logger = LoggerFactory.getLogger(CorporateCultureQuestionController.class);

    @Autowired
    private ICorporateCultureQuestionService cultureQuestionService;

    @Autowired
    private ISysUserService userService;

    /**
     * 查询企业文化题目列表（管理端）
     */
    @PreAuthorize("@ss.hasPermi('train:cultureQuestion:list')")
    @GetMapping("/list")
    public TableDataInfo list(CorporateCultureQuestion query) {
        SysUser user = SecurityUtils.getLoginUser().getUser();
        logger.info("查询企业文化题目列表, user={}, isSuperAdmin={}, isPlatformAdmin={}",
            user.getUserName(), user.isSuperAdmin(), user.isPlatformAdmin());

        // 超管/平台管理员可以看到所有数据，不设置tenantId条件
        if (user.isSuperAdmin() || user.isPlatformAdmin()) {
            logger.info("超管/平台管理员查询所有数据");
            // 不设置tenantId，查询所有数据
        } else {
            String tenantId = user.getTenantId();
            if (StringUtils.isNotEmpty(tenantId)) {
                query.setTenantId(tenantId);
                logger.info("普通用户查询租户数据, tenantId={}", tenantId);
            }
        }
        startPage();
        List<CorporateCultureQuestion> list = cultureQuestionService.selectCorporateCultureQuestionList(query);
        logger.info("查询到 {} 条题目", list != null ? list.size() : 0);
        return getDataTable(list);
    }

    /**
     * 获取企业文化题目详情
     */
    @PreAuthorize("@ss.hasPermi('train:cultureQuestion:query')")
    @GetMapping("/{id}")
    public AjaxResult getInfo(@PathVariable Long id) {
        return success(cultureQuestionService.selectCorporateCultureQuestionById(id));
    }

    /**
     * 新增企业文化题目
     */
    @PreAuthorize("@ss.hasPermi('train:cultureQuestion:add')")
    @Log(title = "企业文化题目", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody CorporateCultureQuestion question) {
        // 设置租户ID：超管/平台管理员新增的是公共数据，普通租户新增的是私有数据
        try {
            SysUser user = SecurityUtils.getLoginUser().getUser();
            if (user.isSuperAdmin() || user.isPlatformAdmin()) {
                question.setTenantId("000000"); // 公共数据
                logger.info("超管/平台管理员新增企业文化题目，设置为公共数据");
            } else {
                String tenantId = user.getTenantId();
                if (StringUtils.isNotEmpty(tenantId)) {
                    question.setTenantId(tenantId); // 私有数据
                    logger.info("租户管理员新增企业文化题目, tenantId={}", tenantId);
                }
            }
        } catch (Exception e) {
            logger.warn("获取用户租户信息失败", e);
        }
        question.setCreateBy(getUsername());
        return toAjax(cultureQuestionService.insertCorporateCultureQuestion(question));
    }

    /**
     * 修改企业文化题目
     */
    @PreAuthorize("@ss.hasPermi('train:cultureQuestion:edit')")
    @Log(title = "企业文化题目", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody CorporateCultureQuestion question) {
        question.setUpdateBy(getUsername());
        return toAjax(cultureQuestionService.updateCorporateCultureQuestion(question));
    }

    /**
     * 删除企业文化题目
     */
    @PreAuthorize("@ss.hasPermi('train:cultureQuestion:remove')")
    @Log(title = "企业文化题目", businessType = BusinessType.DELETE)
    @DeleteMapping("/{ids}")
    public AjaxResult remove(@PathVariable Long[] ids) {
        return toAjax(cultureQuestionService.deleteCorporateCultureQuestionByIds(ids));
    }

    /**
     * 获取分类列表（管理端）
     */
    @PreAuthorize("@ss.hasPermi('train:cultureQuestion:list')")
    @GetMapping("/categories")
    public AjaxResult getCategories() {
        SysUser user = SecurityUtils.getLoginUser().getUser();
        logger.info("获取分类列表, user={}, isSuperAdmin={}, isPlatformAdmin={}",
            user.getUserName(), user.isSuperAdmin(), user.isPlatformAdmin());

        // 超管/平台管理员可以看到所有分类
        if (user.isSuperAdmin() || user.isPlatformAdmin()) {
            logger.info("超管/平台管理员查询所有分类");
            List<Map<String, Object>> categories = cultureQuestionService.selectAllCategories();
            logger.info("查询到 {} 个分类", categories != null ? categories.size() : 0);
            return success(categories);
        }

        // 普通用户按租户查询
        String tenantId = user.getTenantId();
        if (StringUtils.isEmpty(tenantId)) {
            logger.warn("用户租户ID为空，返回空列表");
            return success(new ArrayList<>());
        }

        List<Map<String, Object>> categories = cultureQuestionService.selectCategoriesByTenantId(tenantId);
        logger.info("查询到 {} 个分类", categories != null ? categories.size() : 0);
        return success(categories);
    }

    // ==================== 用户端接口（需要登录） ====================

    /**
     * 用户端获取企业文化题目分类（根据用户租户ID）
     */
    @GetMapping("/user/categories")
    public AjaxResult getUserCategories() {
        String tenantId = getCurrentTenantId();
        logger.info("【企业文化题库】用户端获取分类, tenantId={}", tenantId);
        
        // 调试：如果tenantId为空，返回调试信息
        if (StringUtils.isEmpty(tenantId)) {
            logger.warn("【企业文化题库】tenantId为空，返回空列表");
            Map<String, Object> debug = new HashMap<>();
            debug.put("error", "tenantId为空");
            debug.put("userId", SecurityUtils.getUserId());
            return AjaxResult.success("tenantId为空", Collections.emptyList());
        }
        
        try {
            List<Map<String, Object>> categories = cultureQuestionService.selectCategoriesByTenantId(tenantId);
            logger.info("【企业文化题库】查询到 {} 个分类, tenantId={}", categories != null ? categories.size() : 0, tenantId);
            
            if (categories == null || categories.isEmpty()) {
                logger.warn("【企业文化题库】未查询到分类数据，tenantId={}", tenantId);
                // 返回调试信息
                return AjaxResult.success("查询结果为空,tenantId=" + tenantId, Collections.emptyList());
            }
            
            int id = 1;
            for (Map<String, Object> cat : categories) {
                cat.put("id", "culture_" + id++);
                cat.put("type", "culture");
            }
            return success(categories);
        } catch (Exception e) {
            logger.error("【企业文化题库】查询分类异常", e);
            return AjaxResult.error("查询异常: " + e.getMessage());
        }
    }

    /**
     * 用户端获取企业文化题目列表
     */
    @GetMapping("/user/list")
    public AjaxResult getUserQuestions(@RequestParam(required = false) String category) {
        String tenantId = getCurrentTenantId();
        logger.info("用户端获取企业文化题目, tenantId={}, category={}", tenantId, category);
        
        if (StringUtils.isEmpty(tenantId)) {
            return success(Collections.emptyList());
        }
        
        List<CorporateCultureQuestion> list;
        if (StringUtils.isNotEmpty(category)) {
            list = cultureQuestionService.selectByTenantIdAndCategory(tenantId, category);
        } else {
            list = cultureQuestionService.selectByTenantId(tenantId);
        }
        return success(list);
    }

    /**
     * 用户端获取企业文化题目详情
     */
    @GetMapping("/user/detail/{id}")
    public AjaxResult getUserQuestionDetail(@PathVariable Long id) {
        String tenantId = getCurrentTenantId();
        if (StringUtils.isEmpty(tenantId)) {
            return error("未获取到租户信息");
        }
        CorporateCultureQuestion question = cultureQuestionService.selectCorporateCultureQuestionById(id);
        if (question == null) {
            return error("题目不存在");
        }
        String questionTenantId = question.getTenantId();
        if (StringUtils.isNotEmpty(questionTenantId)
                && !"000000".equals(questionTenantId)
                && !tenantId.equals(questionTenantId)) {
            return error("无权访问该题目");
        }
        return success(question);
    }

    /**
     * 用户端获取题目统计
     */
    @GetMapping("/user/stats")
    public AjaxResult getUserStats() {
        String tenantId = getCurrentTenantId();
        if (StringUtils.isEmpty(tenantId)) {
            Map<String, Object> emptyStats = new HashMap<>();
            emptyStats.put("totalCount", 0);
            emptyStats.put("categoryCount", 0);
            return success(emptyStats);
        }
        
        int totalCount = cultureQuestionService.countByTenantId(tenantId);
        List<Map<String, Object>> categories = cultureQuestionService.selectCategoriesByTenantId(tenantId);
        
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalCount", totalCount);
        stats.put("categoryCount", categories.size());
        return success(stats);
    }

    /**
     * 获取当前用户的租户ID
     */
    private String getCurrentTenantId() {
        try {
            Long userId = SecurityUtils.getUserId();
            if (userId == null) {
                return null;
            }
            SysUser user = userService.selectUserById(userId);
            if (user != null && StringUtils.isNotEmpty(user.getTenantId())) {
                return user.getTenantId();
            }
            if (user != null && user.getDept() != null && StringUtils.isNotEmpty(user.getDept().getTenantId())) {
                return user.getDept().getTenantId();
            }
        } catch (Exception e) {
            logger.error("获取租户ID失败", e);
        }
        return null;
    }
}
