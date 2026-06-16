package com.ruoyi.web.controller.train;

import java.util.List;
import javax.servlet.http.HttpServletResponse;
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
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.system.domain.TrainKnowledgeBase;
import com.ruoyi.system.service.ITrainKnowledgeBaseService;
import com.ruoyi.common.utils.poi.ExcelUtil;
import com.ruoyi.common.core.page.TableDataInfo;

/**
 * 培训知识库Controller
 * 
 * @author ruoyi
 */
@RestController
@RequestMapping("/train/knowledge")
public class TrainKnowledgeController extends BaseController
{
    @Autowired
    private ITrainKnowledgeBaseService trainKnowledgeBaseService;

    /**
     * 查询培训知识库列表
     */
    @PreAuthorize("@ss.hasPermi('train:knowledge:list')")
    @GetMapping("/list")
    public TableDataInfo list(TrainKnowledgeBase trainKnowledgeBase)
    {
        startPage();
        List<TrainKnowledgeBase> list = trainKnowledgeBaseService.selectTrainKnowledgeBaseList(trainKnowledgeBase);
        return getDataTable(list);
    }

    /**
     * 获取培训知识库详细信息
     */
    @PreAuthorize("@ss.hasPermi('train:knowledge:query')")
    @GetMapping(value = "/{id}")
    public AjaxResult getInfo(@PathVariable("id") Long id)
    {
        return success(trainKnowledgeBaseService.selectTrainKnowledgeBaseById(id));
    }

    /**
     * 新增培训知识库
     */
    @PreAuthorize("@ss.hasPermi('train:knowledge:add')")
    @Log(title = "培训知识库", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody TrainKnowledgeBase trainKnowledgeBase)
    {
        return toAjax(trainKnowledgeBaseService.insertTrainKnowledgeBase(trainKnowledgeBase));
    }

    /**
     * 修改培训知识库
     */
    @PreAuthorize("@ss.hasPermi('train:knowledge:edit')")
    @Log(title = "培训知识库", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody TrainKnowledgeBase trainKnowledgeBase)
    {
        return toAjax(trainKnowledgeBaseService.updateTrainKnowledgeBase(trainKnowledgeBase));
    }

    /**
     * 删除培训知识库
     */
    @PreAuthorize("@ss.hasPermi('train:knowledge:remove')")
    @Log(title = "培训知识库", businessType = BusinessType.DELETE)
	@DeleteMapping("/{ids}")
    public AjaxResult remove(@PathVariable Long[] ids)
    {
        return toAjax(trainKnowledgeBaseService.deleteTrainKnowledgeBaseByIds(ids));
    }

    /**
     * 导出培训知识库列表
     */
    @PreAuthorize("@ss.hasPermi('train:knowledge:export')")
    @Log(title = "培训知识库", businessType = BusinessType.EXPORT)
    @GetMapping("/export")
    public void export(HttpServletResponse response, TrainKnowledgeBase trainKnowledgeBase)
    {
        List<TrainKnowledgeBase> list = trainKnowledgeBaseService.selectTrainKnowledgeBaseList(trainKnowledgeBase);
        ExcelUtil<TrainKnowledgeBase> util = new ExcelUtil<TrainKnowledgeBase>(TrainKnowledgeBase.class);
        util.exportExcel(response, list, "知识库数据");
    }
}
