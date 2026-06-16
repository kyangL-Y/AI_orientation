package com.ruoyi.web.controller.train;

import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.enums.DataSourceType;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.system.domain.dto.AnswerRequest;
import com.ruoyi.system.service.ITrainAnswerAttemptService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 答题兼容接口Controller
 * 用于兼容前端旧版API调用 /train/question/submit
 * 实际转发到 /train/attempt/submit 的逻辑
 * 
 * @author Kiro AI
 * @date 2026-02-04
 */
@RestController
@RequestMapping("/train/question")
public class TrainQuestionCompatController extends BaseController {

    private static final Logger log = LoggerFactory.getLogger(TrainQuestionCompatController.class);

    @Autowired
    private ITrainAnswerAttemptService attemptService;

    /**
     * 提交答案（兼容接口）
     * 兼容前端旧版API调用，转发到正确的答题记录服务
     * 
     * @param data 答题数据，可能包含：
     *             - questionId: 题目ID
     *             - answer: 答案
     *             - isCorrect: 是否正确（可选）
     * @return 提交结果
     */
    @DataSource(DataSourceType.SLAVE)
    @PostMapping("/submit")
    public AjaxResult submitAnswerCompat(@RequestBody Map<String, Object> data) {
        log.warn("⚠️ [兼容接口] 收到旧版答题提交请求 /train/question/submit，转发到新接口");
        log.info("📥 [兼容接口] 请求数据: {}", data);
        
        try {
            // 获取当前登录用户ID
            Long userId = getUserId();
            log.info("👤 [兼容接口] 用户ID: {}", userId);
            
            // 转换参数格式
            AnswerRequest request = new AnswerRequest();
            request.setUserId(userId);
            
            // 解析questionId
            if (data.containsKey("questionId")) {
                Object questionIdObj = data.get("questionId");
                if (questionIdObj instanceof Number) {
                    request.setQuestionId(((Number) questionIdObj).longValue());
                } else {
                    request.setQuestionId(Long.valueOf(questionIdObj.toString()));
                }
            } else {
                log.error("❌ [兼容接口] 缺少questionId参数");
                return error("缺少题目ID参数");
            }
            
            // 解析answer
            if (data.containsKey("answer")) {
                request.setAnswer(data.get("answer").toString());
            } else {
                log.error("❌ [兼容接口] 缺少answer参数");
                return error("缺少答案参数");
            }
            
            log.info("🎯 [兼容接口] 转换后的请求: questionId={}, answer={}", 
                    request.getQuestionId(), request.getAnswer());
            
            // 调用正确的答题记录服务
            Map<String, Object> result = attemptService.submitAnswer(request);
            
            log.info("✅ [兼容接口] 答题记录保存成功: {}", result);
            
            // 检查结果
            if (result.containsKey("error")) {
                log.error("❌ [兼容接口] 答题记录保存失败: {}", result.get("error"));
                return error(result.get("error").toString());
            }
            
            return success(result);
            
        } catch (Exception e) {
            log.error("❌ [兼容接口] 答题提交异常", e);
            return error("答题提交失败: " + e.getMessage());
        }
    }
}
