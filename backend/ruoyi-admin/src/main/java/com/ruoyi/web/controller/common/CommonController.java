package com.ruoyi.web.controller.common;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.security.access.prepost.PreAuthorize;
import com.ruoyi.common.config.RuoYiConfig;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.common.utils.CosUtils;
import com.ruoyi.common.utils.DateUtils;
import com.ruoyi.common.utils.file.FileUploadUtils;
import com.ruoyi.common.utils.file.FileUtils;
import com.ruoyi.common.utils.uuid.IdUtils;
import com.ruoyi.framework.config.ServerConfig;

/**
 * 通用请求处理
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/common")
public class CommonController
{
    private static final Logger log = LoggerFactory.getLogger(CommonController.class);

    private static final Set<String> BLOCKED_EXTENSIONS = Collections.unmodifiableSet(new HashSet<>(Arrays.asList(
        ".html", ".htm", ".svg", ".js", ".mjs"
    )));

    private static final Set<String> BLOCKED_CONTENT_TYPES = Collections.unmodifiableSet(new HashSet<>(Arrays.asList(
        "text/html",
        "image/svg+xml",
        "application/javascript",
        "text/javascript"
    )));

    @Autowired
    private ServerConfig serverConfig;
    
    @Autowired
    private CosUtils cosUtils;

    private static final String FILE_DELIMETER = ",";

    /**
     * 通用下载请求
     * 
     * @param fileName 文件名称
     * @param delete 是否删除
     */
    @GetMapping("/download")
    public void fileDownload(String fileName, Boolean delete, HttpServletResponse response, HttpServletRequest request)
    {
        try
        {
            if (!FileUtils.checkAllowDownload(fileName))
            {
                throw new Exception(StringUtils.format("文件名称({})非法，不允许下载。 ", fileName));
            }
            String realFileName = System.currentTimeMillis() + fileName.substring(fileName.indexOf("_") + 1);
            String filePath = RuoYiConfig.getDownloadPath() + fileName;

            response.setContentType(MediaType.APPLICATION_OCTET_STREAM_VALUE);
            FileUtils.setAttachmentResponseHeader(response, realFileName);
            FileUtils.writeBytes(filePath, response.getOutputStream());
            if (delete)
            {
                FileUtils.deleteFile(filePath);
            }
        }
        catch (Exception e)
        {
            log.error("下载文件失败", e);
        }
    }

    /**
     * 通用上传请求（单个）- 使用腾讯云 COS
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping("/upload")
    public AjaxResult uploadFile(MultipartFile file) throws Exception
    {
        try
        {
            if (file == null || file.isEmpty())
            {
                return AjaxResult.error("上传文件不能为空");
            }

            String contentType = file.getContentType();
            if (contentType != null && BLOCKED_CONTENT_TYPES.contains(contentType.trim().toLowerCase()))
            {
                return AjaxResult.error("不支持的文件类型");
            }
            
            // 生成文件名：upload/日期/UUID.扩展名
            String originalFilename = file.getOriginalFilename();
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            }
            String normalizedExt = extension.trim().toLowerCase();
            if (StringUtils.isNotEmpty(normalizedExt) && BLOCKED_EXTENSIONS.contains(normalizedExt))
            {
                return AjaxResult.error("不支持的文件类型");
            }
            
            // 构建 COS 对象键：upload/2026/01/26/uuid.jpg
            String datePath = DateUtils.datePath();
            String fileName = IdUtils.fastSimpleUUID() + extension;
            String objectKey = "upload/" + datePath + "/" + fileName;
            
            // 上传到 COS
            boolean success = cosUtils.uploadFile(objectKey, file.getInputStream(), file.getSize());
            
            if (!success) {
                log.error("COS上传失败: {}", originalFilename);
                return AjaxResult.error("文件上传失败");
            }
            
            // 生成访问URL
            String cosUrl = String.format("https://%s.cos.%s.myqcloud.com/%s",
                cosUtils.getCosConfig().getBucket(),
                cosUtils.getCosConfig().getRegion(),
                objectKey);
            
            AjaxResult ajax = AjaxResult.success();
            ajax.put("url", cosUrl);
            ajax.put("fileName", objectKey);
            ajax.put("newFileName", fileName);
            ajax.put("originalFilename", originalFilename);
            return ajax;
        }
        catch (Exception e)
        {
            log.error("文件上传失败", e);
            return AjaxResult.error("文件上传失败");
        }
    }

    /**
     * 通用上传请求（多个）
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping("/uploads")
    public AjaxResult uploadFiles(List<MultipartFile> files) throws Exception
    {
        try
        {
            // 上传文件路径
            String filePath = RuoYiConfig.getUploadPath();
            List<String> urls = new ArrayList<String>();
            List<String> fileNames = new ArrayList<String>();
            List<String> newFileNames = new ArrayList<String>();
            List<String> originalFilenames = new ArrayList<String>();
            for (MultipartFile file : files)
            {
                String contentType = file.getContentType();
                if (contentType != null && BLOCKED_CONTENT_TYPES.contains(contentType.trim().toLowerCase()))
                {
                    return AjaxResult.error("不支持的文件类型");
                }

                String originalFilename = file.getOriginalFilename();
                String extension = "";
                if (originalFilename != null && originalFilename.contains("."))
                {
                    extension = originalFilename.substring(originalFilename.lastIndexOf("."));
                }
                String normalizedExt = extension.trim().toLowerCase();
                if (StringUtils.isNotEmpty(normalizedExt) && BLOCKED_EXTENSIONS.contains(normalizedExt))
                {
                    return AjaxResult.error("不支持的文件类型");
                }
                // 上传并返回新文件名称
                String fileName = FileUploadUtils.upload(filePath, file);
                String url = serverConfig.getUrl() + fileName;
                urls.add(url);
                fileNames.add(fileName);
                newFileNames.add(FileUtils.getName(fileName));
                originalFilenames.add(originalFilename);
            }
            AjaxResult ajax = AjaxResult.success();
            ajax.put("urls", StringUtils.join(urls, FILE_DELIMETER));
            ajax.put("fileNames", StringUtils.join(fileNames, FILE_DELIMETER));
            ajax.put("newFileNames", StringUtils.join(newFileNames, FILE_DELIMETER));
            ajax.put("originalFilenames", StringUtils.join(originalFilenames, FILE_DELIMETER));
            return ajax;
        }
        catch (Exception e)
        {
            log.error("文件上传失败", e);
            return AjaxResult.error("文件上传失败");
        }
    }

    /**
     * 本地资源通用下载
     */
    @GetMapping("/download/resource")
    public void resourceDownload(String resource, HttpServletRequest request, HttpServletResponse response)
            throws Exception
    {
        try
        {
            if (!FileUtils.checkAllowDownload(resource))
            {
                throw new Exception(StringUtils.format("资源文件({})非法，不允许下载。 ", resource));
            }
            // 本地资源路径
            String localPath = RuoYiConfig.getProfile();
            // 数据库资源地址
            String downloadPath = localPath + FileUtils.stripPrefix(resource);
            // 下载名称
            String downloadName = StringUtils.substringAfterLast(downloadPath, "/");
            response.setContentType(MediaType.APPLICATION_OCTET_STREAM_VALUE);
            FileUtils.setAttachmentResponseHeader(response, downloadName);
            FileUtils.writeBytes(downloadPath, response.getOutputStream());
        }
        catch (Exception e)
        {
            log.error("下载文件失败", e);
        }
    }
}
