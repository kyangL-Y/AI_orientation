package com.ruoyi.web.controller.train;

import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.system.domain.TrainCourse;
import com.ruoyi.system.service.ITrainCourseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import org.springframework.security.access.prepost.PreAuthorize;

@RestController
@RequestMapping("/train/course")
public class TrainCourseController extends BaseController {
    @Autowired
    private ITrainCourseService courseService;

    @PreAuthorize("isAuthenticated()")
    @GetMapping("/list")
    public TableDataInfo list(TrainCourse query) {
        startPage();
        List<TrainCourse> list = courseService.selectList(query);
        return getDataTable(list);
    }

    @GetMapping("/{courseId}")
    public AjaxResult get(@PathVariable Long courseId) {
        return AjaxResult.success(courseService.selectById(courseId));
    }

    @PostMapping
    public AjaxResult add(@RequestBody TrainCourse course) {
        return toAjax(courseService.insert(course));
    }

    @PutMapping
    public AjaxResult edit(@RequestBody TrainCourse course) {
        return toAjax(courseService.update(course));
    }

    @DeleteMapping("/{ids}")
    public AjaxResult remove(@PathVariable Long[] ids) {
        return toAjax(courseService.deleteByIds(ids));
    }
}

