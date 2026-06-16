package com.ruoyi.web.controller.train;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.enums.DataSourceType;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.utils.CosUtils;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.train.service.IMembershipService;
import com.ruoyi.system.domain.DeptTrainingCourse;
import com.ruoyi.system.service.IDeptTrainingCourseService;

/**
 * 部门培训课程Controller
 * 视频存储方式与课程管理一致：通过courseId在COS中查找视频
 */
@RestController
@RequestMapping("/train/dept-course")
public class DeptTrainingCourseController extends BaseController {

    @Autowired
    private IDeptTrainingCourseService deptTrainingCourseService;

    @Autowired
    private CosUtils cosUtils;

    @Autowired(required = false)
    private IMembershipService membershipService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    /** 视频存储路径前缀（与云仓库文件夹名一致） */
    private static final String VIDEO_PATH_PREFIX = "dept_course";
    /** 免费用户试看时长（秒） */
    private static final int FREE_PREVIEW_DURATION = 30;

    /**
     * 查询部门培训课程列表
     */
    @PreAuthorize("@ss.hasPermi('train:deptCourse:list')")
    @GetMapping("/list")
    @DataSource(DataSourceType.SLAVE)
    public TableDataInfo list(DeptTrainingCourse course) {
        startPage();
        List<DeptTrainingCourse> list = deptTrainingCourseService.selectDeptTrainingCourseList(course);
        return getDataTable(list);
    }

    /**
     * 根据部门类型查询课程（用户端使用）
     */
    @GetMapping("/list-by-dept")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult listByDept(@RequestParam String deptType) {
        DeptTrainingCourse query = new DeptTrainingCourse();
        query.setDeptType(deptType);
        query.setStatus("0");
        List<DeptTrainingCourse> list = deptTrainingCourseService.selectDeptTrainingCourseList(query);
        return success(list);
    }

    /**
     * 获取所有部门类型列表（用于动态生成部门导航）
     */
    @GetMapping("/dept-types")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getDeptTypes() {
        List<String> deptTypes = deptTrainingCourseService.selectDistinctDeptTypes();
        return success(deptTypes);
    }

    /**
     * 获取课程与题库映射总览
     */
    @PreAuthorize("@ss.hasPermi('train:deptCourse:list')")
    @GetMapping("/question-mapping-overview")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getQuestionMappingOverview(DeptTrainingCourse course) {
        StringBuilder where = new StringBuilder(" WHERE 1 = 1 ");
        List<Object> args = new ArrayList<>();
        String currentTenantId = resolveCurrentTenantId();
        boolean manageAllTenants = canManageAllTenants();

        if (!manageAllTenants && StringUtils.isNotEmpty(currentTenantId)) {
            where.append(" AND (c.tenant_id = ? OR c.tenant_id = '000000' OR c.tenant_id IS NULL) ");
            args.add(currentTenantId);
        }

        if (StringUtils.isNotEmpty(course.getCourseName())) {
            where.append(" AND c.course_name LIKE ? ");
            args.add("%" + course.getCourseName().trim() + "%");
        }
        if (StringUtils.isNotEmpty(course.getDeptType())) {
            where.append(" AND c.dept_type = ? ");
            args.add(course.getDeptType().trim());
        }
        if (StringUtils.isNotEmpty(course.getLevel())) {
            where.append(" AND c.level = ? ");
            args.add(course.getLevel().trim());
        }
        if (StringUtils.isNotEmpty(course.getStatus())) {
            where.append(" AND c.status = ? ");
            args.add(course.getStatus().trim());
        }

        String rowSql =
            "SELECT c.course_id AS courseId, c.dept_type AS deptType, c.course_name AS courseName, " +
            "c.level AS level, c.duration AS duration, c.status AS status, " +
            "COUNT(q.id) AS questionCount, " +
            "COUNT(DISTINCT CASE WHEN q.category IS NOT NULL AND q.category <> '' THEN q.category END) AS categoryCount, " +
            "GROUP_CONCAT(DISTINCT CASE WHEN q.category IS NOT NULL AND q.category <> '' THEN q.category END ORDER BY q.category SEPARATOR ' / ') AS categoryNames " +
            "FROM dept_training_course c " +
            "LEFT JOIN dept_training_question_classified q ON q.matched_course_id = c.course_id AND q.status = '0' " +
            where +
            "GROUP BY c.course_id, c.dept_type, c.course_name, c.level, c.duration, c.status " +
            "ORDER BY questionCount ASC, c.sort_order ASC, c.course_id ASC";

        String summarySql =
            "SELECT COUNT(*) AS totalCourses, " +
            "SUM(CASE WHEN overview.questionCount > 0 THEN 1 ELSE 0 END) AS mappedCourses, " +
            "SUM(CASE WHEN overview.questionCount = 0 THEN 1 ELSE 0 END) AS unmappedCourses, " +
            "SUM(overview.questionCount) AS totalQuestions, " +
            "ROUND(AVG(overview.questionCount), 2) AS avgQuestionCount " +
            "FROM (" +
            "SELECT c.course_id, COUNT(q.id) AS questionCount " +
            "FROM dept_training_course c " +
            "LEFT JOIN dept_training_question_classified q ON q.matched_course_id = c.course_id AND q.status = '0' " +
            where +
            "GROUP BY c.course_id" +
            ") overview";

        List<Map<String, Object>> rows = args.isEmpty()
            ? jdbcTemplate.queryForList(rowSql)
            : jdbcTemplate.queryForList(rowSql, args.toArray());
        Map<String, Object> summary = args.isEmpty()
            ? jdbcTemplate.queryForMap(summarySql)
            : jdbcTemplate.queryForMap(summarySql, args.toArray());

        Map<String, Object> result = new HashMap<>();
        result.put("summary", summary);
        result.put("rows", rows);
        return success(result);
    }

    private String resolveCurrentTenantId() {
        try {
            SysUser user = SecurityUtils.getLoginUser().getUser();
            return user != null ? user.getTenantId() : null;
        } catch (Exception ignored) {
            return null;
        }
    }

    private boolean canManageAllTenants() {
        try {
            SysUser user = SecurityUtils.getLoginUser().getUser();
            return user != null && (user.isSuperAdmin() || user.isPlatformAdmin());
        } catch (Exception ignored) {
            return false;
        }
    }

    /**
     * 获取部门培训课程详情
     */
    @PreAuthorize("@ss.hasPermi('train:deptCourse:query')")
    @GetMapping("/{courseId}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getInfo(@PathVariable Long courseId) {
        return success(deptTrainingCourseService.selectDeptTrainingCourseById(courseId));
    }

    /**
     * 新增部门培训课程
     */
    @PreAuthorize("@ss.hasPermi('train:deptCourse:add')")
    @Log(title = "部门培训课程", businessType = BusinessType.INSERT)
    @PostMapping
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult add(@RequestBody DeptTrainingCourse course) {
        course.setCreateBy(getUsername());
        return toAjax(deptTrainingCourseService.insertDeptTrainingCourse(course));
    }

    /**
     * 修改部门培训课程
     */
    @PreAuthorize("@ss.hasPermi('train:deptCourse:edit')")
    @Log(title = "部门培训课程", businessType = BusinessType.UPDATE)
    @PutMapping
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult edit(@RequestBody DeptTrainingCourse course) {
        course.setUpdateBy(getUsername());
        return toAjax(deptTrainingCourseService.updateDeptTrainingCourse(course));
    }

    /**
     * 删除部门培训课程
     */
    @PreAuthorize("@ss.hasPermi('train:deptCourse:remove')")
    @Log(title = "部门培训课程", businessType = BusinessType.DELETE)
    @DeleteMapping("/{courseIds}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult remove(@PathVariable Long[] courseIds) {
        return toAjax(deptTrainingCourseService.deleteDeptTrainingCourseByIds(courseIds));
    }

    /**
     * 获取部门培训课程视频播放URL（生成预签名URL）
     * 优先从数据库读取video_url，支持自定义文件名
     */
    @GetMapping("/video/play/{courseId}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getVideoPlayUrl(@PathVariable String courseId) {
        if (StringUtils.isEmpty(courseId)) {
            return error("课程ID不能为空");
        }

        // 会员校验：免费用户为试看模式（30秒），付费会员可完整观看
        boolean isPreviewMode = true;
        int previewDuration = FREE_PREVIEW_DURATION;
        try {
            Long userId = SecurityUtils.getUserId();
            if (userId != null && membershipService != null) {
                String levelCode = membershipService.getUserMembershipLevelCode(userId);
                if (levelCode != null && !"free".equals(levelCode)) {
                    isPreviewMode = false;
                }
            }
        } catch (Exception ignored) {}
        
        // 1. 先从数据库查询video_url
        DeptTrainingCourse course = deptTrainingCourseService.selectDeptTrainingCourseById(Long.parseLong(courseId));
        if (course != null && StringUtils.isNotEmpty(course.getVideoUrl())) {
            String objectKey = course.getVideoUrl();
            if (cosUtils.objectExists(objectKey)) {
                String url = cosUtils.generatePresignedUrl(objectKey);
                if (url != null) {
                    Map<String, Object> result = new HashMap<>();
                    result.put("url", url);
                    result.put("objectKey", objectKey);
                    result.put("isPreview", isPreviewMode);
                    result.put("previewDuration", previewDuration);
                    return success(result);
                }
            }
        }
        
        // 2. 兜底：按courseId查找视频文件（兼容旧数据）
        String[] extensions = {"mp4", "avi", "mov", "wmv", "flv", "mkv", "webm"};
        for (String ext : extensions) {
            String objectKey = VIDEO_PATH_PREFIX + "/" + courseId + "." + ext;
            if (cosUtils.objectExists(objectKey)) {
                String url = cosUtils.generatePresignedUrl(objectKey);
                if (url != null) {
                    Map<String, Object> result = new HashMap<>();
                    result.put("url", url);
                    result.put("objectKey", objectKey);
                    result.put("isPreview", isPreviewMode);
                    result.put("previewDuration", previewDuration);
                    return success(result);
                }
            }
        }
        return error("该课程暂无视频");
    }

    /**
     * 获取课程视频信息（数量和文件名）
     */
    @GetMapping("/video/info/{courseId}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getVideoInfo(@PathVariable String courseId) {
        if (StringUtils.isEmpty(courseId)) {
            return error("课程ID不能为空");
        }
        
        int count = 0;
        List<String> fileNames = new ArrayList<>();
        
        // 1. 先从数据库查询video_url
        DeptTrainingCourse course = deptTrainingCourseService.selectDeptTrainingCourseById(Long.parseLong(courseId));
        if (course != null && StringUtils.isNotEmpty(course.getVideoUrl())) {
            String objectKey = course.getVideoUrl();
            if (cosUtils.objectExists(objectKey)) {
                count = 1;
                // 从objectKey中提取文件名
                String fileName = objectKey.substring(objectKey.lastIndexOf("/") + 1);
                fileNames.add(fileName);
            }
        }
        
        // 2. 兜底：按courseId查找视频文件（兼容旧数据）
        if (count == 0) {
            String[] extensions = {"mp4", "avi", "mov", "wmv", "flv", "mkv", "webm"};
            for (String ext : extensions) {
                String objectKey = VIDEO_PATH_PREFIX + "/" + courseId + "." + ext;
                if (cosUtils.objectExists(objectKey)) {
                    count++;
                    fileNames.add(courseId + "." + ext);
                }
            }
        }
        
        Map<String, Object> result = new HashMap<>();
        result.put("courseId", courseId);
        result.put("count", count);
        result.put("fileNames", fileNames);
        return success(result);
    }

    /**
     * 上传部门培训课程视频
     * @param courseId 课程ID
     * @param videoFile 视频文件
     * @param customName 自定义文件名（可选，不含扩展名）
     */
    @PostMapping("/video/upload")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult uploadVideo(
            @RequestParam("courseId") String courseId,
            @RequestParam("videoFile") MultipartFile videoFile,
            @RequestParam(value = "customName", required = false) String customName) {
        try {
            if (StringUtils.isEmpty(courseId)) {
                return error("课程ID不能为空");
            }
            if (videoFile == null || videoFile.isEmpty()) {
                return error("请选择视频文件");
            }

            // 验证文件类型
            String originalFilename = videoFile.getOriginalFilename();
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf(".") + 1).toLowerCase();
            }
            String[] allowedExtensions = {"mp4", "avi", "mov", "wmv", "flv", "mkv", "webm"};
            boolean isValid = false;
            for (String ext : allowedExtensions) {
                if (ext.equals(extension)) {
                    isValid = true;
                    break;
                }
            }
            if (!isValid) {
                return error("不支持的视频格式，支持：mp4, avi, mov, wmv, flv, mkv, webm");
            }

            // 验证文件大小（500MB）
            if (videoFile.getSize() > 500 * 1024 * 1024L) {
                return error("视频文件不能超过500MB");
            }

            // 确定文件名：优先使用自定义名称，否则使用原始文件名（去掉扩展名）
            String fileName;
            if (StringUtils.isNotEmpty(customName)) {
                // 使用自定义名称，清理特殊字符
                fileName = customName.replaceAll("[\\\\/:*?\"<>|]", "_").trim();
            } else if (originalFilename != null) {
                // 使用原始文件名（去掉扩展名）
                fileName = originalFilename.substring(0, originalFilename.lastIndexOf("."));
            } else {
                // 兜底使用courseId
                fileName = courseId;
            }

            // 上传到COS
            String objectKey = VIDEO_PATH_PREFIX + "/" + fileName + "." + extension;
            boolean uploadSuccess = cosUtils.uploadVideo(videoFile, objectKey);

            if (uploadSuccess) {
                // 更新课程的video_url字段
                DeptTrainingCourse course = new DeptTrainingCourse();
                course.setCourseId(Long.parseLong(courseId));
                course.setVideoUrl(objectKey);  // 存储完整的对象键
                course.setUpdateBy(getUsername());  // 记录更新人
                deptTrainingCourseService.updateDeptTrainingCourse(course);
                
                Map<String, Object> result = new HashMap<>();
                result.put("courseId", courseId);
                result.put("objectKey", objectKey);
                result.put("fileName", fileName + "." + extension);
                result.put("originalFilename", originalFilename);
                result.put("fileSize", videoFile.getSize());
                return AjaxResult.success("上传成功", result);
            } else {
                return error("上传失败");
            }
        } catch (Exception e) {
            return error("上传异常：" + e.getMessage());
        }
    }

    /**
     * 删除课程视频
     */
    @DeleteMapping("/video/{courseId}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult deleteVideo(@PathVariable String courseId) {
        if (StringUtils.isEmpty(courseId)) {
            return error("课程ID不能为空");
        }

        try {
            // 1. 先从数据库查询video_url
            DeptTrainingCourse course = deptTrainingCourseService.selectDeptTrainingCourseById(Long.parseLong(courseId));
            boolean deleted = false;

            if (course != null && StringUtils.isNotEmpty(course.getVideoUrl())) {
                // 删除数据库中记录的视频文件
                String objectKey = course.getVideoUrl();
                if (cosUtils.objectExists(objectKey)) {
                    deleted = cosUtils.deleteObject(objectKey);
                }
            }

            // 2. 兜底：按courseId查找并删除视频文件（兼容旧数据）
            if (!deleted) {
                String[] extensions = {"mp4", "avi", "mov", "wmv", "flv", "mkv", "webm"};
                for (String ext : extensions) {
                    String objectKey = VIDEO_PATH_PREFIX + "/" + courseId + "." + ext;
                    if (cosUtils.objectExists(objectKey)) {
                        if (cosUtils.deleteObject(objectKey)) {
                            deleted = true;
                        }
                    }
                }
            }

            // 3. 清空数据库中的video_url字段
            if (deleted) {
                DeptTrainingCourse updateCourse = new DeptTrainingCourse();
                updateCourse.setCourseId(Long.parseLong(courseId));
                updateCourse.setVideoUrl("");  // 设置为空字符串
                updateCourse.setUpdateBy(getUsername());
                deptTrainingCourseService.updateDeptTrainingCourse(updateCourse);

                return success("删除成功");
            } else {
                return error("未找到对应的视频文件");
            }
        } catch (Exception e) {
            return error("删除视频异常：" + e.getMessage());
        }
    }
}
