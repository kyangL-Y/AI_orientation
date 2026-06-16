package com.ruoyi.web.controller.train;

import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.utils.CosUtils;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.train.service.IMembershipService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * 课程视频播放Controller（用户端）
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/train/video/play")
public class CourseVideoPlayController extends BaseController {
    private static final Logger log = LoggerFactory.getLogger(CourseVideoPlayController.class);

    @Autowired
    private CosUtils cosUtils;
    
    @Autowired(required = false)
    private IMembershipService membershipService;

    // 免费用户试看时长（秒）
    private static final int FREE_PREVIEW_DURATION = 30;

    /**
     * 获取视频播放URL（用户端）
     * 生成临时签名URL，安全且有效
     * 免费用户只能试看30秒
     * 
     * @param courseId 课程ID
     * @return 播放URL
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping
    public AjaxResult getPlayUrl(@RequestParam("courseId") String courseId) {
        try {
            // 1. 参数校验
            if (StringUtils.isEmpty(courseId)) {
                return AjaxResult.error("课程ID不能为空");
            }
            
            if (!courseId.matches("\\d+")) {
                return AjaxResult.error("无效的课程ID");
            }
            
            log.info("========== 视频播放请求 ==========");
            log.info("课程ID: {}", courseId);
            log.info("当前存储桶: {}", cosUtils.getCosConfig().getBucket());
            log.info("当前区域: {}", cosUtils.getCosConfig().getRegion());
            
            // 2. 检查会员状态
            boolean isPreviewMode = true; // 默认试看模式
            int previewDuration = FREE_PREVIEW_DURATION;
            
            try {
                Long userId = SecurityUtils.getUserId();
                if (userId != null && membershipService != null) {
                    String levelCode = membershipService.getUserMembershipLevelCode(userId);
                    log.info("用户ID: {}, 会员等级: {}", userId, levelCode);
                    
                    // 付费会员可以观看完整视频 (light/standard/flagship/enterprise)
                    // free 为免费用户，只能试看
                    if (!"free".equals(levelCode) && levelCode != null) {
                        isPreviewMode = false;
                        log.info("付费会员({})，可观看完整视频", levelCode);
                    } else {
                        log.info("免费用户，试看模式，时长: {}秒", previewDuration);
                    }
                } else {
                    log.info("未登录或无会员服务，默认试看模式");
                }
            } catch (Exception e) {
                log.warn("获取会员状态失败，默认试看模式: {}", e.getMessage());
            }
            
            // 3. 查找视频文件（按优先级顺序查找）
            String[] extensions = {"mp4", "avi", "mov", "wmv", "flv", "mkv", "webm"};
            String foundObjectKey = null;
            String foundExtension = null;
            
            for (String ext : extensions) {
                String objectKey = cosUtils.buildVideoObjectKey(courseId, ext);
                log.info("检查文件: {}", objectKey);
                if (cosUtils.objectExists(objectKey)) {
                    foundObjectKey = objectKey;
                    foundExtension = ext;
                    log.info("找到视频文件: {}", objectKey);
                    break;
                }
            }
            
            if (foundObjectKey == null) {
                log.warn("未找到视频文件 - 课程ID: {}", courseId);
                return AjaxResult.error("未找到对应的视频文件，课程ID: " + courseId);
            }
            
            // 4. 生成预签名URL（临时有效，防止盗链）
            String playUrl = cosUtils.generatePresignedUrl(foundObjectKey);
            
            if (StringUtils.isEmpty(playUrl)) {
                return AjaxResult.error("生成播放链接失败");
            }
            
            // 5. 返回结果（包含试看信息）
            Map<String, Object> result = new HashMap<>();
            result.put("courseId", courseId);
            result.put("url", playUrl);
            result.put("format", foundExtension);
            result.put("expireMinutes", 30); // 有效期30分钟
            result.put("isPreview", isPreviewMode); // 是否试看模式
            result.put("previewDuration", previewDuration); // 试看时长（秒）
            
            log.info("生成播放URL成功 - 课程ID: {}, 格式: {}, 试看模式: {}, URL前缀: {}", 
                courseId, foundExtension, isPreviewMode, playUrl.substring(0, Math.min(100, playUrl.length())));
            log.info("=====================================");
            return AjaxResult.success(result);
            
        } catch (Exception e) {
            log.error("获取播放URL异常: {}", e.getMessage(), e);
            return AjaxResult.error("获取播放链接失败：" + e.getMessage());
        }
    }

    /**
     * 批量获取视频播放URL
     * 
     * @param courseIds 课程ID数组（逗号分隔）
     * @return 播放URL列表
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/batch")
    public AjaxResult getBatchPlayUrls(@RequestParam("courseIds") String courseIds) {
        try {
            if (StringUtils.isEmpty(courseIds)) {
                return AjaxResult.error("课程ID列表不能为空");
            }
            
            String[] ids = courseIds.split(",");
            Map<String, Object> result = new HashMap<>();
            
            for (String courseId : ids) {
                courseId = courseId.trim();
                if (courseId.matches("\\d+")) {
                    AjaxResult singleResult = getPlayUrl(courseId);
                    if (singleResult.isSuccess()) {
                        result.put(courseId, singleResult.get(AjaxResult.DATA_TAG));
                    } else {
                        result.put(courseId, null);
                    }
                }
            }
            
            return AjaxResult.success(result);
            
        } catch (Exception e) {
            log.error("批量获取播放URL异常: {}", e.getMessage(), e);
            return AjaxResult.error("批量获取播放链接失败：" + e.getMessage());
        }
    }
}
