# 邮箱配置说明

## 环境变量配置

请在项目根目录创建 `.env` 文件，并配置以下环境变量：

```bash
# QQ邮箱SMTP配置
EMAIL_SMTP_HOST=smtp.qq.com
EMAIL_SMTP_PORT=465
EMAIL_USERNAME=your-email@qq.com
EMAIL_PASSWORD=your-authorization-code
EMAIL_FROM=your-email@qq.com
```

## 配置说明

- `EMAIL_SMTP_HOST`: QQ邮箱SMTP服务器地址
- `EMAIL_SMTP_PORT`: 端口号，使用465（SSL）或587（STARTTLS）
- `EMAIL_USERNAME`: 您的QQ邮箱地址
- `EMAIL_PASSWORD`: QQ邮箱授权码（不是登录密码）
- `EMAIL_FROM`: 发件人邮箱地址

## 获取QQ邮箱授权码

1. 登录QQ邮箱
2. 点击"设置" -> "账户"
3. 找到"POP3/IMAP/SMTP/Exchange/CardDAV/CalDAV服务"
4. 开启"POP3/SMTP服务"
5. 点击"生成授权码"
6. 将生成的授权码填入 `EMAIL_PASSWORD`

## 启动项目

配置完成后，重启RuoYi后端服务即可使用邮箱验证码功能。
