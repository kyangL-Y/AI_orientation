package com.ruoyi.web.controller.common;

import com.ruoyi.common.annotation.Anonymous;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.redis.RedisCache;
import com.ruoyi.common.utils.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.web.bind.annotation.*;

import javax.mail.MessagingException;
import javax.mail.internet.MimeMessage;
import java.util.Random;
import java.util.concurrent.TimeUnit;

/**
 * 邮箱验证码控制器
 */
@RestController
@RequestMapping("/auth")
public class EmailController extends BaseController {

    @Autowired
    private JavaMailSender mailSender;
    
    @Autowired
    private RedisCache redisCache;

    @Value("${email.from:your-email@qq.com}")
    private String emailFrom;

    /**
     * 发送邮箱验证码
     */
    @PostMapping("/sendEmailCode")
    @Anonymous  // 允许匿名访问
    public AjaxResult sendEmailCode(@RequestBody EmailRequest request) {
        try {
            String email = normalizeEmail(request.getEmail());
            logger.info("收到发送邮箱验证码请求，邮箱：{}", maskEmail(email));
            
            if (StringUtils.isEmpty(email)) {
                return error("邮箱地址不能为空");
            }
            
            // 验证邮箱格式
            if (!email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) {
                return error("邮箱格式不正确");
            }
            
            // 防刷：60秒内仅允许请求一次
            String rateLimitKey = "email_rate_limit_" + email;
            String rateLimitFlag = redisCache.getCacheObject(rateLimitKey);
            if (rateLimitFlag != null) {
                logger.warn("邮箱验证码发送过于频繁，邮箱：{}", maskEmail(email));
                return error("验证码已发送，请稍后再试");
            }

            // 生成6位随机验证码
            String code = generateVerificationCode();
            String cacheKey = "email_code_" + email;
            
            // 将验证码存储到Redis中，设置5分钟过期
            redisCache.setCacheObject(cacheKey, code, 5, TimeUnit.MINUTES);
            redisCache.setCacheObject(rateLimitKey, "1", 60, TimeUnit.SECONDS);
            
            // 发送真实邮件
            try {
                sendEmail(email, code);
                logger.info("邮箱验证码发送成功，邮箱：{}", maskEmail(email));
            } catch (Exception e) {
                logger.error("邮件发送失败，邮箱：{}", maskEmail(email), e);
                // 邮件发送失败时，清除Redis中的验证码
                redisCache.deleteObject(cacheKey);
                redisCache.deleteObject(rateLimitKey);
                return error("邮件发送失败，请稍后重试");
            }
            
            return success("验证码已发送到您的邮箱，请查收");
            
        } catch (Exception e) {
            logger.error("发送邮箱验证码失败，邮箱：{}", maskEmail(request.getEmail()), e);
            return error("发送失败，请稍后重试");
        }
    }

    /**
     * 生成6位随机验证码
     */
    private String generateVerificationCode() {
        Random random = new Random();
        return String.format("%06d", random.nextInt(1000000));
    }

    /**
     * 发送HTML格式邮件
     * @param to 收件人邮箱
     * @param code 验证码
     */
    private void sendEmail(String to, String code) throws MessagingException {
        // 创建MimeMessage对象
        MimeMessage mimeMessage = mailSender.createMimeMessage();
        // 使用MimeMessageHelper辅助类，支持HTML格式
        MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, true, "UTF-8");
        
        // 设置邮件主题
        helper.setSubject("【华智酒店培训中心】验证码");
        
        // 设置收件人
        helper.setTo(to);
        
        // 设置发件人（必须与配置文件中的邮箱一致）
        helper.setFrom(emailFrom);
        
        // 设置HTML格式的邮件内容
        String htmlContent = buildEmailContent(code);
        helper.setText(htmlContent, true);
        
        // 发送邮件
        mailSender.send(mimeMessage);
        logger.info("HTML邮件发送成功，收件人：" + to);
    }
    
    /**
     * 构建HTML格式的邮件内容
     * @param code 验证码
     * @return HTML内容
     */
    private String buildEmailContent(String code) {
        return "<!DOCTYPE html>" +
                "<html>" +
                "<head>" +
                "<meta charset='UTF-8'>" +
                "<style>" +
                "body { font-family: Arial, 'Microsoft YaHei', sans-serif; background-color: #f5f5f5; margin: 0; padding: 20px; }" +
                ".container { max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }" +
                ".header { background: linear-gradient(90deg, #42c8a5, #38a3d1); padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }" +
                ".header h1 { color: #ffffff; margin: 0; font-size: 24px; }" +
                ".content { padding: 40px 30px; }" +
                ".code-box { background-color: #f8f9fa; border: 2px dashed #42c8a5; border-radius: 8px; padding: 20px; text-align: center; margin: 30px 0; }" +
                ".code { font-size: 32px; font-weight: bold; color: #42c8a5; letter-spacing: 8px; font-family: 'Courier New', monospace; }" +
                ".tip { color: #666666; font-size: 14px; line-height: 1.6; margin-top: 20px; }" +
                ".warning { color: #ff4d4f; font-size: 12px; margin-top: 15px; padding: 10px; background-color: #fff1f0; border-left: 3px solid #ff4d4f; border-radius: 4px; }" +
                ".footer { padding: 20px; text-align: center; color: #999999; font-size: 12px; border-top: 1px solid #e8e8e8; }" +
                "</style>" +
                "</head>" +
                "<body>" +
                "<div class='container'>" +
                "<div class='header'>" +
                "<h1>华智酒店培训中心</h1>" +
                "</div>" +
                "<div class='content'>" +
                "<p style='font-size: 16px; color: #333333; margin-bottom: 20px;'>尊敬的用户，您好！</p>" +
                "<p style='font-size: 14px; color: #666666;'>您正在注册/登录华智酒店培训中心账号，验证码如下：</p>" +
                "<div class='code-box'>" +
                "<div class='code'>" + code + "</div>" +
                "</div>" +
                "<div class='tip'>" +
                "<p><strong>验证码有效期：</strong>5分钟</p>" +
                "<p><strong>使用说明：</strong>请在注册页面输入上述验证码完成验证</p>" +
                "</div>" +
                "<div class='warning'>" +
                "<strong>安全提示：</strong>如非本人操作，请勿泄露验证码，并忽略此邮件。" +
                "</div>" +
                "</div>" +
                "<div class='footer'>" +
                "<p>此邮件由系统自动发送，请勿回复。</p>" +
                "<p>© 2025 华智酒店培训中心 All Rights Reserved.</p>" +
                "</div>" +
                "</div>" +
                "</body>" +
                "</html>";
    }

    private String maskEmail(String email)
    {
        try
        {
            if (StringUtils.isEmpty(email))
            {
                return "";
            }
            int atIndex = email.indexOf('@');
            if (atIndex <= 1)
            {
                return "***" + email.substring(Math.max(0, atIndex));
            }
            String prefix = email.substring(0, Math.min(2, atIndex));
            String domain = email.substring(atIndex);
            return prefix + "***" + domain;
        }
        catch (Exception ignored)
        {
            return "***";
        }
    }

    /**
     * 邮箱请求对象
     */
    public static class EmailRequest {
        private String email;

        public String getEmail() {
            return email;
        }

        public void setEmail(String email) {
            this.email = email;
        }
    }

    private String normalizeEmail(String email) {
        return StringUtils.isEmpty(email) ? "" : StringUtils.trim(email).toLowerCase();
    }
}
