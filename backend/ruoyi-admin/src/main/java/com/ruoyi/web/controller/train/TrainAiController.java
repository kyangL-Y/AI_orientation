package com.ruoyi.web.controller.train;

import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.train.service.ITrainAiService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;
import java.util.Map;

/**
 * AI对话Controller (稳定版本)
 *
 * @author ruoyi
 * @date 2025-10-28
 */
@RestController
@RequestMapping("/train/ai")
public class TrainAiController {
    @Autowired
    private ITrainAiService trainAiService;

    /**
     * 发送消息到AI
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping("/sendMessage")
    public AjaxResult sendMessage(@RequestBody Map<String, String> request) {
        try {
            String message = request.get("message");
            String sessionId = request.get("sessionId");

            if (message == null || message.trim().isEmpty()) {
                return AjaxResult.error("消息内容不能为空");
            }

            // 获取当前登录用户ID
            Long userId = SecurityUtils.getUserId();

            String response = trainAiService.chatWithAi(userId, sessionId, message);
            return AjaxResult.success(response);
        } catch (Exception e) {
            return AjaxResult.error("AI服务暂时不可用");
        }
    }

    /**
     * 发送消息到AI（SSE 流式 + Function Calling）
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping(value = "/chat/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter chatStream(@RequestBody Map<String, String> request) {
        SseEmitter emitter = new SseEmitter(180000L); // 3分钟超时

        String message = request.get("message");
        if (message == null || message.trim().isEmpty()) {
            try {
                emitter.send(SseEmitter.event().name("error").data("消息内容不能为空"));
                emitter.complete();
            } catch (Exception ignored) {}
            return emitter;
        }

        String sessionId = request.get("sessionId");
        Long userId = SecurityUtils.getUserId();
        trainAiService.chatWithAiStream(userId, sessionId, message.trim(), emitter);
        return emitter;
    }

    /**
     * 清除指定会话的对话历史
     */
    @PreAuthorize("isAuthenticated()")
    @DeleteMapping("/clearHistory/{sessionId}")
    public AjaxResult clearHistory(@PathVariable String sessionId) {
        try {
            // 获取当前登录用户ID
            Long userId = SecurityUtils.getUserId();

            boolean success = trainAiService.clearChatHistory(userId, sessionId);
            if (success) {
                return AjaxResult.success("对话历史已清除");
            } else {
                return AjaxResult.error("清除对话历史失败");
            }
        } catch (Exception e) {
            return AjaxResult.error("清除对话历史失败");
        }
    }

    /**
     * 获取指定会话的对话历史
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/history/{sessionId}")
    public AjaxResult getChatHistory(@PathVariable String sessionId,
                                     @RequestParam(defaultValue = "100") int limit) {
        try {
            // 获取当前登录用户ID
            Long userId = SecurityUtils.getUserId();

            List<Map<String, Object>> history = trainAiService.getChatHistoryForUser(userId, sessionId, limit);
            return AjaxResult.success(history);
        } catch (Exception e) {
            return AjaxResult.error("获取对话历史失败");
        }
    }

    /**
     * 获取用户的所有会话列表
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/sessions")
    public AjaxResult getSessionList() {
        try {
            // 获取当前登录用户ID
            Long userId = SecurityUtils.getUserId();

            List<Map<String, Object>> sessions = trainAiService.getSessionList(userId);
            return AjaxResult.success(sessions);
        } catch (Exception e) {
            return AjaxResult.error("获取会话列表失败");
        }
    }

    /**
     * AI分析考试结果
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping("/analyzeExam")
    public AjaxResult analyzeExamResult(@RequestBody Map<String, Object> request) {
        try {
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> examDetails = (List<Map<String, Object>>) request.get("examDetails");
            int score = request.get("score") != null ? ((Number) request.get("score")).intValue() : 0;
            int correctCount = request.get("correctCount") != null ? ((Number) request.get("correctCount")).intValue() : 0;
            int totalCount = request.get("totalCount") != null ? ((Number) request.get("totalCount")).intValue() : 0;
            String resultDisplayMode = request.get("resultDisplayMode") != null ? String.valueOf(request.get("resultDisplayMode")) : "score";
            int levelPassScore = parseInteger(request.get("levelPassScore"), 60);
            int levelExcellentScore = parseInteger(request.get("levelExcellentScore"), 85);

            if (examDetails == null || examDetails.isEmpty()) {
                return AjaxResult.error("考试详情不能为空");
            }

            Map<String, Object> analysisResult = trainAiService.analyzeExamResult(
                examDetails,
                score,
                correctCount,
                totalCount,
                resultDisplayMode,
                levelPassScore,
                levelExcellentScore
            );
            return AjaxResult.success(analysisResult);
        } catch (Exception e) {
            return AjaxResult.error("AI分析失败");
        }
    }

    private int parseInteger(Object value, int defaultValue) {
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }
        if (value != null) {
            try {
                return Integer.parseInt(String.valueOf(value));
            } catch (Exception ignored) {
            }
        }
        return defaultValue;
    }
}
