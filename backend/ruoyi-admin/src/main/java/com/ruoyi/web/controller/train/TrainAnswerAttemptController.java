package com.ruoyi.web.controller.train;

import java.util.Map;
import java.util.HashMap;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.enums.DataSourceType;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.constant.MembershipLimitConstants;
import com.ruoyi.system.domain.dto.AnswerRequest;
import com.ruoyi.system.service.ITrainAnswerAttemptService;
import com.ruoyi.common.core.page.TableDataInfo;
import java.util.List;
import com.ruoyi.system.domain.TrainAnswerAttempt;
import com.ruoyi.train.service.IMembershipService;

@RestController
@RequestMapping("/train/attempt")
public class TrainAnswerAttemptController extends BaseController {

    @Autowired
    private ITrainAnswerAttemptService attemptService;

    @Autowired
    private IMembershipService membershipService;

    /**
     * 提交答案（保存到从库 hotel_training）
     * 必须登录才能提交答案
     *
     * 注意：会员权限检查在Controller层完成（使用主库），
     * 答题记录保存在Service层完成（使用从库），
     * 避免数据源切换问题
     */
    @PostMapping("/submit")
    public AjaxResult submit(@RequestBody AnswerRequest request) {
        // 获取当前登录用户ID（必须登录）
        Long userId = getUserId();
        request.setUserId(userId);

        // ========== 会员权限检查（在Controller层，使用主库） ==========
        try {
            // 获取用户会员等级（从主库查询）
            String memberLevel = membershipService.getUserMembershipLevelCode(userId);

            // 检查是否有会员资格
            if (memberLevel == null || "expired".equals(memberLevel)) {
                Map<String, Object> resp = new HashMap<>();
                resp.put("success", false);
                resp.put("error", "会员已过期，请续费后继续答题");
                resp.put("needUpgrade", true);
                return AjaxResult.error("会员已过期，请续费后继续答题").put("data", resp);
            }

            // 免费会员每日限制
            if ("free".equals(memberLevel)) {
                int todayCount = attemptService.getTodayAnswerCountForUser(userId);

                if (todayCount >= MembershipLimitConstants.FREE_PRACTICE_DAILY_LIMIT) {
                    Map<String, Object> resp = new HashMap<>();
                    resp.put("success", false);
                    resp.put("error", "免费会员每日仅可答题" + MembershipLimitConstants.FREE_PRACTICE_DAILY_LIMIT + "次，请升级会员解锁无限刷题");
                    resp.put("needUpgrade", true);
                    resp.put("todayCount", todayCount);
                    resp.put("limit", MembershipLimitConstants.FREE_PRACTICE_DAILY_LIMIT);
                    return AjaxResult.error("免费会员每日仅可答题" + MembershipLimitConstants.FREE_PRACTICE_DAILY_LIMIT + "次，请升级会员解锁无限刷题").put("data", resp);
                }
            }
            // 其他会员等级（basic、premium、vip、light、standard等）无限制
            logger.debug("会员权限检查通过 userId={}, memberLevel={}", userId, memberLevel);

        } catch (Exception e) {
            logger.error("会员权限检查异常 userId={}, questionId={}", userId, request.getQuestionId(), e);

            Map<String, Object> resp = new HashMap<>();
            resp.put("success", false);
            resp.put("error", "权限验证失败，请稍后重试或联系管理员");
            return AjaxResult.error("权限验证失败，请稍后重试或联系管理员").put("data", resp);
        }

        // ========== 提交答案（在Service层，使用从库） ==========
        Map<String, Object> result = attemptService.submitAnswerWithoutMemberCheck(request);
        if (result.containsKey("error")) {
            return AjaxResult.error(result.get("error").toString()).put("data", result);
        }
        return success(result);
    }

    /**
     * 查询答题记录列表
     * 管理端：可查看所有用户记录（支持按用户名筛选，需要关联用户表）
     * 用户端：仅显示当前登录用户记录
     * 
     * 注意：管理端页面访问此接口时，应该始终查询所有用户（不限制userId）
     * 判断方式：如果query中有userName字段（即使为空字符串），说明是管理端查询
     * 或者：通过请求头/参数判断是否为管理端请求
     */
    @DataSource(DataSourceType.SLAVE)
    @RequestMapping("/list")
    public TableDataInfo list(TrainAnswerAttempt query, @org.springframework.web.bind.annotation.RequestParam(required = false) Boolean isAdmin) {
        // 管理端判断：
        // 1. 如果请求参数中有isAdmin=true，明确标识为管理端查询
        // 2. 或者传了userName字段（即使是空字符串），说明是管理端查询
        // 3. 或者传了isCorrect参数（管理端特有的筛选条件），也是管理端查询
        // 4. 或者传了params参数（时间范围筛选），也可能是管理端查询
        // 用户端通常只查询自己的记录，不会传这些筛选条件
        boolean isAdminQuery = Boolean.TRUE.equals(isAdmin) ||  // 明确的isAdmin参数
                               (query.getUserName() != null) ||  // userName字段存在
                               (query.getIsCorrect() != null) || // isCorrect参数存在
                               (query.getParams() != null && !query.getParams().isEmpty()); // params参数存在且不为空

        if (!isAdminQuery) {
            // 用户端：强制设置为当前登录用户的ID
            Long userId = getUserId();
            query.setUserId(userId);
        } else {
            // 【修复】管理端：添加集团过滤
            com.ruoyi.common.core.domain.entity.SysUser currentUser = getLoginUser().getUser();
            String currentTenantId = currentUser.getTenantId();
            Integer adminLevel = currentUser.getAdminLevel();
            boolean isPlatformAdmin = (adminLevel != null && adminLevel <= 5);

            logger.info("📊 查询用户答题记录 - tenantId: {}, adminLevel: {}, isPlatformAdmin: {}, userName: {}",
                       currentTenantId, adminLevel, isPlatformAdmin, query.getUserName());

            // 只有非平台管理员才过滤集团
            if (!isPlatformAdmin) {
                if (query.getParams() == null) {
                    query.setParams(new HashMap<>());
                }
                query.getParams().put("tenantId", currentTenantId);
            }
        }
        // 管理端：不设置userId，可查看所有用户记录，并在Service层关联用户表
        
        startPage();
        List<TrainAnswerAttempt> list = isAdminQuery 
            ? attemptService.selectAttemptListForAdmin(query)  // 管理端：关联用户表
            : attemptService.selectAttemptList(query);          // 用户端：不关联用户表
        
        return getDataTable(list);
    }

    /**
     * 排行榜（允许匿名访问）
     * 第1步：切换到从库查询答题统计
     * 第2步：切换到主库填充用户信息
     */
    @PreAuthorize("isAuthenticated()")
    @RequestMapping("/leaderboard")
    @DataSource(DataSourceType.SLAVE)  // 默认使用从库查询答题记录
    public TableDataInfo leaderboard(TrainAnswerAttempt query) {
        // 第1步：从从库查询答题统计
        List<TrainAnswerAttempt> list = attemptService.selectAttemptLeaderboard(query);
        
        // 第2步：填充用户信息（从主库）
        if (list != null && !list.isEmpty()) {
            attemptService.fillUserInfoFromMaster(list);
            
            // 第3步：过滤掉管理员用户
            list.removeIf(item -> Boolean.TRUE.equals(item.getIsAdmin()));
            list = filterLeaderboardByUserName(list, query != null ? query.getUserName() : null);
        }
        
        // 手动分页
        startPage();
        return getDataTable(list);
    }
    
    /**
     * 获取答题统计（仅限登录用户）
     * 必须查询从库 hotel_training.train_answer_attempt
     */
    @DataSource(DataSourceType.SLAVE)
    @RequestMapping("/statistics")
    public AjaxResult getStatistics() {
        // 获取当前登录用户ID（必须登录）
        Long userId = getUserId();
        
        // 从数据库获取真实统计数据
        Map<String, Object> stats = attemptService.getUserStatistics(userId);
        
        // 如果没有数据，返回0值
        if (stats == null || stats.isEmpty()) {
            stats = new HashMap<>();
            stats.put("totalQuestions", 0);
            stats.put("correctAnswers", 0);
            stats.put("accuracyRate", 0.0);
            stats.put("totalTime", 0);
        }
        
        // 获取连续打卡天数
        int consecutiveDays = attemptService.getConsecutiveDays(userId);
        stats.put("consecutiveDays", consecutiveDays);
        
        return success(stats);
    }

    private List<TrainAnswerAttempt> filterLeaderboardByUserName(List<TrainAnswerAttempt> leaderboard, String keyword) {
        if (leaderboard == null || leaderboard.isEmpty() || keyword == null) {
            return leaderboard;
        }

        String normalizedKeyword = keyword.trim().toLowerCase();
        if (normalizedKeyword.isEmpty()) {
            return leaderboard;
        }

        return leaderboard.stream()
            .filter(item -> containsKeyword(item.getUserName(), normalizedKeyword)
                || containsKeyword(item.getNickName(), normalizedKeyword))
            .collect(java.util.stream.Collectors.toList());
    }

    private boolean containsKeyword(String source, String keyword) {
        return source != null && source.toLowerCase().contains(keyword);
    }
}
