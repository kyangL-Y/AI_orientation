package com.ruoyi.web.controller.common;

import com.ruoyi.common.annotation.Anonymous;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.redis.RedisCache;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.common.utils.SMSUtils;
import com.ruoyi.common.utils.ValidateCodeUtils;
import com.ruoyi.common.utils.ip.IpUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.concurrent.TimeUnit;
import java.util.HashMap;
import java.util.Map;

/**
 * 手机验证码控制器
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/auth")
public class SmsController extends BaseController
{
    @Autowired
    private RedisCache redisCache;

    /**
     * 发送手机验证码
     */
    @PostMapping("/sendSmsCode")
    @Anonymous // 允许匿名访问
    public AjaxResult sendSmsCode(@RequestBody SmsRequest request)
    {
        try
        {
            String phone = normalizePhone(request.getPhone());
            logger.info("收到发送手机验证码请求，手机号：{}", maskPhone(phone));

            if (StringUtils.isEmpty(phone))
            {
                return error("手机号码不能为空");
            }

            // 验证手机号格式（11位数字，1开头）
            if (!phone.matches("^1[3-9]\\d{9}$"))
            {
                return error("手机号码格式不正确");
            }

            // 检查是否在1分钟内已经发送过验证码（防止频繁请求）
            String rateLimitKey = "sms_rate_limit_" + phone;
            String rateLimitFlag = redisCache.getCacheObject(rateLimitKey);
            if (rateLimitFlag != null)
            {
                logger.warn("手机验证码发送过于频繁，手机号：{}", maskPhone(phone));
                return error("验证码已发送，请60秒后再试");
            }

            // 生成4位随机验证码
            String code = ValidateCodeUtils.generateValidateCode(4).toString();

            // 调用腾讯云短信服务发送验证码
            boolean flag = SMSUtils.send(phone, code);
            if (flag)
            {
                // 将生成的验证码缓存到redis中，设置有效期5分钟
                String cacheKey = "sms_code_" + phone;
                redisCache.setCacheObject(cacheKey, code, 5, TimeUnit.MINUTES);
                logger.info("手机验证码已存储到Redis，手机号：{}，有效期：5分钟", maskPhone(phone));
                
                // 设置防重发标记，60秒有效期
                redisCache.setCacheObject(rateLimitKey, "1", 60, TimeUnit.SECONDS);
                logger.info("设置防重发标记，手机号：{}，有效期：60秒", maskPhone(phone));

                Map<String, Object> data = new HashMap<>();
                data.put("phone", phone);
                if (!com.ruoyi.common.utils.MsmConstantUtils.ENABLED)
                {
                    String ip = IpUtils.getIpAddr();
                    if ("127.0.0.1".equals(ip))
                    {
                        data.put("mockCode", code);
                    }
                    return success("验证码已生成（短信未启用）").put("data", data);
                }

                return success("手机验证码发送成功").put("data", data);
            }
            else
            {
                logger.error("短信发送失败，手机号：{}", maskPhone(phone));
                return error("短信发送失败，请检查手机号是否正确或稍后重试");
            }
        }
        catch (RuntimeException e)
        {
            logger.error("短信发送业务错误，手机号：{}", maskPhone(request.getPhone()), e);
            return error("发送失败，请稍后重试");
        }
        catch (Exception e)
        {
            logger.error("发送手机验证码失败，手机号：{}", maskPhone(request.getPhone()), e);
            return error("发送失败，请稍后重试");
        }
    }

    private String maskPhone(String phone)
    {
        try
        {
            if (StringUtils.isEmpty(phone) || phone.length() < 7)
            {
                return "***";
            }
            return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
        }
        catch (Exception ignored)
        {
            return "***";
        }
    }

    private String normalizePhone(String phone)
    {
        return StringUtils.isEmpty(phone) ? "" : StringUtils.trim(phone).replaceAll("\\s+", "");
    }

    /**
     * 手机验证码请求对象
     */
    public static class SmsRequest
    {
        private String phone;

        public String getPhone()
        {
            return phone;
        }

        public void setPhone(String phone)
        {
            this.phone = phone;
        }
    }
}
