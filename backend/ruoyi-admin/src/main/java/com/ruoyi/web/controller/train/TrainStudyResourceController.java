package com.ruoyi.web.controller.train;

import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 学习资源相关API控制器
 */
@RestController
@RequestMapping("/train/study-resources")
public class TrainStudyResourceController extends BaseController {

    /**
     * 获取学习资源列表
     */
    @GetMapping("/list")
    public AjaxResult getStudyResources(@RequestParam(required = false) Map<String, Object> params) {
        List<Map<String, Object>> resources = new ArrayList<>();
        
        // 模拟学习资源数据
        Map<String, Object> resource1 = new HashMap<>();
        resource1.put("id", 1L);
        resource1.put("title", "酒店前台服务标准");
        resource1.put("description", "学习酒店前台服务的基本流程和标准");
        resource1.put("type", "视频课程");
        resource1.put("duration", "2小时30分钟");
        resource1.put("difficulty", "初级");
        resource1.put("category", "前台服务");
        resource1.put("progress", 75);
        resource1.put("status", "进行中");
        resource1.put("thumbnail", "/images/course1.jpg");
        resources.add(resource1);
        
        Map<String, Object> resource2 = new HashMap<>();
        resource2.put("id", 2L);
        resource2.put("title", "客房清洁标准操作");
        resource2.put("description", "掌握客房清洁的标准操作流程");
        resource2.put("type", "文档教程");
        resource2.put("duration", "1小时15分钟");
        resource2.put("difficulty", "中级");
        resource2.put("category", "客房管理");
        resource2.put("progress", 100);
        resource2.put("status", "已完成");
        resource2.put("thumbnail", "/images/course2.jpg");
        resources.add(resource2);
        
        Map<String, Object> resource3 = new HashMap<>();
        resource3.put("id", 3L);
        resource3.put("title", "餐饮服务礼仪");
        resource3.put("description", "学习餐饮服务的基本礼仪和技巧");
        resource3.put("type", "视频课程");
        resource3.put("duration", "3小时");
        resource3.put("difficulty", "初级");
        resource3.put("category", "餐饮服务");
        resource3.put("progress", 0);
        resource3.put("status", "未开始");
        resource3.put("thumbnail", "/images/course3.jpg");
        resources.add(resource3);
        
        return success(resources);
    }

    /**
     * 获取学习分类
     */
    @GetMapping("/categories")
    public AjaxResult getStudyCategories() {
        List<Map<String, Object>> categories = new ArrayList<>();
        
        Map<String, Object> category1 = new HashMap<>();
        category1.put("id", 1L);
        category1.put("name", "前台服务");
        category1.put("count", 15);
        category1.put("icon", "front-desk");
        categories.add(category1);
        
        Map<String, Object> category2 = new HashMap<>();
        category2.put("id", 2L);
        category2.put("name", "客房管理");
        category2.put("count", 12);
        category2.put("icon", "room-service");
        categories.add(category2);
        
        Map<String, Object> category3 = new HashMap<>();
        category3.put("id", 3L);
        category3.put("name", "餐饮服务");
        category3.put("count", 8);
        category3.put("icon", "restaurant");
        categories.add(category3);
        
        Map<String, Object> category4 = new HashMap<>();
        category4.put("id", 4L);
        category4.put("name", "安全管理");
        category4.put("count", 6);
        category4.put("icon", "security");
        categories.add(category4);
        
        return success(categories);
    }

    /**
     * 获取推荐课程
     */
    @GetMapping("/recommended")
    public AjaxResult getRecommendedCourses() {
        List<Map<String, Object>> courses = new ArrayList<>();
        
        Map<String, Object> course1 = new HashMap<>();
        course1.put("id", 1L);
        course1.put("title", "酒店服务英语口语");
        course1.put("description", "提升酒店服务英语口语能力");
        course1.put("rating", 4.8);
        course1.put("students", 1250);
        course1.put("duration", "4小时");
        course1.put("price", 0);
        course1.put("thumbnail", "/images/recommended1.jpg");
        courses.add(course1);
        
        Map<String, Object> course2 = new HashMap<>();
        course2.put("id", 2L);
        course2.put("title", "客户投诉处理技巧");
        course2.put("description", "学习处理客户投诉的有效方法");
        course2.put("rating", 4.6);
        course2.put("students", 890);
        course2.put("duration", "2.5小时");
        course2.put("price", 0);
        course2.put("thumbnail", "/images/recommended2.jpg");
        courses.add(course2);
        
        return success(courses);
    }

    /**
     * 获取用户学习进度
     */
    @GetMapping("/progress")
    public AjaxResult getUserStudyProgress() {
        Map<String, Object> progress = new HashMap<>();
        progress.put("totalCourses", 20);
        progress.put("completedCourses", 8);
        progress.put("inProgressCourses", 3);
        progress.put("totalHours", 45);
        progress.put("thisWeekHours", 8);
        progress.put("currentStreak", 7);
        progress.put("longestStreak", 15);
        
        return success(progress);
    }
}
