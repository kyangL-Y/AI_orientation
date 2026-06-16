package com.ruoyi.web.controller.train;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
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
import com.ruoyi.common.utils.SecurityUtils;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.system.domain.LearningPath;
import com.ruoyi.system.domain.UserLearningPath;
import com.ruoyi.system.service.ILearningPathService;
import com.ruoyi.system.service.IUserLearningPathService;
import com.ruoyi.common.core.page.TableDataInfo;

/**
 * 学习路径Controller
 * 
 * @author ruoyi
 * @date 2025-01-30
 */
@RestController
@RequestMapping("/train/path")
public class LearningPathController extends BaseController
{
    @Autowired
    private ILearningPathService learningPathService;
    
    @Autowired
    private IUserLearningPathService userLearningPathService;

    /**
     * 查询学习路径列表
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/list")
    public TableDataInfo list(LearningPath learningPath)
    {
        startPage();
        List<LearningPath> list = learningPathService.selectLearningPathList(learningPath);
        return getDataTable(list);
    }

    /**
     * 获取学习路径详细信息
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping(value = "/{pathId}")
    public AjaxResult getInfo(@PathVariable("pathId") Long pathId)
    {
        Map<String, Object> detail = learningPathService.getLearningPathDetail(pathId);
        return success(detail);
    }

    @PreAuthorize("@ss.hasPermi('train:plans:query')")
    @GetMapping(value = "/assign-info/{pathId}")
    public AjaxResult getAssignInfo(@PathVariable("pathId") Long pathId)
    {
        LearningPath path = learningPathService.selectLearningPathByPathId(pathId);
        boolean assignAll = path != null && Boolean.TRUE.equals(path.getAutoAssignAll());

        Map<String, Object> result = new HashMap<>();
        result.put("pathId", pathId);
        result.put("assignAll", assignAll);

        if (assignAll)
        {
            result.put("userIds", java.util.Collections.emptyList());
            return success(result);
        }

        UserLearningPath query = new UserLearningPath();
        query.setPathId(pathId);
        List<UserLearningPath> assigns = userLearningPathService.selectUserLearningPathList(query);
        List<Long> userIds = assigns == null ? java.util.Collections.emptyList() : assigns.stream()
            .map(UserLearningPath::getUserId)
            .filter(id -> id != null)
            .distinct()
            .collect(Collectors.toList());

        result.put("userIds", userIds);
        return success(result);
    }

    /**
     * 新增学习路径
     */
    @PreAuthorize("@ss.hasPermi('train:path:add')")
    @Log(title = "学习路径", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody LearningPath learningPath)
    {
        return toAjax(learningPathService.insertLearningPath(learningPath));
    }

    /**
     * 修改学习路径
     */
    @PreAuthorize("@ss.hasPermi('train:path:edit')")
    @Log(title = "学习路径", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody LearningPath learningPath)
    {
        return toAjax(learningPathService.updateLearningPath(learningPath));
    }

    /**
     * 删除学习路径
     */
    @PreAuthorize("@ss.hasPermi('train:path:remove')")
    @Log(title = "学习路径", businessType = BusinessType.DELETE)
	@DeleteMapping("/{pathIds}")
    public AjaxResult remove(@PathVariable Long[] pathIds)
    {
        return toAjax(learningPathService.deleteLearningPathByPathIds(pathIds));
    }
    
    /**
     * 查询用户的学习路径
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/user/{userId}")
    public AjaxResult getUserPaths(@PathVariable("userId") Long userId)
    {
        Long currentUserId = SecurityUtils.getUserId();
        if (currentUserId == null || !currentUserId.equals(userId)) {
            return error("无权限查看其他用户学习路径");
        }
        List<LearningPath> list = learningPathService.selectUserLearningPaths(userId);
        return success(list);
    }
    
    /**
     * 查询当前登录用户的学习路径
     */
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/my")
    public AjaxResult getMyPaths()
    {
        Long userId = SecurityUtils.getUserId();
        List<LearningPath> list = learningPathService.selectUserLearningPaths(userId);
        return success(list);
    }
    
    /**
     * 更新学习路径-计划关联信息（sequence和isRequired）
     */
    @PreAuthorize("@ss.hasPermi('train:path:edit')")
    @PutMapping("/plan/relation")
    public AjaxResult updatePathPlanRelation(@RequestBody Map<String, Object> params)
    {
        Long pathId = params.get("pathId") != null ? Long.valueOf(params.get("pathId").toString()) : null;
        Long planId = params.get("planId") != null ? Long.valueOf(params.get("planId").toString()) : null;
        Integer sequence = params.get("sequence") != null ? Integer.valueOf(params.get("sequence").toString()) : null;
        Integer isRequired = params.get("isRequired") != null ? Integer.valueOf(params.get("isRequired").toString()) : null;
        
        if (pathId == null || planId == null) {
            return error("路径ID和计划ID不能为空");
        }
        
        int result = learningPathService.updatePathPlanRelation(pathId, planId, sequence, isRequired);
        return result > 0 ? success("更新成功") : error("更新失败");
    }
    
    /**
     * 分配学习路径给用户
     */
    @PreAuthorize("@ss.hasPermi('train:path:assign')")
    @Log(title = "学习路径", businessType = BusinessType.UPDATE)
    @PostMapping("/assign")
    public AjaxResult assignPathToUsers(@RequestBody Map<String, Object> params)
    {
        Long pathId = params.get("pathId") != null ? Long.valueOf(params.get("pathId").toString()) : null;
        Boolean assignAll = params.get("assignAll") != null ? Boolean.valueOf(params.get("assignAll").toString()) : Boolean.FALSE;
        @SuppressWarnings("unchecked")
        List<Object> userIdList = (List<Object>) params.get("userIds");
        
        if (pathId == null) {
            return error("路径ID不能为空");
        }
        
        if (Boolean.TRUE.equals(assignAll)) {
            learningPathService.updateAutoAssignAll(pathId, true);
            int result = userLearningPathService.assignPathToAllUsers(pathId);
            return success("已为全员分配学习路径，目前新增 " + result + " 名用户，后续新用户将自动加入该路径");
        }

        if (userIdList == null || userIdList.isEmpty()) {
            return error("请选择要分配的用户");
        }
        
        Long[] userIds = new Long[userIdList.size()];
        for (int i = 0; i < userIdList.size(); i++) {
            userIds[i] = Long.valueOf(userIdList.get(i).toString());
        }
        
        learningPathService.updateAutoAssignAll(pathId, false);
        int result = userLearningPathService.assignPathToUsers(userIds, pathId);
        return result > 0 ? success("分配成功，共分配给 " + result + " 个用户") : error("分配失败");
    }
    
    /**
     * 取消用户的学习路径分配
     */
    @PreAuthorize("@ss.hasPermi('train:path:assign')")
    @Log(title = "学习路径", businessType = BusinessType.DELETE)
    @DeleteMapping("/unassign")
    public AjaxResult unassignPathFromUser(@RequestBody Map<String, Object> params)
    {
        Long userId = params.get("userId") != null ? Long.valueOf(params.get("userId").toString()) : null;
        Long pathId = params.get("pathId") != null ? Long.valueOf(params.get("pathId").toString()) : null;
        
        if (userId == null || pathId == null) {
            return error("用户ID和路径ID不能为空");
        }
        
        int result = userLearningPathService.unassignPathFromUser(userId, pathId);
        return result > 0 ? success("取消分配成功") : error("取消分配失败");
    }
}
