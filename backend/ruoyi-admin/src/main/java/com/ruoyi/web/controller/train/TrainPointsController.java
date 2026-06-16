package com.ruoyi.web.controller.train;

import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Points APIs for frontend integration.
 */
@RestController
@RequestMapping("/train/points")
public class TrainPointsController extends BaseController {

    /**
     * My current points
     */
    @GetMapping("/my")
    public AjaxResult myPoints() {
        Map<String, Object> data = new HashMap<>();
        data.put("points", 860);
        data.put("level", "银卡");
        return AjaxResult.success(data);
    }

    /**
     * Points records list
     */
    @GetMapping("/records")
    public AjaxResult records() {
        List<Map<String, Object>> list = new ArrayList<>();
        list.add(record("学习课程", +20));
        list.add(record("完成练习", +15));
        list.add(record("考试通过", +60));
        list.add(record("迟到扣分", -5));
        return AjaxResult.success(list);
    }

    private Map<String, Object> record(String reason, int change) {
        Map<String, Object> m = new HashMap<>();
        m.put("reason", reason);
        m.put("change", change);
        m.put("time", new Date());
        return m;
    }
}


