package com.ruoyi.web.controller.train;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.Collections;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
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
import com.ruoyi.system.domain.GreenHotelQuestion;
import com.ruoyi.system.service.IGreenHotelQuestionService;
import com.ruoyi.system.service.ISysUserService;

/**
 * 绿色饭店题目Controller
 */
@RestController
@RequestMapping("/train/green-hotel-question")
public class GreenHotelQuestionController extends BaseController {

    private static final Logger logger = LoggerFactory.getLogger(GreenHotelQuestionController.class);

    @Autowired
    private IGreenHotelQuestionService greenHotelQuestionService;

    @Autowired
    private ISysUserService userService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private boolean hasGreenHotelQuestionCourseIdColumn() {
        try {
            Integer columnCount = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'green_hotel_question' AND COLUMN_NAME = 'course_id'",
                    Integer.class);
            return columnCount != null && columnCount > 0;
        } catch (Exception e) {
            logger.warn("检查green_hotel_question.course_id字段失败", e);
            return false;
        }
    }

    private List<GreenHotelQuestion> selectByTenantIdAndCourseId(String tenantId, Long courseId) {
        if (courseId == null || !hasGreenHotelQuestionCourseIdColumn()) {
            return new ArrayList<>();
        }
        String sql = "SELECT id, course_id AS courseId, tenant_id AS tenantId, category, question_type AS questionType, " +
                "question_text AS questionText, option_a AS optionA, option_b AS optionB, option_c AS optionC, option_d AS optionD, " +
                "correct_answer AS correctAnswer, explanation, difficulty, sort_order AS sortOrder, status, create_time AS createTime, " +
                "update_time AS updateTime, create_by AS createBy, update_by AS updateBy, remark " +
                "FROM green_hotel_question WHERE course_id = ? AND status = '0' " +
                "AND (tenant_id = ? OR tenant_id = '000000' OR tenant_id IS NULL) ORDER BY sort_order ASC, id ASC";
        return jdbcTemplate.query(sql, new BeanPropertyRowMapper<>(GreenHotelQuestion.class), courseId, tenantId);
    }

    @PreAuthorize("@ss.hasPermi('train:greenHotelQuestion:list')")
    @GetMapping("/list")
    public TableDataInfo list(GreenHotelQuestion query) {
        SysUser user = SecurityUtils.getLoginUser().getUser();
        if (user.isSuperAdmin() || user.isPlatformAdmin()) {
            // 超管/平台管理员查询所有数据
        } else {
            String tenantId = user.getTenantId();
            if (StringUtils.isNotEmpty(tenantId)) {
                query.setTenantId(tenantId);
            }
        }
        startPage();
        List<GreenHotelQuestion> list = greenHotelQuestionService.selectGreenHotelQuestionList(query);
        return getDataTable(list);
    }

    @PreAuthorize("@ss.hasPermi('train:greenHotelQuestion:query')")
    @GetMapping("/{id}")
    public AjaxResult getInfo(@PathVariable Long id) {
        return success(greenHotelQuestionService.selectGreenHotelQuestionById(id));
    }

    @PreAuthorize("@ss.hasPermi('train:greenHotelQuestion:add')")
    @Log(title = "绿色饭店题目", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody GreenHotelQuestion question) {
        try {
            SysUser user = SecurityUtils.getLoginUser().getUser();
            if (user.isSuperAdmin() || user.isPlatformAdmin()) {
                question.setTenantId("000000");
            } else {
                String tenantId = user.getTenantId();
                if (StringUtils.isNotEmpty(tenantId)) {
                    question.setTenantId(tenantId);
                }
            }
        } catch (Exception e) {
            logger.warn("获取用户租户信息失败", e);
        }
        question.setCreateBy(getUsername());
        return toAjax(greenHotelQuestionService.insertGreenHotelQuestion(question));
    }

    @PreAuthorize("@ss.hasPermi('train:greenHotelQuestion:edit')")
    @Log(title = "绿色饭店题目", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody GreenHotelQuestion question) {
        question.setUpdateBy(getUsername());
        return toAjax(greenHotelQuestionService.updateGreenHotelQuestion(question));
    }

    @PreAuthorize("@ss.hasPermi('train:greenHotelQuestion:remove')")
    @Log(title = "绿色饭店题目", businessType = BusinessType.DELETE)
    @DeleteMapping("/{ids}")
    public AjaxResult remove(@PathVariable Long[] ids) {
        return toAjax(greenHotelQuestionService.deleteGreenHotelQuestionByIds(ids));
    }

    @PreAuthorize("@ss.hasPermi('train:greenHotelQuestion:list')")
    @GetMapping("/categories")
    public AjaxResult getCategories() {
        SysUser user = SecurityUtils.getLoginUser().getUser();
        if (user.isSuperAdmin() || user.isPlatformAdmin()) {
            return success(greenHotelQuestionService.selectAllCategories());
        }
        String tenantId = user.getTenantId();
        if (StringUtils.isEmpty(tenantId)) {
            return success(new ArrayList<>());
        }
        return success(greenHotelQuestionService.selectCategoriesByTenantId(tenantId));
    }

    // ==================== 用户端接口 ====================

    @GetMapping("/user/categories")
    public AjaxResult getUserCategories() {
        String tenantId = getCurrentTenantId();
        logger.info("【绿色饭店题库】用户端获取分类, tenantId={}", tenantId);

        if (StringUtils.isEmpty(tenantId)) {
            return AjaxResult.success("tenantId为空", Collections.emptyList());
        }

        try {
            List<Map<String, Object>> categories = greenHotelQuestionService.selectCategoriesByTenantId(tenantId);
            if (categories == null || categories.isEmpty()) {
                return AjaxResult.success("查询结果为空,tenantId=" + tenantId, Collections.emptyList());
            }
            for (Map<String, Object> cat : categories) {
                cat.put("type", "green_hotel");
            }
            return success(categories);
        } catch (Exception e) {
            logger.error("【绿色饭店题库】查询分类异常", e);
            return AjaxResult.error("查询异常: " + e.getMessage());
        }
    }

    @GetMapping("/user/list")
    public AjaxResult getUserQuestions(@RequestParam(required = false) String category,
                                       @RequestParam(required = false) Long courseId) {
        String tenantId = getCurrentTenantId();
        logger.info("用户端获取绿色饭店题目, tenantId={}, courseId={}, category={}", tenantId, courseId, category);

        if (StringUtils.isEmpty(tenantId)) {
            return success(Collections.emptyList());
        }

        List<GreenHotelQuestion> list;
        list = selectByTenantIdAndCourseId(tenantId, courseId);
        if (!list.isEmpty()) {
            return success(list);
        }
        if (StringUtils.isNotEmpty(category)) {
            list = greenHotelQuestionService.selectByTenantIdAndCategory(tenantId, category);
        } else {
            list = greenHotelQuestionService.selectByTenantId(tenantId);
        }
        return success(list);
    }

    /**
     * 用户端获取绿色饭店题目详情
     */
    @GetMapping("/user/detail/{id}")
    public AjaxResult getUserQuestionDetail(@PathVariable Long id) {
        String tenantId = getCurrentTenantId();
        if (StringUtils.isEmpty(tenantId)) {
            return error("未获取到租户信息");
        }
        GreenHotelQuestion question = greenHotelQuestionService.selectGreenHotelQuestionById(id);
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

    @GetMapping("/user/stats")
    public AjaxResult getUserStats() {
        String tenantId = getCurrentTenantId();
        if (StringUtils.isEmpty(tenantId)) {
            Map<String, Object> emptyStats = new HashMap<>();
            emptyStats.put("totalCount", 0);
            emptyStats.put("categoryCount", 0);
            return success(emptyStats);
        }
        int totalCount = greenHotelQuestionService.countByTenantId(tenantId);
        List<Map<String, Object>> categories = greenHotelQuestionService.selectCategoriesByTenantId(tenantId);
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalCount", totalCount);
        stats.put("categoryCount", categories.size());
        return success(stats);
    }

    private String getCurrentTenantId() {
        try {
            Long userId = SecurityUtils.getUserId();
            if (userId == null) return null;
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
