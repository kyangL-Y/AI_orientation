package com.ruoyi.web.controller.train;

import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.train.domain.TrainLearningReport;
import com.ruoyi.train.service.IMultiAgentReportService;
import com.ruoyi.train.service.ITrainLearningReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;

import java.util.Date;
import java.util.List;

/**
 * 多智能体学习报告控制器
 *
 * @author ruoyi
 */
@RestController
@RequestMapping("/train/report/multi-agent")
public class MultiAgentReportController extends BaseController {

    @Autowired
    private IMultiAgentReportService multiAgentReportService;

    @Autowired
    private ITrainLearningReportService trainLearningReportService;

    @Value("${multi.agent.enabled:false}")
    private Boolean multiAgentEnabled;

    /**
     * 生成多智能体学习报告
     */
    @PostMapping("/generate")
    public AjaxResult generateReport(@RequestBody ReportGenerateRequest request) {
        // 检查多智能体系统是否启用
        if (!multiAgentEnabled) {
            return AjaxResult.error("多智能体系统未启用，请联系管理员配置");
        }

        // 检查多智能体服务健康状态
        if (!multiAgentReportService.checkServiceHealth()) {
            return AjaxResult.error("多智能体服务暂时不可用，请稍后重试或使用标准报告");
        }

        try {
            Long userId = SecurityUtils.getUserId();
            String tenantId = "000000"; // 默认租户ID，实际项目中应从上下文获取
            Long deptId = SecurityUtils.getDeptId();

            // 调用多智能体系统生成报告
            TrainLearningReport report = multiAgentReportService.generateReportWithMultiAgent(
                userId,
                request.getPeriodType(),
                tenantId,
                request.getStartDate(),
                request.getEndDate(),
                deptId
            );

            if (report == null) {
                return AjaxResult.error("报告生成失败，多智能体系统返回空结果");
            }

            // 保存报告到数据库
            int result = trainLearningReportService.insertTrainLearningReport(report);
            if (result > 0) {
                return AjaxResult.success("多智能体报告生成成功", report);
            } else {
                return AjaxResult.error("报告保存失败");
            }

        } catch (Exception e) {
            logger.error("生成多智能体报告失败", e);
            return AjaxResult.error("报告生成失败：" + e.getMessage());
        }
    }

    /**
     * 获取最新的多智能体报告
     */
    @GetMapping
    public AjaxResult getReport(@RequestParam(required = false) String periodType) {
        try {
            Long userId = SecurityUtils.getUserId();
            String tenantId = "000000"; // 默认租户ID

            // 默认查询本周报告
            if (periodType == null || periodType.isEmpty()) {
                periodType = "weekly";
            }

            // 查询数据库获取最新报告
            TrainLearningReport report = trainLearningReportService.selectLatestReportByUserAndPeriod(
                userId,
                periodType,
                tenantId
            );

            if (report == null) {
                return AjaxResult.error("未找到报告，请先生成报告");
            }

            return AjaxResult.success(report);

        } catch (Exception e) {
            logger.error("获取多智能体报告失败", e);
            return AjaxResult.error("获取报告失败：" + e.getMessage());
        }
    }

    /**
     * 获取历史报告列表
     */
    @GetMapping("/history")
    public AjaxResult getHistoryReports(
            @RequestParam(required = false) String periodType,
            @RequestParam(required = false, defaultValue = "1") Integer pageNum,
            @RequestParam(required = false, defaultValue = "10") Integer pageSize) {
        try {
            Long userId = SecurityUtils.getUserId();
            String tenantId = "000000"; // 默认租户ID

            // 查询历史报告列表
            startPage();
            List<TrainLearningReport> reports = trainLearningReportService.selectReportListByUser(
                userId,
                periodType,
                tenantId
            );

            return AjaxResult.success(getDataTable(reports));

        } catch (Exception e) {
            logger.error("获取历史报告列表失败", e);
            return AjaxResult.error("获取历史报告失败：" + e.getMessage());
        }
    }

    /**
     * 清除用户缓存
     */
    @PostMapping("/cache/clear")
    public AjaxResult clearCache() {
        if (!multiAgentEnabled) {
            return AjaxResult.error("多智能体系统未启用");
        }

        try {
            Long userId = SecurityUtils.getUserId();
            boolean success = multiAgentReportService.clearUserCache(userId);

            if (success) {
                return AjaxResult.success("缓存清除成功");
            } else {
                return AjaxResult.warn("缓存清除失败或多智能体服务不可用");
            }

        } catch (Exception e) {
            logger.error("清除用户缓存失败", e);
            return AjaxResult.error("清除缓存失败：" + e.getMessage());
        }
    }

    /**
     * 检查多智能体服务状态
     */
    @GetMapping("/health")
    public AjaxResult checkHealth() {
        if (!multiAgentEnabled) {
            return AjaxResult.success("disabled", "多智能体系统未启用");
        }

        boolean healthy = multiAgentReportService.checkServiceHealth();
        if (healthy) {
            return AjaxResult.success("healthy", "多智能体服务运行正常");
        } else {
            return AjaxResult.error("unhealthy", "多智能体服务不可用");
        }
    }

    /**
     * 报告生成请求对象
     */
    public static class ReportGenerateRequest {
        /** 周期类型：weekly/monthly/quarterly/custom */
        private String periodType;

        /** 自定义开始日期（periodType=custom时必填） */
        private Date startDate;

        /** 自定义结束日期（periodType=custom时必填） */
        private Date endDate;

        public String getPeriodType() {
            return periodType;
        }

        public void setPeriodType(String periodType) {
            this.periodType = periodType;
        }

        public Date getStartDate() {
            return startDate;
        }

        public void setStartDate(Date startDate) {
            this.startDate = startDate;
        }

        public Date getEndDate() {
            return endDate;
        }

        public void setEndDate(Date endDate) {
            this.endDate = endDate;
        }
    }
}
