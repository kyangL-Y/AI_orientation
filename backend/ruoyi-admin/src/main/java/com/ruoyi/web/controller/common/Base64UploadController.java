package com.ruoyi.web.controller.common;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.util.Arrays;
import java.util.Base64;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import javax.imageio.ImageIO;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import com.ruoyi.common.core.domain.AjaxResult;
import org.springframework.security.access.prepost.PreAuthorize;

/**
 * Base64图片上传接口
 * 将图片转为Base64存储，不依赖文件系统
 */
@RestController
@RequestMapping("/common")
public class Base64UploadController {

    private static final Set<String> ALLOWED_IMAGE_TYPES = Collections.unmodifiableSet(new HashSet<>(Arrays.asList(
        "image/png",
        "image/jpeg",
        "image/gif"
    )));

    /**
     * 上传图片并返回Base64
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping("/uploadBase64")
    public AjaxResult uploadBase64(@RequestParam("file") MultipartFile file) {
        try {
            if (file.isEmpty()) {
                return AjaxResult.error("文件不能为空");
            }
            
            // 检查文件类型
            String contentType = file.getContentType();
            if (contentType == null) {
                return AjaxResult.error("无法识别图片类型");
            }
            String normalizedType = contentType.trim().toLowerCase();
            if (!ALLOWED_IMAGE_TYPES.contains(normalizedType)) {
                return AjaxResult.error("仅支持 PNG/JPEG/GIF 图片");
            }
            
            // 检查文件大小（限制2MB）
            if (file.getSize() > 2 * 1024 * 1024) {
                return AjaxResult.error("图片大小不能超过2MB");
            }
            
            // 转换为Base64
            byte[] bytes = file.getBytes();
            try (ByteArrayInputStream input = new ByteArrayInputStream(bytes)) {
                BufferedImage image = ImageIO.read(input);
                if (image == null) {
                    return AjaxResult.error("图片内容不合法");
                }
            }
            String base64 = Base64.getEncoder().encodeToString(bytes);
            String dataUrl = "data:" + normalizedType + ";base64," + base64;
            
            AjaxResult ajax = AjaxResult.success("上传成功");
            ajax.put("url", dataUrl);
            ajax.put("fileName", file.getOriginalFilename());
            return ajax;
        } catch (Exception e) {
            return AjaxResult.error("上传失败");
        }
    }
}
