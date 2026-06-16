package com.ruoyi.web.controller.train;

import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.system.domain.TrainStudyAssign;
import com.ruoyi.system.service.ITrainStudyAssignService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 学习管理控制器
 */
@RestController
@RequestMapping("/train/study")
public class TrainStudyController extends BaseController {

    @Autowired
    private ITrainStudyAssignService trainStudyAssignService;

    @PreAuthorize("@ss.hasPermi('train:study:list')")
    @GetMapping("/list")
    public TableDataInfo list(@RequestParam(required = false) Map<String, Object> params) {
        List<Map<String, Object>> list = new ArrayList<>();
        // 模拟学习记录数据
        Map<String, Object> item = new HashMap<>();
        item.put("id", 1L);
        item.put("courseName", "基础培训课程");
        item.put("progress", 80);
        item.put("status", "进行中");
        item.put("startTime", "2024-01-01");
        list.add(item);
        
        TableDataInfo dataTable = new TableDataInfo();
        dataTable.setCode(200);
        dataTable.setRows(list);
        dataTable.setTotal(list.size());
        return dataTable;
    }

    @PreAuthorize("@ss.hasPermi('train:study:query')")
    @GetMapping(value = "/{id}")
    public AjaxResult getInfo(@PathVariable Long id) {
        Map<String, Object> data = new HashMap<>();
        data.put("id", id);
        data.put("courseName", "基础培训课程");
        data.put("progress", 80);
        data.put("status", "进行中");
        data.put("startTime", "2024-01-01");
        return success(data);
    }

    @PreAuthorize("@ss.hasPermi('train:study:query')")
    @GetMapping("/assign-info/{studyId}")
    public AjaxResult getAssign(@PathVariable Long studyId) {
        List<TrainStudyAssign> assigns = trainStudyAssignService.selectByStudyId(studyId);
        return success(assigns);
    }

    @PreAuthorize("@ss.hasPermi('train:study:edit')")
    @Log(title = "学习管理权限管理", businessType = BusinessType.UPDATE)
    @PostMapping("/assign-info/{studyId}")
    public AjaxResult saveAssign(@PathVariable Long studyId, @RequestBody List<TrainStudyAssign> assigns) {
        return toAjax(trainStudyAssignService.batchInsert(studyId, assigns, getUsername()));
    }
}