package com.ruoyi.web.controller.train;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import com.ruoyi.common.core.domain.entity.SysDept;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.system.mapper.SysDeptMapper;
import com.ruoyi.system.mapper.SysUserMapper;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.train.domain.TrainLearningReport;
import com.ruoyi.train.service.ITrainLearningReportService;
import com.ruoyi.common.core.page.TableDataInfo;

/**
 * 学习报告Controller（管理端）
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/train/assessment/report")
public class TrainLearningReportController extends BaseController {

    /** 有效的报告周期类型 */
    private static final List<String> VALID_PERIOD_TYPES = Arrays.asList("weekly", "monthly", "quarterly");

    @Autowired
    private ITrainLearningReportService reportService;
    
    @Autowired
    private SysUserMapper userMapper;
    
    @Autowired
    private SysDeptMapper deptMapper;

    /**
     * 查询学习报告列表（支持部门隔离）
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:report:list')")
    @GetMapping("/list")
    public TableDataInfo list(TrainLearningReport report,
                               @RequestParam(required = false) Long deptId,
                               @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") Date startDate,
                               @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") Date endDate) {
        SysUser currentUser = SecurityUtils.getLoginUser().getUser();
        boolean isAdmin = currentUser.canManageAllTenants();
        
        if (!isAdmin) {
            report.setTenantId(currentUser.getTenantId());
        }
        if (startDate != null) {
            report.setPeriodStart(startDate);
        }
        if (endDate != null) {
            report.setPeriodEnd(endDate);
        }
        
        // 获取可查看的用户ID列表（主库查询）
        List<SysUser> viewableUsers = getViewableUsers(currentUser, deptId, isAdmin, report.getUserName());
        List<Long> userIds = viewableUsers.stream().map(SysUser::getUserId).collect(Collectors.toList());
        
        startPage();
        List<TrainLearningReport> list = reportService.listReports(report, userIds);
        
        // 填充用户信息（主库查询）
        fillUserInfo(list);
        
        return getDataTable(list);
    }

    /**
     * 获取报告详情
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:report:query')")
    @GetMapping("/{reportId}")
    public AjaxResult getInfo(@PathVariable Long reportId) {
        TrainLearningReport report = reportService.getReportById(reportId);
        if (report != null) {
            // 填充用户信息
            SysUser user = userMapper.selectUserById(report.getUserId());
            if (user != null) {
                report.setUserName(user.getUserName());
                report.setDeptId(user.getDeptId());
                if (user.getDept() != null) {
                    report.setDeptName(user.getDept().getDeptName());
                }
            }
        }
        return AjaxResult.success(report);
    }

    /**
     * 手动为员工生成报告（管理端）
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:report:generate')")
    @Log(title = "学习报告", businessType = BusinessType.INSERT)
    @PostMapping("/generate")
    public AjaxResult generate(@RequestParam Long userId,
                                @RequestParam String periodType) {
        // 校验周期类型
        if (!VALID_PERIOD_TYPES.contains(periodType)) {
            return AjaxResult.error("无效的报告周期类型，支持: weekly, monthly, quarterly");
        }

        SysUser currentUser = SecurityUtils.getLoginUser().getUser();
        
        // 从主库查询目标用户的部门信息
        SysUser targetUser = userMapper.selectUserById(userId);
        if (targetUser == null) {
            return AjaxResult.error("用户信息不存在");
        }
        
        // 调用带部门ID的生成方法（Service层会抛出ServiceException，由全局异常处理器处理）
        String targetTenantId = StringUtils.isNotEmpty(targetUser.getTenantId())
            ? targetUser.getTenantId()
            : currentUser.getTenantId();

        TrainLearningReport report = reportService
            .generateReportWithDept(userId, targetUser.getDeptId(), periodType, targetTenantId);

        return AjaxResult.success(report);
    }

    /**
     * 批量生成报告（管理端）
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:report:generate')")
    @Log(title = "学习报告", businessType = BusinessType.INSERT)
    @PostMapping("/batchGenerate")
    public AjaxResult batchGenerate(@RequestParam(required = false) Long deptId,
                                     @RequestParam String periodType) {
        // 校验周期类型
        if (!VALID_PERIOD_TYPES.contains(periodType)) {
            return AjaxResult.error("无效的报告周期类型，支持: weekly, monthly, quarterly");
        }

        SysUser currentUser = SecurityUtils.getLoginUser().getUser();
        boolean isAdmin = currentUser.canManageAllTenants();
        
        // 获取用户列表
        List<Long> userIds = getViewableUserIds(currentUser, deptId, isAdmin);
        if (userIds == null || userIds.isEmpty()) {
            return AjaxResult.error("没有可生成报告的用户");
        }
        
        // 批量生成报告（每个用户使用自己的部门规则，单个用户失败不阻断批量操作）
        int count = 0;
        int failed = 0;
        for (Long userId : userIds) {
            SysUser targetUser = userMapper.selectUserById(userId);
            if (targetUser != null) {
                try {
                    String targetTenantId = StringUtils.isNotEmpty(targetUser.getTenantId())
                        ? targetUser.getTenantId()
                        : currentUser.getTenantId();
                    reportService.generateReportWithDept(userId, targetUser.getDeptId(), periodType, targetTenantId);
                    count++;
                } catch (Exception e) {
                    failed++;
                    logger.warn("用户 {} 报告生成失败: {}", userId, e.getMessage());
                }
            }
        }

        if (failed > 0) {
            return AjaxResult.success(String.format("成功生成 %d 份报告，%d 份失败", count, failed));
        }
        return AjaxResult.success("成功生成 " + count + " 份报告");
    }

    /**
     * 查询部门统计
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:statistics:query')")
    @GetMapping("/statistics")
    public AjaxResult statistics(@RequestParam(required = false) Long deptId,
                                  @RequestParam String periodType,
                                  @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") Date periodEnd) {
        SysUser currentUser = SecurityUtils.getLoginUser().getUser();
        boolean isAdmin = currentUser.canManageAllTenants();
        
        List<Long> userIds = getViewableUserIds(currentUser, deptId, isAdmin);
        if (userIds == null || userIds.isEmpty()) {
            return AjaxResult.success();
        }
        
        Map<String, Object> stats = reportService.getDeptStatistics(
            currentUser.getTenantId(), userIds, periodType, periodEnd);
        return AjaxResult.success(stats);
    }

    /**
     * 查询部门排名
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:statistics:query')")
    @GetMapping("/ranking")
    public AjaxResult ranking(@RequestParam(required = false) Long deptId,
                               @RequestParam String periodType,
                               @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") Date periodEnd) {
        SysUser currentUser = SecurityUtils.getLoginUser().getUser();
        boolean isAdmin = currentUser.canManageAllTenants();
        
        List<Long> userIds = getViewableUserIds(currentUser, deptId, isAdmin);
        if (userIds == null || userIds.isEmpty()) {
            return AjaxResult.success(new ArrayList<>());
        }
        
        List<TrainLearningReport> ranking = reportService.getDeptRanking(
            currentUser.getTenantId(), userIds, periodType, periodEnd);
        
        // 填充用户信息
        fillUserInfo(ranking);
        
        return AjaxResult.success(ranking);
    }

    /**
     * 导出报告PDF
     */
    @PreAuthorize("@ss.hasPermi('train:assessment:report:export')")
    @Log(title = "学习报告", businessType = BusinessType.EXPORT)
    @GetMapping("/export/{reportId}")
    public void export(@PathVariable Long reportId, javax.servlet.http.HttpServletResponse response) {
        byte[] pdfBytes = reportService.exportReportPdf(reportId);
        if (pdfBytes == null || pdfBytes.length == 0) {
            try {
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"code\":500,\"msg\":\"PDF生成失败\"}");
            } catch (Exception ignored) { logger.debug("写入错误响应失败", ignored); }
            return;
        }
        try {
            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition", "attachment; filename=report_" + reportId + ".pdf");
            response.setContentLength(pdfBytes.length);
            response.getOutputStream().write(pdfBytes);
            response.getOutputStream().flush();
        } catch (Exception e) {
            logger.error("PDF导出失败", e);
        }
    }

    // ========== 私有方法 ==========

    /**
     * 获取可查看的用户ID列表（主库查询）
     */
    private List<Long> getViewableUserIds(SysUser currentUser, Long deptId, boolean isAdmin) {
        return getViewableUsers(currentUser, deptId, isAdmin, null).stream()
            .map(SysUser::getUserId)
            .collect(Collectors.toList());
    }

    private List<SysUser> getViewableUsers(SysUser currentUser, Long deptId, boolean isAdmin, String userName) {
        List<Long> deptIds = new ArrayList<>();
        
        if (deptId != null) {
            // 指定了部门
            deptIds.add(deptId);
            List<SysDept> childDepts = deptMapper.selectChildrenDeptById(deptId);
            if (childDepts != null) {
                for (SysDept dept : childDepts) {
                    deptIds.add(dept.getDeptId());
                }
            }
        } else if (!isAdmin && currentUser.getDeptId() != null) {
            // 非管理员，使用当前用户部门
            deptIds.add(currentUser.getDeptId());
            List<SysDept> childDepts = deptMapper.selectChildrenDeptById(currentUser.getDeptId());
            if (childDepts != null) {
                for (SysDept dept : childDepts) {
                    deptIds.add(dept.getDeptId());
                }
            }
        }
        
        // 查询部门下的用户
        SysUser queryUser = new SysUser();
        if (!isAdmin) {
            queryUser.setTenantId(currentUser.getTenantId());
        }
        if (!deptIds.isEmpty()) {
            // 这里需要根据部门ID列表查询用户
            // 简化处理：查询所有用户然后过滤
            List<SysUser> users = userMapper.selectUserList(queryUser);
            return users.stream()
                .filter(u -> deptIds.contains(u.getDeptId()))
                .filter(u -> StringUtils.isEmpty(userName) || StringUtils.containsIgnoreCase(u.getUserName(), userName))
                .collect(Collectors.toList());
        } else if (isAdmin) {
            List<SysUser> users = userMapper.selectUserList(queryUser);
            return users.stream()
                .filter(u -> StringUtils.isEmpty(userName) || StringUtils.containsIgnoreCase(u.getUserName(), userName))
                .collect(Collectors.toList());
        }

        return new ArrayList<>();
    }

    /**
     * 填充用户信息（主库查询）
     */
    private void fillUserInfo(List<TrainLearningReport> reports) {
        if (reports == null || reports.isEmpty()) {
            return;
        }
        
        List<Long> userIds = reports.stream()
            .map(TrainLearningReport::getUserId)
            .distinct()
            .collect(Collectors.toList());
        
        for (Long userId : userIds) {
            SysUser user = userMapper.selectUserById(userId);
            if (user != null) {
                for (TrainLearningReport report : reports) {
                    if (userId.equals(report.getUserId())) {
                        report.setUserName(user.getUserName());
                        report.setDeptId(user.getDeptId());
                        if (user.getDept() != null) {
                            report.setDeptName(user.getDept().getDeptName());
                        }
                    }
                }
            }
        }
    }
}
