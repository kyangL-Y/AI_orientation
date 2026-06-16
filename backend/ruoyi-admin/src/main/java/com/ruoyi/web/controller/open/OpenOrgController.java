package com.ruoyi.web.controller.open;

import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysDept;
import com.ruoyi.common.core.domain.entity.SysUser;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.common.utils.StringUtils;
import com.ruoyi.system.service.ISysDeptService;
import com.ruoyi.system.service.ISysPostService;
import com.ruoyi.system.domain.SysPost;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 开放只读的组织架构接口（匿名可访问）
 */
@RestController
@RequestMapping("/open/org")
public class OpenOrgController {

    @Autowired
    private ISysDeptService deptService;
    
    @Autowired
    private ISysPostService postService;

    /**
     * 获取部门树
     * @param tenantId 租户ID（可选），如果传入则只返回该租户下的部门
     */
    @GetMapping("/treeselect")
    public AjaxResult treeselect(@RequestParam(required = false) String tenantId) {
        SysDept dept = new SysDept();
        
        // 如果传入了tenantId，按租户过滤
        if (StringUtils.isNotEmpty(tenantId)) {
            dept.setTenantId(tenantId);
        } else {
            // 尝试从当前登录用户获取租户ID
            try {
                SysUser currentUser = SecurityUtils.getLoginUser().getUser();
                if (currentUser != null && StringUtils.isNotEmpty(currentUser.getTenantId())) {
                    dept.setTenantId(currentUser.getTenantId());
                }
            } catch (Exception e) {
                // 未登录用户，返回所有数据（用于注册页面）
            }
        }
        
        return AjaxResult.success(deptService.selectDeptTreeListOpen(dept));
    }
    
    /**
     * 获取部门列表（树形结构）
     * @param tenantId 租户ID
     */
    @GetMapping("/depts")
    public AjaxResult depts(@RequestParam(required = false) String tenantId) {
        SysDept dept = new SysDept();
        dept.setStatus("0"); // 只返回正常状态的部门
        
        if (StringUtils.isNotEmpty(tenantId)) {
            dept.setTenantId(tenantId);
        }
        
        return AjaxResult.success(deptService.selectDeptTreeListOpen(dept));
    }
    
    /**
     * 获取职位列表
     * @param tenantId 租户ID（可选）
     */
    @GetMapping("/posts")
    public AjaxResult posts(@RequestParam(required = false) String tenantId) {
        SysPost post = new SysPost();
        post.setStatus("0"); // 只返回正常状态的职位
        
        // 注意：SysPost 可能没有 tenantId 字段，需要检查
        // 如果有的话可以按租户过滤
        
        List<SysPost> list = postService.selectPostList(post);
        return AjaxResult.success(list);
    }
}


