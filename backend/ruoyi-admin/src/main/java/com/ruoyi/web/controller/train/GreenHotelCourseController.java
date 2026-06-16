package com.ruoyi.web.controller.train;

import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.enums.DataSourceType;
import com.ruoyi.common.utils.CosUtils;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.common.utils.poi.ExcelUtil;
import com.ruoyi.train.service.IMembershipService;
import com.ruoyi.system.domain.GreenHotelCourse;
import com.ruoyi.system.service.IGreenHotelCourseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import javax.servlet.http.HttpServletResponse;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * 绿色饭店课程Controller
 */
@RestController
@RequestMapping("/train/green-hotel-course")
public class GreenHotelCourseController extends BaseController
{
    @Autowired
    private IGreenHotelCourseService greenHotelCourseService;

    @Autowired
    private CosUtils cosUtils;

    @Autowired(required = false)
    private IMembershipService membershipService;

    /** 视频存储路径前缀 */
    private static final String VIDEO_PATH_PREFIX = "green_hotel_course";
    /** 免费用户试看时长（秒） */
    private static final int FREE_PREVIEW_DURATION = 30;

    /**
     * 查询绿色饭店课程列表（分页）
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/list")
    @DataSource(DataSourceType.SLAVE)
    public TableDataInfo list(GreenHotelCourse query)
    {
        applyTenantScope(query);
        startPage();
        List<GreenHotelCourse> list = greenHotelCourseService.selectGreenHotelCourseList(query);
        return getDataTable(list);
    }

    /**
     * 查询绿色饭店课程列表（不分页）
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/list-all")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult listAll(GreenHotelCourse query)
    {
        applyTenantScope(query);
        List<GreenHotelCourse> list = greenHotelCourseService.selectGreenHotelCourseList(query);
        return success(list);
    }

    /**
     * 查询绿色饭店课程详情
     */
    @PreAuthorize("@ss.hasPermi('train:greenHotelCourse:query')")
    @GetMapping("/{greenCourseId}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getInfo(@PathVariable Long greenCourseId)
    {
        GreenHotelCourse course = greenHotelCourseService.selectGreenHotelCourseById(greenCourseId);
        if (course == null)
        {
            return error("课程不存在");
        }
        if (!hasTenantDataPermission(course))
        {
            return error("无权限访问该课程");
        }
        return success(course);
    }

    /**
     * 新增绿色饭店课程
     */
    @PreAuthorize("@ss.hasPermi('train:greenHotelCourse:add')")
    @Log(title = "绿色饭店课程", businessType = BusinessType.INSERT)
    @PostMapping
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult add(@RequestBody GreenHotelCourse course)
    {
        fillTenantForWrite(course, true);
        course.setCreateBy(getUsername());
        return toAjax(greenHotelCourseService.insertGreenHotelCourse(course));
    }

    /**
     * 修改绿色饭店课程
     */
    @PreAuthorize("@ss.hasPermi('train:greenHotelCourse:edit')")
    @Log(title = "绿色饭店课程", businessType = BusinessType.UPDATE)
    @PutMapping
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult edit(@RequestBody GreenHotelCourse course)
    {
        if (course == null || course.getGreenCourseId() == null)
        {
            return error("课程ID不能为空");
        }
        GreenHotelCourse exist = greenHotelCourseService.selectGreenHotelCourseById(course.getGreenCourseId());
        if (exist == null)
        {
            return error("课程不存在");
        }
        if (!hasTenantDataPermission(exist))
        {
            return error("无权限修改该课程");
        }

        fillTenantForWrite(course, false);
        course.setUpdateBy(getUsername());
        return toAjax(greenHotelCourseService.updateGreenHotelCourse(course));
    }

    /**
     * 删除绿色饭店课程
     */
    @PreAuthorize("@ss.hasPermi('train:greenHotelCourse:remove')")
    @Log(title = "绿色饭店课程", businessType = BusinessType.DELETE)
    @DeleteMapping("/{ids}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult remove(@PathVariable Long[] ids)
    {
        if (ids == null || ids.length == 0)
        {
            return error("请选择要删除的课程");
        }
        for (Long id : ids)
        {
            GreenHotelCourse exist = greenHotelCourseService.selectGreenHotelCourseById(id);
            if (exist == null)
            {
                continue;
            }
            if (!hasTenantDataPermission(exist))
            {
                return error("包含无权限删除的数据");
            }
        }
        return toAjax(greenHotelCourseService.deleteGreenHotelCourseByIds(ids));
    }

    /**
     * 导出绿色饭店课程列表
     */
    @PreAuthorize("@ss.hasPermi('train:greenHotelCourse:list')")
    @Log(title = "绿色饭店课程", businessType = BusinessType.EXPORT)
    @PostMapping("/export")
    @DataSource(DataSourceType.SLAVE)
    public void export(HttpServletResponse response, GreenHotelCourse query)
    {
        applyTenantScope(query);
        List<GreenHotelCourse> list = greenHotelCourseService.selectGreenHotelCourseList(query);
        ExcelUtil<GreenHotelCourse> util = new ExcelUtil<GreenHotelCourse>(GreenHotelCourse.class);
        util.exportExcel(response, list, "绿色饭店课程数据");
    }

    /**
     * 导入绿色饭店课程数据
     */
    @PreAuthorize("@ss.hasPermi('train:greenHotelCourse:add')")
    @Log(title = "绿色饭店课程", businessType = BusinessType.IMPORT)
    @PostMapping("/importData")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult importData(MultipartFile file, boolean updateSupport) throws Exception
    {
        ExcelUtil<GreenHotelCourse> util = new ExcelUtil<GreenHotelCourse>(GreenHotelCourse.class);
        List<GreenHotelCourse> list = util.importExcel(file.getInputStream());
        for (GreenHotelCourse item : list)
        {
            fillTenantForWrite(item, true);
            item.setCreateBy(getUsername());
            item.setUpdateBy(getUsername());
        }
        String message = greenHotelCourseService.importGreenHotelCourse(list, updateSupport);
        return success(message);
    }

    /**
     * 下载导入模板
     */
    @PreAuthorize("@ss.hasPermi('train:greenHotelCourse:add')")
    @PostMapping("/importTemplate")
    public void importTemplate(HttpServletResponse response)
    {
        ExcelUtil<GreenHotelCourse> util = new ExcelUtil<GreenHotelCourse>(GreenHotelCourse.class);
        util.importTemplateExcel(response, "绿色饭店课程数据");
    }

    /**
     * 获取课程视频播放URL（生成预签名URL）
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/video/play/{courseId}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getVideoPlayUrl(@PathVariable String courseId)
    {
        if (StringUtils.isEmpty(courseId))
        {
            return error("课程ID不能为空");
        }

        Long id;
        try
        {
            id = Long.parseLong(courseId);
        }
        catch (NumberFormatException e)
        {
            return error("课程ID格式错误");
        }

        // 会员校验：免费用户为试看模式（30秒），付费会员可完整观看
        boolean isPreviewMode = true;
        int previewDuration = FREE_PREVIEW_DURATION;
        try
        {
            Long userId = SecurityUtils.getUserId();
            if (userId != null && membershipService != null)
            {
                String levelCode = membershipService.getUserMembershipLevelCode(userId);
                if (levelCode != null && !"free".equals(levelCode))
                {
                    isPreviewMode = false;
                }
            }
        }
        catch (Exception ignored) {}

        // 1. 先从数据库查询video_url
        GreenHotelCourse course = greenHotelCourseService.selectGreenHotelCourseById(id);
        if (course != null && StringUtils.isNotEmpty(course.getVideoUrl()))
        {
            String objectKey = course.getVideoUrl();
            if (cosUtils.objectExists(objectKey))
            {
                String url = cosUtils.generatePresignedUrl(objectKey);
                if (url != null)
                {
                    Map<String, Object> result = new HashMap<>();
                    result.put("url", url);
                    result.put("objectKey", objectKey);
                    result.put("isPreview", isPreviewMode);
                    result.put("previewDuration", previewDuration);
                    return success(result);
                }
            }
        }

        // 课程未配置视频
        return error("该课程暂无视频");
    }

    /**
     * 获取课程视频信息（数量和文件名）
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/video/info/{courseId}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getVideoInfo(@PathVariable String courseId)
    {
        if (StringUtils.isEmpty(courseId))
        {
            return error("课程ID不能为空");
        }

        Long id;
        try
        {
            id = Long.parseLong(courseId);
        }
        catch (NumberFormatException e)
        {
            return error("课程ID格式错误");
        }

        int count = 0;
        List<String> fileNames = new ArrayList<>();

        // 从数据库查询video_url
        GreenHotelCourse course = greenHotelCourseService.selectGreenHotelCourseById(id);
        if (course != null && StringUtils.isNotEmpty(course.getVideoUrl()))
        {
            String objectKey = course.getVideoUrl();
            if (cosUtils.objectExists(objectKey))
            {
                count = 1;
                String fileName = objectKey.substring(objectKey.lastIndexOf("/") + 1);
                fileNames.add(fileName);
            }
        }

        Map<String, Object> result = new HashMap<>();
        result.put("courseId", courseId);
        result.put("count", count);
        result.put("fileNames", fileNames);
        return success(result);
    }

    /**
     * 上传课程视频
     */
    @PreAuthorize("@ss.hasPermi('train:greenHotelCourse:edit')")
    @PostMapping("/video/upload")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult uploadVideo(
            @RequestParam("courseId") String courseId,
            @RequestParam("videoFile") MultipartFile videoFile,
            @RequestParam(value = "customName", required = false) String customName)
    {
        try
        {
            if (StringUtils.isEmpty(courseId))
            {
                return error("课程ID不能为空");
            }

            Long id;
            try
            {
                id = Long.parseLong(courseId);
            }
            catch (NumberFormatException e)
            {
                return error("课程ID格式错误");
            }

            // 检查课程是否存在
            GreenHotelCourse existCourse = greenHotelCourseService.selectGreenHotelCourseById(id);
            if (existCourse == null)
            {
                return error("课程不存在");
            }

            if (videoFile == null || videoFile.isEmpty())
            {
                return error("请选择视频文件");
            }

            // 验证文件类型
            String originalFilename = videoFile.getOriginalFilename();
            String extension = "";
            if (originalFilename != null && originalFilename.contains("."))
            {
                extension = originalFilename.substring(originalFilename.lastIndexOf(".") + 1).toLowerCase();
            }
            String[] allowedExtensions = {"mp4", "avi", "mov", "wmv", "flv", "mkv", "webm"};
            boolean isValid = false;
            for (String ext : allowedExtensions)
            {
                if (ext.equals(extension))
                {
                    isValid = true;
                    break;
                }
            }
            if (!isValid)
            {
                return error("不支持的视频格式，支持：mp4, avi, mov, wmv, flv, mkv, webm");
            }

            // 验证文件大小（500MB）
            if (videoFile.getSize() > 500 * 1024 * 1024L)
            {
                return error("视频文件不能超过500MB");
            }

            // 使用courseId作为文件名，确保唯一性
            String fileName = courseId;

            // 上传到COS
            String objectKey = VIDEO_PATH_PREFIX + "/" + fileName + "." + extension;
            boolean uploadSuccess = cosUtils.uploadVideo(videoFile, objectKey);

            if (uploadSuccess)
            {
                // 更新课程的video_url字段
                GreenHotelCourse course = new GreenHotelCourse();
                course.setGreenCourseId(id);
                course.setVideoUrl(objectKey);
                course.setUpdateBy(getUsername());
                greenHotelCourseService.updateGreenHotelCourse(course);

                Map<String, Object> result = new HashMap<>();
                result.put("courseId", courseId);
                result.put("objectKey", objectKey);
                result.put("fileName", fileName + "." + extension);
                result.put("originalFilename", originalFilename);
                result.put("fileSize", videoFile.getSize());
                return AjaxResult.success("上传成功", result);
            }
            else
            {
                return error("上传失败");
            }
        }
        catch (Exception e)
        {
            return error("上传异常，请稍后重试");
        }
    }

    /**
     * 删除课程视频
     */
    @PreAuthorize("@ss.hasPermi('train:greenHotelCourse:edit')")
    @DeleteMapping("/video/{courseId}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult deleteVideo(@PathVariable String courseId)
    {
        if (StringUtils.isEmpty(courseId))
        {
            return error("课程ID不能为空");
        }

        Long id;
        try
        {
            id = Long.parseLong(courseId);
        }
        catch (NumberFormatException e)
        {
            return error("课程ID格式错误");
        }

        try
        {
            GreenHotelCourse course = greenHotelCourseService.selectGreenHotelCourseById(id);
            if (course == null)
            {
                return error("课程不存在");
            }
            if (StringUtils.isEmpty(course.getVideoUrl()))
            {
                return success("该课程未配置视频");
            }

            // 尝试删除COS文件
            boolean cosDeleted = false;
            String objectKey = course.getVideoUrl();
            if (cosUtils.objectExists(objectKey))
            {
                cosDeleted = cosUtils.deleteObject(objectKey);
            }

            // 无论COS删除结果如何，都清空数据库中的video_url字段
            GreenHotelCourse updateCourse = new GreenHotelCourse();
            updateCourse.setGreenCourseId(id);
            updateCourse.setVideoUrl("");
            updateCourse.setUpdateBy(getUsername());
            greenHotelCourseService.updateGreenHotelCourse(updateCourse);

            return success(cosDeleted ? "视频删除成功" : "视频记录已清除");
        }
        catch (Exception e)
        {
            return error("删除视频异常，请稍后重试");
        }
    }

    private void applyTenantScope(GreenHotelCourse query)
    {
        if (query == null)
        {
            return;
        }
        try
        {
            SysUser user = getLoginUser().getUser();
            if (!user.isSuperAdmin() && !user.isPlatformAdmin())
            {
                query.setTenantId(user.getTenantId());
            }
        }
        catch (Exception ignored)
        {
            // 匿名/异常保持默认条件
        }
    }

    private void fillTenantForWrite(GreenHotelCourse course, boolean isAdd)
    {
        if (course == null)
        {
            return;
        }
        if (isAdd && course.getStatus() == null)
        {
            course.setStatus(1);
        }

        try
        {
            SysUser user = getLoginUser().getUser();
            if (user.isSuperAdmin() || user.isPlatformAdmin())
            {
                if (isAdd && StringUtils.isEmpty(course.getTenantId()))
                {
                    course.setTenantId("000000");
                }
                return;
            }
            course.setTenantId(user.getTenantId());
        }
        catch (Exception ignored)
        {
            if (isAdd && StringUtils.isEmpty(course.getTenantId()))
            {
                course.setTenantId("000000");
            }
        }
    }

    private boolean hasTenantDataPermission(GreenHotelCourse course)
    {
        if (course == null)
        {
            return false;
        }
        try
        {
            SysUser user = getLoginUser().getUser();
            if (user.isSuperAdmin() || user.isPlatformAdmin())
            {
                return true;
            }
            return Objects.equals(course.getTenantId(), user.getTenantId())
                || "000000".equals(course.getTenantId())
                || course.getTenantId() == null
                || course.getTenantId().trim().isEmpty();
        }
        catch (Exception ignored)
        {
            return false;
        }
    }
}
