package com.ruoyi.web.controller.train;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.system.domain.TrainUserPoints;
import com.ruoyi.system.domain.TrainUserPointsLog;
import com.ruoyi.system.service.ITrainUserPointsService;
import com.ruoyi.system.service.ISysUserService;

/**
 * 用户积分Controller
 * 
 * @author ruoyi
 * @date 2024-02-12
 */
@RestController
@RequestMapping("/train/points")
public class TrainUserPointsController extends BaseController
{
    @Autowired
    private ITrainUserPointsService trainUserPointsService;

    @Autowired
    private com.ruoyi.system.service.ISysConfigService sysConfigService;

    @Autowired
    private ISysUserService userService;

    /**
     * 查询用户积分列表
     */
    @PreAuthorize("@ss.hasAnyPermi('train:points:list,system:user:list')")
    @GetMapping("/list")
    public TableDataInfo list(TrainUserPoints trainUserPoints)
    {
        Long queryUserId = trainUserPoints.getUserId();
        if (!SecurityUtils.hasPermi("train:points:list")) {
            if (queryUserId == null) {
                return getDataTable(new java.util.ArrayList<>());
            }
            userService.checkUserDataScope(queryUserId);
        } else if (queryUserId != null) {
            userService.checkUserDataScope(queryUserId);
        }

        // 【修复】添加集团过滤
        com.ruoyi.common.core.domain.entity.SysUser currentUser = SecurityUtils.getLoginUser().getUser();
        String currentTenantId = currentUser.getTenantId();
        Integer adminLevel = currentUser.getAdminLevel();
        boolean isPlatformAdmin = (adminLevel != null && adminLevel <= 5);

        logger.info("📊 查询用户积分列表 - tenantId: , adminLevel: {}, isPlatformAdmin: {}",
                   currentTenantId, adminLevel, isPlatformAdmin);

        // 只有非平台管理员才过滤集团
        if (!isPlatformAdmin) {
            if (trainUserPoints.getParams() == null) {
                trainUserPoints.setParams(new java.util.HashMap<>());
            }
            trainUserPoints.getParams().put("tenantId", currentTenantId);
        }

        startPage();
        List<TrainUserPoints> list = trainUserPointsService.selectTrainUserPointsList(trainUserPoints);
        return getDataTable(list);
    }

    /**
     * 增加用户积分
     */
    @PreAuthorize("@ss.hasPermi('train:points:add')")
    @Log(title = "用户积分", businessType = BusinessType.UPDATE)
    @PostMapping("/add")
    public AjaxResult add(@RequestBody PointAdjustmentBody body)
    {
        return toAjax(trainUserPointsService.addPoints(body.getUserId(), body.getPoints(), body.getReason()));
    }

    /**
     * 用户端每日打卡积分
     */
    @PostMapping("/checkin")
    public AjaxResult dailyCheckIn()
    {
        Long userId = getUserId();
        if (userId == null)
        {
            return AjaxResult.error("用户未登录");
        }

        String reason = "每日打卡奖励";
        int awardedToday = trainUserPointsService.getTodayPointsByReasonKeyword(userId, reason);
        if (awardedToday > 0)
        {
            return AjaxResult.success("今日已领取打卡奖励");
        }

        int points = 10;
        String configValue = sysConfigService.selectConfigByKey("train.points.daily.checkin");
        if (configValue != null && !configValue.isEmpty())
        {
            try
            {
                int configuredPoints = Integer.parseInt(configValue);
                if (configuredPoints > 0)
                {
                    points = configuredPoints;
                }
            }
            catch (Exception e)
            {
            }
        }

        trainUserPointsService.addPoints(userId, points, reason);
        return AjaxResult.success("打卡奖励发放成功");
    }

    /**
     * 查询用户积分日志列表
     */
    @PreAuthorize("@ss.hasPermi('train:points:list')")
    @GetMapping("/log/list")
    public TableDataInfo listLog(TrainUserPointsLog trainUserPointsLog)
    {
        // 【修复】添加集团过滤
        com.ruoyi.common.core.domain.entity.SysUser currentUser = SecurityUtils.getLoginUser().getUser();
        String currentTenantId = currentUser.getTenantId();
        Integer adminLevel = currentUser.getAdminLevel();
        boolean isPlatformAdmin = (adminLevel != null && adminLevel <= 5);

        logger.info("📊 查询用户积分日志 - tenantId: {}, adminLevel: {}, isPlatformAdmin: {}",
                   currentTenantId, adminLevel, isPlatformAdmin);

        // 只有非平台管理员才过滤集团
        if (!isPlatformAdmin) {
            if (trainUserPointsLog.getParams() == null) {
                trainUserPointsLog.setParams(new java.util.HashMap<>());
            }
            trainUserPointsLog.getParams().put("tenantId", currentTenantId);
        }

        startPage();
        List<TrainUserPointsLog> list = trainUserPointsService.selectTrainUserPointsLogList(trainUserPointsLog);
        return getDataTable(list);
    }

    /**
     * 查询我的积分明细（用户端）
     */
    @GetMapping("/my-log")
    public TableDataInfo myLog(TrainUserPointsLog trainUserPointsLog)
    {
        startPage();
        trainUserPointsLog.setUserId(getUserId());
        List<TrainUserPointsLog> list = trainUserPointsService.selectTrainUserPointsLogList(trainUserPointsLog);
        return getDataTable(list);
    }
    
    /**
     * 获取积分规则配置
     */
    @GetMapping("/rules")
    public AjaxResult getRules()
    {
        java.util.Map<String, Object> rules = new java.util.HashMap<>();
        String pointsPerAnswer = sysConfigService.selectConfigByKey("train.points.per.answer");
        // 默认为10
        int points = 10;
        if (pointsPerAnswer != null && !pointsPerAnswer.isEmpty()) {
            try {
                points = Integer.parseInt(pointsPerAnswer);
            } catch (Exception e) {
                // ignore
            }
        }
        rules.put("pointsPerAnswer", points);
        return AjaxResult.success(rules);
    }
    
    public static class PointAdjustmentBody {
        private Long userId;
        private Integer points;
        private String reason;

        public Long getUserId() { return userId; }
        public void setUserId(Long userId) { this.userId = userId; }
        public Integer getPoints() { return points; }
        public void setPoints(Integer points) { this.points = points; }
        public String getReason() { return reason; }
        public void setReason(String reason) { this.reason = reason; }
    }
}
