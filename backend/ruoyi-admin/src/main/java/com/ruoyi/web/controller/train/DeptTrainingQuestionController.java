package com.ruoyi.web.controller.train;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.enums.DataSourceType;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.constant.HttpStatus;
import com.ruoyi.common.core.domain.entity.SysDept;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.system.domain.DeptTrainingQuestion;
import com.ruoyi.system.service.IDeptQuestionBankScopeService;
import com.ruoyi.system.service.IDeptTrainingQuestionService;
import com.ruoyi.system.service.ISysDeptService;
import com.ruoyi.train.service.ITrainAiService;
import com.ruoyi.train.service.IMembershipService;

/**
 * 部门培训题目Controller
 */
@RestController
@RequestMapping("/train/dept-question")
public class DeptTrainingQuestionController extends BaseController {

    private static final Logger logger = LoggerFactory.getLogger(DeptTrainingQuestionController.class);
    private static final String SCOPE_SELF = "self";
    private static final String SCOPE_ALL = "all";
    private static final String VISIBLE_SCOPE_SELF = "SELF";
    private static final String VISIBLE_SCOPE_SELF_AND_CHILDREN = "SELF_AND_CHILDREN";
    private static final String VISIBLE_SCOPE_CUSTOM = "CUSTOM";
    private static final String VISIBLE_SCOPE_ALL_TENANT = "ALL_TENANT";
    private static final String FIXED_DAILY_CATEGORY = "每日一练固定题组";

    @Autowired
    private IDeptTrainingQuestionService deptTrainingQuestionService;

    @Autowired(required = false)
    private ITrainAiService trainAiService;

    @Autowired
    private IMembershipService membershipService;

    @Autowired
    private ISysDeptService deptService;

    @Autowired
    private IDeptQuestionBankScopeService deptQuestionBankScopeService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private static class DeptBankScopeContext {
        private final SysDept currentDept;
        private final Set<String> configuredDeptTypes;
        private final Set<String> visibleDeptTypes;

        private DeptBankScopeContext(SysDept currentDept, Set<String> configuredDeptTypes, Set<String> visibleDeptTypes) {
            this.currentDept = currentDept;
            this.configuredDeptTypes = configuredDeptTypes;
            this.visibleDeptTypes = visibleDeptTypes;
        }
    }

    private static class CourseGroupMeta {
        private final String groupId;
        private final String groupName;

        private CourseGroupMeta(String groupId, String groupName) {
            this.groupId = groupId;
            this.groupName = groupName;
        }
    }

    private Long resolveUserIdOrFree() {
        try {
            return getUserId();
        } catch (Exception ignored) {
            return 0L;
        }
    }

    private SysUser resolveCurrentUser() {
        try {
            return getLoginUser().getUser();
        } catch (Exception ignored) {
            return null;
        }
    }

    private String resolveCurrentTenantId() {
        SysUser currentUser = resolveCurrentUser();
        return currentUser != null ? currentUser.getTenantId() : null;
    }

    private Long resolveCurrentDeptId() {
        SysUser currentUser = resolveCurrentUser();
        return currentUser != null ? currentUser.getDeptId() : null;
    }

    private SysDept resolveCurrentDept() {
        Long currentDeptId = resolveCurrentDeptId();
        return currentDeptId == null ? null : deptService.selectDeptById(currentDeptId);
    }

    private String normalizeDeptType(String deptType) {
        return deptType == null ? null : deptType.trim();
    }

    private String normalizeScope(String scope) {
        return SCOPE_ALL.equalsIgnoreCase(scope) ? SCOPE_ALL : SCOPE_SELF;
    }

    private String normalizeVisibleScope(String visibleScope) {
        if (VISIBLE_SCOPE_SELF_AND_CHILDREN.equalsIgnoreCase(visibleScope)) {
            return VISIBLE_SCOPE_SELF_AND_CHILDREN;
        }
        if (VISIBLE_SCOPE_CUSTOM.equalsIgnoreCase(visibleScope)) {
            return VISIBLE_SCOPE_CUSTOM;
        }
        if (VISIBLE_SCOPE_ALL_TENANT.equalsIgnoreCase(visibleScope)) {
            return VISIBLE_SCOPE_ALL_TENANT;
        }
        return VISIBLE_SCOPE_SELF;
    }

    private String resolveDeptName(Long deptId) {
        if (deptId == null) {
            return null;
        }
        SysDept dept = deptService.selectDeptById(deptId);
        if (dept == null || StringUtils.isEmpty(dept.getDeptName())) {
            return null;
        }
        return dept.getDeptName().trim();
    }

    private Set<String> normalizeDeptTypeSet(List<String> deptTypes) {
        if (deptTypes == null || deptTypes.isEmpty()) {
            return Collections.emptySet();
        }
        LinkedHashSet<String> normalized = new LinkedHashSet<>();
        for (String deptType : deptTypes) {
            String normalizedDeptType = normalizeDeptType(deptType);
            if (StringUtils.isNotEmpty(normalizedDeptType)) {
                normalized.add(normalizedDeptType);
            }
        }
        return normalized.isEmpty() ? Collections.emptySet() : normalized;
    }

    private DeptBankScopeContext buildDeptBankScopeContext(String normalizedScope) {
        SysDept currentDept = resolveCurrentDept();
        if (!SCOPE_SELF.equals(normalizedScope) || currentDept == null || currentDept.getDeptId() == null) {
            return new DeptBankScopeContext(currentDept, Collections.emptySet(), Collections.emptySet());
        }

        String tenantId = resolveCurrentTenantId();
        try {
            Set<String> visibleDeptTypes = new LinkedHashSet<>();
            for (Long deptId : resolveScopeDeptIds(currentDept)) {
                visibleDeptTypes.addAll(normalizeDeptTypeSet(
                        deptQuestionBankScopeService.selectVisibleDeptTypesByDeptId(tenantId, deptId)));
            }
            return new DeptBankScopeContext(
                    currentDept,
                    normalizeDeptTypeSet(deptQuestionBankScopeService.selectConfiguredDeptTypes(tenantId)),
                    visibleDeptTypes);
        } catch (Exception e) {
            logger.warn("【部门题库】查询题库级授权失败，降级为历史规则, tenantId={}, deptId={}", tenantId, currentDept.getDeptId(), e);
            return new DeptBankScopeContext(currentDept, Collections.emptySet(), Collections.emptySet());
        }
    }

    private Set<Long> resolveScopeDeptIds(SysDept currentDept) {
        if (currentDept == null || currentDept.getDeptId() == null) {
            return Collections.emptySet();
        }

        LinkedHashSet<Long> deptIds = new LinkedHashSet<>();
        deptIds.add(currentDept.getDeptId());

        if (StringUtils.isEmpty(currentDept.getAncestors())) {
            return deptIds;
        }

        for (String ancestor : currentDept.getAncestors().split(",")) {
            if (StringUtils.isEmpty(ancestor)) {
                continue;
            }
            try {
                Long ancestorDeptId = Long.valueOf(ancestor.trim());
                if (ancestorDeptId > 0) {
                    deptIds.add(ancestorDeptId);
                }
            } catch (NumberFormatException ignored) {
                logger.warn("【部门题库】忽略无法解析的祖先部门ID: {}", ancestor);
            }
        }
        return deptIds;
    }

    private boolean isDeptTypeVisibleToCurrentDept(String deptType, DeptBankScopeContext context) {
        if (context == null || context.currentDept == null) {
            return false;
        }
        String normalizedDeptType = normalizeDeptType(deptType);
        if (StringUtils.isEmpty(normalizedDeptType)) {
            return false;
        }
        if (context.configuredDeptTypes.contains(normalizedDeptType)) {
            return context.visibleDeptTypes.contains(normalizedDeptType);
        }
        return StringUtils.isNotEmpty(context.currentDept.getDeptName())
                && context.currentDept.getDeptName().trim().equals(normalizedDeptType);
    }

    private boolean matchesTenantScope(DeptTrainingQuestion question, String currentTenantId) {
        if (question == null) {
            return false;
        }
        String tenantId = question.getTenantId();
        return StringUtils.isEmpty(tenantId)
                || "000000".equals(tenantId)
                || StringUtils.isEmpty(currentTenantId)
                || currentTenantId.equals(tenantId);
    }

    private DeptTrainingQuestion buildUserScopedQuery(String deptType, Long ownerDeptId, String category) {
        DeptTrainingQuestion query = new DeptTrainingQuestion();
        query.setStatus("0");
        String normalizedDeptType = normalizeDeptType(deptType);
        if (StringUtils.isNotEmpty(normalizedDeptType)) {
            query.setDeptType(normalizedDeptType);
        }
        if (ownerDeptId != null) {
            query.setOwnerDeptId(ownerDeptId);
        }
        if (StringUtils.isNotEmpty(category)) {
            query.setCategory(category.trim());
        }
        String tenantId = resolveCurrentTenantId();
        if (StringUtils.isNotEmpty(tenantId)) {
            query.setTenantId(tenantId);
        }
        return query;
    }

    private List<DeptTrainingQuestion> selectUserScopedQuestions(String deptType, Long ownerDeptId, String category) {
        return deptTrainingQuestionService.selectDeptTrainingQuestionList(buildUserScopedQuery(deptType, ownerDeptId, category));
    }

    private boolean hasQuestionAccess(Long userId, Long questionId) {
        if (questionId == null) {
            return true;
        }
        return membershipService.checkContentAccess(userId, "question", questionId);
    }

    private boolean isCurrentDeptMatchLegacyType(SysDept currentDept, DeptTrainingQuestion question) {
        if (currentDept == null || question == null) {
            return false;
        }
        return StringUtils.isNotEmpty(currentDept.getDeptName())
                && StringUtils.isNotEmpty(question.getDeptType())
                && currentDept.getDeptName().trim().equals(question.getDeptType().trim());
    }

    private boolean isSelfDeptQuestion(DeptTrainingQuestion question, SysDept currentDept) {
        if (question == null || currentDept == null) {
            return false;
        }
        if (question.getOwnerDeptId() != null) {
            if (question.getOwnerDeptId().equals(currentDept.getDeptId())) {
                return true;
            }
            logger.warn("【部门题库】题目归属部门ID与当前用户部门ID不一致，回退按部门名称匹配, questionId={}, ownerDeptId={}, currentDeptId={}",
                    question.getId(), question.getOwnerDeptId(), currentDept.getDeptId());
        }
        return isCurrentDeptMatchLegacyType(currentDept, question);
    }

    private boolean isDeptSelfOrChildOf(SysDept currentDept, Long ownerDeptId) {
        if (currentDept == null || ownerDeptId == null) {
            return false;
        }
        if (ownerDeptId.equals(currentDept.getDeptId())) {
            return true;
        }
        String ancestors = currentDept.getAncestors();
        if (StringUtils.isEmpty(ancestors)) {
            return false;
        }
        String ownerDeptIdText = String.valueOf(ownerDeptId);
        for (String ancestor : ancestors.split(",")) {
            if (ownerDeptIdText.equals(ancestor != null ? ancestor.trim() : null)) {
                return true;
            }
        }
        return false;
    }

    private Set<Long> resolveCustomVisibleQuestionIds(String tenantId, Long currentDeptId) {
        if (currentDeptId == null) {
            return Collections.emptySet();
        }
        try {
            List<Long> questionIds = deptTrainingQuestionService.selectQuestionIdsByVisibleDeptId(tenantId, currentDeptId);
            if (questionIds == null || questionIds.isEmpty()) {
                return Collections.emptySet();
            }
            return new HashSet<>(questionIds);
        } catch (Exception e) {
            logger.warn("【部门题库】查询自定义可见题目失败，按空授权降级处理, tenantId={}, deptId={}", tenantId, currentDeptId, e);
            return Collections.emptySet();
        }
    }

    private boolean requiresCustomVisibleLookup(List<DeptTrainingQuestion> list, String normalizedScope) {
        if (!SCOPE_ALL.equals(normalizedScope) || list == null || list.isEmpty()) {
            return false;
        }
        for (DeptTrainingQuestion question : list) {
            if (question != null && VISIBLE_SCOPE_CUSTOM.equals(normalizeVisibleScope(question.getVisibleScope()))) {
                return true;
            }
        }
        return false;
    }

    private boolean isQuestionVisibleToCurrentDept(DeptTrainingQuestion question, SysDept currentDept, Set<Long> customVisibleQuestionIds) {
        if (question == null || currentDept == null) {
            return false;
        }
        if (isSelfDeptQuestion(question, currentDept)) {
            return true;
        }

        String visibleScope = normalizeVisibleScope(question.getVisibleScope());
        // 历史题库数据只有 dept_type，没有部门归属ID和授权配置。
        // “全部课程”视图下放宽为可浏览全部历史部门题库，避免被当前部门误筛空。
        if (question.getOwnerDeptId() == null && VISIBLE_SCOPE_SELF.equals(visibleScope)) {
            return true;
        }
        if (VISIBLE_SCOPE_ALL_TENANT.equals(visibleScope)) {
            return true;
        }
        if (VISIBLE_SCOPE_SELF_AND_CHILDREN.equals(visibleScope)) {
            return isDeptSelfOrChildOf(currentDept, question.getOwnerDeptId());
        }
        if (VISIBLE_SCOPE_CUSTOM.equals(visibleScope)) {
            return question.getId() != null && customVisibleQuestionIds.contains(question.getId());
        }
        return false;
    }

    private List<DeptTrainingQuestion> filterQuestionsByScope(Long userId, List<DeptTrainingQuestion> list, String scope) {
        if (list == null || list.isEmpty()) {
            return list;
        }
        List<DeptTrainingQuestion> filtered = new ArrayList<>();
        String currentTenantId = resolveCurrentTenantId();
        String normalizedScope = normalizeScope(scope);
        DeptBankScopeContext bankScopeContext = buildDeptBankScopeContext(normalizedScope);
        for (DeptTrainingQuestion q : list) {
            if (q != null
                    && matchesTenantScope(q, currentTenantId)
                    && hasQuestionAccess(userId, q.getId())
                    && (SCOPE_ALL.equals(normalizedScope)
                        || isDeptTypeVisibleToCurrentDept(q.getDeptType(), bankScopeContext))) {
                filtered.add(q);
            }
        }
        return filtered;
    }

    private List<DeptTrainingQuestion> collectQuestions(String deptType, Long ownerDeptId, String category, String scope, Long userId, Integer limit) {
        List<DeptTrainingQuestion> questions = filterQuestionsByScope(
                userId,
                selectUserScopedQuestions(deptType, ownerDeptId, category),
                scope);
        if (questions == null || questions.isEmpty()) {
            return new ArrayList<>();
        }
        Collections.shuffle(questions);
        if (limit != null && limit > 0 && questions.size() > limit) {
            return new ArrayList<>(questions.subList(0, limit));
        }
        return questions;
    }

    private List<DeptTrainingQuestion> collectClassifiedQuestions(Long courseId,
                                                                  String courseName,
                                                                  String deptType,
                                                                  String scope,
                                                                  Long userId,
                                                                  Integer limit) {
        List<DeptTrainingQuestion> questions = filterQuestionsByScope(
                userId,
                deptTrainingQuestionService.selectClassifiedQuestions(courseId, courseName, deptType),
                scope);
        if (questions == null || questions.isEmpty()) {
            return new ArrayList<>();
        }
        if (limit != null && limit > 0 && questions.size() > limit) {
            Collections.shuffle(questions);
            return new ArrayList<>(questions.subList(0, limit));
        }
        return questions;
    }

    private List<DeptTrainingQuestion> trimQuestions(List<DeptTrainingQuestion> questions, Integer limit) {
        if (questions == null || questions.isEmpty()) {
            return new ArrayList<>();
        }
        List<DeptTrainingQuestion> randomized = new ArrayList<>(questions);
        Collections.shuffle(randomized);
        if (limit != null && limit > 0 && randomized.size() > limit) {
            return new ArrayList<>(randomized.subList(0, limit));
        }
        return randomized;
    }

    private List<DeptTrainingQuestion> collectFixedDailyQuestions(Long userId, Integer limit) {
        List<DeptTrainingQuestion> fixedQuestions = selectUserScopedQuestions(null, null, FIXED_DAILY_CATEGORY);
        if (fixedQuestions == null || fixedQuestions.isEmpty()) {
            return new ArrayList<>();
        }

        List<DeptTrainingQuestion> filtered = new ArrayList<>();
        String currentTenantId = resolveCurrentTenantId();
        for (DeptTrainingQuestion question : fixedQuestions) {
            if (question != null
                    && matchesTenantScope(question, currentTenantId)
                    && hasQuestionAccess(userId, question.getId())) {
                filtered.add(question);
            }
        }

        filtered.sort(Comparator
                .comparing(DeptTrainingQuestion::getSortOrder, Comparator.nullsLast(Integer::compareTo))
                .thenComparing(DeptTrainingQuestion::getId, Comparator.nullsLast(Long::compareTo)));

        if (limit != null && limit > 0 && filtered.size() > limit) {
            return new ArrayList<>(filtered.subList(0, limit));
        }
        return filtered;
    }

    private List<DeptTrainingQuestion> mergeDailyQuestions(List<DeptTrainingQuestion> fixedQuestions,
                                                           List<DeptTrainingQuestion> randomQuestions,
                                                           Integer limit) {
        LinkedHashSet<Long> addedIds = new LinkedHashSet<>();
        List<DeptTrainingQuestion> merged = new ArrayList<>();

        if (fixedQuestions != null) {
            for (DeptTrainingQuestion question : fixedQuestions) {
                if (question == null) {
                    continue;
                }
                Long questionId = question.getId();
                if (questionId == null || addedIds.add(questionId)) {
                    merged.add(question);
                }
                if (limit != null && limit > 0 && merged.size() >= limit) {
                    return merged;
                }
            }
        }

        if (randomQuestions != null) {
            for (DeptTrainingQuestion question : randomQuestions) {
                if (question == null) {
                    continue;
                }
                Long questionId = question.getId();
                if (questionId != null && !addedIds.add(questionId)) {
                    continue;
                }
                merged.add(question);
                if (limit != null && limit > 0 && merged.size() >= limit) {
                    return merged;
                }
            }
        }
        return merged;
    }

    private String firstNonEmpty(String... values) {
        for (String value : values) {
            if (StringUtils.isNotEmpty(value)) {
                return value.trim();
            }
        }
        return null;
    }

    private Map<Long, CourseGroupMeta> selectCourseGroupMetas(List<DeptTrainingQuestion> questions) {
        Set<Long> courseIds = new LinkedHashSet<>();
        for (DeptTrainingQuestion question : questions) {
            if (question != null && question.getMatchedCourseId() != null) {
                courseIds.add(question.getMatchedCourseId());
            }
        }
        if (courseIds.isEmpty()) {
            return new HashMap<>();
        }

        String placeholders = String.join(",", Collections.nCopies(courseIds.size(), "?"));
        String sql = "SELECT course_category_id, main_title, main_s, specific_category, third_level_c " +
                "FROM course_category WHERE course_category_id IN (" + placeholders + ")";
        Map<Long, CourseGroupMeta> metas = new HashMap<>();
        jdbcTemplate.query(sql, courseIds.toArray(), rs -> {
            Long courseId = rs.getLong("course_category_id");
            String thirdLevelName = rs.getString("third_level_c");
            String groupName = firstNonEmpty(rs.getString("specific_category"), rs.getString("main_s"), rs.getString("main_title"));
            if (StringUtils.isEmpty(groupName) || groupName.equals(thirdLevelName)) {
                groupName = firstNonEmpty(rs.getString("main_s"), rs.getString("main_title"), thirdLevelName);
            }
            metas.put(courseId, new CourseGroupMeta("dept_course_group_" + groupName, groupName));
        });
        return metas;
    }

    private AjaxResult normalizeQuestionBeforeSave(DeptTrainingQuestion question) {
        if (question == null || question.getOwnerDeptId() == null) {
            return error("请选择归属部门");
        }
        String ownerDeptName = resolveDeptName(question.getOwnerDeptId());
        if (StringUtils.isEmpty(ownerDeptName)) {
            return error("归属部门不存在");
        }
        question.setDeptType(ownerDeptName);
        question.setOwnerDeptName(ownerDeptName);
        question.setVisibleScope(normalizeVisibleScope(question.getVisibleScope()));
        if (!VISIBLE_SCOPE_CUSTOM.equals(question.getVisibleScope())) {
            question.setVisibleDeptIds(new ArrayList<>());
        }

        String tenantId = resolveCurrentTenantId();
        if (StringUtils.isNotEmpty(tenantId)) {
            question.setTenantId(tenantId);
        } else if (StringUtils.isEmpty(question.getTenantId())) {
            question.setTenantId("000000");
        }
        return null;
    }

    /**
     * 查询部门培训题目列表（管理端）
     */
    @PreAuthorize("@ss.hasPermi('train:deptQuestion:list')")
    @GetMapping("/list")
    @DataSource(DataSourceType.SLAVE)
    public TableDataInfo list(DeptTrainingQuestion query) {
        try {
            String tenantId = getLoginUser().getUser().getTenantId();
            if (StringUtils.isNotEmpty(tenantId)) {
                query.setTenantId(tenantId);
            }
        } catch (Exception e) {
            // ignore
        }
        startPage();
        List<DeptTrainingQuestion> list = deptTrainingQuestionService.selectDeptTrainingQuestionList(query);
        return getDataTable(list);
    }

    /**
     * 根据部门类型查询题目（用户端使用）
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/list-by-dept")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult listByDept(@RequestParam(required = false) String deptType,
                                 @RequestParam(required = false) Long ownerDeptId,
                                 @RequestParam(defaultValue = SCOPE_SELF) String scope) {
        logger.info("【部门题库】用户端获取题目, deptType={}, ownerDeptId={}, scope={}", deptType, ownerDeptId, scope);
        Long userId = resolveUserIdOrFree();
        try {
            List<DeptTrainingQuestion> list = collectQuestions(
                    deptType,
                    ownerDeptId,
                    null,
                    scope,
                    userId,
                    null);
            logger.info("【部门题库】查询到 {} 道题目, deptType={}, ownerDeptId={}, scope={}",
                    list != null ? list.size() : 0, deptType, ownerDeptId, normalizeScope(scope));
            return success(list);
        } catch (Exception e) {
            logger.error("【部门题库】查询异常, deptType={}, ownerDeptId={}", deptType, ownerDeptId, e);
            return error("查询失败: " + e.getMessage());
        }
    }

    /**
     * 根据课程分类查询题目（用户端使用）
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/list-by-course")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult listByCourse(@RequestParam(required = false) Long courseId,
                                   @RequestParam(required = false) String courseName,
                                   @RequestParam(required = false) String deptType,
                                   @RequestParam(required = false) String category,
                                   @RequestParam(required = false) String keyword,
                                   @RequestParam(defaultValue = SCOPE_SELF) String scope) {
        logger.info("【部门题库】按课程分类获取题目, courseId={}, courseName={}, deptType={}, category={}, keyword={}, scope={}",
                courseId, courseName, deptType, category, keyword, scope);
        Long userId = resolveUserIdOrFree();
        try {
            String normalizedCourseName = StringUtils.isEmpty(courseName) ? null : courseName.trim();
            String normalizedDeptType = normalizeDeptType(deptType);
            String normalizedCategory = StringUtils.isEmpty(category) ? null : category.trim();
            String normalizedKeyword = StringUtils.isEmpty(keyword) ? null : keyword.trim();
            if (courseId == null
                    && StringUtils.isEmpty(normalizedCourseName)
                    && StringUtils.isEmpty(normalizedCategory)) {
                return error("课程标识不能为空");
            }
            List<DeptTrainingQuestion> list = collectClassifiedQuestions(
                    courseId,
                    normalizedCourseName,
                    normalizedDeptType,
                    scope,
                    userId,
                    null);
            if (list.isEmpty() && StringUtils.isNotEmpty(normalizedCourseName)) {
                list = collectQuestions(normalizedDeptType, null, normalizedCourseName, scope, userId, null);
            }
            if (StringUtils.isNotEmpty(normalizedCategory)) {
                List<DeptTrainingQuestion> filtered = new ArrayList<>();
                for (DeptTrainingQuestion question : list) {
                    if (question != null && normalizedCategory.equals(question.getCategory())) {
                        filtered.add(question);
                    }
                }
                list = filtered;
            }
            if (StringUtils.isNotEmpty(normalizedKeyword)) {
                List<DeptTrainingQuestion> filtered = new ArrayList<>();
                String loweredKeyword = normalizedKeyword.toLowerCase();
                for (DeptTrainingQuestion question : list) {
                    if (question == null || StringUtils.isEmpty(question.getQuestionText())) {
                        continue;
                    }
                    if (question.getQuestionText().toLowerCase().contains(loweredKeyword)) {
                        filtered.add(question);
                    }
                }
                list = filtered;
            }
            logger.info("【部门题库】按课程分类查询到 {} 道题目, courseId={}, courseName={}, deptType={}, category={}, keyword={}, scope={}",
                    list.size(), courseId, normalizedCourseName, normalizedDeptType, normalizedCategory, normalizedKeyword, normalizeScope(scope));
            return success(list);
        } catch (Exception e) {
            logger.error("【部门题库】按课程分类查询异常, courseId={}, courseName={}, deptType={}, category={}, keyword={}",
                    courseId, courseName, deptType, category, keyword, e);
            return error("查询失败: " + e.getMessage());
        }
    }

    /**
     * 获取部门题目分类统计
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/categories")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getCategories(@RequestParam(required = false) String deptType,
                                    @RequestParam(required = false) Long ownerDeptId,
                                    @RequestParam(defaultValue = SCOPE_SELF) String scope) {
        Long userId = resolveUserIdOrFree();
        List<DeptTrainingQuestion> scopedQuestions = collectQuestions(deptType, ownerDeptId, null, scope, userId, null);
        Map<String, Integer> categoryCounter = new HashMap<>();
        for (DeptTrainingQuestion question : scopedQuestions) {
            if (question == null || StringUtils.isEmpty(question.getCategory())) {
                continue;
            }
            String categoryName = question.getCategory().trim();
            categoryCounter.put(categoryName, categoryCounter.getOrDefault(categoryName, 0) + 1);
        }

        List<Map<String, Object>> categories = new ArrayList<>();
        int id = 1;
        for (Map.Entry<String, Integer> entry : categoryCounter.entrySet()) {
            Map<String, Object> cat = new HashMap<>();
            cat.put("id", id++);
            cat.put("name", entry.getKey());
            cat.put("count", entry.getValue());
            categories.add(cat);
        }
        return success(categories);
    }

    /**
     * 获取按课程整理后的部门专项题库分类
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/course-categories")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getCourseCategories(@RequestParam(defaultValue = SCOPE_SELF) String scope) {
        Long userId = resolveUserIdOrFree();
        List<DeptTrainingQuestion> scopedQuestions = collectClassifiedQuestions(null, null, null, scope, userId, null);
        Map<Long, CourseGroupMeta> courseGroupMetas = selectCourseGroupMetas(scopedQuestions);
        Map<String, Map<String, Object>> courseCounter = new LinkedHashMap<>();
        for (DeptTrainingQuestion question : scopedQuestions) {
            if (question == null) {
                continue;
            }
            String courseName = StringUtils.isNotEmpty(question.getMatchedCourseName())
                    ? question.getMatchedCourseName().trim()
                    : (StringUtils.isNotEmpty(question.getCategory()) ? question.getCategory().trim() : null);
            if (StringUtils.isEmpty(courseName)) {
                continue;
            }
            Long courseId = question.getMatchedCourseId();
            String deptType = StringUtils.isNotEmpty(question.getMatchedCourseDeptType())
                    ? question.getMatchedCourseDeptType().trim()
                    : (StringUtils.isNotEmpty(question.getDeptType()) ? question.getDeptType().trim() : "");
            String key = (courseId != null ? String.valueOf(courseId) : deptType + "::" + courseName);
            CourseGroupMeta courseGroupMeta = courseId == null ? null : courseGroupMetas.get(courseId);
            String groupName = courseGroupMeta != null && StringUtils.isNotEmpty(courseGroupMeta.groupName)
                    ? courseGroupMeta.groupName
                    : (StringUtils.isNotEmpty(deptType) ? deptType : "未分组课程");
            String groupId = courseGroupMeta != null && StringUtils.isNotEmpty(courseGroupMeta.groupId)
                    ? courseGroupMeta.groupId
                    : "dept_course_group_" + groupName;
            Map<String, Object> course = courseCounter.computeIfAbsent(key, ignored -> {
                Map<String, Object> item = new HashMap<>();
                item.put("id", key);
                item.put("courseId", courseId);
                item.put("courseName", courseName);
                item.put("deptType", deptType);
                item.put("groupId", groupId);
                item.put("groupName", groupName);
                item.put("questionCount", 0);
                return item;
            });
            course.put("questionCount", ((Integer) course.get("questionCount")) + 1);
        }

        List<Map<String, Object>> categories = new ArrayList<>(courseCounter.values());
        categories.sort((a, b) -> {
            String deptA = String.valueOf(a.get("deptType"));
            String deptB = String.valueOf(b.get("deptType"));
            int deptCompare = deptA.compareTo(deptB);
            if (deptCompare != 0) {
                return deptCompare;
            }
            String groupA = String.valueOf(a.get("groupName"));
            String groupB = String.valueOf(b.get("groupName"));
            int groupCompare = groupA.compareTo(groupB);
            if (groupCompare != 0) {
                return groupCompare;
            }
            return String.valueOf(a.get("courseName")).compareTo(String.valueOf(b.get("courseName")));
        });
        return success(categories);
    }

    /**
     * 获取所有有题目的部门类型（带统计信息）
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/dept-types")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getDeptTypes(@RequestParam(defaultValue = SCOPE_SELF) String scope) {
        logger.info("=== 获取部门题库类型, scope={} ===", scope);
        try {
            String normalizedScope = normalizeScope(scope);
            List<Map<String, Object>> deptTypeStats = deptQuestionBankScopeService.selectBankStats(resolveCurrentTenantId());
            if (deptTypeStats == null || deptTypeStats.isEmpty()) {
                return success(new ArrayList<>());
            }

            if (SCOPE_SELF.equals(normalizedScope)) {
                DeptBankScopeContext bankScopeContext = buildDeptBankScopeContext(normalizedScope);
                List<Map<String, Object>> filteredStats = new ArrayList<>();
                for (Map<String, Object> stat : deptTypeStats) {
                    if (stat == null) {
                        continue;
                    }
                    String deptType = stat.get("deptType") == null ? null : String.valueOf(stat.get("deptType"));
                    if (isDeptTypeVisibleToCurrentDept(deptType, bankScopeContext)) {
                        filteredStats.add(stat);
                    }
                }
                deptTypeStats = filteredStats;
            }

            List<Map<String, Object>> normalizedStats = new ArrayList<>();
            for (Map<String, Object> stat : deptTypeStats) {
                if (stat == null) {
                    continue;
                }
                Map<String, Object> normalizedStat = new HashMap<>();
                normalizedStat.put("ownerDeptId", null);
                normalizedStat.put("deptType", stat.get("deptType"));
                normalizedStat.put("deptName", stat.get("deptType"));
                normalizedStat.put("questionCount", stat.get("questionCount"));
                normalizedStats.add(normalizedStat);
            }
            for (Map<String, Object> stat : normalizedStats) {
                logger.info("部门: {}, ownerDeptId={}, 题目数: {}",
                        stat.get("deptName"), stat.get("ownerDeptId"), stat.get("questionCount"));
            }
            return success(normalizedStats);
        } catch (Exception e) {
            logger.error("获取部门题库类型失败", e);
            return error("获取部门题库类型失败: " + e.getMessage());
        }
    }

    /**
     * 获取部门培训题目详情
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/{id}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getInfo(@PathVariable Long id) {
        Long userId = resolveUserIdOrFree();
        DeptTrainingQuestion question = deptTrainingQuestionService.selectDeptTrainingQuestionById(id);
        if (question == null) {
            return error("题目不存在");
        }
        List<DeptTrainingQuestion> visibleQuestions = filterQuestionsByScope(userId, Collections.singletonList(question), SCOPE_ALL);
        if (visibleQuestions == null || visibleQuestions.isEmpty()) {
            return AjaxResult.error(HttpStatus.FORBIDDEN, "无权限访问该内容");
        }
        question.setVisibleDeptIds(deptTrainingQuestionService.selectVisibleDeptIdsByQuestionId(id));
        return success(question);
    }

    @PreAuthorize("@ss.hasPermi('train:deptQuestion:query')")
    @GetMapping("/detail/{id}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getDetail(@PathVariable Long id) {
        DeptTrainingQuestion question = deptTrainingQuestionService.selectDeptTrainingQuestionById(id);
        if (question == null) {
            return error("题目不存在");
        }
        if (!matchesTenantScope(question, resolveCurrentTenantId())) {
            return AjaxResult.error(HttpStatus.FORBIDDEN, "无权限访问该题目");
        }
        question.setVisibleDeptIds(deptTrainingQuestionService.selectVisibleDeptIdsByQuestionId(id));
        return success(question);
    }

    /**
     * 新增部门培训题目
     */
    @PreAuthorize("@ss.hasPermi('train:deptQuestion:add')")
    @Log(title = "部门培训题目", businessType = BusinessType.INSERT)
    @PostMapping
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult add(@RequestBody DeptTrainingQuestion question) {
        question.setCreateBy(getUsername());
        AjaxResult validation = normalizeQuestionBeforeSave(question);
        if (validation != null) {
            return validation;
        }
        return toAjax(deptTrainingQuestionService.insertDeptTrainingQuestion(question));
    }

    /**
     * 修改部门培训题目
     */
    @PreAuthorize("@ss.hasPermi('train:deptQuestion:edit')")
    @Log(title = "部门培训题目", businessType = BusinessType.UPDATE)
    @PutMapping
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult edit(@RequestBody DeptTrainingQuestion question) {
        question.setUpdateBy(getUsername());
        AjaxResult validation = normalizeQuestionBeforeSave(question);
        if (validation != null) {
            return validation;
        }
        return toAjax(deptTrainingQuestionService.updateDeptTrainingQuestion(question));
    }

    /**
     * 删除部门培训题目
     */
    @PreAuthorize("@ss.hasPermi('train:deptQuestion:remove')")
    @Log(title = "部门培训题目", businessType = BusinessType.DELETE)
    @DeleteMapping("/{ids}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult remove(@PathVariable Long[] ids) {
        return toAjax(deptTrainingQuestionService.deleteDeptTrainingQuestionByIds(ids));
    }

    /**
     * 提交答题结果
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping("/answer")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult submitAnswer(@RequestBody Map<String, Object> answerData) {
        try {
            Long questionId = Long.valueOf(answerData.get("questionId").toString());
            String userAnswer = answerData.get("answer").toString();
            Boolean isCorrect = Boolean.valueOf(answerData.get("isCorrect").toString());

            Long userId = null;
            try {
                userId = getUserId();
            } catch (Exception e) {
                // 未登录用户，仅返回成功但不保存记录
                return success("答案已记录（本地存储）");
            }

            // 已登录用户，保存答题记录到数据库
            int result = deptTrainingQuestionService.saveAnswerRecord(userId, questionId, userAnswer, isCorrect);
            if (result > 0) {
                return success("答案已保存");
            } else {
                return error("保存答题记录失败");
            }
        } catch (Exception e) {
            return error("提交答案失败: " + e.getMessage());
        }
    }

    /**
     * 收藏题目
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping("/{questionId}/favorite")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult favoriteQuestion(@PathVariable Long questionId) {
        try {
            Long userId = null;
            try {
                userId = getUserId();
            } catch (Exception e) {
                return error("请先登录后再收藏题目");
            }
            int result = deptTrainingQuestionService.favoriteQuestion(userId, questionId);
            return toAjax(result);
        } catch (Exception e) {
            return error("收藏失败: " + e.getMessage());
        }
    }

    /**
     * 取消收藏
     */
    @PreAuthorize("isAuthenticated()")
    @DeleteMapping("/{questionId}/unfavorite")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult unfavoriteQuestion(@PathVariable Long questionId) {
        try {
            Long userId = null;
            try {
                userId = getUserId();
            } catch (Exception e) {
                return error("请先登录后再操作收藏");
            }
            int result = deptTrainingQuestionService.unfavoriteQuestion(userId, questionId);
            return toAjax(result);
        } catch (Exception e) {
            return error("取消收藏失败: " + e.getMessage());
        }
    }

    /**
     * 获取用户收藏的题目
     */
    @GetMapping("/favorites")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getFavorites(@RequestParam(required = false) String deptType) {
        try {
            Long userId = getUserId();
            String normalizedDeptType = normalizeDeptType(deptType);
            List<DeptTrainingQuestion> list = deptTrainingQuestionService.selectFavoriteQuestions(userId, normalizedDeptType);
            return success(filterQuestionsByScope(userId, list, SCOPE_ALL));
        } catch (Exception e) {
            return error("获取收藏失败: " + e.getMessage());
        }
    }

    /**
     * 获取用户错题
     */
    @GetMapping("/wrong-questions")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getWrongQuestions(@RequestParam(required = false) String deptType) {
        try {
            Long userId = getUserId();
            String normalizedDeptType = normalizeDeptType(deptType);
            List<DeptTrainingQuestion> list = deptTrainingQuestionService.selectWrongQuestions(userId, normalizedDeptType);
            return success(filterQuestionsByScope(userId, list, SCOPE_ALL));
        } catch (Exception e) {
            return error("获取错题失败: " + e.getMessage());
        }
    }

    /**
     * 获取用户答题统计
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/stats")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getStats(@RequestParam(required = false) String deptType) {
        try {
            Long userId = null;
            try {
                userId = getUserId();
            } catch (Exception e) {
                // 未登录返回默认统计
                Map<String, Object> defaultStats = new HashMap<>();
                defaultStats.put("totalAnswered", 0);
                defaultStats.put("correctCount", 0);
                defaultStats.put("wrongCount", 0);
                defaultStats.put("favoriteCount", 0);
                return success(defaultStats);
            }
            String normalizedDeptType = normalizeDeptType(deptType);
            Map<String, Object> stats = deptTrainingQuestionService.getUserStats(userId, normalizedDeptType);
            return success(stats);
        } catch (Exception e) {
            return error("获取统计失败: " + e.getMessage());
        }
    }

    /**
     * 随机获取每日练习题目
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/daily")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getDailyQuestions(
            @RequestParam(required = false) String deptType,
            @RequestParam(required = false) Long ownerDeptId,
            @RequestParam(required = false) String category,
            @RequestParam(defaultValue = "10") Integer limit,
            @RequestParam(defaultValue = SCOPE_SELF) String scope) {
        Long userId = resolveUserIdOrFree();
        boolean preferFixedDaily = StringUtils.isEmpty(category) || FIXED_DAILY_CATEGORY.equals(category != null ? category.trim() : null);
        List<DeptTrainingQuestion> fixedDailyQuestions = preferFixedDaily
                ? collectFixedDailyQuestions(userId, limit)
                : new ArrayList<>();
        Integer randomLimit = limit;
        if (limit != null && limit > 0) {
            randomLimit = Math.max(limit - fixedDailyQuestions.size(), 0);
        }
        List<DeptTrainingQuestion> randomQuestions = randomLimit != null && randomLimit == 0
                ? new ArrayList<>()
                : collectQuestions(
                        deptType,
                        ownerDeptId,
                        category,
                        scope,
                        userId,
                        randomLimit);
        List<DeptTrainingQuestion> list = mergeDailyQuestions(fixedDailyQuestions, randomQuestions, limit);
        logger.info("每日一练 - 部门: {}, ownerDeptId={}, scope={}, 固定题: {}, 补充题: {}, 返回: {}",
                deptType, ownerDeptId, normalizeScope(scope), fixedDailyQuestions.size(), randomQuestions.size(), list.size());
        return success(list);
    }

    /**
     * 根据分类获取题目
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/category/{category}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getByCategory(
            @PathVariable String category,
            @RequestParam(required = false) String deptType,
            @RequestParam(required = false) Long ownerDeptId,
            @RequestParam(defaultValue = SCOPE_SELF) String scope) {
        Long userId = resolveUserIdOrFree();
        List<DeptTrainingQuestion> list = collectQuestions(
                deptType,
                ownerDeptId,
                category,
                scope,
                userId,
                null);
        return success(list);
    }

    /**
     * 按课程获取结课测验题目
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/course-quiz")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getCourseQuizQuestions(
            @RequestParam(required = false) Long courseId,
            @RequestParam(required = false) String courseName,
            @RequestParam(required = false) String deptType,
            @RequestParam(required = false) String category,
            @RequestParam(defaultValue = "5") Integer limit,
            @RequestParam(defaultValue = SCOPE_SELF) String scope) {
        Long userId = resolveUserIdOrFree();
        String normalizedDeptType = normalizeDeptType(deptType);
        String normalizedCourseName = StringUtils.isEmpty(courseName) ? null : courseName.trim();
        String normalizedCategory = StringUtils.isEmpty(category) ? null : category.trim();
        if (courseId == null
                && StringUtils.isEmpty(normalizedCourseName)
                && StringUtils.isEmpty(normalizedCategory)) {
            return error("课程标识不能为空");
        }

        List<DeptTrainingQuestion> list = new ArrayList<>();
        try {
            list = trimQuestions(
                    filterQuestionsByScope(
                            userId,
                            deptTrainingQuestionService.selectCourseQuizQuestions(courseId, normalizedCourseName, normalizedDeptType),
                            scope),
                    limit);
        } catch (Exception e) {
            logger.warn("【结课测验】按课程分类题库取题失败，回退历史规则, courseId={}, courseName={}, deptType={}",
                    courseId, normalizedCourseName, normalizedDeptType, e);
        }

        if (list.isEmpty() && StringUtils.isNotEmpty(normalizedCategory)) {
            list = collectQuestions(normalizedDeptType, null, normalizedCategory, scope, userId, limit);
        }
        if (list.isEmpty() && StringUtils.isNotEmpty(normalizedCourseName)) {
            list = collectQuestions(normalizedDeptType, null, normalizedCourseName, scope, userId, limit);
        }

        logger.info("结课测验取题 - courseId={}, courseName={}, deptType={}, category={}, scope={}, 返回={}",
                courseId, normalizedCourseName, normalizedDeptType, normalizedCategory, normalizeScope(scope), list.size());
        return success(list);
    }

    /**
     * 批量生成部门培训题目解析
     */
    @PreAuthorize("@ss.hasPermi('train:deptQuestion:edit')")
    @Log(title = "批量生成部门题目解析", businessType = BusinessType.UPDATE)
    @PostMapping("/batch-generate-explanation")
    public AjaxResult batchGenerateExplanation(@RequestBody Map<String, Object> params) {
        try {
            // 1. 获取题目ID列表
            Object questionIdsObj = params.get("questionIds");
            if (questionIdsObj == null) {
                return error("请选择要生成解析的题目");
            }
            
            List<Long> questionIds = new ArrayList<>();
            if (questionIdsObj instanceof List) {
                @SuppressWarnings("unchecked")
                List<Object> idsList = (List<Object>) questionIdsObj;
                for (Object idObj : idsList) {
                    if (idObj instanceof Number) {
                        questionIds.add(((Number) idObj).longValue());
                    } else if (idObj instanceof String) {
                        try {
                            questionIds.add(Long.parseLong((String) idObj));
                        } catch (NumberFormatException e) {
                            logger.warn("无法解析题目ID: {}", idObj);
                        }
                    }
                }
            }
            
            if (questionIds.isEmpty()) {
                return error("请选择要生成解析的题目");
            }
            
            // 2. 是否强制重新生成
            Boolean forceRegenerate = params.get("forceRegenerate") != null 
                ? Boolean.valueOf(params.get("forceRegenerate").toString()) 
                : false;
            
            int successCount = 0;
            int skipCount = 0;
            int failCount = 0;
            List<String> failMessages = new ArrayList<>();
            
            // 3. 遍历每个题目ID
            for (Long questionId : questionIds) {
                try {
                    // 3.1 查询题目（从从库）
                    DeptTrainingQuestion question = deptTrainingQuestionService.selectDeptTrainingQuestionById(questionId);
                    if (question == null) {
                        failCount++;
                        failMessages.add("题目ID " + questionId + " 不存在");
                        continue;
                    }
                    
                    // 3.2 检查是否已有解析
                    boolean hasExplanation = question.getExplanation() != null 
                        && !question.getExplanation().trim().isEmpty();
                    
                    if (hasExplanation && !forceRegenerate) {
                        skipCount++;
                        continue;
                    }
                    
                    // 3.3 验证题目信息
                    if (question.getQuestionText() == null || question.getQuestionText().trim().isEmpty()) {
                        failCount++;
                        failMessages.add("题目ID " + questionId + " 题目内容为空");
                        continue;
                    }
                    if (question.getCorrectAnswer() == null || question.getCorrectAnswer().trim().isEmpty()) {
                        failCount++;
                        failMessages.add("题目ID " + questionId + " 正确答案为空");
                        continue;
                    }
                    
                    // 3.4 构建选项列表
                    List<String> options = new ArrayList<>();
                    if (question.getOptionA() != null && !question.getOptionA().trim().isEmpty()) {
                        options.add(question.getOptionA());
                    }
                    if (question.getOptionB() != null && !question.getOptionB().trim().isEmpty()) {
                        options.add(question.getOptionB());
                    }
                    if (question.getOptionC() != null && !question.getOptionC().trim().isEmpty()) {
                        options.add(question.getOptionC());
                    }
                    if (question.getOptionD() != null && !question.getOptionD().trim().isEmpty()) {
                        options.add(question.getOptionD());
                    }
                    
                    if (options.isEmpty()) {
                        failCount++;
                        failMessages.add("题目ID " + questionId + " 题目选项为空");
                        continue;
                    }
                    
                    // 3.5 调用AI服务生成解析
                    if (trainAiService == null) {
                        failCount++;
                        failMessages.add("题目ID " + questionId + " AI服务未启用");
                        continue;
                    }

                    String explanation = trainAiService.generateQuestionExplanation(
                        question.getQuestionText(),
                        options,
                        question.getCorrectAnswer()
                    );
                    
                    if (explanation == null || explanation.trim().isEmpty()) {
                        failCount++;
                        failMessages.add("题目ID " + questionId + " AI生成解析失败");
                        continue;
                    }
                    
                    // 3.6 保存解析到数据库
                    question.setExplanation(explanation.trim());
                    question.setUpdateBy(getUsername());
                    int updateResult = deptTrainingQuestionService.updateDeptTrainingQuestion(question);
                    
                    if (updateResult > 0) {
                        successCount++;
                    } else {
                        failCount++;
                        failMessages.add("题目ID " + questionId + " 保存解析失败");
                    }
                    
                } catch (Exception e) {
                    failCount++;
                    failMessages.add("题目ID " + questionId + " 处理失败: " + e.getMessage());
                    logger.error("生成题目{}解析失败", questionId, e);
                }
            }
            
            // 4. 构建返回结果
            Map<String, Object> result = new HashMap<>();
            result.put("total", questionIds.size());
            result.put("success", successCount);
            result.put("skip", skipCount);
            result.put("fail", failCount);
            result.put("failMessages", failMessages);
            
            String message = String.format("批量生成完成：成功 %d 个，跳过 %d 个（已有解析），失败 %d 个", 
                successCount, skipCount, failCount);
            result.put("message", message);
            
            return success(result);
            
        } catch (Exception e) {
            logger.error("批量生成部门题目解析异常", e);
            return error("批量生成解析失败: " + e.getMessage());
        }
    }

    /**
     * 单个题目生成解析
     */
    @PreAuthorize("@ss.hasPermi('train:deptQuestion:edit')")
    @Log(title = "生成部门题目解析", businessType = BusinessType.UPDATE)
    @PostMapping("/{id}/generate-explanation")
    public AjaxResult generateExplanation(@PathVariable Long id) {
        try {
            DeptTrainingQuestion question = deptTrainingQuestionService.selectDeptTrainingQuestionById(id);
            if (question == null) {
                return error("题目不存在");
            }
            
            // 构建选项列表
            List<String> options = new ArrayList<>();
            if (question.getOptionA() != null) options.add(question.getOptionA());
            if (question.getOptionB() != null) options.add(question.getOptionB());
            if (question.getOptionC() != null) options.add(question.getOptionC());
            if (question.getOptionD() != null) options.add(question.getOptionD());
            
            // 调用AI生成解析
            if (trainAiService == null) {
                return error("AI服务未启用");
            }

            String explanation = trainAiService.generateQuestionExplanation(
                question.getQuestionText(),
                options,
                question.getCorrectAnswer()
            );
            
            if (explanation == null || explanation.trim().isEmpty()) {
                return error("AI生成解析失败，请重试");
            }
            
            // 保存解析
            question.setExplanation(explanation.trim());
            question.setUpdateBy(getUsername());
            deptTrainingQuestionService.updateDeptTrainingQuestion(question);
            
            return success(explanation);
            
        } catch (Exception e) {
            logger.error("生成题目解析失败", e);
            return error("生成解析失败: " + e.getMessage());
        }
    }
}
