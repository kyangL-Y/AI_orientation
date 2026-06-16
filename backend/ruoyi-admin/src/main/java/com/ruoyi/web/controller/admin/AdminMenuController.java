package com.ruoyi.web.controller.admin;

import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.domain.entity.SysMenu;
import com.ruoyi.system.domain.vo.RouterVo;
import com.ruoyi.system.service.IAdminMenuService;
import com.ruoyi.system.service.ISysMenuService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

/**
 * 管理端菜单Controller
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/admin/menu")
public class AdminMenuController extends BaseController
{
    @Autowired
    private IAdminMenuService adminMenuService;
    
    @Autowired
    private ISysMenuService menuService;

    /**
     * 获取当前用户的菜单树（路由格式）
     */
    @GetMapping("/getMenuTree")
    public AjaxResult getMenuTree()
    {
        List<SysMenu> menus = adminMenuService.getMenusByUser();
        List<SysMenu> menuTree = adminMenuService.buildMenuTree(menus);
        // 转换为路由格式，与 getRouters 接口保持一致
        List<RouterVo> result = menuService.buildMenus(menuTree);

        // 【调试】打印返回的菜单数据
        try {
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            String json = mapper.writerWithDefaultPrettyPrinter().writeValueAsString(result);
            logger.info("========== 返回给前端的菜单数据 ==========");
            logger.info(json);
            logger.info("==========================================");
        } catch (Exception e) {
            logger.error("序列化菜单数据失败", e);
        }

        return success(result);
    }

    /**
     * 获取当前用户的菜单列表
     */
    @GetMapping("/list")
    public AjaxResult list()
    {
        List<SysMenu> menus = adminMenuService.getMenusByUser();
        return success(menus);
    }
}
