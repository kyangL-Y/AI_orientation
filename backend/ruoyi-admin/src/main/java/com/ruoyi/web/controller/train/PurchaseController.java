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
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.train.domain.TrainUserPurchase;
import com.ruoyi.train.service.IPurchaseService;
import com.ruoyi.common.core.page.TableDataInfo;

/**
 * 购买记录Controller
 * 
 * @author Yjo
 * @date 2026-01-14
 */
@RestController
@RequestMapping("/train/membership/purchase")
public class PurchaseController extends BaseController
{
    @Autowired
    private IPurchaseService purchaseService;

    /**
     * 查询我的购买记录
     */
    @GetMapping("/my")
    public TableDataInfo myPurchases()
    {
        startPage();
        TrainUserPurchase query = new TrainUserPurchase();
        query.setUserId(SecurityUtils.getUserId());
        List<TrainUserPurchase> list = purchaseService.selectTrainUserPurchaseList(query);
        return getDataTable(list);
    }

    /**
     * 创建B2B订单
     */
    @PostMapping("/create-b2b")
    public AjaxResult createB2BOrder(@RequestBody Map<String, Object> params)
    {
        String levelCode = (String) params.get("levelCode");
        Integer accountCount = (Integer) params.get("accountCount");
        Long userId = SecurityUtils.getUserId();
        
        String orderNo = purchaseService.createB2BOrder(userId, levelCode, accountCount);
        return AjaxResult.success("订单创建成功", orderNo);
    }
    
    /**
     * 模拟支付
     */
    @PostMapping("/pay")
    public AjaxResult pay(@RequestBody Map<String, String> params)
    {
        String orderNo = params.get("orderNo");
        String method = params.get("method"); // wechat/alipay
        
        boolean result = purchaseService.processPayment(orderNo, method);
        return result ? success("支付成功") : error("支付失败，订单无效");
    }
}
