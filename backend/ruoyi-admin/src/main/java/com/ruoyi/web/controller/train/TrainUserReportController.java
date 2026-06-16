package com.ruoyi.web.controller.train;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.TimeZone;

import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.system.mapper.SysUserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.train.domain.TrainLearningReport;
import com.ruoyi.train.service.ITrainLearningReportService;

/**
 * 用户端学习报告Controller
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/train/user/report")
public class TrainUserReportController extends BaseController {

    /** 有效的报告周期类型 */
    private static final List<String> VALID_PERIOD_TYPES = Arrays.asList("daily", "weekly", "monthly", "quarterly", "custom");

    @Autowired
    private ITrainLearningReportService reportService;
    
    @Autowired
    private SysUserMapper userMapper;

    /**
     * 生成我的学习报告
     */
    @PreAuthorize("isAuthenticated()")
    @Log(title = "生成学习报告", businessType = BusinessType.INSERT)
    @PostMapping("/generate")
    public AjaxResult generateReport(@RequestParam String periodType,
                                     @RequestParam(required = false) String startDate,
                                     @RequestParam(required = false) String endDate) {
        // 校验周期类型
        if (!VALID_PERIOD_TYPES.contains(periodType)) {
            return AjaxResult.error("无效的报告周期类型，支持: daily, weekly, monthly, quarterly, custom");
        }

        Date[] customRange;
        try {
            customRange = resolveRange(periodType, startDate, endDate);
        } catch (IllegalArgumentException e) {
            return AjaxResult.error(e.getMessage());
        }

        SysUser user = SecurityUtils.getLoginUser().getUser();
        
        // 从主库查询用户完整信息（包含部门ID）
        SysUser userWithDept = userMapper.selectUserById(user.getUserId());
        if (userWithDept == null) {
            return AjaxResult.error("用户信息不存在");
        }
        
        // 调用带部门ID的生成方法（Service层会抛出ServiceException，由全局异常处理器处理）
        TrainLearningReport report = reportService
            .generateReportWithDept(
                user.getUserId(),
                userWithDept.getDeptId(),
                periodType,
                user.getTenantId(),
                customRange[0],
                customRange[1]
            );

        return AjaxResult.success(report);
    }

    /**
     * 获取我的最新报告
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/latest")
    public AjaxResult getLatestReport(@RequestParam(required = false, defaultValue = "monthly") String periodType,
                                      @RequestParam(required = false) String startDate,
                                      @RequestParam(required = false) String endDate) {
        if (!VALID_PERIOD_TYPES.contains(periodType)) {
            return AjaxResult.error("无效的报告周期类型，支持: daily, weekly, monthly, quarterly, custom");
        }

        Date[] customRange;
        try {
            customRange = resolveRange(periodType, startDate, endDate);
        } catch (IllegalArgumentException e) {
            return AjaxResult.error(e.getMessage());
        }

        SysUser user = SecurityUtils.getLoginUser().getUser();
        TrainLearningReport report = reportService.getLatestReport(user.getUserId(), periodType, customRange[0], customRange[1]);
        return AjaxResult.success(report);
    }

    /**
     * 获取我的报告列表
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/list")
    public AjaxResult listMyReports(@RequestParam(required = false) String periodType,
                                    @RequestParam(required = false) String startDate,
                                    @RequestParam(required = false) String endDate) {
        if (periodType != null && !VALID_PERIOD_TYPES.contains(periodType)) {
            return AjaxResult.error("无效的报告周期类型，支持: daily, weekly, monthly, quarterly, custom");
        }

        Date[] customRange;
        try {
            customRange = resolveRange(periodType, startDate, endDate);
        } catch (IllegalArgumentException e) {
            return AjaxResult.error(e.getMessage());
        }

        SysUser user = SecurityUtils.getLoginUser().getUser();
        List<TrainLearningReport> list = reportService.listUserReports(user.getUserId(), periodType, customRange[0], customRange[1]);
        return AjaxResult.success(list);
    }

    private Date[] resolveRange(String periodType, String startDate, String endDate) {
        if (!"custom".equals(periodType)) {
            return new Date[] { null, null };
        }
        if (startDate == null || endDate == null || startDate.trim().isEmpty() || endDate.trim().isEmpty()) {
            throw new IllegalArgumentException("自定义范围必须同时提供开始日期和结束日期");
        }

        Date start = parseDate(startDate, false);
        Date end = parseDate(endDate, true);
        if (!start.before(end)) {
            throw new IllegalArgumentException("开始日期必须早于结束日期");
        }
        return new Date[] { start, end };
    }

    private Date parseDate(String rawDate, boolean endOfDay) {
        try {
            SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd");
            formatter.setLenient(false);
            formatter.setTimeZone(TimeZone.getTimeZone("Asia/Shanghai"));
            Date parsed = formatter.parse(rawDate);
            Calendar calendar = Calendar.getInstance(TimeZone.getTimeZone("Asia/Shanghai"));
            calendar.setTime(parsed);
            if (endOfDay) {
                calendar.set(Calendar.HOUR_OF_DAY, 23);
                calendar.set(Calendar.MINUTE, 59);
                calendar.set(Calendar.SECOND, 59);
                calendar.set(Calendar.MILLISECOND, 999);
            } else {
                calendar.set(Calendar.HOUR_OF_DAY, 0);
                calendar.set(Calendar.MINUTE, 0);
                calendar.set(Calendar.SECOND, 0);
                calendar.set(Calendar.MILLISECOND, 0);
            }
            return calendar.getTime();
        } catch (ParseException e) {
            throw new IllegalArgumentException("日期格式无效，请使用 yyyy-MM-dd");
        }
    }

    /**
     * 获取报告详情
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/{reportId}")
    public AjaxResult getReportDetail(@PathVariable Long reportId) {
        SysUser user = SecurityUtils.getLoginUser().getUser();
        TrainLearningReport report = reportService.getReportById(reportId);
        
        // 验证权限：只能查看自己的报告
        if (report == null || !user.getUserId().equals(report.getUserId())) {
            return AjaxResult.error("无权查看此报告");
        }
        
        return AjaxResult.success(report);
    }
}
