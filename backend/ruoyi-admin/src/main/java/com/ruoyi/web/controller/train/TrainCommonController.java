package com.ruoyi.web.controller.train;

import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysDept;
import com.ruoyi.common.core.domain.model.LoginUser;
import com.ruoyi.common.annotation.DataSource;
import com.ruoyi.common.annotation.Anonymous;
import com.ruoyi.common.enums.DataSourceType;
import com.ruoyi.system.service.ISysDeptService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 培训模块通用API控制器
 * 提供酒店和部门列表等通用接口
 */
@RestController
@RequestMapping("/train/common")
public class TrainCommonController extends BaseController {

    private static final Logger logger = LoggerFactory.getLogger(TrainCommonController.class);

    @Autowired
    private ISysDeptService deptService;

    /**
     * 测试接口
     */
    @GetMapping("/test")
    public AjaxResult test() {
        return success("API is working");
    }

    /**
     * 获取集团列表（根据当前用户租户过滤）
     */
    @GetMapping("/companies")
    @DataSource(DataSourceType.MASTER)
    public AjaxResult getCompanyList() {
        try {
            logger.info("🔍 开始查询集团列表");
            
            // 获取当前登录用户信息
            LoginUser loginUser = getLoginUser();
            String currentTenantId = null;
            boolean isSuperAdmin = false;
            
            if (loginUser != null && loginUser.getUser() != null) {
                currentTenantId = loginUser.getUser().getTenantId();
                isSuperAdmin = loginUser.getUserId() == 1L; // 超级管理员
                logger.info("🔍 当前用户: userId={}, tenantId={}, isSuperAdmin={}", 
                    loginUser.getUserId(), currentTenantId, isSuperAdmin);
            }
            
            // 查询部门（会自动根据租户过滤）
            List<SysDept> allDepts = deptService.selectDeptList(new SysDept());
            List<Map<String, Object>> companies = new ArrayList<>();
            
            // 查找 parent_id = 0 的部门作为集团
            for (SysDept dept : allDepts) {
                if (dept.getParentId() != null && dept.getParentId().equals(0L)) {
                    Map<String, Object> company = new HashMap<>();
                    company.put("value", dept.getDeptId());
                    company.put("label", dept.getDeptName());
                    company.put("type", "集团");
                    companies.add(company);
                    logger.info("✅ 找到集团: deptId={}, deptName={}", dept.getDeptId(), dept.getDeptName());
                }
            }
            
            logger.info("📊 集团列表查询结果：共 {} 个集团", companies.size());
            return success(companies);
        } catch (Exception e) {
            logger.error("❌ 获取集团列表失败", e);
            return success(new ArrayList<>());
        }
    }

    /**
     * 获取公司列表（从部门表中获取，parent_id = 100 的部门作为公司）
     * 如果能够识别当前登录用户所在的公司，只返回用户公司；否则返回所有公司
     * @param allCompanies 如果为true，强制返回所有公司（忽略用户公司过滤）
     */
    @GetMapping("/hotels")
    @DataSource(DataSourceType.MASTER)
    public AjaxResult getHotelList(@RequestParam(required = false, defaultValue = "true") Boolean allCompanies) {
        try {
            logger.info("🔍 开始查询酒店列表，数据源：MASTER (hz-vue数据库)");
            // 查询所有部门
            List<SysDept> allDepts = deptService.selectDeptList(new SysDept());
            logger.info("📊 从数据库查询到 {} 个部门", allDepts.size());
            
            // 打印所有部门的parent_id，帮助调试
            logger.info("📋 所有部门的parent_id分布：");
            for (SysDept dept : allDepts) {
                if (dept.getParentId() != null && dept.getParentId().equals(100L)) {
                    logger.info("  ✅ 找到公司：deptId={}, deptName={}, parentId={}", 
                        dept.getDeptId(), dept.getDeptName(), dept.getParentId());
                }
            }
            
            List<Map<String, Object>> hotels = new ArrayList<>();
            
            // 尝试获取当前登录用户的部门信息
            Long userDeptId = null;
            Long userCompanyId = null;
            try {
                // 先获取登录用户信息
                LoginUser loginUser = getLoginUser();
                if (loginUser == null) {
                    logger.warn("⚠️ 无法获取登录用户信息，getLoginUser() 返回 null");
                } else {
                    logger.info("🔍 当前登录用户: userId={}, username={}", loginUser.getUserId(), loginUser.getUsername());
                    // 使用 SecurityUtils 获取当前用户信息
                    userDeptId = getDeptId(); // 获取当前用户部门ID
                    logger.info("🔍 当前登录用户的部门ID: {}", userDeptId);
                }
                
                if (userDeptId != null) {
                    // 向上查找用户所在的公司（parent_id = 100）
                    SysDept userDept = deptService.selectDeptById(userDeptId);
                    logger.info("🔍 用户部门信息: deptId={}, deptName={}, parentId={}", 
                        userDept != null ? userDept.getDeptId() : null,
                        userDept != null ? userDept.getDeptName() : null,
                        userDept != null ? userDept.getParentId() : null);
                    
                    if (userDept != null) {
                        // 如果用户部门本身的parent_id就是100，说明用户部门就是公司
                        if (userDept.getParentId() != null && userDept.getParentId().equals(100L)) {
                            userCompanyId = userDept.getDeptId();
                            logger.info("✅ 用户部门本身就是公司，公司ID: {}", userCompanyId);
                        } else {
                            // 否则向上遍历查找parent_id = 100的公司
                            Long currentDeptId = userDept.getDeptId();
                            Long currentParentId = userDept.getParentId();
                            int maxLevels = 10; // 防止无限循环
                            int level = 0;
                            
                            logger.info("🔍 开始向上查找公司，起始部门ID: {}, 父部门ID: {}", currentDeptId, currentParentId);
                            
                            while (currentParentId != null && 
                                   !currentParentId.equals(100L) && 
                                   !currentParentId.equals(0L) && 
                                   level < maxLevels) {
                                SysDept parentDept = deptService.selectDeptById(currentParentId);
                                if (parentDept == null) {
                                    logger.warn("⚠️ 找不到父部门，parentId: {}", currentParentId);
                                    break;
                                }
                                logger.info("🔍 第{}层：部门ID={}, 部门名称={}, 父部门ID={}", 
                                    level + 1, parentDept.getDeptId(), parentDept.getDeptName(), parentDept.getParentId());
                                currentDeptId = parentDept.getDeptId();
                                currentParentId = parentDept.getParentId();
                                level++;
                            }
                            
                            if (currentParentId != null && currentParentId.equals(100L)) {
                                userCompanyId = currentDeptId;
                                logger.info("✅ 找到用户公司，公司ID: {}", userCompanyId);
                            } else {
                                logger.warn("⚠️ 未找到公司（parent_id=100），最终部门ID: {}, 最终父部门ID: {}", 
                                    currentDeptId, currentParentId);
                            }
                        }
                        
                        logger.info("📊 最终结果 - 用户部门ID: {}, 识别到的公司ID: {}", userDeptId, userCompanyId);
                    } else {
                        logger.warn("⚠️ 无法获取用户部门信息，userDeptId: {}", userDeptId);
                    }
                } else {
                    logger.warn("⚠️ 当前用户没有部门ID，将返回所有公司列表");
                }
            } catch (Exception e) {
                logger.error("❌ 获取当前用户部门信息失败，将返回所有公司列表", e);
            }
            
            // 查找 parent_id = 100 的部门作为公司
            logger.info("🔍 开始查找公司列表，allCompanies={}, userCompanyId={}", allCompanies, userCompanyId);
            int allCompanyCount = 0;
            for (SysDept dept : allDepts) {
                if (dept.getParentId() != null && dept.getParentId().equals(100L)) {
                    allCompanyCount++;
                    logger.info("🔍 找到公司：deptId={}, deptName={}, parentId={}", 
                        dept.getDeptId(), dept.getDeptName(), dept.getParentId());
                    
                    // 如果已识别用户公司且未强制显示所有公司，只返回用户公司；否则返回所有公司
                    if (!allCompanies && userCompanyId != null) {
                        if (!userCompanyId.equals(dept.getDeptId())) {
                            logger.info("⏭️ 跳过非用户公司：deptId={}, deptName={}", dept.getDeptId(), dept.getDeptName());
                            continue; // 跳过非用户公司
                        } else {
                            logger.info("✅ 匹配到用户公司：deptId={}, deptName={}", dept.getDeptId(), dept.getDeptName());
                        }
                    }
                    
                    Map<String, Object> hotel = new HashMap<>();
                    hotel.put("value", dept.getDeptId());
                    hotel.put("label", dept.getDeptName());
                    hotel.put("parentId", dept.getParentId());
                    hotels.add(hotel);
                }
            }
            logger.info("📊 公司统计：数据库中总共有 {} 个公司，最终返回 {} 个公司", allCompanyCount, hotels.size());
            
            // 如果识别到用户公司但没有找到匹配的公司，说明用户部门层级可能有问题
            if (userCompanyId != null && hotels.isEmpty()) {
                logger.warn("⚠️ 识别到用户公司ID {} 但未找到匹配的公司，尝试直接查询该公司", userCompanyId);
                // 尝试直接查询用户公司
                SysDept userCompany = deptService.selectDeptById(userCompanyId);
                if (userCompany != null && userCompany.getParentId() != null && userCompany.getParentId().equals(100L)) {
                    Map<String, Object> hotel = new HashMap<>();
                    hotel.put("value", userCompany.getDeptId());
                    hotel.put("label", userCompany.getDeptName());
                    hotel.put("parentId", userCompany.getParentId());
                    hotels.add(hotel);
                    logger.info("✅ 直接查询到用户公司: {}", userCompany.getDeptName());
                } else {
                    logger.warn("⚠️ 用户公司ID {} 不存在或不是公司级别，返回所有公司列表", userCompanyId);
                    // 重新构建所有公司列表
                    hotels.clear();
                    for (SysDept dept : allDepts) {
                        if (dept.getParentId() != null && dept.getParentId().equals(100L)) {
                            Map<String, Object> hotel = new HashMap<>();
                            hotel.put("value", dept.getDeptId());
                            hotel.put("label", dept.getDeptName());
                            hotel.put("parentId", dept.getParentId());
                            hotels.add(hotel);
                        }
                    }
                }
            }
            
            // 如果没有识别到用户公司，且没有找到任何公司数据，返回所有公司（而不是默认数据）
            if (hotels.isEmpty() && userCompanyId == null) {
                logger.warn("⚠️ 未识别到用户公司且公司列表为空，返回所有公司列表");
                for (SysDept dept : allDepts) {
                    if (dept.getParentId() != null && dept.getParentId().equals(100L)) {
                        Map<String, Object> hotel = new HashMap<>();
                        hotel.put("value", dept.getDeptId());
                        hotel.put("label", dept.getDeptName());
                        hotel.put("parentId", dept.getParentId());
                        hotels.add(hotel);
                    }
                }
            }
            
            // 如果仍然为空，说明数据库中没有公司数据（parent_id=100的部门）
            if (hotels.isEmpty()) {
                logger.error("❌ 数据库中没有任何公司数据（parent_id=100的部门），请检查数据库！");
            }
            
            return success(hotels);
        } catch (Exception e) {
            logger.error("❌ 获取酒店列表失败", e);
            // 异常时返回空列表，让前端处理
            return success(new ArrayList<>());
        }
    }

    /**
     * 获取部门列表（根据当前用户租户过滤，只获取真正的业务部门）
     */
    @GetMapping("/depts")
    @DataSource(DataSourceType.MASTER)
    public AjaxResult getDeptList() {
        try {
            logger.info("🔍 开始查询部门列表");
            
            // 获取当前登录用户信息
            LoginUser loginUser = getLoginUser();
            if (loginUser != null && loginUser.getUser() != null) {
                logger.info("🔍 当前用户: userId={}, tenantId={}", 
                    loginUser.getUserId(), loginUser.getUser().getTenantId());
            }
            
            // 查询部门（会自动根据租户过滤）
            List<SysDept> allDepts = deptService.selectDeptList(new SysDept());
            List<Map<String, Object>> depts = new ArrayList<>();
            
            // 只获取真正的业务部门（排除集团和公司级别的部门）
            for (SysDept dept : allDepts) {
                // 排除集团级别（parent_id = 0）和公司级别（parent_id = 100）的部门
                if (dept.getParentId() != null && 
                    !dept.getParentId().equals(0L) && 
                    !dept.getParentId().equals(100L)) {
                    
                    Map<String, Object> deptMap = new HashMap<>();
                    deptMap.put("value", dept.getDeptId());
                    deptMap.put("label", dept.getDeptName());
                    deptMap.put("parentId", dept.getParentId());
                    depts.add(deptMap);
                    logger.info("✅ 找到部门: deptId={}, deptName={}, parentId={}", 
                        dept.getDeptId(), dept.getDeptName(), dept.getParentId());
                }
            }
            
            logger.info("📊 部门列表查询结果：总共查询到 {} 个业务部门", depts.size());
            return success(depts);
        } catch (Exception e) {
            logger.error("❌ 获取部门列表失败", e);
            return success(new ArrayList<>());
        }
    }
}