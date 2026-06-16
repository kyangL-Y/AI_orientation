<template>
  <footer class="footer-bar">
    <div class="footer-main">
      <div class="footer-cols">
        <div class="footer-col">
          <div class="footer-title">平台功能</div>
          <router-link to="/department-training"><span class="dot"></span>岗位课程</router-link>
          <router-link to="/online"><span class="dot"></span>AI督学</router-link>
          <router-link to="/online-exam/start"><span class="dot"></span>在线测评</router-link>
          <router-link to="/learning-plans"><span class="dot"></span>学习路径</router-link>
        </div>
        <div class="footer-col">
          <div class="footer-title">学习支持</div>
          <router-link to="/answer-record"><span class="dot"></span>答题记录</router-link>
          <router-link to="/wrong-book"><span class="dot"></span>我的错题</router-link>
          <router-link to="/learning-report"><span class="dot"></span>学习报告</router-link>
          <router-link to="/member-center"><span class="dot"></span>会员中心</router-link>
        </div>
        <div class="footer-col">
          <div class="footer-title">联系我们</div>
          <div class="footer-contact">
            <i class="fa fa-envelope"></i> support@boer-hotel.com
          </div>
          <div class="footer-contact">
            <i class="fa fa-phone"></i> 400-123-4567
          </div>
          <div class="footer-contact">
            <i class="fa fa-clock-o"></i> 服务时间：9:00-18:00（工作日）
          </div>
        </div>
        <div class="footer-col">
          <div class="footer-title">关于华智酒店</div>
          <router-link to="/hotel"><span class="dot"></span>平台介绍</router-link>
          <router-link to="/corporate-culture"><span class="dot"></span>企业文化</router-link>
          <router-link to="/knowledge"><span class="dot"></span>知识广场</router-link>
        </div>
      </div>
    </div>
    <div class="footer-bottom">
      <div class="footer-bottom-main">
        <span>© 2025 华智酒店及度假村员工培训平台 All Rights Reserved.</span>
        <span class="icp">粤ICP备2025000000号</span>
        <span>企业培训资质备案 1234567890</span>
      </div>
    </div>
  </footer>
</template>

<script>
export default {
  name: 'FooterBar'
}
</script>

<style scoped>
.footer-bar {
  width: 100vw;
  height: 100%;
  background: #f8fafc;
  border-top: 1px solid #e6e6e6;
  color: #666;
  font-size: 1rem;
  margin-top: 48px;
  
}
.footer-main {
  max-width: 1480px;
  margin: 0 auto;
  padding: 40px 24px 0 24px;
  border-radius: 18px 18px 0 0;
  background: #fff;
  /* box-shadow: 0 rgba(37,99,235,0.04); */
}
.footer-cols {
  display: flex;
  gap: 48px;
  justify-content: space-between;
  flex-wrap: wrap;
  margin-bottom: 18px;
}
.footer-col {
  min-width: 180px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.footer-title {
  font-weight: 800;
  color: #22223b;
  margin-bottom: 8px;
  font-size: 1.13rem;
  letter-spacing: 1px;
}
.footer-col a {
  color: #666;
  text-decoration: none;
  font-weight: 500;
  transition: color 0.2s, background 0.2s;
  border-radius: 6px;
  padding: 2px 0 2px 0;
  display: flex;
  align-items: center;
  gap: 6px;
}
.footer-col a:hover {
  color: #fff;
  background: #19c2c6;
}
.dot {
  display: inline-block;
  width: 6px;
  height: 6px;
  background: #19c2c6;
  border-radius: 50%;
  margin-right: 2px;
}
.footer-col span,
.footer-contact {
  color: #888;
  font-size: 0.98rem;
  display: flex;
  align-items: center;
  gap: 6px;
}
.footer-contact i {
  color: #19c2c6;
  font-size: 1.08rem;
}
.footer-bottom {
  background: #f4f8fb;
  border-top: 1px solid #e6e6e6;
  margin-top: 0;
  padding: 18px 0 10px 0;
}
.footer-bottom-main {
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  flex-wrap: wrap;
  gap: 18px;
  align-items: center;
  justify-content: center;
  color: #888;
  font-size: 0.98rem;
}
.icp {
  color: #aaa;
}
@media (max-width: 900px) {
  .footer-cols {
    flex-direction: column;
    gap: 18px;
  }
  .footer-main {
    padding: 24px 8px 0 8px;
  }
}
</style> 