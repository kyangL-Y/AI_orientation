package com.ruoyi.web.controller.train;

import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.utils.CosUtils;
import com.ruoyi.common.utils.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 课程视频管理Controller（管理端）
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/train/video")
public class CourseVideoController extends BaseController {
    private static final Logger log = LoggerFactory.getLogger(CourseVideoController.class);

    @Autowired
    private CosUtils cosUtils;

    /**
     * 批量上传视频到视频库（不关联课程）
     * 权限控制：只有管理员可以上传
     * 
     * @param videoFiles 视频文件数组
     * @return 上传结果
     */
    @PreAuthorize("@ss.hasPermi('train:video:upload')")
    @PostMapping("/batch-upload")
    public AjaxResult batchUploadVideos(@RequestParam("videoFiles") MultipartFile[] videoFiles) {
        try {
            if (videoFiles == null || videoFiles.length == 0) {
                return AjaxResult.error("请选择要上传的视频文件");
            }
            
            List<Map<String, Object>> results = new ArrayList<>();
            int successCount = 0;
            int failCount = 0;
            
            for (MultipartFile videoFile : videoFiles) {
                Map<String, Object> result = new HashMap<>();
                result.put("fileName", videoFile.getOriginalFilename());
                
                try {
                    // 验证文件类型
                    String originalFilename = videoFile.getOriginalFilename();
                    String extension = "";
                    if (originalFilename != null && originalFilename.contains(".")) {
                        extension = originalFilename.substring(originalFilename.lastIndexOf(".") + 1).toLowerCase();
                    }
                    
                    // 允许的视频格式
                    String[] allowedExtensions = {"mp4", "avi", "mov", "wmv", "flv", "mkv", "webm"};
                    boolean isValidExtension = false;
                    for (String ext : allowedExtensions) {
                        if (ext.equals(extension)) {
                            isValidExtension = true;
                            break;
                        }
                    }
                    
                    if (!isValidExtension) {
                        result.put("success", false);
                        result.put("message", "不支持的视频格式");
                        failCount++;
                        results.add(result);
                        continue;
                    }
                    
                    // 验证文件大小（500MB）
                    long maxSize = 500 * 1024 * 1024L;
                    if (videoFile.getSize() > maxSize) {
                        result.put("success", false);
                        result.put("message", "文件大小超过500MB");
                        failCount++;
                        results.add(result);
                        continue;
                    }
                    
                    // 生成唯一文件名（使用时间戳和随机数，避免重名）
                    String uniqueFileName = System.currentTimeMillis() + "_" + 
                        (int)(Math.random() * 10000) + "." + extension;
                    String objectKey = cosUtils.buildVideoPathPrefix() + "/" + uniqueFileName;
                    
                    // 上传到COS
                    boolean uploaded = cosUtils.uploadFile(objectKey, videoFile.getInputStream(), videoFile.getSize());
                    
                    if (uploaded) {
                        result.put("success", true);
                        result.put("message", "上传成功");
                        result.put("objectKey", objectKey);
                        result.put("size", videoFile.getSize());
                        successCount++;
                    } else {
                        result.put("success", false);
                        result.put("message", "上传失败");
                        failCount++;
                    }
                    
                } catch (Exception e) {
                    log.error("批量上传视频异常: {}", e.getMessage(), e);
                    result.put("success", false);
                    result.put("message", "上传异常：" + e.getMessage());
                    failCount++;
                }
                
                results.add(result);
            }
            
            Map<String, Object> response = new HashMap<>();
            response.put("total", videoFiles.length);
            response.put("successCount", successCount);
            response.put("failCount", failCount);
            response.put("results", results);
            
            log.info("批量上传完成，成功: {}, 失败: {}", successCount, failCount);
            return AjaxResult.success(response);
            
        } catch (Exception e) {
            log.error("批量上传视频异常: {}", e.getMessage(), e);
            return AjaxResult.error("批量上传失败：" + e.getMessage());
        }
    }

    /**
     * 上传课程视频（管理端）- 自动关联到课程
     * 权限控制：只有管理员可以上传
     * 
     * @param courseId 课程ID
     * @param videoFile 视频文件
     * @return 上传结果
     */
    @PreAuthorize("@ss.hasPermi('train:video:upload')")
    @PostMapping("/upload")
    public AjaxResult uploadVideo(
            @RequestParam("courseId") String courseId,
            @RequestParam("videoFile") MultipartFile videoFile) {
        
        try {
            // 1. 参数校验
            if (StringUtils.isEmpty(courseId)) {
                return AjaxResult.error("课程ID不能为空");
            }
            
            // 验证课程ID格式（数字）
            if (!courseId.matches("\\d+")) {
                return AjaxResult.error("课程ID必须为数字");
            }
            
            if (videoFile == null || videoFile.isEmpty()) {
                return AjaxResult.error("请选择要上传的视频文件");
            }
            
            // 验证文件类型
            String originalFilename = videoFile.getOriginalFilename();
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf(".") + 1).toLowerCase();
            }
            
            // 允许的视频格式
            String[] allowedExtensions = {"mp4", "avi", "mov", "wmv", "flv", "mkv", "webm"};
            boolean isValidExtension = false;
            for (String ext : allowedExtensions) {
                if (ext.equals(extension)) {
                    isValidExtension = true;
                    break;
                }
            }
            
            if (!isValidExtension) {
                return AjaxResult.error("不支持的视频格式，支持的格式：mp4, avi, mov, wmv, flv, mkv, webm");
            }
            
            // 验证文件大小（500MB）
            long maxSize = 500 * 1024 * 1024L; // 500MB
            if (videoFile.getSize() > maxSize) {
                return AjaxResult.error("视频文件大小不能超过500MB");
            }
            
            // 2. 构建对象键（存储路径）
            String objectKey = cosUtils.buildVideoObjectKey(courseId, extension);
            
            // 3. 上传到COS
            boolean success = cosUtils.uploadVideo(videoFile, objectKey);
            
            if (success) {
                Map<String, Object> result = new HashMap<>();
                result.put("courseId", courseId);
                result.put("objectKey", objectKey);
                result.put("originalFilename", originalFilename);
                result.put("fileSize", videoFile.getSize());
                
                log.info("视频上传成功 - 课程ID: {}, 文件: {}", courseId, originalFilename);
                return AjaxResult.success("上传成功", result);
            } else {
                return AjaxResult.error("上传失败，请检查COS配置和网络连接");
            }
            
        } catch (Exception e) {
            log.error("上传视频异常: {}", e.getMessage(), e);
            return AjaxResult.error("上传失败：" + e.getMessage());
        }
    }

    /**
     * 删除课程视频（管理端）
     * 
     * @param courseId 课程ID
     * @return 删除结果
     */
    @PreAuthorize("@ss.hasPermi('train:video:remove')")
    @DeleteMapping("/{courseId}")
    public AjaxResult deleteVideo(@PathVariable String courseId) {
        try {
            if (StringUtils.isEmpty(courseId) || !courseId.matches("\\d+")) {
                return AjaxResult.error("无效的课程ID");
            }
            
            // 尝试删除不同格式的视频文件
            String[] extensions = {"mp4", "avi", "mov", "wmv", "flv", "mkv", "webm"};
            boolean deleted = false;
            
            for (String ext : extensions) {
                String objectKey = cosUtils.buildVideoObjectKey(courseId, ext);
                if (cosUtils.objectExists(objectKey)) {
                    if (cosUtils.deleteObject(objectKey)) {
                        deleted = true;
                        log.info("删除视频成功 - 课程ID: {}, 文件: {}", courseId, objectKey);
                    }
                }
            }
            
            if (deleted) {
                return AjaxResult.success("删除成功");
            } else {
                return AjaxResult.error("未找到对应的视频文件");
            }
            
        } catch (Exception e) {
            log.error("删除视频异常: {}", e.getMessage(), e);
            return AjaxResult.error("删除失败：" + e.getMessage());
        }
    }

    /**
     * 检查视频是否存在
     * 
     * @param courseId 课程ID
     * @return 是否存在
     */
    @PreAuthorize("@ss.hasPermi('train:video:query')")
    @GetMapping("/check/{courseId}")
    public AjaxResult checkVideo(@PathVariable String courseId) {
        try {
            if (StringUtils.isEmpty(courseId) || !courseId.matches("\\d+")) {
                return AjaxResult.error("无效的课程ID");
            }
            
            // 检查常见格式的文件
            String[] extensions = {"mp4", "avi", "mov", "wmv", "flv", "mkv", "webm"};
            Map<String, Boolean> result = new HashMap<>();
            
            for (String ext : extensions) {
                String objectKey = cosUtils.buildVideoObjectKey(courseId, ext);
                result.put(ext, cosUtils.objectExists(objectKey));
            }
            
            return AjaxResult.success(result);
            
        } catch (Exception e) {
            log.error("检查视频异常: {}", e.getMessage(), e);
            return AjaxResult.error("检查失败：" + e.getMessage());
        }
    }

    /**
     * 获取课程的视频数量
     * 
     * @param courseId 课程ID
     * @return 视频数量
     */
    @PreAuthorize("@ss.hasPermi('train:video:query')")
    @GetMapping("/count/{courseId}")
    public AjaxResult getVideoCount(@PathVariable String courseId) {
        try {
            if (StringUtils.isEmpty(courseId) || !courseId.matches("\\d+")) {
                return AjaxResult.error("无效的课程ID");
            }
            
            int count = cosUtils.getVideoCount(courseId);
            Map<String, Object> result = new HashMap<>();
            result.put("courseId", courseId);
            result.put("count", count);
            
            return AjaxResult.success(result);
            
        } catch (Exception e) {
            log.error("获取视频数量异常: {}", e.getMessage(), e);
            return AjaxResult.error("获取失败：" + e.getMessage());
        }
    }

    /**
     * 获取课程的视频详细信息（数量和文件名列表）
     * 
     * @param courseId 课程ID
     * @param platform 平台名称（美团/飞猪/携程/独家）
     * @return 视频详细信息
     */
    @GetMapping("/info/{courseId}")
    public AjaxResult getCourseVideoInfo(@PathVariable String courseId, String platform) {
        try {
            if (StringUtils.isEmpty(courseId) || !courseId.matches("\\d+")) {
                return AjaxResult.error("无效的课程ID");
            }
            
            // 根据平台确定表名
            String tableName = getTableNameByPlatform(platform);
            
            // 获取视频数量
            int count = cosUtils.getVideoCount(courseId, tableName);
            
            // 获取视频文件名列表
            List<String> fileNames = cosUtils.getVideoFileNames(courseId, tableName);
            
            Map<String, Object> result = new HashMap<>();
            result.put("courseId", courseId);
            result.put("platform", platform);
            result.put("tableName", tableName);
            result.put("count", count);
            result.put("fileNames", fileNames);
            
            return AjaxResult.success(result);
            
        } catch (Exception e) {
            log.error("获取视频信息异常: {}", e.getMessage(), e);
            return AjaxResult.error("获取失败：" + e.getMessage());
        }
    }

    /**
     * 根据平台名称获取对应的表名
     */
    private String getTableNameByPlatform(String platform) {
        if (StringUtils.isEmpty(platform)) {
            return "course_category"; // 默认表
        }
        switch (platform) {
            case "美团":
                return "course_mei";
            case "飞猪":
                return "course_fei";
            case "携程":
            case "独家":
            default:
                return "course_category";
        }
    }

    /**
     * 列出云存储中的所有视频文件
     * 
     * @return 视频文件列表
     */
    @PreAuthorize("@ss.hasPermi('train:video:query')")
    @GetMapping("/list")
    public AjaxResult listAllVideos() {
        try {
            List<Map<String, Object>> videoList = cosUtils.listAllVideos();
            return AjaxResult.success(videoList);
            
        } catch (Exception e) {
            log.error("列出视频异常: {}", e.getMessage(), e);
            return AjaxResult.error("列出失败：" + e.getMessage());
        }
    }

    /**
     * 手动关联视频到课程（重命名/移动视频文件）
     * 
     * @param sourceObjectKey 源视频文件路径
     * @param targetCourseId 目标课程ID
     * @return 关联结果
     */
    @PreAuthorize("@ss.hasPermi('train:video:edit')")
    @PostMapping("/assign")
    public AjaxResult assignVideoToCourse(
            @RequestParam("sourceObjectKey") String sourceObjectKey,
            @RequestParam("targetCourseId") String targetCourseId) {
        try {
            if (StringUtils.isEmpty(sourceObjectKey)) {
                return AjaxResult.error("源视频路径不能为空");
            }
            
            if (StringUtils.isEmpty(targetCourseId) || !targetCourseId.matches("\\d+")) {
                return AjaxResult.error("无效的课程ID");
            }
            
            boolean success = cosUtils.assignVideoToCourse(sourceObjectKey, targetCourseId);
            
            if (success) {
                Map<String, Object> result = new HashMap<>();
                result.put("courseId", targetCourseId);
                result.put("message", "视频关联成功");
                return AjaxResult.success(result);
            } else {
                return AjaxResult.error("视频关联失败，可能目标课程已有视频");
            }
            
        } catch (Exception e) {
            log.error("关联视频异常: {}", e.getMessage(), e);
            return AjaxResult.error("关联失败：" + e.getMessage());
        }
    }
}

