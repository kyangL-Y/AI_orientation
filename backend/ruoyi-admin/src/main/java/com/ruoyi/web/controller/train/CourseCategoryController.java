package com.ruoyi.web.controller.train;

import java.util.List;
import javax.servlet.http.HttpServletResponse;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.enums.DataSourceType;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.system.domain.CourseCategory;
import com.ruoyi.system.service.ICourseCategoryService;
import com.ruoyi.common.utils.poi.ExcelUtil;
import com.ruoyi.common.core.page.TableDataInfo;

/**
 * 课程分类Controller
 * 
 * @author ruoyi
 * @date 2025-01-27
 */
@RestController
@RequestMapping("/train/course-category")
public class CourseCategoryController extends BaseController
{
    @Autowired
    private ICourseCategoryService courseCategoryService;

    /**
     * 查询课程分类列表
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/list")
    @DataSource(DataSourceType.SLAVE)
    public TableDataInfo list(CourseCategory courseCategory)
    {
        startPage();
        List<CourseCategory> list = courseCategoryService.selectCourseCategoryList(courseCategory);
        return getDataTable(list);
    }

    /**
     * 查询课程分类列表（不分页，返回所有数据，用于前端展示）
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/list-all")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult listAll(CourseCategory courseCategory)
    {
        List<CourseCategory> list = courseCategoryService.selectCourseCategoryList(courseCategory);
        return success(list);
    }

    /**
     * 根据平台查询课程列表（不分页）
     * @param platform 平台名称：美团、携程、飞猪、独家
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/list-by-platform")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult listByPlatform(String platform, CourseCategory courseCategory)
    {
        List<CourseCategory> list = courseCategoryService.selectCourseListByPlatform(platform, courseCategory);
        return success(list);
    }

    /**
     * 根据平台查询课程列表（分页）
     * @param platform 平台名称：美团、携程、飞猪、独家
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/list-platform")
    @DataSource(DataSourceType.SLAVE)
    public TableDataInfo listPlatform(String platform, CourseCategory courseCategory)
    {
        startPage();
        List<CourseCategory> list = courseCategoryService.selectCourseListByPlatform(platform, courseCategory);
        return getDataTable(list);
    }

    /**
     * 查询课程分类树形结构（用于用户端前端）
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/tree")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult tree(CourseCategory courseCategory)
    {
        List<CourseCategory> list = courseCategoryService.selectCourseCategoryList(courseCategory);
        return success(list);
    }

    /**
     * 测试数据库连接
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/test")
    public AjaxResult test()
    {
        try {
            // 直接测试数据库连接
            List<CourseCategory> list = courseCategoryService.selectCourseCategoryList(new CourseCategory());
            return success("数据库连接成功，数据条数: " + list.size());
        } catch (Exception e) {
            return error("数据库连接失败: " + e.getMessage());
        }
    }

    /**
     * 测试数据库连接（直接SQL）
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/test-sql")
    public AjaxResult testSql()
    {
        try {
            // 直接测试数据库连接
            List<CourseCategory> list = courseCategoryService.selectCourseCategoryList(new CourseCategory());
            return success("数据库连接成功，数据条数: " + list.size());
        } catch (Exception e) {
            return error("数据库连接失败: " + e.getMessage());
        }
    }

    /**
     * 导出课程分类列表
     */
    @PreAuthorize("@ss.hasPermi('train:courseCategory:export')")
    @Log(title = "课程分类", businessType = BusinessType.EXPORT)
    @PostMapping("/export")
    public void export(HttpServletResponse response, CourseCategory courseCategory)
    {
        List<CourseCategory> list = courseCategoryService.selectCourseCategoryList(courseCategory);
        ExcelUtil<CourseCategory> util = new ExcelUtil<CourseCategory>(CourseCategory.class);
        util.exportExcel(response, list, "课程分类数据");
    }

    /**
     * 获取课程分类详细信息
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping(value = "/{courseCategoryId}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult getInfo(@PathVariable("courseCategoryId") Long courseCategoryId)
    {
        return success(courseCategoryService.selectCourseCategoryByCourseCategoryId(courseCategoryId));
    }

    /**
     * 新增课程分类
     */
    @PreAuthorize("@ss.hasPermi('train:courseCategory:add')")
    @Log(title = "课程分类", businessType = BusinessType.INSERT)
    @PostMapping
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult add(@RequestBody CourseCategory courseCategory)
    {
        return toAjax(courseCategoryService.insertCourseCategory(courseCategory));
    }

    /**
     * 修改课程分类
     */
    @PreAuthorize("@ss.hasPermi('train:courseCategory:edit')")
    @Log(title = "课程分类", businessType = BusinessType.UPDATE)
    @PutMapping
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult edit(@RequestBody CourseCategory courseCategory)
    {
        return toAjax(courseCategoryService.updateCourseCategory(courseCategory));
    }

    /**
     * 删除课程分类
     */
    @PreAuthorize("@ss.hasPermi('train:courseCategory:remove')")
    @Log(title = "课程分类", businessType = BusinessType.DELETE)
	@DeleteMapping("/{courseCategoryIds}")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult remove(@PathVariable Long[] courseCategoryIds)
    {
        return toAjax(courseCategoryService.deleteCourseCategoryByCourseCategoryIds(courseCategoryIds));
    }

    /**
     * 导入课程分类数据
     */
    @Log(title = "课程分类", businessType = BusinessType.IMPORT)
    @PreAuthorize("@ss.hasPermi('train:courseCategory:import')")
    @PostMapping("/importData")
    @DataSource(DataSourceType.SLAVE)
    public AjaxResult importData(org.springframework.web.multipart.MultipartFile file, boolean updateSupport) throws Exception
    {
        ExcelUtil<CourseCategory> util = new ExcelUtil<CourseCategory>(CourseCategory.class);
        List<CourseCategory> courseCategoryList = util.importExcel(file.getInputStream());
        String message = courseCategoryService.importCourseCategory(courseCategoryList, updateSupport);
        return success(message);
    }

    /**
     * 下载导入模板
     */
    @PreAuthorize("@ss.hasPermi('train:courseCategory:import')")
    @PostMapping("/importTemplate")
    public void importTemplate(HttpServletResponse response)
    {
        ExcelUtil<CourseCategory> util = new ExcelUtil<CourseCategory>(CourseCategory.class);
        util.importTemplateExcel(response, "课程分类数据");
    }
}
