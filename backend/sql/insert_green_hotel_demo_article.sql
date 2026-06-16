-- 绿色饭店示例文章（幂等）
-- 用途：为智囊阁补充一篇可被“绿色饭店培训页”稳定命中的示例内容

SET NAMES utf8mb4;

INSERT INTO `train_knowledge_article`
(`title`, `content`, `cover_image`, `author_id`, `author_name`, `dept_id`, `dept_name`, `tenant_id`, `publish_scope`, `status`,
 `view_count`, `like_count`, `favorite_count`, `comment_count`, `is_top`, `top_time`, `create_time`, `update_time`, `del_flag`)
SELECT
  '绿色饭店客房低碳实操：布草减量与低温洗涤7天落地方案',
  '<h3>一、适用场景</h3><p>本方案适用于酒店客房部，目标是在不降低住客满意度的前提下，实现节能、减排和耗材优化，满足绿色饭店运营要求。</p><h3>二、量化目标（7天）</h3><ul><li>客房布草更换量下降10%-15%</li><li>洗涤能耗下降8%-12%</li><li>一次性洗护用品使用量下降15%</li></ul><h3>三、执行步骤</h3><ol><li>前台入住提示“连住免换床品”绿色选项。</li><li>客房布草分级回收，区分重污与轻污。</li><li>洗涤房常规布草执行低温洗涤程序。</li><li>按入住人数精细投放一次性用品。</li><li>每日复盘房晚数、换洗件数与能耗数据。</li></ol><h3>四、岗位检查清单</h3><p>前台、客房、洗涤、主管四岗联动，形成闭环。</p><h3>五、预期结果</h3><p>通过流程改造与岗位协同，一周内形成稳定低碳运营动作，为绿色饭店评定提供可追踪数据支撑。</p>',
  NULL, 1, '平台运营中心', NULL, '培训中心', '000000', 'platform', 'published',
  0, 0, 0, 0, 0, NULL, NOW(), NOW(), '0'
WHERE NOT EXISTS (
  SELECT 1
  FROM train_knowledge_article
  WHERE title = '绿色饭店客房低碳实操：布草减量与低温洗涤7天落地方案'
    AND del_flag = '0'
);

SELECT article_id, title, status, publish_scope, create_time
FROM train_knowledge_article
WHERE title = '绿色饭店客房低碳实操：布草减量与低温洗涤7天落地方案'
  AND del_flag = '0'
ORDER BY article_id DESC
LIMIT 1;
