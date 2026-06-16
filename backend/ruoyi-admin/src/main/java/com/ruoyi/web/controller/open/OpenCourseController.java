package com.ruoyi.web.controller.open;

import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.system.domain.TrainCourse;
import com.ruoyi.system.service.ITrainCourseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

/**
 * 开放课程接口 - 无需认证
 */
@RestController
@RequestMapping("/open/course")
public class OpenCourseController extends BaseController {
    
    @Autowired
    private ITrainCourseService courseService;

    /**
     * 获取课程列表 - 开放接口，无需认证
     */
    @GetMapping("/list")
    public TableDataInfo list(TrainCourse query) {
        startPage();
        List<TrainCourse> list = courseService.selectList(query);
        return getDataTable(list);
    }

    /**
     * 获取课程详情 - 开放接口，无需认证
     */
    @GetMapping("/{courseId}")
    public AjaxResult get(@PathVariable Long courseId) {
        return AjaxResult.success(courseService.selectById(courseId));
    }
}
