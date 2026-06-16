package com.ruoyi.web.controller.train;

import java.util.List;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.train.domain.TrainMembershipLevel;
import com.ruoyi.train.service.IMembershipService;

/**
 * 会员等级Controller
 * 
 * @author ruoyi
 * @date 2026-01-14
 */
@RestController
@RequestMapping("/train/membership/level")
public class MembershipLevelController extends BaseController
{
    @Autowired
    private IMembershipService membershipService;

    /**
     * 查询会员等级列表
     */
    @PreAuthorize("@ss.hasPermi('train:membership:level:list')")
    @GetMapping("/list")
    public TableDataInfo list(TrainMembershipLevel trainMembershipLevel)
    {
        startPage();
        List<TrainMembershipLevel> list = membershipService.selectTrainMembershipLevelList(trainMembershipLevel);
        return getDataTable(list);
    }
    
    /**
     * 获取所有可用会员等级 (公开接口)
     */
    @GetMapping("/active")
    public AjaxResult getActiveLevels()
    {
        return AjaxResult.success(membershipService.selectActiveLevels());
    }

    /**
     * 获取会员等级详细信息
     */
    @PreAuthorize("@ss.hasPermi('train:membership:level:query')")
    @GetMapping(value = "/{levelId}")
    public AjaxResult getInfo(@PathVariable("levelId") Long levelId)
    {
        return AjaxResult.success(membershipService.selectTrainMembershipLevelByLevelId(levelId));
    }
    
    // 注意：增删改功能通常由后台管理，此处仅实现基础查询，完整管理功能可后续补充
}
