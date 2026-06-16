package com.ruoyi.web.controller.train;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
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
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.train.domain.TrainPaidContent;
import com.ruoyi.train.service.IPaidContentService;
import com.ruoyi.common.core.page.TableDataInfo;

/**
 * 付费内容Controller
 * 
 * @author Yjo
 * @date 2026-01-14
 */
@RestController
@RequestMapping("/train/membership/content")
public class PaidContentController extends BaseController
{
    @Autowired
    private IPaidContentService trainPaidContentService;

    /**
     * 查询付费内容列表
     */
    @PreAuthorize("@ss.hasPermi('train:membership:content:list')")
    @GetMapping("/list")
    public TableDataInfo list(TrainPaidContent trainPaidContent)
    {
        startPage();
        List<TrainPaidContent> list = trainPaidContentService.selectTrainPaidContentList(trainPaidContent);
        return getDataTable(list);
    }

    /**
     * 获取付费内容详细信息
     */
    @PreAuthorize("@ss.hasPermi('train:membership:content:query')")
    @GetMapping(value = "/{contentId}")
    public AjaxResult getInfo(@PathVariable("contentId") Long contentId)
    {
        return success(trainPaidContentService.selectTrainPaidContentByContentId(contentId));
    }

    /**
     * 新增付费内容
     */
    @PreAuthorize("@ss.hasPermi('train:membership:content:add')")
    @Log(title = "付费内容", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody TrainPaidContent trainPaidContent)
    {
        return toAjax(trainPaidContentService.insertTrainPaidContent(trainPaidContent));
    }

    /**
     * 修改付费内容
     */
    @PreAuthorize("@ss.hasPermi('train:membership:content:edit')")
    @Log(title = "付费内容", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody TrainPaidContent trainPaidContent)
    {
        return toAjax(trainPaidContentService.updateTrainPaidContent(trainPaidContent));
    }

    /**
     * 删除付费内容
     */
    @PreAuthorize("@ss.hasPermi('train:membership:content:remove')")
    @Log(title = "付费内容", businessType = BusinessType.DELETE)
	@DeleteMapping(value = "/{contentIds}")
    public AjaxResult remove(@PathVariable Long[] contentIds)
    {
        return toAjax(trainPaidContentService.deleteTrainPaidContentByContentIds(contentIds));
    }
}
