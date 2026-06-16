package com.ruoyi.web.controller.train;

import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.system.domain.TrainShopItem;
import com.ruoyi.system.domain.TrainShopOrder;
import com.ruoyi.system.service.ITrainShopService;
import com.ruoyi.system.service.ITrainUserPointsService;

/**
 * 积分商城Controller
 */
@RestController
@RequestMapping("/train/shop")
public class TrainShopController extends BaseController
{
    @Autowired
    private ITrainShopService trainShopService;
    
    @Autowired
    private ITrainUserPointsService trainUserPointsService;

    /**
     * 查询商品列表 (用户端/管理端)
     * 管理端不传status可查所有，用户端通常只查status=1
     */
    @GetMapping("/list")
    public TableDataInfo list(TrainShopItem item)
    {
        startPage();
        List<TrainShopItem> list = trainShopService.selectShopItemList(item);
        return getDataTable(list);
    }
    
    /**
     * 获取商品详细信息
     */
    @PreAuthorize("@ss.hasPermi('train:shop:query')")
    @GetMapping(value = "/{itemId}")
    public AjaxResult getInfo(@PathVariable("itemId") Long itemId)
    {
        return success(trainShopService.selectShopItemById(itemId));
    }

    /**
     * 新增商品
     */
    @PreAuthorize("@ss.hasPermi('train:shop:add')")
    @Log(title = "积分商城", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody TrainShopItem item)
    {
        item.setCreateBy(getUsername());
        return toAjax(trainShopService.insertShopItem(item));
    }

    /**
     * 修改商品
     */
    @PreAuthorize("@ss.hasPermi('train:shop:edit')")
    @Log(title = "积分商城", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody TrainShopItem item)
    {
        item.setUpdateBy(getUsername());
        return toAjax(trainShopService.updateShopItem(item));
    }

    /**
     * 删除商品
     */
    @PreAuthorize("@ss.hasPermi('train:shop:remove')")
    @Log(title = "积分商城", businessType = BusinessType.DELETE)
	@DeleteMapping("/{itemIds}")
    public AjaxResult remove(@PathVariable Long[] itemIds)
    {
        return toAjax(trainShopService.deleteShopItemByIds(itemIds));
    }

    /**
     * 兑换商品 (用户端)
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping("/redeem")
    @Log(title = "积分商城", businessType = BusinessType.INSERT)
    public AjaxResult redeem(@RequestBody Map<String, Long> params)
    {
        Long userId = getUserId(); // 必须登录
        if (userId == null) {
            return error("请先登录");
        }
        
        Long itemId = params.get("itemId");
        if (itemId == null) {
            return error("参数错误");
        }
        
        String result = trainShopService.redeemItem(userId, itemId);
        if ("success".equals(result)) {
            return success("兑换成功");
        } else {
            return error(result);
        }
    }

    /**
     * 查询我的兑换记录 (用户端)
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/my-orders")
    public TableDataInfo myOrders()
    {
        Long userId = getUserId();
        if (userId == null) {
            return getDataTable(java.util.Collections.emptyList());
        }
        startPage();
        List<TrainShopOrder> list = trainShopService.selectUserOrders(userId);
        return getDataTable(list);
    }
    
    /**
     * 查询所有订单 (管理端)
     */
    @PreAuthorize("@ss.hasPermi('train:shop:order:list')")
    @GetMapping("/orders")
    public TableDataInfo orderList(TrainShopOrder order)
    {
        startPage();
        List<TrainShopOrder> list = trainShopService.selectOrderList(order);
        return getDataTable(list);
    }
    
    /**
     * 修改订单状态 (管理端)
     */
    @PreAuthorize("@ss.hasPermi('train:shop:order:edit')")
    @Log(title = "积分商城订单", businessType = BusinessType.UPDATE)
    @PutMapping("/order")
    public AjaxResult editOrder(@RequestBody TrainShopOrder order)
    {
        return toAjax(trainShopService.updateShopOrder(order));
    }
    
    /**
     * 获取我的积分信息
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/my-points")
    public AjaxResult myPoints()
    {
        Long userId = getUserId();
        if (userId == null) {
            return success(0);
        }
        return success(trainUserPointsService.getUserTotalPoints(userId));
    }
}
