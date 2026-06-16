package com.ruoyi.web.controller.system;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.system.domain.SysNotice;
import com.ruoyi.system.service.ISysNoticeService;

/**
 * 公告 信息操作处理
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/system/notice")
public class SysNoticeController extends BaseController
{
    @Autowired
    private ISysNoticeService noticeService;

    /**
     * 获取通知公告列表（管理端使用，根据当前用户权限过滤）
     */
    @PreAuthorize("@ss.hasPermi('system:notice:list')")
    @GetMapping("/list")
    public TableDataInfo list(SysNotice notice)
    {
        startPage();
        // 根据当前用户权限过滤公告
        try {
            SysUser currentUser = SecurityUtils.getLoginUser().getUser();
            if (currentUser != null && !currentUser.canManageAllTenants()) {
                String tenantId = currentUser.getTenantId();
                if (StringUtils.isNotEmpty(tenantId)) {
                    notice.setTenantId(tenantId);
                }
            }
        } catch (Exception e) {
            // 忽略
        }
        List<SysNotice> list = noticeService.selectNoticeList(notice);
        return getDataTable(list);
    }

    /**
     * 获取公开的通知公告列表（用户端使用，根据用户所属租户和部门过滤）
     * scope: 0=全平台, 1=本集团, 2=本公司, 3=本部门
     */
    @GetMapping("/public/list")
    public AjaxResult publicList(@RequestParam(required = false) String tenantId, 
                                  @RequestParam(required = false) Long deptId,
                                  @RequestParam(required = false) Long companyId)
    {
        logger.info("📢 获取公告列表 - tenantId: {}, deptId: {}, companyId: {}", tenantId, deptId, companyId);
        List<SysNotice> result = new ArrayList<>();
        
        // 1. 获取全平台公告（scope=0 或 scope为空）
        SysNotice globalNotice = new SysNotice();
        globalNotice.setStatus("0");
        globalNotice.setScope("0");
        List<SysNotice> globalList = noticeService.selectNoticeList(globalNotice);
        logger.info("📢 全平台公告(scope=0)数量: {}", globalList.size());
        result.addAll(globalList);
        
        // 1.1 获取未设置scope的公告（兼容旧数据）
        SysNotice noScopeNotice = new SysNotice();
        noScopeNotice.setStatus("0");
        List<SysNotice> allNotices = noticeService.selectNoticeList(noScopeNotice);
        logger.info("📢 所有正常状态公告数量: {}", allNotices.size());
        for (SysNotice n : allNotices) {
            logger.info("📢 公告: id={}, title={}, scope={}, status={}", n.getNoticeId(), n.getNoticeTitle(), n.getScope(), n.getStatus());
            if (StringUtils.isEmpty(n.getScope()) && !result.stream().anyMatch(r -> r.getNoticeId().equals(n.getNoticeId()))) {
                result.add(n);
            }
        }
        logger.info("📢 最终返回公告数量: {}", result.size());
        
        // 2. 如果有租户ID，获取该集团的公告（scope=1）
        if (StringUtils.isNotEmpty(tenantId)) {
            SysNotice tenantNotice = new SysNotice();
            tenantNotice.setStatus("0");
            tenantNotice.setScope("1");
            tenantNotice.setTenantId(tenantId);
            result.addAll(noticeService.selectNoticeList(tenantNotice));
        }
        
        // 3. 如果有公司ID，获取该公司的公告（scope=2）
        if (companyId != null) {
            SysNotice companyNotice = new SysNotice();
            companyNotice.setStatus("0");
            companyNotice.setScope("2");
            companyNotice.setDeptId(companyId);
            result.addAll(noticeService.selectNoticeList(companyNotice));
        }
        
        // 4. 如果有部门ID，获取该部门的公告（scope=3）
        if (deptId != null) {
            SysNotice deptNotice = new SysNotice();
            deptNotice.setStatus("0");
            deptNotice.setScope("3");
            deptNotice.setDeptId(deptId);
            result.addAll(noticeService.selectNoticeList(deptNotice));
        }
        
        // 按创建时间倒序排序
        result.sort((a, b) -> {
            if (a.getCreateTime() == null) return 1;
            if (b.getCreateTime() == null) return -1;
            return b.getCreateTime().compareTo(a.getCreateTime());
        });
        
        return success(result);
    }

    /**
     * 获取公开的通知公告详情（用户端使用，无需权限）
     */
    @GetMapping("/public/{noticeId}")
    public AjaxResult publicGetInfo(@PathVariable Long noticeId)
    {
        SysNotice notice = noticeService.selectNoticeById(noticeId);
        // 只返回正常状态的公告
        if (notice != null && "0".equals(notice.getStatus())) {
            return success(notice);
        }
        return error("公告不存在或已关闭");
    }

    /**
     * 根据通知公告编号获取详细信息
     */
    @PreAuthorize("@ss.hasPermi('system:notice:query')")
    @GetMapping(value = "/{noticeId}")
    public AjaxResult getInfo(@PathVariable Long noticeId)
    {
        return success(noticeService.selectNoticeById(noticeId));
    }

    /**
     * 新增通知公告
     */
    @PreAuthorize("@ss.hasPermi('system:notice:add')")
    @Log(title = "通知公告", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@Validated @RequestBody SysNotice notice)
    {
        notice.setCreateBy(getUsername());
        
        // 根据当前用户设置租户和部门信息
        // scope: 0=全平台, 1=本集团, 2=本公司, 3=本部门
        try {
            SysUser currentUser = SecurityUtils.getLoginUser().getUser();
            if (currentUser != null && !currentUser.canManageAllTenants()) {
                if (StringUtils.isNotEmpty(currentUser.getTenantId())) {
                    notice.setTenantId(currentUser.getTenantId());
                }
                // 如果是公司或部门级别的公告，设置部门ID
                if (("2".equals(notice.getScope()) || "3".equals(notice.getScope())) && currentUser.getDeptId() != null) {
                    notice.setDeptId(currentUser.getDeptId());
                }
                // 非全租户管理员不能发全平台公告
                if ("0".equals(notice.getScope())) {
                    notice.setScope("1"); // 降级为集团公告
                }
            }
        } catch (Exception e) {
            // 忽略
        }
        
        return toAjax(noticeService.insertNotice(notice));
    }

    /**
     * 修改通知公告
     */
    @PreAuthorize("@ss.hasPermi('system:notice:edit')")
    @Log(title = "通知公告", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@Validated @RequestBody SysNotice notice)
    {
        notice.setUpdateBy(getUsername());
        return toAjax(noticeService.updateNotice(notice));
    }

    /**
     * 删除通知公告
     */
    @PreAuthorize("@ss.hasPermi('system:notice:remove')")
    @Log(title = "通知公告", businessType = BusinessType.DELETE)
    @DeleteMapping("/{noticeIds}")
    public AjaxResult remove(@PathVariable Long[] noticeIds)
    {
        return toAjax(noticeService.deleteNoticeByIds(noticeIds));
    }
}
