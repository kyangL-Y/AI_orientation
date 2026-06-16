-- 初始化默认租户(000000)和华智租户(HZ001)的企业文化配置
-- 在已存在 sys_tenant_customization 表的库中执行本脚本

SET NAMES utf8mb4;

-- 企业文化 HTML 内容（可在管理端继续编辑）
SET @corp_html = '
  <h2>服务宣言</h2>
  <p>我是华智大家庭的一员，我愿与华智共同进步、共同成长，为华智发展贡献自己的全部力量！无论何时何地，我都是华智的形象代言人，我的一言一行都关系着华智的声誉。我要通过自身的优质服务，不断地给顾客带来满意、惊喜和感动，从而成为顾客人生重要时刻的参与者和见证者！</p>
  <hr/>
  <h2>企业文化核心理念</h2>
  <p><strong>华智酒店及度假村（HUAWISE Hotels &amp; Resorts）</strong></p>
  <ul>
    <li>酒店定位：赏心悦目的地域文化，呈现在地文化，打造城市印象。</li>
    <li>酒店主张：有温度的文化企业。</li>
    <li>价值观：顾客至上、追求卓越、永葆激情、独树一帜。</li>
    <li>公司使命：成就高品质生活。</li>
    <li>公司愿景：成为受社会尊重的旅游连锁酒店业的标杆企业。</li>
    <li>道德准则：眼前利益必须服从长远利益；宁可酒店吃亏，不让顾客吃亏；个人利益必须服从集体利益；宁可自己吃亏，不让酒店吃亏。</li>
    <li>企业主张：与同道之人，成伟大之事。</li>
    <li>酒店精神：以情服务，用心做事。</li>
    <li>酒店宗旨：顾客利益第一，酒店声誉第一。</li>
    <li>企业精神：开放、包容、团结、协作、敬业、奉献、务实、创新。</li>
    <li>产品理念：匠心产品，极致服务。</li>
    <li>质量意识：追求完美，自我苛求。</li>
    <li>经营理念：稳健经营，追求永续。</li>
    <li>营销理念：为用户创造价值，为酒店赢得朋友。</li>
    <li>发展理念：共生、共享、共赢。</li>
    <li>顾客理念：顾客是我们的衣食父母，酒店是顾客的家外之家。</li>
    <li>创新理念：持续创新，宽容失败。</li>
    <li>忧患意识：永远要“战战兢兢，如履薄冰”；居安思危，居危思进；危机中育新机，变局中开新局。</li>
    <li>核心价值观（补充）：求真、求新、至善、至美。</li>
  </ul>
  <hr/>
  <h2>安全篇</h2>
  <p>安全理念：隐患险于明火，防范胜于救灾，责任重于泰山。安全是卓越管理的基础，安全问题绝不妥协。</p>
  <ul>
    <li>安全重于一切，没有安全就没有一切。</li>
    <li>任何对安全问题的忽视和疏漏，本质上都是在用企业和员工的命运进行一场赌博。</li>
    <li>安全源自于严密有效的安全规程，安全规程高于上级命令。</li>
    <li>领导违章指挥等于犯罪，员工违章操作等于自杀。</li>
    <li>安全来自长期警惕，事故源于瞬间麻痹。</li>
    <li>必须牢固树立“安全防控、人人有责”的理念。</li>
  </ul>
  <hr/>
  <h2>服务篇</h2>
  <p>服务理念：行动换取心动，超值体现价值。品质、品味、品牌。</p>
  <p>服务承诺：让我们服务得更好。服务准则：热情、礼貌、迅速、周到。</p>
  <p>发展目标：精益求精，打造卓越服务品牌。服务目标：给每一位顾客都提供令人感动的服务。</p>
  <hr/>
  <h2>管理篇</h2>
  <p>管理定位：管理零缺陷，服务零距离。管理追求：打造动车组文化，让企业每个部分自带动力。</p>
  <p>管理目标：一线满意是支持部门工作的最终结果，顾客满意是全部工作的最终大结果。</p>
  <p>管理方针：“高、严、细、实”；管理程式：“一动、两表、三环节、三关键”。</p>
  <hr/>
  <h2>作风篇</h2>
  <ul>
    <li>工作认真，一丝不苟；遵守纪律，严守机密。</li>
    <li>尊重领导，团结群众；任劳任怨，脚踏实地。</li>
    <li>快速反应，立即行动；尽职尽责，绝不推诿。</li>
    <li>日事日毕，日清日高。</li>
  </ul>
  <hr/>
  <h2>人才篇</h2>
  <p>人才理念：科技是第一生产力，人才是第一资源。以人兴企，人企共进；人人是人才，人人可替代。</p>
  <p>品德为先，唯才是举；人尽其才，才尽其用。员工培训是企业风险最小、收益最大的战略性投资。</p>
  <hr/>
  <h2>创新篇</h2>
  <p>创新理念：创新是第一动力。全员创新，人人有责。发现顾客需求是创新的源头，满足顾客需求是创新的基础，超越顾客需求是创新的目标，引导顾客需求是创新的升华。</p>
';

-- 组装 custom_pages_config JSON
SET @corp_cfg = JSON_OBJECT('corporateCultureHtml', @corp_html);

-- 默认租户（未登录用户使用）
INSERT INTO sys_tenant_customization (
  tenant_id,
  custom_pages_config,
  create_by,
  create_time,
  update_by,
  update_time
) VALUES (
  '000000',
  @corp_cfg,
  'admin',
  NOW(),
  'admin',
  NOW()
)
ON DUPLICATE KEY UPDATE
  custom_pages_config = VALUES(custom_pages_config),
  update_by = VALUES(update_by),
  update_time = VALUES(update_time);

-- 华智租户（示例租户ID：HZ001，如有不同请按实际 tenant_id 修改）
INSERT INTO sys_tenant_customization (
  tenant_id,
  custom_pages_config,
  create_by,
  create_time,
  update_by,
  update_time
) VALUES (
  'HZ001',
  @corp_cfg,
  'admin',
  NOW(),
  'admin',
  NOW()
)
ON DUPLICATE KEY UPDATE
  custom_pages_config = VALUES(custom_pages_config),
  update_by = VALUES(update_by),
  update_time = VALUES(update_time);


