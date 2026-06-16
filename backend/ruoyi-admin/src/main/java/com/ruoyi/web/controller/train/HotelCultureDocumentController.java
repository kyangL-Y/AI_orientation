package com.ruoyi.web.controller.train;

import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.config.RuoYiConfig;
import com.ruoyi.common.constant.HttpStatus;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysDept;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.enums.DataSourceType;
import com.ruoyi.common.utils.DateUtils;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.common.utils.file.FileUploadUtils;
import com.ruoyi.common.utils.uuid.IdUtils;
import com.ruoyi.system.domain.TrainHotelCultureDocument;
import com.ruoyi.system.service.ISysDeptService;
import com.ruoyi.system.service.ITrainHotelCultureDocumentService;
import org.apache.commons.io.FilenameUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ClassPathResource;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.util.StreamUtils;
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
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * 酒店文化资料接口。
 */
@RestController
@RequestMapping("/train/hotel-culture/documents")
public class HotelCultureDocumentController extends BaseController
{
    private static final String CATEGORY_HOTEL_CULTURE = "hotel_culture";
    private static final String SCOPE_TENANT = "tenant";
    private static final String SCOPE_COMPANY = "company";
    private static final String SCOPE_DEPT = "dept";
    private static final String STATUS_NORMAL = "0";
    private static final String NANJING_TENANT_ID = "T001";
    private static final Long NANJING_COMPANY_DEPT_ID = 264L;
    private static final String NANJING_COMPANY_NAME = "南京卧龙湖温德姆至尊豪庭酒店";
    private static final String RESOURCE_ROOT = "protected/hotel-culture/nanjing/";
    private static final String STORAGE_DIR_NAME = "protected-hotel-culture-documents";
    private static final String[] ALLOWED_DOCUMENT_EXTENSIONS = {
            "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt"
    };

    private static final Map<String, CultureDocument> NANJING_DOCUMENTS = createNanjingDocuments();

    @Autowired
    private ISysDeptService deptService;

    @Autowired
    private ITrainHotelCultureDocumentService documentService;

    /**
     * 当前登录人是否有任一酒店文化资料可看。前端用它控制按钮显示。
     */
    @GetMapping("/access")
    @DataSource(DataSourceType.MASTER)
    public AjaxResult getDocumentAccess()
    {
        Map<String, Object> access = new LinkedHashMap<>();
        access.put("visible", !listVisibleDocumentViews().isEmpty());
        return AjaxResult.success(access);
    }

    /**
     * 用户端获取可见资料。无权限时返回空列表，正常页面不会展示403。
     */
    @GetMapping("/visible")
    @DataSource(DataSourceType.MASTER)
    public AjaxResult listVisibleDocuments()
    {
        return AjaxResult.success(listVisibleDocumentViews());
    }

    @GetMapping("/{documentId}/download")
    @DataSource(DataSourceType.MASTER)
    public void downloadDocument(@PathVariable String documentId, HttpServletResponse response) throws IOException
    {
        if (StringUtils.startsWith(documentId, "nanjing-"))
        {
            downloadNanjingDocument(documentId.substring("nanjing-".length()), response);
            return;
        }

        Long id = parseDocumentId(documentId);
        if (id == null)
        {
            response.sendError(HttpStatus.NOT_FOUND, "资料不存在");
            return;
        }

        TrainHotelCultureDocument document = documentService.selectTrainHotelCultureDocumentById(id);
        if (document == null || !STATUS_NORMAL.equals(document.getStatus()))
        {
            response.sendError(HttpStatus.NOT_FOUND, "资料不存在");
            return;
        }
        if (!canAccessDocument(currentUser(), document))
        {
            response.sendError(HttpStatus.FORBIDDEN, "无权查看该资料");
            return;
        }

        Path file = resolveProtectedFile(document.getFilePath());
        if (file == null || !Files.exists(file))
        {
            response.sendError(HttpStatus.NOT_FOUND, "资料文件不存在");
            return;
        }
        writeLocalDocument(response, file, document.getFileName(), document.getStoredName(), document.getFileType(), false);
    }

    @GetMapping("/nanjing/access")
    @DataSource(DataSourceType.MASTER)
    public AjaxResult getNanjingDocumentAccess()
    {
        Map<String, Object> access = new LinkedHashMap<>();
        access.put("visible", canAccessNanjingDocuments());
        return AjaxResult.success(access);
    }

    @GetMapping("/nanjing")
    @DataSource(DataSourceType.MASTER)
    public org.springframework.http.ResponseEntity<AjaxResult> listNanjingDocuments()
    {
        if (!canAccessNanjingDocuments())
        {
            return org.springframework.http.ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN)
                    .body(AjaxResult.error(HttpStatus.FORBIDDEN, "仅南京公司员工可查看该资料"));
        }
        return org.springframework.http.ResponseEntity.ok(AjaxResult.success(new ArrayList<>(NANJING_DOCUMENTS.values())));
    }

    @GetMapping("/nanjing/{docKey}/download")
    @DataSource(DataSourceType.MASTER)
    public void downloadNanjingDocument(@PathVariable String docKey, HttpServletResponse response) throws IOException
    {
        CultureDocument document = NANJING_DOCUMENTS.get(docKey);
        if (document == null)
        {
            response.sendError(HttpStatus.NOT_FOUND, "资料不存在");
            return;
        }

        if (!canAccessNanjingDocuments())
        {
            response.sendError(HttpStatus.FORBIDDEN, "仅南京公司员工可查看该资料");
            return;
        }

        ClassPathResource resource = new ClassPathResource(RESOURCE_ROOT + document.getResourceName());
        if (!resource.exists())
        {
            response.sendError(HttpStatus.NOT_FOUND, "资料文件不存在");
            return;
        }

        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", buildContentDisposition(document.getFileName(), document.getAsciiFileName(), false));
        response.setHeader("Cache-Control", "private, max-age=300");
        response.setHeader("X-Content-Type-Options", "nosniff");
        response.setContentLengthLong(resource.contentLength());
        StreamUtils.copy(resource.getInputStream(), response.getOutputStream());
    }

    @PreAuthorize("@ss.hasPermi('train:hotelCultureDocument:list')")
    @GetMapping("/admin/list")
    @DataSource(DataSourceType.MASTER)
    public TableDataInfo listAdmin(TrainHotelCultureDocument query)
    {
        bindAdminTenant(query);
        startPage();
        return getDataTable(documentService.selectTrainHotelCultureDocumentList(query));
    }

    @PreAuthorize("@ss.hasPermi('train:hotelCultureDocument:query')")
    @GetMapping("/admin/{documentId}")
    @DataSource(DataSourceType.MASTER)
    public AjaxResult getInfo(@PathVariable Long documentId)
    {
        TrainHotelCultureDocument document = documentService.selectTrainHotelCultureDocumentById(documentId);
        if (!canAdminOperate(document))
        {
            return AjaxResult.error(HttpStatus.FORBIDDEN, "无权查看该资料");
        }
        return success(document);
    }

    @PreAuthorize("@ss.hasPermi('train:hotelCultureDocument:add')")
    @Log(title = "酒店文化资料", businessType = BusinessType.INSERT)
    @PostMapping("/admin/upload")
    @DataSource(DataSourceType.MASTER)
    public AjaxResult uploadAdmin(@RequestParam("file") MultipartFile file,
                                  @RequestParam String title,
                                  @RequestParam(required = false) String description,
                                  @RequestParam(required = false) String tenantId,
                                  @RequestParam(defaultValue = SCOPE_TENANT) String scopeType,
                                  @RequestParam(required = false) Long scopeDeptId,
                                  @RequestParam(required = false, defaultValue = "0") Integer sortOrder,
                                  @RequestParam(required = false, defaultValue = STATUS_NORMAL) String status,
                                  @RequestParam(required = false) String remark) throws Exception
    {
        if (file == null || file.isEmpty())
        {
            return AjaxResult.error("上传文件不能为空");
        }
        TrainHotelCultureDocument document = new TrainHotelCultureDocument();
        document.setTitle(StringUtils.trim(title));
        document.setDescription(StringUtils.trim(description));
        document.setTenantId(resolveAdminTenantId(tenantId));
        document.setScopeType(normalizeScopeType(scopeType));
        document.setScopeDeptId(scopeDeptId);
        document.setSortOrder(sortOrder == null ? 0 : sortOrder);
        document.setStatus(StringUtils.defaultIfEmpty(status, STATUS_NORMAL));
        document.setRemark(remark);
        document.setCategory(CATEGORY_HOTEL_CULTURE);
        document.setCreateBy(getUsername());

        AjaxResult validation = validateDocumentMeta(document);
        if (validation != null)
        {
            return validation;
        }

        FileUploadUtils.assertAllowed(file, ALLOWED_DOCUMENT_EXTENSIONS);
        StoredFile storedFile = storeProtectedFile(file);
        document.setFileName(safeOriginalName(file.getOriginalFilename()));
        document.setStoredName(storedFile.storedName);
        document.setFilePath(storedFile.relativePath);
        document.setFileSize(file.getSize());
        document.setFileType(FilenameUtils.getExtension(document.getFileName()).toLowerCase(Locale.ROOT));
        documentService.insertTrainHotelCultureDocument(document);
        return AjaxResult.success(document);
    }

    @PreAuthorize("@ss.hasPermi('train:hotelCultureDocument:edit')")
    @Log(title = "酒店文化资料", businessType = BusinessType.UPDATE)
    @PutMapping("/admin")
    @DataSource(DataSourceType.MASTER)
    public AjaxResult editAdmin(@RequestBody TrainHotelCultureDocument document)
    {
        TrainHotelCultureDocument old = documentService.selectTrainHotelCultureDocumentById(document.getDocumentId());
        if (!canAdminOperate(old))
        {
            return AjaxResult.error(HttpStatus.FORBIDDEN, "无权修改该资料");
        }
        document.setTenantId(resolveAdminTenantId(document.getTenantId()));
        document.setScopeType(normalizeScopeType(document.getScopeType()));
        document.setCategory(CATEGORY_HOTEL_CULTURE);
        document.setUpdateBy(getUsername());
        AjaxResult validation = validateDocumentMeta(document);
        if (validation != null)
        {
            return validation;
        }
        return toAjax(documentService.updateTrainHotelCultureDocument(document));
    }

    @PreAuthorize("@ss.hasPermi('train:hotelCultureDocument:remove')")
    @Log(title = "酒店文化资料", businessType = BusinessType.DELETE)
    @DeleteMapping("/admin/{documentIds}")
    @DataSource(DataSourceType.MASTER)
    public AjaxResult removeAdmin(@PathVariable Long[] documentIds)
    {
        for (Long documentId : documentIds)
        {
            if (!canAdminOperate(documentService.selectTrainHotelCultureDocumentById(documentId)))
            {
                return AjaxResult.error(HttpStatus.FORBIDDEN, "无权删除部分资料");
            }
        }
        return toAjax(documentService.deleteTrainHotelCultureDocumentByIds(documentIds));
    }

    private List<Map<String, Object>> listVisibleDocumentViews()
    {
        SysUser user = currentUser();
        if (user == null)
        {
            return Collections.emptyList();
        }

        List<Map<String, Object>> views = new ArrayList<>();
        TrainHotelCultureDocument query = new TrainHotelCultureDocument();
        query.setCategory(CATEGORY_HOTEL_CULTURE);
        query.setStatus(STATUS_NORMAL);
        if (!user.canManageAllTenants())
        {
            query.setTenantId(user.getTenantId());
        }
        try
        {
            List<TrainHotelCultureDocument> documents = documentService.selectTrainHotelCultureDocumentList(query);
            for (TrainHotelCultureDocument document : documents)
            {
                if (canAccessDocument(user, document))
                {
                    views.add(toDocumentView(document));
                }
            }
        }
        catch (Exception ignored)
        {
            // 兼容未执行新表SQL的环境：南京内置资料仍可正常显示。
        }

        if (canAccessNanjingDocuments())
        {
            for (CultureDocument document : NANJING_DOCUMENTS.values())
            {
                views.add(toNanjingDocumentView(document));
            }
        }
        return views;
    }

    private Map<String, Object> toDocumentView(TrainHotelCultureDocument document)
    {
        Map<String, Object> view = new LinkedHashMap<>();
        view.put("id", String.valueOf(document.getDocumentId()));
        view.put("documentId", document.getDocumentId());
        view.put("title", document.getTitle());
        view.put("description", document.getDescription());
        view.put("fileName", document.getFileName());
        view.put("fileType", document.getFileType());
        view.put("sizeLabel", formatSize(document.getFileSize()));
        view.put("companyName", StringUtils.defaultIfEmpty(document.getScopeDeptName(), document.getTenantId()));
        return view;
    }

    private Map<String, Object> toNanjingDocumentView(CultureDocument document)
    {
        Map<String, Object> view = new LinkedHashMap<>();
        view.put("id", "nanjing-" + document.getKey());
        view.put("key", document.getKey());
        view.put("title", document.getTitle());
        view.put("description", document.getDescription());
        view.put("fileName", document.getFileName());
        view.put("fileType", "pdf");
        view.put("sizeLabel", document.getSizeLabel());
        view.put("companyName", document.getCompanyName());
        view.put("readable", toReadableView(document));
        return view;
    }

    private Map<String, Object> toReadableView(CultureDocument document)
    {
        Map<String, Object> readable = new LinkedHashMap<>();
        readable.put("title", document.getTitle());
        readable.put("subtitle", document.getCompanyName());
        readable.put("version", document.getVersion());
        readable.put("badge", document.getBadge());
        readable.put("summary", document.getSummary());
        readable.put("sections", document.getSections());
        return readable;
    }

    private boolean canAccessDocument(SysUser user, TrainHotelCultureDocument document)
    {
        if (user == null || document == null)
        {
            return false;
        }
        if (user.canManageAllTenants())
        {
            return true;
        }
        if (!StringUtils.equals(user.getTenantId(), document.getTenantId()))
        {
            return false;
        }
        if (SCOPE_TENANT.equals(document.getScopeType()))
        {
            return true;
        }
        Long scopeDeptId = document.getScopeDeptId();
        if (scopeDeptId == null || user.getDeptId() == null)
        {
            return false;
        }
        if (scopeDeptId.equals(user.getDeptId()))
        {
            return true;
        }
        SysDept dept = deptService.selectDeptById(user.getDeptId());
        return dept != null && StringUtils.equals(user.getTenantId(), dept.getTenantId())
                && containsDeptId(dept.getAncestors(), scopeDeptId);
    }

    private boolean canAccessNanjingDocuments()
    {
        SysUser user = currentUser();
        if (user == null)
        {
            return false;
        }
        if (user.canManageAllTenants())
        {
            return true;
        }
        if (!StringUtils.equals(NANJING_TENANT_ID, user.getTenantId()) || user.getDeptId() == null)
        {
            return false;
        }
        if (NANJING_COMPANY_DEPT_ID.equals(user.getDeptId()))
        {
            return true;
        }

        SysDept dept = deptService.selectDeptById(user.getDeptId());
        if (dept == null || !StringUtils.equals(NANJING_TENANT_ID, dept.getTenantId()))
        {
            return false;
        }
        return containsDeptId(dept.getAncestors(), NANJING_COMPANY_DEPT_ID);
    }

    private AjaxResult validateDocumentMeta(TrainHotelCultureDocument document)
    {
        if (StringUtils.isEmpty(document.getTitle()))
        {
            return AjaxResult.error("资料标题不能为空");
        }
        if (StringUtils.isEmpty(document.getTenantId()))
        {
            return AjaxResult.error("租户不能为空");
        }
        String scopeType = normalizeScopeType(document.getScopeType());
        document.setScopeType(scopeType);
        if (!SCOPE_TENANT.equals(scopeType))
        {
            if (document.getScopeDeptId() == null)
            {
                return AjaxResult.error("公司/部门范围必须选择部门");
            }
            SysDept dept = deptService.selectDeptById(document.getScopeDeptId());
            if (dept == null)
            {
                return AjaxResult.error("选择的公司/部门不存在");
            }
            if (!StringUtils.equals(document.getTenantId(), dept.getTenantId()))
            {
                return AjaxResult.error("公司/部门不属于所选租户");
            }
            document.setScopeDeptName(dept.getDeptName());
        }
        else
        {
            document.setScopeDeptId(null);
            document.setScopeDeptName(null);
        }
        return null;
    }

    private boolean canAdminOperate(TrainHotelCultureDocument document)
    {
        if (document == null)
        {
            return false;
        }
        SysUser user = currentUser();
        return user != null && (user.canManageAllTenants() || StringUtils.equals(user.getTenantId(), document.getTenantId()));
    }

    private void bindAdminTenant(TrainHotelCultureDocument query)
    {
        SysUser user = currentUser();
        if (user != null && !user.canManageAllTenants())
        {
            query.setTenantId(user.getTenantId());
        }
    }

    private String resolveAdminTenantId(String tenantId)
    {
        SysUser user = currentUser();
        if (user != null && !user.canManageAllTenants())
        {
            return user.getTenantId();
        }
        return StringUtils.defaultIfEmpty(StringUtils.trim(tenantId), NANJING_TENANT_ID);
    }

    private String normalizeScopeType(String scopeType)
    {
        if (SCOPE_COMPANY.equals(scopeType) || SCOPE_DEPT.equals(scopeType))
        {
            return scopeType;
        }
        return SCOPE_TENANT;
    }

    private StoredFile storeProtectedFile(MultipartFile file) throws IOException
    {
        Path root = getProtectedRoot();
        String originalName = safeOriginalName(file.getOriginalFilename());
        String extension = FilenameUtils.getExtension(originalName).toLowerCase(Locale.ROOT);
        String datePath = DateUtils.datePath();
        String storedName = IdUtils.fastSimpleUUID() + "." + extension;
        String relativePath = datePath + "/" + storedName;
        Path target = root.resolve(relativePath).normalize();
        if (!target.startsWith(root))
        {
            throw new IOException("非法文件路径");
        }
        Files.createDirectories(target.getParent());
        Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);
        return new StoredFile(relativePath, storedName);
    }

    private Path getProtectedRoot() throws IOException
    {
        Path profile = Paths.get(RuoYiConfig.getProfile()).toAbsolutePath().normalize();
        Path parent = profile.getParent() == null ? profile : profile.getParent();
        Path root = parent.resolve(STORAGE_DIR_NAME).toAbsolutePath().normalize();
        Files.createDirectories(root);
        return root;
    }

    private Path resolveProtectedFile(String relativePath) throws IOException
    {
        if (StringUtils.isEmpty(relativePath))
        {
            return null;
        }
        Path root = getProtectedRoot();
        Path file = root.resolve(relativePath).normalize();
        return file.startsWith(root) ? file : null;
    }

    private void writeLocalDocument(HttpServletResponse response, Path file, String fileName, String asciiName,
                                    String fileType, boolean attachment) throws IOException
    {
        response.setContentType(toContentType(fileType));
        response.setHeader("Content-Disposition", buildContentDisposition(fileName, FilenameUtils.getName(asciiName), attachment));
        response.setHeader("Cache-Control", "private, max-age=300");
        response.setHeader("X-Content-Type-Options", "nosniff");
        response.setContentLengthLong(Files.size(file));
        Files.copy(file, response.getOutputStream());
    }

    private String buildContentDisposition(String fileName, String asciiName, boolean attachment) throws IOException
    {
        String encodedName = URLEncoder.encode(fileName, StandardCharsets.UTF_8.name()).replace("+", "%20");
        return (attachment ? "attachment" : "inline") + "; filename=\"" + asciiName + "\"; filename*=UTF-8''" + encodedName;
    }

    private String toContentType(String fileType)
    {
        String ext = StringUtils.defaultIfEmpty(fileType, "").toLowerCase(Locale.ROOT);
        if ("pdf".equals(ext)) return "application/pdf";
        if ("doc".equals(ext)) return "application/msword";
        if ("docx".equals(ext)) return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
        if ("xls".equals(ext)) return "application/vnd.ms-excel";
        if ("xlsx".equals(ext)) return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
        if ("ppt".equals(ext)) return "application/vnd.ms-powerpoint";
        if ("pptx".equals(ext)) return "application/vnd.openxmlformats-officedocument.presentationml.presentation";
        if ("txt".equals(ext)) return "text/plain; charset=UTF-8";
        return "application/octet-stream";
    }

    private String safeOriginalName(String originalFilename)
    {
        String name = FilenameUtils.getName(StringUtils.defaultIfEmpty(originalFilename, "document"));
        return StringUtils.defaultIfEmpty(name, "document");
    }

    private String formatSize(Long size)
    {
        if (size == null)
        {
            return "";
        }
        if (size < 1024)
        {
            return size + " B";
        }
        if (size < 1024 * 1024)
        {
            return (size / 1024) + " KB";
        }
        return String.format(Locale.ROOT, "%.1f MB", size / 1024.0 / 1024.0);
    }

    private Long parseDocumentId(String documentId)
    {
        try
        {
            return Long.valueOf(documentId);
        }
        catch (NumberFormatException e)
        {
            return null;
        }
    }

    private SysUser currentUser()
    {
        try
        {
            return SecurityUtils.getLoginUser().getUser();
        }
        catch (Exception e)
        {
            return null;
        }
    }

    private boolean containsDeptId(String ancestors, Long deptId)
    {
        if (StringUtils.isEmpty(ancestors) || deptId == null)
        {
            return false;
        }
        String target = String.valueOf(deptId);
        String[] parts = ancestors.split(",");
        for (String part : parts)
        {
            if (target.equals(part != null ? part.trim() : null))
            {
                return true;
            }
        }
        return false;
    }

    private static Map<String, CultureDocument> createNanjingDocuments()
    {
        Map<String, CultureDocument> documents = new LinkedHashMap<>();
        documents.put("employee-handbook", new CultureDocument(
                "employee-handbook",
                "员工手册",
                "南京公司员工手册 v1.0",
                "南京雅泉道悦湖度假酒店员工手册v1.0.pdf",
                "employee-handbook.pdf",
                "477 KB",
                NANJING_COMPANY_NAME,
                "2026 年 5 月 V1.0",
                "员工日常准则",
                "涵盖精神宪法、日常行为、入离职、薪资福利、客户服务、安全奖惩、沟通值班、学习成长与特殊管理机制。",
                NanjingHotelCultureReadableDocuments.employeeHandbookSections()
        ));
        documents.put("rules-general", new CultureDocument(
                "rules-general",
                "规章制度总纲",
                "南京卧龙湖雅泉道度假酒店规章制度总纲",
                "南京卧龙湖雅泉道度假酒店_规章制度总纲.pdf",
                "rules-general.pdf",
                "207 KB",
                NANJING_COMPANY_NAME,
                "2026 年 4 月",
                "制度根本纲领",
                "作为酒店的根本纲领，明确总则、核心价值观、组织原则、经营原则、三大红线、员工行为基本准则与附则。",
                NanjingHotelCultureReadableDocuments.rulesGeneralSections()
        ));
        return documents;
    }

    private static class StoredFile
    {
        private final String relativePath;
        private final String storedName;

        private StoredFile(String relativePath, String storedName)
        {
            this.relativePath = relativePath;
            this.storedName = storedName;
        }
    }

    public static class CultureDocument
    {
        private final String key;
        private final String title;
        private final String description;
        private final String fileName;
        private final String resourceName;
        private final String sizeLabel;
        private final String companyName;
        private final String version;
        private final String badge;
        private final String summary;
        private final List<NanjingHotelCultureReadableDocuments.CultureDocumentSection> sections;

        CultureDocument(String key, String title, String description, String fileName, String resourceName,
                        String sizeLabel, String companyName, String version, String badge, String summary,
                        List<NanjingHotelCultureReadableDocuments.CultureDocumentSection> sections)
        {
            this.key = key;
            this.title = title;
            this.description = description;
            this.fileName = fileName;
            this.resourceName = resourceName;
            this.sizeLabel = sizeLabel;
            this.companyName = companyName;
            this.version = version;
            this.badge = badge;
            this.summary = summary;
            this.sections = sections;
        }

        public String getKey()
        {
            return key;
        }

        public String getTitle()
        {
            return title;
        }

        public String getDescription()
        {
            return description;
        }

        public String getFileName()
        {
            return fileName;
        }

        public String getResourceName()
        {
            return resourceName;
        }

        public String getAsciiFileName()
        {
            return resourceName;
        }

        public String getSizeLabel()
        {
            return sizeLabel;
        }

        public String getCompanyName()
        {
            return companyName;
        }

        public String getVersion()
        {
            return version;
        }

        public String getBadge()
        {
            return badge;
        }

        public String getSummary()
        {
            return summary;
        }

        public List<NanjingHotelCultureReadableDocuments.CultureDocumentSection> getSections()
        {
            return sections;
        }
    }
}
