package com.ruoyi.web.controller.system;

import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.redis.RedisCache;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

/**
 * Redis连接测试Controller
 * 用于诊断Token认证问题
 */
@RestController
@RequestMapping("/system/redis")
public class RedisTestController extends BaseController {

    @Autowired
    private RedisCache redisCache;

    /**
     * 测试Redis连接
     */
    @PreAuthorize("@ss.hasRole('admin')")
    @GetMapping("/test")
    public AjaxResult testConnection() {
        Map<String, Object> result = new HashMap<>();
        
        try {
            // 测试写入
            String testKey = "test:connection:" + System.currentTimeMillis();
            redisCache.setCacheObject(testKey, "test_value");
            
            // 测试读取
            String value = redisCache.getCacheObject(testKey);
            
            // 清理测试数据
            redisCache.deleteObject(testKey);
            
            result.put("status", "success");
            result.put("message", "Redis连接正常");
            result.put("testValue", value);
            
            return AjaxResult.success(result);
        } catch (Exception e) {
            result.put("status", "error");
            result.put("message", "Redis连接失败: " + e.getMessage());
            return AjaxResult.error("Redis连接失败", result);
        }
    }

    /**
     * 查询登录Token数量
     */
    @PreAuthorize("@ss.hasRole('admin')")
    @GetMapping("/tokens/count")
    public AjaxResult getTokenCount() {
        try {
            Collection<String> keys = redisCache.keys("login_tokens:*");
            Map<String, Object> result = new HashMap<>();
            result.put("count", keys != null ? keys.size() : 0);
            result.put("message", "查询成功");
            return AjaxResult.success(result);
        } catch (Exception e) {
            return AjaxResult.error("查询失败: " + e.getMessage());
        }
    }
}
